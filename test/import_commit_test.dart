import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/import/application/import_provider.dart';
import 'package:recess/features/import/application/import_commit.dart';
import 'package:recess/features/import/domain/import_course.dart';
import 'package:recess/features/import/presentation/import_screen.dart';
import 'package:recess/features/import/application/webview_import_provider.dart';
import 'package:recess/features/import/application/course_capture_orientation.dart';
import 'package:recess/features/import/presentation/webview_import_screen.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late db.AppDatabase database;
  late ProviderContainer container;
  late _ImportPicker picker;
  const oldPlatform = CoursePlatform(
    purpose: CoursePlatformPurpose.other,
    name: '原平台',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    picker = _ImportPicker();
    FilePicker.platform = picker;
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    final semesters = container.read(semesterRepositoryProvider);
    for (final id in ['s1', 's2']) {
      await semesters.upsert(
        Semester(
          id: id,
          name: id,
          startDate: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
      );
      await container
          .read(courseRepositoryProvider)
          .upsert(
            Course(
              id: 'old-$id',
              semesterId: id,
              name: '高数',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: const [1],
            ),
          );
      await container.read(coursePlatformRepositoryProvider).replacePlatforms(
        id,
        '高数',
        [oldPlatform],
      );
    }
    await semesters.setActive('s1');
  });

  testWidgets('教务提交失败保留预览并提示，重试保留勾选并使用节次时间与自动配色', (tester) async {
    await tester.runAsync(() async {
      await container.read(activeSemesterProvider.future);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('课表')),
          ),
          GoRoute(
            path: '/import',
            builder:
                (_, __) => WebviewImportScreen(
                  orientationController: CourseCaptureOrientationController(
                    setPreferredOrientations: (_) async {},
                  ),
                ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/import');
      await tester.pumpAndSettle();
      final notifier = container.read(webviewImportProvider.notifier);
      final (parsed, _) = importCoursesFromDecoded([
        {
          'name': '高数',
          'dayOfWeek': 2,
          'startSection': 3,
          'endSection': 4,
          'weeks': [1, 2],
        },
        {
          'name': '物理',
          'dayOfWeek': 3,
          'startSection': 1,
          'endSection': 2,
          'weeks': [1],
        },
        {
          'name': '不选',
          'dayOfWeek': 4,
          'startSection': 1,
          'endSection': 2,
          'weeks': [1],
        },
      ]);
      notifier.showPreview(parsed, 0);
      notifier.toggle(2);
      await tester.pumpAndSettle();
      await tester.tap(find.text('导入 (2)'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).single.id,
        'old-s1',
      );
      await database.customStatement('''
        CREATE TRIGGER fail_course BEFORE INSERT ON courses
        WHEN NEW.name = '物理'
        BEGIN SELECT RAISE(ABORT, 'course rejected'); END;
      ''');
      await tester.tap(find.text('导入 (2)'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '替换'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.textContaining('导入失败'), findsOneWidget);
      expect(find.text('导入 (2)'), findsOneWidget);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).single.id,
        'old-s1',
      );
      await database.customStatement('DROP TRIGGER fail_course');
      await tester.tap(find.text('导入 (2)'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await container.read(semesterRepositoryProvider).setActive('s2');
      container.invalidate(activeSemesterProvider);
      await container.read(activeSemesterProvider.future);
      notifier.toggle(1);
      notifier.setMode(ImportMode.merge);
      await tester.tap(find.widgetWithText(FilledButton, '替换'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      final courses = await container
          .read(courseRepositoryProvider)
          .getCourses('s1');
      expect(courses.map((c) => c.name), unorderedEquals(['高数', '物理']));
      final math = courses.singleWhere((c) => c.name == '高数');
      final physics = courses.singleWhere((c) => c.name == '物理');
      expect(
        (math.startTime, math.endTime, math.colorValue),
        ('10:00', '11:40', 0xFF4399F1),
      );
      expect(
        (physics.startTime, physics.endTime, physics.colorValue),
        ('08:00', '09:40', 0xFF4BA89A),
      );
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s2')).single.id,
        'old-s2',
      );
      expect(
        await container
            .read(coursePlatformRepositoryProvider)
            .getPlatforms('s1', '高数'),
        [oldPlatform],
      );
      expect(find.text('已用 2 门课程替换当前课表'), findsOneWidget);
    });
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  testWidgets('文件提交失败在原预览明确反馈，保留选择供重试', (tester) async {
    await tester.runAsync(() async {
      picker.content = jsonEncode({
        'courses': [_jsonCourse('高数')],
        'platforms': {
          '高数': [
            {'purpose': 'other', 'name': '新平台'},
          ],
        },
      });
      await container.read(importProvider.notifier).pickAndParse();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ImportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await database.customStatement('''
        CREATE TRIGGER reject_platform BEFORE INSERT ON course_platforms
        BEGIN SELECT RAISE(ABORT, 'platform rejected'); END;
      ''');
      await tester.tap(find.text('导入 1 门'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '替换'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.textContaining('导入失败'), findsOneWidget);
      expect(find.text('导入 1 门'), findsOneWidget);
      expect(find.text('已导入 1 门课程'), findsNothing);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).single.id,
        'old-s1',
      );
    });
  });

  for (final mode in ImportMode.values) {
    test('JSON ${mode.name} 只写勾选课程及其多个平台组，保留颜色钟点和其他学期', () async {
      picker.content = jsonEncode({
        'courses': [
          _jsonCourse('高数'),
          _jsonCourse('高数'),
          _jsonCourse('物理'),
          _jsonCourse('不选'),
        ],
        'platforms': {
          '高数': [
            {'purpose': 'online_course', 'name': '学习通'},
            {'purpose': 'group', 'name': '课程群'},
          ],
          '物理': [
            {'purpose': 'lab', 'name': '实验平台'},
          ],
          '不选': [
            {'purpose': 'other', 'name': '不应写入'},
          ],
        },
      });
      final notifier = container.read(importProvider.notifier);
      await notifier.pickAndParse();
      notifier.toggleSelected(3);
      notifier.setMode(mode);
      await notifier.confirmImport();
      final actual = await container
          .read(courseRepositoryProvider)
          .getCourses('s1');
      expect(actual, hasLength(mode == ImportMode.merge ? 4 : 3));
      final imported = actual.where((c) => c.id != 'old-s1').toList();
      expect(imported.map((c) => c.name), unorderedEquals(['高数', '高数', '物理']));
      expect(imported.map((c) => c.id).toSet(), hasLength(3));
      expect(
        imported.every((c) => c.id.isNotEmpty && c.semesterId == 's1'),
        isTrue,
      );
      expect(
        imported.every(
          (c) =>
              c.startTime == '10:05' &&
              c.endTime == '11:40' &&
              c.colorValue == 0xFF123456,
        ),
        isTrue,
      );
      final platforms = container.read(coursePlatformRepositoryProvider);
      expect((await platforms.getPlatforms('s1', '高数')).map((p) => p.name), [
        '学习通',
        '课程群',
      ]);
      expect((await platforms.getPlatforms('s1', '物理')).single.name, '实验平台');
      expect(await platforms.getPlatforms('s1', '不选'), isEmpty);
      expect(await platforms.getPlatforms('s2', '高数'), [oldPlatform]);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s2')).single.id,
        'old-s2',
      );
      expect(container.read(importProvider).importedCount, 3);
    });
  }

  for (final raw in [
    null,
    <String, Object>{'高数': []},
    <String, Object>{
      '高数': [
        {'purpose': 'invalid', 'name': '跳过'},
        {'purpose': 'other', 'name': '  '},
        7,
      ],
    },
  ]) {
    test('JSON 未产生有效平台组时保留原平台：$raw', () async {
      picker.content = jsonEncode({
        'courses': [_jsonCourse('高数')],
        if (raw != null) 'platforms': raw,
      });
      final notifier = container.read(importProvider.notifier);
      await notifier.pickAndParse();
      await notifier.confirmImport();
      expect(container.read(importProvider).importedCount, 1);
      expect(
        await container
            .read(coursePlatformRepositoryProvider)
            .getPlatforms('s1', '高数'),
        [oldPlatform],
      );
    });
  }

  test('文件取消选择与全不选不替换任何课程或平台', () async {
    final before =
        jsonDecode(
          await container.read(backupRepositoryProvider).exportJson(),
        )['semesters'];
    final notifier = container.read(importProvider.notifier);
    await notifier.pickAndParse();
    expect(container.read(importProvider).status, ImportStatus.idle);
    picker.content = jsonEncode({
      'courses': [_jsonCourse('高数')],
    });
    await notifier.pickAndParse();
    notifier.setAllSelected(false);
    await notifier.confirmImport();
    expect(container.read(importProvider).status, ImportStatus.preview);
    expect(container.read(importProvider).importedCount, 0);
    expect(
      jsonDecode(
        await container.read(backupRepositoryProvider).exportJson(),
      )['semesters'],
      before,
    );
  });

  test('ICS 文件只提交勾选课程并保留日历钟点和已有平台', () async {
    picker.extension = 'ics';
    picker.content = '''BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:高数
DTSTART:20260907T090500
DTEND:20260907T104000
RRULE:FREQ=WEEKLY;COUNT=1
END:VEVENT
BEGIN:VEVENT
SUMMARY:物理
DTSTART:20260908T140000
DTEND:20260908T153000
END:VEVENT
END:VCALENDAR''';
    final notifier = container.read(importProvider.notifier);
    await notifier.pickAndParse();
    expect(container.read(importProvider).courses, hasLength(2));
    notifier.toggleSelected(1);
    await notifier.confirmImport();
    final course =
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).single;
    expect(
      (course.name, course.startTime, course.endTime),
      ('高数', '09:05', '10:40'),
    );
    expect(course.weeks, [1]);
    expect(container.read(importProvider).importedCount, 1);
    expect(
      await container
          .read(coursePlatformRepositoryProvider)
          .getPlatforms('s1', '高数'),
      [oldPlatform],
    );
  });

  test('共同提交使用不可变快照，之后改变选择、周次与平台不会改变结果', () async {
    final weeks = [1, 3];
    final course = ImportCourse(
      name: '高数',
      dayOfWeek: 2,
      startSection: 1,
      endSection: 2,
      weeks: weeks,
      source: 'json',
    );
    final groups = <String, List<CoursePlatform>>{
      '高数': [oldPlatform],
    };
    final submission = ImportSubmission.file(
      semesterId: 's1',
      mode: ImportMode.replace,
      courses: [course],
      platforms: groups,
    );
    course.selected = false;
    weeks.add(5);
    groups['高数']!.clear();
    expect(await container.read(importCommitProvider).commit(submission), 1);
    expect(
      (await container
          .read(courseRepositoryProvider)
          .getCourses('s1')).single.weeks,
      [1, 3],
    );
    expect(
      await container
          .read(coursePlatformRepositoryProvider)
          .getPlatforms('s1', '高数'),
      [oldPlatform],
    );
  });

  test('教务没有有效选择时共同提交不清空课表', () async {
    final before =
        jsonDecode(
          await container.read(backupRepositoryProvider).exportJson(),
        )['semesters'];
    final submission = ImportSubmission.webview(
      semesterId: 's1',
      mode: ImportMode.replace,
      courses: [
        ImportCourse(
          name: '',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [1],
          source: 'webview',
        ),
        ImportCourse(
          name: '未排周次',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          source: 'webview',
        ),
        ImportCourse(
          name: '不选',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [1],
          source: 'webview',
          selected: false,
        ),
      ],
      sectionTimes: const {},
    );
    expect(await container.read(importCommitProvider).commit(submission), 0);
    expect(
      jsonDecode(
        await container.read(backupRepositoryProvider).exportJson(),
      )['semesters'],
      before,
    );
  });

  for (final mode in ImportMode.values) {
    test('多个平台组后续失败时 ${mode.name} 课程和先前平台组共同回滚', () async {
      picker.content = jsonEncode({
        'courses': [_jsonCourse('高数'), _jsonCourse('物理')],
        'platforms': {
          '高数': [
            {'purpose': 'other', 'name': '新平台'},
          ],
          '物理': [
            {'purpose': 'lab', 'name': '失败平台'},
          ],
        },
      });
      final notifier = container.read(importProvider.notifier);
      await notifier.pickAndParse();
      notifier.setMode(mode);
      final before =
          jsonDecode(
            await container.read(backupRepositoryProvider).exportJson(),
          )['semesters'];
      await database.customStatement('''
        CREATE TRIGGER fail_second_platform BEFORE INSERT ON course_platforms
        WHEN NEW.course_name = '物理'
        BEGIN SELECT RAISE(ABORT, 'second platform rejected'); END;
      ''');
      await notifier.confirmImport();
      expect(
        jsonDecode(
          await container.read(backupRepositoryProvider).exportJson(),
        )['semesters'],
        before,
      );
      expect(container.read(importProvider).status, ImportStatus.preview);
      expect(container.read(importProvider).importedCount, 0);
    });
  }

  testWidgets('确认弹窗冻结目标学期、所选课程与模式，取消不写库', (tester) async {
    await tester.runAsync(() async {
      picker.content = jsonEncode({
        'courses': [_jsonCourse('高数'), _jsonCourse('物理')],
      });
      final notifier = container.read(importProvider.notifier);
      await notifier.pickAndParse();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ImportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('导入 2 门'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).single.id,
        'old-s1',
      );
      expect(container.read(importProvider).status, ImportStatus.preview);

      await tester.tap(find.text('导入 2 门'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      await container.read(semesterRepositoryProvider).setActive('s2');
      notifier.toggleSelected(1);
      notifier.setMode(ImportMode.merge);
      await tester.tap(find.widgetWithText(FilledButton, '替换'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      final imported = await container
          .read(courseRepositoryProvider)
          .getCourses('s1');
      expect(imported.map((c) => c.name), unorderedEquals(['高数', '物理']));
      expect(imported.every((c) => c.id != 'old-s1'), isTrue);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s2')).single.id,
        'old-s2',
      );
      expect(container.read(importProvider).importedCount, 2);
    });
  });

  test('平台写入失败时整次导入回滚，保留预览与失败信息，重试只提交一次', () async {
    picker.content = jsonEncode({
      'courses': [_jsonCourse('高数')],
      'platforms': {
        '高数': [
          {'purpose': 'other', 'name': '新平台'},
        ],
      },
    });
    final notifier = container.read(importProvider.notifier);
    await notifier.pickAndParse();
    final before =
        jsonDecode(
          await container.read(backupRepositoryProvider).exportJson(),
        )['semesters'];
    await database.customStatement('''
      CREATE TRIGGER fail_platform BEFORE INSERT ON course_platforms
      BEGIN SELECT RAISE(ABORT, 'platform rejected'); END;
    ''');
    try {
      await notifier.confirmImport();
    } catch (_) {
      // 旧实现向调用方泄漏异常；以下外部结果仍须整体回滚。
    }
    expect(
      jsonDecode(
        await container.read(backupRepositoryProvider).exportJson(),
      )['semesters'],
      before,
    );
    expect(container.read(importProvider).status, ImportStatus.preview);
    expect(container.read(importProvider).errorMessage, contains('导入失败'));
    expect(container.read(importProvider).importedCount, 0);
    expect(container.read(importProvider).courses, hasLength(1));

    await database.customStatement('DROP TRIGGER fail_platform');
    await notifier.confirmImport();
    expect(container.read(importProvider).status, ImportStatus.done);
    expect(container.read(importProvider).importedCount, 1);
    expect(
      await container.read(courseRepositoryProvider).getCourses('s1'),
      hasLength(1),
    );
    expect(
      (await container
          .read(coursePlatformRepositoryProvider)
          .getPlatforms('s1', '高数')).single.name,
      '新平台',
    );
  });
}

Map<String, Object> _jsonCourse(String name) => {
  'name': name,
  'dayOfWeek': 2,
  'startSection': 3,
  'endSection': 4,
  'weeks': [1, 2],
  'color': '#123456',
  'startTime': '10:05',
  'endTime': '11:40',
};

class _ImportPicker extends FilePicker {
  String? content;
  String extension = 'json';

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    if (content == null) return null;
    final bytes = Uint8List.fromList(utf8.encode(content!));
    return FilePickerResult([
      PlatformFile(
        name: 'courses.$extension',
        size: bytes.length,
        bytes: bytes,
      ),
    ]);
  }
}
