import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/core/models/semester.dart';
import 'package:hormone/data/app_database.dart' as db;
import 'package:hormone/data/repositories/course_platform_repository.dart';
import 'package:hormone/data/repositories/course_repository.dart';
import 'package:hormone/data/repositories/semester_repository.dart';
import 'package:hormone/features/semester/application/semester_form_provider.dart';

void main() {
  test('删除学期时连同该学期的课程与课程平台一起删除', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final courses = CourseRepository(database);
    final platforms = CoursePlatformRepository(database);

    final doomed = Semester(
      id: 's1',
      name: '要删的学期',
      startDate: DateTime(2026, 9, 1),
      totalWeeks: 18,
    );
    await semesters.upsert(doomed);
    await semesters.upsert(Semester(
      id: 's2',
      name: '保留的学期',
      startDate: DateTime(2026, 2, 1),
      totalWeeks: 18,
    ));
    await courses.upsert(const Course(
      id: 'c1',
      semesterId: 's1',
      name: '操作系统',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
    ));
    const platform = CoursePlatform(
      purpose: CoursePlatformPurpose.onlineCourse,
      name: '学习通',
    );
    await platforms.replacePlatforms('s1', '操作系统', [platform]);
    await platforms.replacePlatforms('s2', '操作系统', [platform]);

    final notifier = SemesterFormNotifier(semesters, courses, platforms)
      ..init(doomed);
    await notifier.delete();

    expect((await semesters.getSemesters()).map((s) => s.id), ['s2']);
    expect(await courses.getCourses('s1'), isEmpty);
    expect(await platforms.getPlatforms('s1', '操作系统'), isEmpty);
    expect(await platforms.getPlatforms('s2', '操作系统'), [platform]);
  });
}
