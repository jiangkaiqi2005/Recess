import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/features/schedule/domain/schedule_helpers.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';

void main() {
  final sectionTimes = {
    1: const SectionTime('08:00', 45),
    2: const SectionTime('08:55', 45),
    3: const SectionTime('10:00', 45),
  };

  Course _c(String id, int day, int start, int end,
          {List<int> weeks = const [1]}) =>
      Course(
        id: id,
        semesterId: 's',
        name: '课$id',
        dayOfWeek: day,
        startSection: start,
        endSection: end,
        weeks: weeks,
      );

  test('只保留当天星期且命中当前周的课程，按起始节次排序', () {
    // now = 周一
    final courses = [
      _c('a', DateTime.monday, 3, 3),
      _c('b', DateTime.monday, 1, 2),
      _c('c', DateTime.tuesday, 1, 1),
      _c('d', DateTime.monday, 5, 5, weeks: const [2]), // 本周无课
    ];
    final slots = todayCourseSlots(
      courses: courses,
      currentWeek: 1,
      now: DateTime(2026, 8, 31, 12, 0),
      sectionTimes: sectionTimes,
    );
    expect(slots.map((s) => s.course.id), ['b', 'a']);
  });

  test('按当前钟点标注 未开始 / 进行中 / 已结束', () {
    final courses = [
      _c('early', DateTime.monday, 1, 1), // 08:00-08:45
      _c('now', DateTime.monday, 2, 2), // 08:55-09:40
      _c('later', DateTime.monday, 3, 3), // 10:00
    ];
    final slots = todayCourseSlots(
      courses: courses,
      currentWeek: 1,
      now: DateTime(2026, 8, 31, 9, 0), // 正在上第 2 节
      sectionTimes: sectionTimes,
    );
    expect(slots[0].status, CourseStatus.done);
    expect(slots[1].status, CourseStatus.ongoing);
    expect(slots[2].status, CourseStatus.upcoming);
  });

  test('课程自带 startTime/endTime 优先于节次时间表', () {
    final course = const Course(
      id: 'x',
      semesterId: 's',
      name: '自定时间',
      dayOfWeek: DateTime.monday,
      startSection: 1,
      endSection: 1,
      startTime: '08:30',
      endTime: '09:00',
      weeks: [1],
    );
    final slots = todayCourseSlots(
      courses: [course],
      currentWeek: 1,
      now: DateTime(2026, 8, 31, 8, 45), // 08:30-09:00 进行中
      sectionTimes: sectionTimes,
    );
    expect(slots.single.status, CourseStatus.ongoing);
  });

  test('无钟点信息的课程状态为未开始（不崩溃）', () {
    final course = const Course(
      id: 'y',
      semesterId: 's',
      name: '无钟点',
      dayOfWeek: DateTime.monday,
      startSection: 10,
      endSection: 10,
      weeks: [1],
    );
    final slots = todayCourseSlots(
      courses: [course],
      currentWeek: 1,
      now: DateTime(2026, 8, 31, 9, 0),
      sectionTimes: sectionTimes,
    );
    expect(slots.single.status, CourseStatus.upcoming);
  });

  test('今日状态逐端回退，空串或不可解析显式端保持未开始降级', () {
    final base = _c('x', DateTime.monday, 1, 2);
    final slots = todayCourseSlots(
      courses: [
        base.copyWith(id: 'start', startTime: '08:30'),
        base.copyWith(id: 'end', endTime: '09:00'),
        base.copyWith(id: 'empty', startTime: ''),
        base.copyWith(id: 'bad', endTime: '不是钟点'),
        base.copyWith(id: 'missing', endSection: 16),
      ],
      currentWeek: 1,
      now: DateTime(2026, 8, 31, 9, 5),
      sectionTimes: sectionTimes,
    );
    expect({for (final slot in slots) slot.course.id: slot.status}, {
      'start': CourseStatus.ongoing,
      'end': CourseStatus.done,
      'empty': CourseStatus.upcoming,
      'bad': CourseStatus.upcoming,
      'missing': CourseStatus.upcoming,
    });
  });

  test('filterCourses 按名称/教师/教室模糊匹配（不区分大小写）', () {
    final a = const Course(
      id: 'a', semesterId: 's', name: '高等数学', teacher: '张三',
      location: '教三 201', dayOfWeek: 1, startSection: 1, endSection: 1,
    );
    final b = const Course(
      id: 'b', semesterId: 's', name: '线性代数', teacher: '李四',
      location: '教二 105', dayOfWeek: 1, startSection: 1, endSection: 1,
    );
    final filtered = filterCourses([a, b], '代数');
    expect(filtered.map((c) => c.id), ['b']);

    expect(filterCourses([a, b], '教三'), [a]);
    expect(filterCourses([a, b], '三'), [a]); // 教师名匹配
    expect(filterCourses([a, b], ''), hasLength(2));
  });

  group('visibleSectionCount', () {
    final timed = {
      for (var i = 1; i <= 12; i++) i: const SectionTime('08:00', 45),
      for (var i = 13; i <= 16; i++) i: const SectionTime('', 45),
    };

    test('课程都在已设时间的节次内时，显示到最后一个设了时间的节次', () {
      expect(
        visibleSectionCount(
          sectionTimes: timed,
          courses: [_c('a', 1, 1, 2), _c('b', 3, 9, 11)],
        ),
        12,
      );
    });

    test('有课程晚于最后一个设了时间的节次时，显示到该课程结束', () {
      expect(
        visibleSectionCount(
          sectionTimes: timed,
          courses: [_c('a', 1, 1, 2), _c('b', 3, 13, 14)],
        ),
        14,
      );
    });

    test('没有节次设了时间时显示到最大结束节次', () {
      final untimed = {
        for (var i = 1; i <= 16; i++) i: const SectionTime('', 45),
      };
      expect(
        visibleSectionCount(
          sectionTimes: untimed,
          courses: [_c('a', 1, 3, 5)],
        ),
        5,
      );
    });

    test('既没有设时间也没有课程时至少显示 1 节', () {
      expect(
        visibleSectionCount(
          sectionTimes: {1: const SectionTime('', 45)},
          courses: const [],
        ),
        1,
      );
    });
  });
}
