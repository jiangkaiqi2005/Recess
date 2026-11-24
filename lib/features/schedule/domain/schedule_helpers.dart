import 'package:recess/core/models/course.dart';
import 'package:recess/core/utils/week_calculator.dart';
import 'package:recess/features/course/domain/course_clock.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';

/// 今日某一门课的状态（相对当前时刻）。
enum CourseStatus {
  /// 尚未开始
  upcoming,

  /// 正在上课
  ongoing,

  /// 已结束
  done,
}

/// 「今日课程」时间线上的一个条目。
class TodayCourseSlot {
  final Course course;
  final CourseStatus status;

  const TodayCourseSlot({required this.course, required this.status});
}

/// 计算「今日」的课程时间线（纯函数，可单测）。
///
/// 只保留当天星期 × 上课周次命中 [currentWeek] 的课程，按起始节次排序，
/// 并依据当前钟点标注 未开始/进行中/已结束。钟点优先取课程自带
/// startTime/endTime（WebView 导入已补全），缺省回退节次时间表。
List<TodayCourseSlot> todayCourseSlots({
  required List<Course> courses,
  required int currentWeek,
  required DateTime now,
  required Map<int, SectionTime> sectionTimes,
}) {
  final today = now.weekday;
  final slots = courses
      .where((c) =>
          c.dayOfWeek == today && courseOnWeek(c.weeks, currentWeek))
      .toList()
    ..sort((a, b) => a.startSection.compareTo(b.startSection));

  final nowMin = now.hour * 60 + now.minute;
  return slots
      .map((c) {
        final clock = CourseClock(c, sectionTimes);
        final startClock = clock.start;
        final endClock = clock.end;
        final start =
            startClock == null ? null : startClock.$1 * 60 + startClock.$2;
        final end = endClock == null ? null : endClock.$1 * 60 + endClock.$2;
        var status = CourseStatus.upcoming;
        if (start != null && end != null) {
          if (nowMin >= end) {
            status = CourseStatus.done;
          } else if (nowMin >= start) {
            status = CourseStatus.ongoing;
          }
        }
        return TodayCourseSlot(course: c, status: status);
      })
      .toList(growable: false);
}

/// 在激活学期课程中按名称/教师/教室模糊过滤（小写不区分大小写）。
List<Course> filterCourses(List<Course> courses, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(courses);
  return courses
      .where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.teacher ?? '').toLowerCase().contains(q) ||
          (c.location ?? '').toLowerCase().contains(q))
      .toList(growable: false);
}

/// 周视图显示的节次数：取「最后一个设了时间的节次」与「本学期课程最大
/// endSection」中较大者；没有节次设了时间时只看课程，且至少显示 1 节。
int visibleSectionCount({
  required Map<int, SectionTime> sectionTimes,
  required Iterable<Course> courses,
}) {
  var count = 1;
  for (final entry in sectionTimes.entries) {
    if (entry.value.startTime.isNotEmpty && entry.key > count) {
      count = entry.key;
    }
  }
  for (final c in courses) {
    if (c.endSection > count) count = c.endSection;
  }
  return count;
}
