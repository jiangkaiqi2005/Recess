import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/repositories/backup_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/full_week_course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/import/application/import_commit.dart';
import 'package:recess/features/import/domain/import_course.dart';
import 'package:recess/features/import/domain/webview_course_parser.dart';

void main() {
  late db.AppDatabase database;
  final semester = Semester(
    id: 's1',
    name: '2026 秋',
    startDate: DateTime(2026, 8, 31),
    totalWeeks: 20,
  );
  final context = WebviewPreviewContext.fromSemester(semester);

  setUp(() async {
    database = db.AppDatabase(NativeDatabase.memory());
    await SemesterRepository(database).upsert(semester, activate: true);
  });
  tearDown(() => database.close());

  Map<String, dynamic> fullWeekRecord(String name, List<int> weeks) => {
        'name': name,
        'dayOfWeek': null,
        'startSection': null,
        'endSection': null,
        'weeks': weeks,
        'fullWeek': true,
      };
  Map<String, dynamic> lectureRecord(String name) => {
        'name': name,
        'dayOfWeek': 1,
        'startSection': 1,
        'endSection': 2,
        'weeks': [1, 2],
      };

  group('教务预览', () {
    test('整周记录不要求星期和节次，并显示为「整周」', () {
      final preview = previewWebviewCourses([
        fullWeekRecord('硬件综合设计', [20, 18, 19]),
        lectureRecord('边缘计算'),
      ], context);

      expect(preview.skippedCount, 0);
      final fullWeek = preview.courses.first;
      expect(fullWeek.fullWeek, isTrue);
      expect(fullWeek.weeks, [18, 19, 20]);
      expect(fullWeek.sectionLabel, '整周');
      expect(preview.courses.last.fullWeek, isFalse);
    });

    test('整周记录缺周次仍被跳过，超出学期周数仍阻止提交', () {
      final preview = previewWebviewCourses([
        fullWeekRecord('课程设计', []),
        fullWeekRecord('硬件综合设计', [21]),
      ], context);

      expect(preview.skippedReasons, {'周次缺失或无效': 1});
      expect(preview.weekConflicts.single, contains('21'));
      expect(preview.canSubmit, isFalse);
    });

    test('整周课之间、整周课与普通课都不算时间冲突', () {
      final a = ImportCourse.fullWeek(
          name: '操作系统课程设计', weeks: const [17], source: 'webview');
      final b = ImportCourse.fullWeek(
          name: '计算机网络课程设计', weeks: const [17], source: 'webview');
      const lecture = Course(
        id: 'c1',
        semesterId: 's1',
        name: '边缘计算',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        weeks: [17],
      );

      expect(coursesConflict(a, b), isFalse);
      expect(conflictsWithCourse(a, lecture), isFalse);
      expect(conflictNames([a, b], [lecture]), isEmpty);
      expect(a.withSelected(false).fullWeek, isTrue);
    });
  });

  group('导入提交', () {
    ImportSubmission submission(ImportMode mode, List<ImportCourse> courses) =>
        ImportSubmission.webview(
          semesterId: 's1',
          mode: mode,
          courses: courses,
          previewContext: context,
        );

    test('同名课程每节课颜色相同，不同课程颜色不同', () {
      final s = submission(ImportMode.replace, [
        ImportCourse(
            name: '高数', dayOfWeek: 1, startSection: 1, endSection: 2,
            weeks: const [1], source: 'webview'),
        ImportCourse(
            name: '物理', dayOfWeek: 2, startSection: 1, endSection: 2,
            weeks: const [1], source: 'webview'),
        ImportCourse(
            name: '高数', dayOfWeek: 3, startSection: 3, endSection: 4,
            weeks: const [1], source: 'webview'),
        ImportCourse.fullWeek(
            name: '课程设计', weeks: const [18], source: 'webview'),
      ]);

      final colors = s.courses.map((c) => c.colorValue).toList();
      expect(colors[0], colors[2]);
      expect(colors[0], isNot(colors[1]));
      expect(s.fullWeekCourses.single.colorValue, isNot(isIn(colors)));
    });

    test('替换导入分别写入普通课和整周课，再次替换会清掉旧整周课', () async {
      final preview = previewWebviewCourses([
        lectureRecord('边缘计算'),
        fullWeekRecord('硬件综合设计', [18, 19, 20]),
      ], context);
      final first = submission(ImportMode.replace, preview.courses);

      expect(first.count, 2);
      expect(await ImportCommit(database).commit(first), 2);
      expect(
        (await CourseRepository(database).getCourses('s1')).single.name,
        '边缘计算',
      );
      final stored = await FullWeekCourseRepository(database).getAll('s1');
      expect(stored.single.name, '硬件综合设计');
      expect(stored.single.weeks, [18, 19, 20]);

      final onlyLecture = previewWebviewCourses(
        [lectureRecord('计算机网络')],
        context,
      );
      await ImportCommit(database)
          .commit(submission(ImportMode.replace, onlyLecture.courses));
      expect(await FullWeekCourseRepository(database).getAll('s1'), isEmpty);
    });

    test('合并导入追加整周课，只有整周课也能提交', () async {
      final preview = previewWebviewCourses(
        [fullWeekRecord('操作系统课程设计', [17])],
        context,
      );
      final merge = submission(ImportMode.merge, preview.courses);

      expect(merge.isEmpty, isFalse);
      await ImportCommit(database).commit(merge);
      await ImportCommit(database).commit(
        submission(ImportMode.merge, preview.courses),
      );
      expect(await FullWeekCourseRepository(database).getAll('s1'), hasLength(2));
    });
  });

  test('删除学期时一并删除整周课', () async {
    await FullWeekCourseRepository(database).addAll('s1', const [
      FullWeekCourse(id: 'f1', semesterId: 's1', name: '课程设计', weeks: [17]),
    ]);
    await SemesterRepository(database).delete('s1');

    expect(await FullWeekCourseRepository(database).getAll('s1'), isEmpty);
  });

  test('备份导出并恢复整周课，旧备份没有整周课时恢复为空', () async {
    const course = FullWeekCourse(
      id: 'f1',
      semesterId: 's1',
      name: '硬件综合设计',
      location: '实验室',
      weeks: [18, 19, 20],
      colorValue: 0xFF4BA89A,
      notes: '带电脑',
    );
    await FullWeekCourseRepository(database).addAll('s1', const [course]);
    final json = await BackupRepository(database).exportJson();

    final restored = db.AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    final result = await BackupRepository(restored).restore(json);
    expect(result.courseCount, 1);
    expect(await FullWeekCourseRepository(restored).getAll('s1'), [course]);

    final legacy = json.replaceAll('"fullWeekCourses"', '"ignored"');
    await BackupRepository(restored).restore(legacy);
    expect(await FullWeekCourseRepository(restored).getAll('s1'), isEmpty);
  });
}
