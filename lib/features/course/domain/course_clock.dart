import 'package:recess/core/models/course.dart';
import 'package:recess/features/settings/domain/section_time.dart';

/// 课程钟点：两端各自优先保留显式值，仅 null 使用当前节次时间。
class CourseClock {
  final String? startTime;
  final String? endTime;

  CourseClock(Course course, Map<int, SectionTime> sectionTimes)
    : startTime =
          (course.useExplicitTimes ? course.startTime : null) ??
          sectionTimes[course.startSection]?.startTime,
      endTime =
          (course.useExplicitTimes ? course.endTime : null) ??
          sectionTimes[course.endSection]?.endTime;

  (int, int)? get start => _parse(startTime);
  (int, int)? get end => _parse(endTime);

  static (int, int)? _parse(String? clock) {
    if (clock == null || clock.isEmpty) return null;
    final parts = clock.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour, minute);
  }
}
