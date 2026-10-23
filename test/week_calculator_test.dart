import 'package:flutter_test/flutter_test.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/core/utils/week_calculator.dart';

void main() {
  // 2024-09-02 是周一。
  final monday = DateTime(2024, 9, 2);

  group('computeCurrentWeek', () {
    test('开学当天为第 1 周', () {
      expect(computeCurrentWeek(monday, monday), 1);
    });

    test('恰好一周后为第 2 周', () {
      expect(computeCurrentWeek(monday, monday.add(const Duration(days: 7))), 2);
    });

    test('两周后为第 3 周', () {
      expect(
          computeCurrentWeek(monday, monday.add(const Duration(days: 14))), 3);
    });

    test('早于开学返回 0', () {
      expect(
          computeCurrentWeek(monday, monday.subtract(const Duration(days: 1))),
          0);
    });

    // 非周一开学：周三开学时，同周的周一应为第 1 周
    final wednesday = DateTime(2024, 9, 4);
    test('周三开学，同周周一为第 1 周', () {
      expect(computeCurrentWeek(wednesday, DateTime(2024, 9, 2)), 1);
    });

    test('周三开学，开学当天为第 1 周', () {
      expect(computeCurrentWeek(wednesday, wednesday), 1);
    });

    test('周三开学，下周周一为第 2 周', () {
      expect(computeCurrentWeek(wednesday, DateTime(2024, 9, 9)), 2);
    });

    // 周五开学
    final friday = DateTime(2024, 9, 6);
    test('周五开学，同周周一为第 1 周', () {
      expect(computeCurrentWeek(friday, DateTime(2024, 9, 2)), 1);
    });

    test('周五开学，开学当天为第 1 周', () {
      expect(computeCurrentWeek(friday, friday), 1);
    });
  });

  group('dateForWeekday', () {
    test('第1周周一 = 开学日', () {
      expect(dateForWeekday(monday, 1, 1), DateTime(2024, 9, 2));
    });

    test('第1周周三 = 开学日+2', () {
      expect(dateForWeekday(monday, 1, 3), DateTime(2024, 9, 4));
    });

    test('第2周周一 = 开学日+7', () {
      expect(dateForWeekday(monday, 2, 1), DateTime(2024, 9, 9));
    });

    // 非周一开学：dateForWeekday 与 computeCurrentWeek 应一致
    final wednesday = DateTime(2024, 9, 4);
    test('周三开学，第1周周一 = 开学日-2', () {
      expect(dateForWeekday(wednesday, 1, 1), DateTime(2024, 9, 2));
    });

    test('周三开学，第1周周三 = 开学日', () {
      expect(dateForWeekday(wednesday, 1, 3), DateTime(2024, 9, 4));
    });

    test('周三开学，第2周周一 = 开学日+5', () {
      expect(dateForWeekday(wednesday, 2, 1), DateTime(2024, 9, 9));
    });
  });

  group('computeCurrentWeek 与 dateForWeekday 一致性', () {
    test('非周一开学时两函数对同一日期的周次判定一致', () {
      final wednesday = DateTime(2024, 9, 4);
      // 开学当天是周三，用 dateForWeekday 反推该日期，再用 computeCurrentWeek 计算
      final date = dateForWeekday(wednesday, 1, 3); // 第1周周三 = 开学日
      expect(date, wednesday);
      expect(computeCurrentWeek(wednesday, date), 1);
    });
  });

  group('courseOnWeek', () {
    test('周次包含时为真', () {
      expect(courseOnWeek([1, 3, 5, 7], 3), isTrue);
    });
    test('周次不包含时为假', () {
      expect(courseOnWeek([1, 3, 5, 7], 2), isFalse);
    });
    test('空周次永远为假', () {
      expect(courseOnWeek(const [], 1), isFalse);
    });
  });

  group('currentWeekOf', () {
    test('自动周保留非周一开学的周一对齐和学期前后原始周数', () {
      final semester = Semester(
        id: 's', name: '学期', startDate: DateTime(2024, 9, 4), totalWeeks: 8,
      );
      expect(currentWeekOf(semester, DateTime(2024, 9, 1)), 0);
      expect(currentWeekOf(semester, DateTime(2024, 9, 2)), 1);
      expect(currentWeekOf(semester, DateTime(2024, 9, 4)), 1);
      expect(currentWeekOf(semester, DateTime(2024, 10, 27)), 8);
      expect(currentWeekOf(semester, DateTime(2024, 10, 28)), 9);
      expect(semester.currentWeekOverride, isNull);
    });
    test('读取旧越界手动当前周时调整到最近合法周', () {
      final semester = Semester(
        id: 's', name: '学期', startDate: monday, totalWeeks: 8,
        currentWeekOverride: 12,
      );
      expect(currentWeekOf(semester, monday), 8);
      expect(currentWeekOf(semester.copyWith(currentWeekOverride: 0), monday), 1);
      expect(currentWeekOf(semester.copyWith(currentWeekOverride: -3), monday), 1);
      expect(semester.currentWeekOverride, 12);
    });

    test('没有手动修改时按开学日期推算', () {
      final semester = Semester(
        id: 's',
        name: '学期',
        startDate: monday,
        totalWeeks: 18,
      );
      expect(currentWeekOf(semester, monday.add(const Duration(days: 15))), 3);
    });

    test('有手动修改时以修改值为准', () {
      final semester = Semester(
        id: 's',
        name: '学期',
        startDate: monday,
        totalWeeks: 18,
        currentWeekOverride: 9,
      );
      expect(currentWeekOf(semester, monday.add(const Duration(days: 15))), 9);
    });
  });
}
