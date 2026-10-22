import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/features/import/data/json_importer.dart';

void main() {
  test('显式 JSON 颜色保留旧色和自定义 ARGB，不替换为显示色', () {
    const rawColors = ['#C08CE8', '#F08C7C', '#E3753F', '#80123456'];
    final result = JsonCourseImporter.parse(jsonEncode({
      'courses': [
        for (var i = 0; i < rawColors.length; i++) {
          'name': '课程$i', 'dayOfWeek': 1, 'startSection': 1,
          'endSection': 2, 'weeks': [1], 'color': rawColors[i],
        },
      ],
    }), totalWeeks: 18);
    expect(result.courses.map((c) => c.colorValue),
        [0xFFC08CE8, 0xFFF08C7C, 0xFFE3753F, 0x80123456]);
  });

  group('JsonCourseImporter - 合法模板', () {
    final json = jsonEncode({
      'courses': [
        {
          'name': '高等数学',
          'teacher': '张三',
          'location': '教三-201',
          'dayOfWeek': 2,
          'startSection': 3,
          'endSection': 4,
          'weeks': [1, 2, 3, 4, 5],
          'color': '#5B8DEF',
          'notes': '带书',
        }
      ]
    });

    final result = JsonCourseImporter.parse(json, totalWeeks: 18);

    test('解析出 1 门', () {
      expect(result.courses, hasLength(1));
    });
    test('字段映射正确', () {
      final c = result.courses.first;
      expect(c.name, '高等数学');
      expect(c.teacher, '张三');
      expect(c.dayOfWeek, 2);
      expect(c.startSection, 3);
      expect(c.endSection, 4);
      expect(c.weeks, [1, 2, 3, 4, 5]);
    });
    test('颜色解析为 ARGB', () {
      // #5B8DEF -> 0xFF5B8DEF
      expect(result.courses.first.colorValue, 0xFF5B8DEF);
    });
  });

  group('JsonCourseImporter - 容错', () {
    test('非法 dayOfWeek 被跳过并计入 skipped', () {
      final json = jsonEncode({
        'courses': [
          {'name': '有效', 'dayOfWeek': 1, 'startSection': 1, 'endSection': 2, 'weeks': [1, 2, 3]},
          {'name': '非法星期', 'dayOfWeek': 9, 'startSection': 1, 'endSection': 2, 'weeks': [1, 2, 3]},
        ]
      });
      final result = JsonCourseImporter.parse(json, totalWeeks: 18);
      expect(result.courses, hasLength(1));
    });

    test('缺少 name 被跳过', () {
      final json = jsonEncode({
        'courses': [
          {'dayOfWeek': 1, 'startSection': 1, 'endSection': 2, 'weeks': [1, 2, 3]},
        ]
      });
      final result = JsonCourseImporter.parse(json, totalWeeks: 18);
      expect(result.courses, isEmpty);
    });

    test('超过总周数的周次被过滤', () {
      final json = jsonEncode({
        'courses': [
          {
            'name': '越界周',
            'dayOfWeek': 1,
            'startSection': 1,
            'endSection': 2,
            'weeks': [1, 2, 30],
          }
        ]
      });
      final result = JsonCourseImporter.parse(json, totalWeeks: 18);
      expect(result.courses.first.weeks, [1, 2]);
    });
  });

  group('JsonCourseImporter - 顶层为数组', () {
    test('直接数组也可解析', () {
      final json = jsonEncode([
        {'name': 'A', 'dayOfWeek': 1, 'startSection': 1, 'endSection': 2, 'weeks': [1, 2, 3]}
      ]);
      final result = JsonCourseImporter.parse(json, totalWeeks: 18);
      expect(result.courses, hasLength(1));
      expect(result.courses.first.name, 'A');
      expect(result.platforms, isEmpty);
    });
  });

  group('JsonCourseImporter - 课程平台', () {
    test('顶层 platforms 按课程名解析，非法条目跳过并计入 skipped', () {
      final json = jsonEncode({
        'courses': [
          {'name': '操作系统', 'dayOfWeek': 2, 'startSection': 3, 'endSection': 4, 'weeks': [1, 2]},
        ],
        'platforms': {
          '操作系统': [
            {'purpose': 'online_course', 'name': '学习通', 'url': 'https://mooc1.chaoxing.com'},
            {'purpose': 'group', 'name': 'QQ 群', 'url': ''},
            {'purpose': '网课', 'name': '用了中文用途'},
            {'purpose': 'lab'},
          ],
          '体育': 'not a list',
        },
      });

      final result = JsonCourseImporter.parse(json, totalWeeks: 18);

      expect(result.courses, hasLength(1));
      expect(result.platforms, {
        '操作系统': const [
          CoursePlatform(
            purpose: CoursePlatformPurpose.onlineCourse,
            name: '学习通',
            url: 'https://mooc1.chaoxing.com',
          ),
          CoursePlatform(purpose: CoursePlatformPurpose.group, name: 'QQ 群'),
        ],
      });
      expect(result.skipped, hasLength(3));
    });

    test('没有 platforms 字段时平台为空', () {
      final json = jsonEncode({
        'courses': [
          {'name': 'A', 'dayOfWeek': 1, 'startSection': 1, 'endSection': 2, 'weeks': [1]},
        ],
      });
      final result = JsonCourseImporter.parse(json, totalWeeks: 18);
      expect(result.platforms, isEmpty);
      expect(result.skipped, isEmpty);
    });
  });
}
