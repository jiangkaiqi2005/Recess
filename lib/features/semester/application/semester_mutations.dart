import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recess/core/models/semester.dart';
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/schedule/application/schedule_providers.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

final semesterMutationsProvider = Provider<SemesterMutations>((ref) {
  return SemesterMutations(ref);
});

/// 学期变更提交成功后统一刷新；提醒与小组件继续由应用级监听更新。
class SemesterMutations {
  final Ref _ref;

  SemesterMutations(this._ref);

  Future<void> save(Semester semester, {bool activate = false}) async {
    final repo = _ref.read(semesterRepositoryProvider);
    final previous = activate ? await repo.getActiveSemester() : null;
    await repo.upsert(semester, activate: activate);
    _refresh(resetViewedWeek: activate && previous?.id != semester.id);
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(semesterRepositoryProvider);
    final previous = await repo.getActiveSemester();
    await repo.delete(id);
    _refresh(resetViewedWeek: previous?.id == id);
  }

  void _refresh({bool resetViewedWeek = false}) {
    if (resetViewedWeek) _ref.invalidate(selectedWeekProvider);
    _ref.invalidate(activeSemesterProvider);
    _ref.invalidate(scheduleCoursesProvider);
    _ref.invalidate(semestersProvider);
  }
}
