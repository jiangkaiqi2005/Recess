import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:recess/core/constants/app_constants.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/full_week_course_repository.dart';

const _fullWeekPrefix = 'fullweek:';

/// 编辑整周课时传给 `/course/edit` 的 extra。
String fullWeekCourseEditExtra(String id) => '$_fullWeekPrefix$id';

/// 编辑页参数是否指向整周课。
bool isFullWeekCourseEdit(String? courseId) =>
    courseId?.startsWith(_fullWeekPrefix) ?? false;

/// 解析课程编辑页的初始数据：
/// - 给定 [courseId] 且存在 → 返回该课程（编辑）
/// - `fullweek:<id>` → 整周课的表单草稿：表单状态仍是 [Course]，星期和节次
///   填占位值 1，页面隐藏这两项，保存时写回 [FullWeekCourse]
/// - 否则 → 返回属于当前激活学期的空白课程，周次默认填满整学期
final courseInitialProvider =
    FutureProvider.family<Course, String?>((ref, courseId) async {
  final courseRepo = ref.watch(courseRepositoryProvider);
  final semesterRepo = ref.watch(semesterRepositoryProvider);

  if (isFullWeekCourseEdit(courseId)) {
    final id = courseId!.substring(_fullWeekPrefix.length);
    final c = await ref.watch(fullWeekCourseRepositoryProvider).get(id);
    if (c == null) throw StateError('整周课不存在：$id');
    return Course(
      id: c.id,
      semesterId: c.semesterId,
      name: c.name,
      teacher: c.teacher,
      location: c.location,
      dayOfWeek: 1,
      startSection: 1,
      endSection: 1,
      weeks: c.weeks,
      colorValue: c.colorValue,
      notes: c.notes,
    );
  }

  // 处理复制课程：copy:<courseId>
  if (courseId != null && courseId.startsWith('copy:')) {
    final originalId = courseId.substring(5);
    final original = await courseRepo.getCourse(originalId);
    if (original != null) {
      return original.copyWith(id: '', name: '${original.name}（副本）');
    }
    throw StateError('课程不存在：$originalId');
  }

  if (courseId != null && courseId.isNotEmpty) {
    final existing = await courseRepo.getCourse(courseId);
    if (existing != null) return existing;
    // Course not found for the given ID — could be deleted or invalid.
    // Throw so the UI can show an error instead of silently creating a blank course.
    throw StateError('课程不存在：$courseId');
  }

  final semester = await semesterRepo.getActiveSemester();
  final totalWeeks = semester?.totalWeeks ?? 18;
  return Course(
    id: '',
    semesterId: semester?.id ?? '',
    name: '',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    weeks: List.generate(totalWeeks, (i) => i + 1),
    colorValue: AppConstants.defaultCourseColor,
  );
});

/// 课程表单状态机。所有字段修改都通过 copyWith 生成新状态，UI 直接 watch。
final courseFormProvider =
    StateNotifierProvider.autoDispose<CourseFormNotifier, Course>(
  (ref) => CourseFormNotifier(
    ref.watch(courseRepositoryProvider),
    fullWeekRepo: ref.watch(fullWeekCourseRepositoryProvider),
  ),
);

class CourseFormNotifier extends StateNotifier<Course> {
  final CourseRepository _repo;

  /// 编辑整周课时必须提供。
  final FullWeekCourseRepository? _fullWeekRepo;

  CourseFormNotifier(this._repo, {FullWeekCourseRepository? fullWeekRepo})
      : _fullWeekRepo = fullWeekRepo,
        super(const Course(
          id: '',
          semesterId: '',
          name: '',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [],
          colorValue: AppConstants.defaultCourseColor,
        ));

  bool _initialized = false;

  /// 编辑已有课程时的原课程名，保存时据此判断是否改名；新建/复制时为 null。
  String? _originalName;

  /// 打开表单时的颜色；保存时颜色变了才同步到同名课程。
  int? _originalColor;

  /// 草稿是否是整周课（保存时写回整周课表）。
  bool _fullWeek = false;

  /// 用解析出的初始课程填充表单（仅一次，避免覆盖用户已输入内容）。
  void init(Course initial, {bool fullWeek = false}) {
    if (_initialized) return;
    _initialized = true;
    _fullWeek = fullWeek;
    state = initial;
    _originalName = initial.id.isEmpty ? null : initial.name;
    _originalColor = initial.colorValue;
  }

  void setName(String v) => state = state.copyWith(name: v);

  void setTeacher(String v) => state = _withOptionalText(
        teacher: v.isEmpty ? null : v,
        location: state.location,
        notes: state.notes,
      );

  void setLocation(String v) => state = _withOptionalText(
        teacher: state.teacher,
        location: v.isEmpty ? null : v,
        notes: state.notes,
      );

  /// [Course.copyWith] 把 null 当作「不修改」，清空教师、教室、备注时
  /// 用它会留下旧值，所以这三项按给定值重建草稿。
  Course _withOptionalText({
    required String? teacher,
    required String? location,
    required String? notes,
  }) =>
      Course(
        id: state.id,
        semesterId: state.semesterId,
        name: state.name,
        teacher: teacher,
        location: location,
        dayOfWeek: state.dayOfWeek,
        startSection: state.startSection,
        endSection: state.endSection,
        startTime: state.startTime,
        endTime: state.endTime,
        useExplicitTimes: state.useExplicitTimes,
        weeks: state.weeks,
        colorValue: state.colorValue,
        notes: notes,
      );

  void setDayOfWeek(int d) => state = state.copyWith(dayOfWeek: d);

  void setStartSection(int s) {
    final end = state.endSection < s ? s : state.endSection;
    state = state.copyWith(startSection: s, endSection: end);
  }

  void setEndSection(int e) {
    final start = state.startSection > e ? e : state.startSection;
    state = state.copyWith(startSection: start, endSection: e);
  }

  void toggleWeek(int w, {int maxWeek = 40}) {
    if (w < 1 || w > maxWeek) return;
    final set = {...state.weeks};
    if (set.contains(w)) {
      set.remove(w);
    } else {
      set.add(w);
    }
    state = state.copyWith(weeks: set.toList()..sort());
  }

  void setAllWeeks(List<int> all) =>
      state = state.copyWith(weeks: [...all]..sort());

  void clearWeeks() => state = state.copyWith(weeks: const []);

  /// 选择单周（奇数周）。
  void setOddWeeks(int maxWeek) {
    final odd = [for (var i = 1; i <= maxWeek; i += 2) i];
    state = state.copyWith(weeks: odd);
  }

  /// 选择双周（偶数周）。
  void setEvenWeeks(int maxWeek) {
    final even = [for (var i = 2; i <= maxWeek; i += 2) i];
    state = state.copyWith(weeks: even);
  }

  /// 反选周次。
  void invertWeeks(int maxWeek) {
    final current = {...state.weeks};
    final inverted = <int>[];
    for (var i = 1; i <= maxWeek; i++) {
      if (!current.contains(i)) inverted.add(i);
    }
    state = state.copyWith(weeks: inverted);
  }

  void setColor(int v) => state = state.copyWith(colorValue: v);

  void setNotes(String v) => state = _withOptionalText(
        teacher: state.teacher,
        location: state.location,
        notes: v.isEmpty ? null : v,
      );

  /// 保存：新增时生成 id，编辑时沿用。
  /// 无学期时返回 false；无周次时返回 null（课程不会显示）；
  /// DB 错误时抛出异常由 UI 捕获。
  ///
  /// 课程名变了时先把旧名下的平台迁移到新名下；[platforms] 非 null 表示
  /// 用户在编辑页改过平台，整体写到当前课程名下。颜色改了时同步到本学期
  /// 同名的全部课程和整周课。课程、平台与颜色在同一事务内写入。
  Future<bool?> save({List<CoursePlatform>? platforms}) async {
    if (state.semesterId.isEmpty) return false;
    if (state.weeks.isEmpty) return null;
    if (_fullWeek) {
      // 整周课没有课程平台入口，只写课程字段，颜色同步规则与普通课相同。
      await _fullWeekRepo!.save(
        FullWeekCourse(
          id: state.id,
          semesterId: state.semesterId,
          name: state.name,
          teacher: state.teacher,
          location: state.location,
          weeks: state.weeks,
          colorValue: state.colorValue,
          notes: state.notes,
        ),
        syncColor: state.colorValue != _originalColor,
      );
      return true;
    }
    final toSave =
        state.copyWith(id: state.id.isEmpty ? const Uuid().v4() : state.id);
    await _repo.saveWithPlatforms(
      toSave,
      renamedFrom: _originalName,
      platforms: platforms,
      syncColor: toSave.colorValue != _originalColor,
    );
    return true;
  }
}
