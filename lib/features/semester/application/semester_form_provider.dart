import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:recess/core/models/semester.dart';
import 'package:recess/features/semester/application/semester_mutations.dart';

/// 学期编辑表单状态机。新增时 id 为空，保存时生成。
final semesterFormProvider =
    StateNotifierProvider.autoDispose<SemesterFormNotifier, Semester>(
  (ref) => SemesterFormNotifier(ref.watch(semesterMutationsProvider)),
);

class SemesterFormNotifier extends StateNotifier<Semester> {
  final SemesterMutations _mutations;
  SemesterFormNotifier(this._mutations)
      : super(Semester(
          id: '',
          name: '',
          startDate: DateTime.now(),
          totalWeeks: 18,
        ));

  bool _initialized = false;

  void init(Semester initial) {
    if (_initialized) return;
    _initialized = true;
    state = initial;
  }

  void setName(String v) => state = state.copyWith(name: v);

  void setStartDate(DateTime d) => state = state.copyWith(startDate: d);

  void setTotalWeeks(int w) =>
      state = state.copyWith(totalWeeks: w.clamp(1, 30));

  void setCurrentWeekOverride(int? w) =>
      state = state.copyWith(currentWeekOverride: w);

  /// 返回保存后的 id。新增时生成 id；[activate] 为 true 则设为唯一激活学期。
  Future<String> save({bool activate = false}) async {
    var s = state;
    if (s.id.isEmpty) s = s.copyWith(id: const Uuid().v4());
    await _mutations.save(s, activate: activate);
    state = s;
    return s.id;
  }

  Future<void> delete() async {
    if (state.id.isEmpty) return;
    await _mutations.delete(state.id);
  }
}
