import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';

/// 判定课程编辑页当前草稿相对初始内容是否存在实际差异。
///
/// 以「初始快照 vs 草稿」的逐字段比较为准，不关心控件是否曾被触碰：
/// 把修改改回初始值即视为无差异。比较范围是页面上全部可编辑字段
/// （周次按集合比较，顺序无语义）；课程平台按列表比较（顺序即展示顺序，
/// 调序算修改）。id、学期、上下课钟点等页面不可编辑字段不参与判定。
bool hasUnsavedCourseChanges({
  required Course draft,
  required Course initial,
  required List<CoursePlatform> platforms,
  required List<CoursePlatform> initialPlatforms,
}) {
  if (draft.name != initial.name ||
      draft.teacher != initial.teacher ||
      draft.location != initial.location ||
      draft.notes != initial.notes ||
      draft.dayOfWeek != initial.dayOfWeek ||
      draft.startSection != initial.startSection ||
      draft.endSection != initial.endSection ||
      draft.colorValue != initial.colorValue) {
    return true;
  }
  if (!_sameWeeks(draft.weeks, initial.weeks)) return true;
  return !_samePlatforms(platforms, initialPlatforms);
}

bool _sameWeeks(List<int> a, List<int> b) =>
    a.length == b.length && {...a}.containsAll(b);

bool _samePlatforms(List<CoursePlatform> a, List<CoursePlatform> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
