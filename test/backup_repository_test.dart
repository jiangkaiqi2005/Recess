import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/repositories/backup_repository.dart';
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';

void main() {
  late db.AppDatabase database;
  late BackupRepository backup;
  late CourseRepository courses;
  late SemesterRepository semesters;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    backup = BackupRepository(database);
    courses = CourseRepository(database);
    semesters = SemesterRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('新旧色板与自定义 ARGB 在备份导出恢复后保持原始值', () async {
    const rawColors = [0xFFC08CE8, 0xFFF08C7C, 0xFFE3753F, 0x80123456];
    await semesters.upsert(Semester(
      id: 's1', name: '学期', startDate: DateTime(2026, 9, 1), totalWeeks: 18,
    ));
    for (var i = 0; i < rawColors.length; i++) {
      await courses.upsert(Course(
        id: 'color-$i', semesterId: 's1', name: '课程$i', dayOfWeek: 1,
        startSection: 1, endSection: 2, weeks: [1], colorValue: rawColors[i],
      ));
    }
    final exported = await backup.exportJson();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    expect(decoded['app'], 'recess');
    final rows = ((decoded['semesters'] as List).single as Map)['courses'] as List;
    expect(rows.map((row) => (row as Map)['colorValue']), unorderedEquals(rawColors));
    await backup.restore(exported);
    expect((await courses.getCourses('s1')).map((c) => c.colorValue),
        unorderedEquals(rawColors));
  });

  String exportFixture() {
    final data = {
      'app': 'recess',
      'version': 1,
      'exportedAt': '2026-08-26T00:00:00.000',
      'semesters': [
        {
          'id': 's1',
          'name': '2026 秋',
          'startDate': DateTime(2026, 9, 1).toIso8601String(),
          'totalWeeks': 18,
          'currentWeekOverride': 3,
          'isActive': true,
          'courses': [
            {
              'id': 'c1',
              'name': '高等数学',
              'teacher': '张三',
              'location': '教三 201',
              'dayOfWeek': 1,
              'startSection': 1,
              'endSection': 2,
              'startTime': '08:00',
              'endTime': '09:35',
              'weeks': [1, 2, 3, 4, 5],
              'colorValue': 0xFF3FBFA8,
              'notes': '带课本',
            },
          ],
        },
        {
          'id': 's2',
          'name': '2025 春',
          'startDate': DateTime(2025, 3, 1).toIso8601String(),
          'totalWeeks': 16,
          'courses': [
            {
              'id': 'c2',
              'name': '线性代数',
              'dayOfWeek': 2,
              'startSection': 3,
              'endSection': 4,
              'weeks': [1, 2, 3],
            },
          ],
        },
      ],
    };
    return const JsonEncoder().convert(data);
  }

  test('恢复备份后数据与备份一致，激活学期与周次覆盖被保留', () async {
    // 先写入一些旧数据，确保被覆盖。
    await semesters.upsert(Semester(
      id: 'old-s',
      name: '旧学期',
      startDate: DateTime(2020),
      totalWeeks: 10,
    ));
    await courses.upsert(const Course(
      id: 'old-c',
      semesterId: 'old-s',
      name: '旧课程',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 1,
    ));

    final result = await backup.restore(exportFixture());
    expect(result.semesterCount, 2);
    expect(result.courseCount, 2);

    final allSemesters = await semesters.getSemesters();
    expect(allSemesters, hasLength(2));
    final s1 = allSemesters.firstWhere((s) => s.id == 's1');
    expect(s1.name, '2026 秋');
    expect(s1.currentWeekOverride, 3);

    final active = await semesters.getActiveSemester();
    expect(active?.id, 's1');

    final c1 = await courses.getCourses('s1');
    expect(c1, hasLength(1));
    expect(c1.single.name, '高等数学');
    expect(c1.single.teacher, '张三');
    expect(c1.single.colorValue, 0xFF3FBFA8);
    expect(c1.single.weeks, [1, 2, 3, 4, 5]);
    expect(c1.single.startTime, '08:00');
    expect(c1.single.endTime, '09:35');

    final c2 = await courses.getCourses('s2');
    expect(c2.single.colorValue, 0xFF5B8DEF); // 无颜色时回退默认蓝
  });

  test('旧 app 标识 hormone 的备份仍能恢复学期和课程', () async {
    final data = jsonDecode(exportFixture()) as Map<String, dynamic>;
    data['app'] = 'hormone';

    final result = await backup.restore(jsonEncode(data));

    expect(result.semesterCount, 2);
    expect(result.courseCount, 2);
    expect((await semesters.getActiveSemester())?.id, 's1');
    expect(await semesters.getSemesters(), hasLength(2));
    expect((await courses.getCourses('s1')).single.name, '高等数学');
    expect((await courses.getCourses('s2')).single.name, '线性代数');
  });

  test('导出再恢复：课程平台按学期原样往返', () async {
    final platforms = CoursePlatformRepository(database);
    await semesters.upsert(Semester(
      id: 's1',
      name: '2026 秋',
      startDate: DateTime(2026, 9, 1),
      totalWeeks: 18,
    ));
    await semesters.setActive('s1');
    await semesters.upsert(Semester(
      id: 's2',
      name: '2025 春',
      startDate: DateTime(2025, 3, 1),
      totalWeeks: 16,
    ));
    await courses.upsert(const Course(
      id: 'c1',
      semesterId: 's1',
      name: '操作系统',
      dayOfWeek: 2,
      startSection: 3,
      endSection: 4,
      weeks: [1, 2],
    ));
    const online = CoursePlatform(
      purpose: CoursePlatformPurpose.onlineCourse,
      name: '学习通',
      url: 'https://mooc1.chaoxing.com',
    );
    const group = CoursePlatform(
      purpose: CoursePlatformPurpose.group,
      name: 'QQ 群',
    );
    const lab = CoursePlatform(
      purpose: CoursePlatformPurpose.lab,
      name: '头歌',
    );
    await platforms.replacePlatforms('s1', '操作系统', [online, group]);
    await platforms.replacePlatforms('s2', '操作系统', [lab]);

    final exported = await backup.exportJson();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    final s1 = (decoded['semesters'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['id'] == 's1');
    expect(s1['platforms'], {
      '操作系统': [
        {
          'purpose': 'online_course',
          'name': '学习通',
          'url': 'https://mooc1.chaoxing.com',
        },
        {'purpose': 'group', 'name': 'QQ 群', 'url': null},
      ],
    });

    // 恢复前把平台改乱，确认恢复后以备份为准。
    await platforms.replacePlatforms('s1', '操作系统', const []);
    await platforms.replacePlatforms('s1', '别的课', [lab]);

    await backup.restore(exported);

    expect(await platforms.getPlatforms('s1', '操作系统'), [online, group]);
    expect(await platforms.getPlatforms('s1', '别的课'), isEmpty);
    expect(await platforms.getPlatforms('s2', '操作系统'), [lab]);
    expect((await courses.getCourses('s1')).single.name, '操作系统');
    expect((await semesters.getActiveSemester())?.id, 's1');
  });

  test('旧备份没有 platforms 字段时照常恢复', () async {
    final platforms = CoursePlatformRepository(database);

    final result = await backup.restore(exportFixture());

    expect(result.semesterCount, 2);
    expect(await platforms.getPlatformsBySemester('s1'), isEmpty);
    expect(await courses.getCourses('s1'), hasLength(1));
  });

  test('备份中的非法平台条目被跳过，其余照常恢复', () async {
    final data = {
      'app': 'recess',
      'semesters': [
        {
          'id': 's1',
          'name': 'A',
          'startDate': '2026-09-01',
          'totalWeeks': 18,
          'platforms': {
            '操作系统': [
              {'purpose': 'lab', 'name': '头歌'},
              {'purpose': 'unknown', 'name': '未知用途'},
              {'purpose': 'lab', 'name': ''},
              'not an object',
            ],
          },
        },
      ],
    };
    await backup.restore(const JsonEncoder().convert(data));

    expect(
      await CoursePlatformRepository(database).getPlatforms('s1', '操作系统'),
      const [CoursePlatform(purpose: CoursePlatformPurpose.lab, name: '头歌')],
    );
  });

  test('非备份文件（缺少 app 标识）抛出错误且不改动数据', () async {
    await semesters.upsert(Semester(
      id: 'old-s',
      name: '旧学期',
      startDate: DateTime(2020),
      totalWeeks: 10,
    ));

    for (final invalid in ['{"foo": 1}', '{"app": "other"}']) {
      await expectLater(
        backup.restore(invalid),
        throwsA(isA<FormatException>().having(
          (error) => error.message,
          'message',
          '这不是 Recess 的备份文件',
        )),
      );
    }

    // 数据未被改动。
    final allSemesters = await semesters.getSemesters();
    expect(allSemesters, hasLength(1));
    expect(allSemesters.single.id, 'old-s');
  });

  test('非法 JSON 抛出异常', () async {
    await expectLater(
      backup.restore('not json at all'),
      throwsA(isA<FormatException>()),
    );
  });

  test('含重复学期 id 的备份抛出异常', () async {
    final data = {
      'app': 'recess',
      'semesters': [
        {'id': 'dup', 'name': 'A', 'startDate': '2026-01-01', 'totalWeeks': 18},
        {'id': 'dup', 'name': 'B', 'startDate': '2026-02-01', 'totalWeeks': 16},
      ],
    };
    await expectLater(
      backup.restore(const JsonEncoder().convert(data)),
      throwsA(isA<FormatException>()),
    );
  });
}
