import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/constants/app_constants.dart';
import 'package:recess/core/models/course.dart';

void main() {
  const light = [
    0xFF4399F1,
    0xFF4BA89A,
    0xFFE3753F,
    0xFF7C83E7,
    0xFFE36679,
    0xFF46A4C1,
    0xFFB28C6D,
    0xFF53A88D,
  ];
  const dark = [
    0xFF217BD1,
    0xFF298B7E,
    0xFFC3581D,
    0xFF6266C7,
    0xFFC2485D,
    0xFF2287A3,
    0xFF947052,
    0xFF348B72,
  ];
  const legacy = [
    0xFF5B8DEF,
    0xFF3FBFA8,
    0xFFF2A25C,
    0xFF9B8AFB,
    0xFFEF6E8D,
    0xFF4FA3E3,
    0xFFE8BE50,
    0xFF63C98D,
    0xFFC08CE8,
    0xFFF08C7C,
  ];

  test('八色顺序、默认颜色和自动配色循环使用冻结的浅色值', () {
    expect(AppConstants.coursePalette, light);
    expect(AppConstants.defaultCourseColor, light.first);
    const course = Course(
      id: '',
      semesterId: '',
      name: '',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 1,
    );
    expect(course.colorValue, light.first);
    for (var i = 0; i < 24; i++) {
      expect(AppConstants.courseAutoColor(i), light[i % 8]);
    }
  });

  test('旧十色只在显示时按 i % 8 映射，主题不改写原始值', () {
    for (var i = 0; i < legacy.length; i++) {
      final course = Course(
        id: '',
        semesterId: '',
        name: '',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 1,
        colorValue: legacy[i],
      );
      expect(AppConstants.coursePaletteIndex(course.colorValue), i % 8);
      expect(AppConstants.courseDisplayColor(course.colorValue), light[i % 8]);
      expect(
        AppConstants.courseDisplayColor(course.colorValue, dark: true),
        dark[i % 8],
      );
      expect(course.colorValue, legacy[i]);
    }
  });

  test('新色重复解析保持不变，深色使用冻结值，切回浅色仍按持久化标识解析', () {
    for (var i = 0; i < light.length; i++) {
      final resolved = AppConstants.courseDisplayColor(light[i]);
      expect(resolved, light[i]);
      expect(AppConstants.courseDisplayColor(resolved), light[i]);
      expect(AppConstants.courseDisplayColor(light[i], dark: true), dark[i]);
      expect(AppConstants.courseDisplayColor(light[i]), light[i]);
    }
  });

  test('未知自定义 ARGB 在两种主题下保持原样且不选中色板', () {
    for (final value in [0xFF123456, 0x80123456, 0x00000000]) {
      expect(AppConstants.coursePaletteIndex(value), isNull);
      expect(AppConstants.courseDisplayColor(value), value);
      expect(AppConstants.courseDisplayColor(value, dark: true), value);
    }
  });
}
