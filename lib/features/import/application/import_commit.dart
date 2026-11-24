import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:recess/core/constants/app_constants.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/full_week_course_repository.dart';
import 'package:recess/features/import/domain/import_course.dart';
import 'package:recess/features/import/domain/webview_preview_context.dart';

/// 一次确认使用的快照，确认弹窗和写入过程不再读取预览的可变状态。
class ImportSubmission {
  final String semesterId;
  final WebviewPreviewContext? previewContext;
  final ImportMode mode;
  final List<Course> courses;
  final List<FullWeekCourse> fullWeekCourses;
  final CoursePlatformGroups platforms;

  ImportSubmission._(
    this.semesterId,
    this.mode,
    List<Course> courses,
    CoursePlatformGroups platforms, {
    this.previewContext,
    List<FullWeekCourse> fullWeekCourses = const [],
  }) : courses = List.unmodifiable(
         courses.map((c) => c.copyWith(weeks: List.unmodifiable(c.weeks))),
       ),
       fullWeekCourses = List.unmodifiable(fullWeekCourses),
       platforms = Map.unmodifiable(
         platforms.map(
           (name, items) =>
               MapEntry(name, List<CoursePlatform>.unmodifiable(items)),
         ),
       );

  /// 本次导入的课程总数，整周课也算一门。
  int get count => courses.length + fullWeekCourses.length;

  bool get isEmpty => count == 0;

  factory ImportSubmission.file({
    required String semesterId,
    required ImportMode mode,
    required Iterable<ImportCourse> courses,
    CoursePlatformGroups platforms = const {},
  }) {
    final selected = courses.where((c) => c.selected).toList();
    return ImportSubmission._(
      semesterId,
      mode,
      selected
          .map((c) => c.toCourse(semesterId).copyWith(id: const Uuid().v4()))
          .toList(),
      platformsForImportedCourses(platforms, selected),
    );
  }

  factory ImportSubmission.webview({
    required String semesterId,
    required ImportMode mode,
    required Iterable<ImportCourse> courses,
    required WebviewPreviewContext previewContext,
  }) {
    final replacements = <Course>[];
    final fullWeek = <FullWeekCourse>[];
    // 同名课程（含整周课）共用一个颜色，不同课程按首次出现的顺序取色。
    final colors = <String, int>{};
    int colorFor(String name) => colors.putIfAbsent(
          name,
          () => AppConstants.courseAutoColor(colors.length),
        );
    for (final c in courses.where((c) => c.selected)) {
      if (c.fullWeek) {
        fullWeek.add(FullWeekCourse(
          id: const Uuid().v4(),
          semesterId: semesterId,
          name: c.name,
          teacher: c.teacher,
          location: c.location,
          weeks: List.unmodifiable(c.weeks),
          colorValue: colorFor(c.name),
        ));
        continue;
      }
      replacements.add(
        Course(
          id: const Uuid().v4(),
          semesterId: semesterId,
          name: c.name,
          teacher: c.teacher,
          location: c.location,
          dayOfWeek: c.dayOfWeek,
          startSection: c.startSection,
          endSection: c.endSection,
          weeks: c.weeks,
          colorValue: colorFor(c.name),
        ),
      );
    }
    return ImportSubmission._(
      semesterId,
      mode,
      replacements,
      const {},
      previewContext: previewContext,
      fullWeekCourses: fullWeek,
    );
  }
}

final importCommitProvider = Provider<ImportCommit>((ref) {
  return ImportCommit(ref.watch(appDatabaseProvider));
});

/// 课程与本次明确提供的平台共同提交，返回完整成功的课程数。
class ImportCommit {
  final db.AppDatabase _database;

  ImportCommit(this._database);

  Future<int> commit(ImportSubmission submission) async {
    if (submission.isEmpty) return 0;
    final courses = CourseRepository(_database);
    final fullWeek = FullWeekCourseRepository(_database);
    final platforms = CoursePlatformRepository(_database);
    await _database.transaction(() async {
      final context = submission.previewContext;
      if (context != null) {
        final semester =
            await SemesterRepository(_database).getActiveSemester();
        if (!context.matches(semester) ||
            submission.semesterId != context.semesterId) {
          throw StateError('学期设置已改变，请重新抓取并预览');
        }
        final allWeeks = [
          for (final c in submission.courses) ...c.weeks,
          for (final c in submission.fullWeekCourses) ...c.weeks,
        ];
        if (allWeeks.any((w) => w > context.totalWeeks)) {
          throw StateError('明确周次超出本地学期，请先核对调整学期并重新预览');
        }
      }
      if (submission.mode == ImportMode.merge) {
        await courses.addCourses(submission.semesterId, submission.courses);
        await fullWeek.addAll(
          submission.semesterId,
          submission.fullWeekCourses,
        );
      } else {
        await courses.replaceForSemester(
          submission.semesterId,
          submission.courses,
        );
        await fullWeek.replaceForSemester(
          submission.semesterId,
          submission.fullWeekCourses,
        );
      }
      for (final entry in submission.platforms.entries) {
        if (entry.value.isNotEmpty) {
          await platforms.replacePlatforms(
            submission.semesterId,
            entry.key,
            entry.value,
          );
        }
      }
    });
    // drift 的变化流由现有 AppEffects 统一刷新提醒和小组件。
    return submission.count;
  }
}
