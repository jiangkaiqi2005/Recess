import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';

void main() {
  test('数据库从版本 1 升到 2：已有学期和课程保留，课程平台表可用', () async {
    // 按版本 1 的表结构建库并写入数据，模拟老用户升级。
    final database = db.AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE "courses" (
              "id" TEXT NOT NULL, "semester_id" TEXT NOT NULL,
              "name" TEXT NOT NULL, "teacher" TEXT NULL, "location" TEXT NULL,
              "day_of_week" INTEGER NOT NULL, "start_section" INTEGER NOT NULL,
              "end_section" INTEGER NOT NULL, "start_time" TEXT NULL,
              "end_time" TEXT NULL, "weeks" TEXT NOT NULL DEFAULT '',
              "color_value" INTEGER NOT NULL DEFAULT 4284190191,
              "notes" TEXT NULL, PRIMARY KEY ("id"));
          ''');
          raw.execute('''
            CREATE TABLE "semesters" (
              "id" TEXT NOT NULL, "name" TEXT NOT NULL,
              "start_date" INTEGER NOT NULL, "total_weeks" INTEGER NOT NULL,
              "current_week_override" INTEGER NULL,
              "is_active" INTEGER NOT NULL DEFAULT 0
                CHECK ("is_active" IN (0, 1)),
              PRIMARY KEY ("id"));
          ''');
          raw.execute('''
            INSERT INTO "semesters" VALUES ('s1', '2026 秋', 1788192000, 18, 3, 1);
          ''');
          raw.execute('''
            INSERT INTO "courses" ("id", "semester_id", "name", "day_of_week",
              "start_section", "end_section", "weeks")
            VALUES ('c1', 's1', '操作系统', 2, 3, 4, '1,2,3');
          ''');
          raw.execute('PRAGMA user_version = 1;');
        },
      ),
    );
    addTearDown(database.close);

    final semester = await SemesterRepository(database).getActiveSemester();
    expect(semester?.id, 's1');
    expect(semester?.currentWeekOverride, 3);

    final courses = await CourseRepository(database).getCourses('s1');
    expect(courses.single.name, '操作系统');
    expect(courses.single.weeks, [1, 2, 3]);

    final platforms = CoursePlatformRepository(database);
    const platform = CoursePlatform(
      purpose: CoursePlatformPurpose.onlineCourse,
      name: '学习通',
    );
    await platforms.replacePlatforms('s1', '操作系统', [platform]);
    expect(await platforms.getPlatforms('s1', '操作系统'), [platform]);

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((row) => row.read<int>('user_version'));
    expect(version, 2);
  });
}
