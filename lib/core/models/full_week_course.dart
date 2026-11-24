import 'package:recess/core/constants/app_constants.dart';

/// 整周课：在某些周整周都要上、但没有固定星期和节次的课，如课程设计、实习。
///
/// 与 [Course] 分开建模，见 docs/adr/0003-full-week-courses-separate-table.md。
class FullWeekCourse {
  final String id;
  final String semesterId;
  final String name;
  final String? teacher;
  final String? location;
  final List<int> weeks;
  final int colorValue;
  final String? notes;

  const FullWeekCourse({
    required this.id,
    required this.semesterId,
    required this.name,
    this.teacher,
    this.location,
    this.weeks = const [],
    this.colorValue = AppConstants.defaultCourseColor,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullWeekCourse &&
          id == other.id &&
          semesterId == other.semesterId &&
          name == other.name &&
          teacher == other.teacher &&
          location == other.location &&
          _listEquals(weeks, other.weeks) &&
          colorValue == other.colorValue &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    name,
    teacher,
    location,
    Object.hashAll(weeks),
    colorValue,
    notes,
  );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
