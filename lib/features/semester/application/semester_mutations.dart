import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recess/core/models/semester.dart';
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

final semesterMutationsProvider = Provider<SemesterMutations>((ref) {
  return SemesterMutations(ref);
});

/// 学期变更提交成功后统一刷新；提醒与小组件继续由应用级监听更新。
class SemesterMutations {
  final Ref _ref;

  SemesterMutations(this._ref);

  Future<void> save(Semester semester, {bool activate = false}) async {
    await _ref
        .read(semesterRepositoryProvider)
        .upsert(semester, activate: activate);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _ref.read(semesterRepositoryProvider).delete(id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(activeSemesterProvider);
    _ref.invalidate(scheduleCoursesProvider);
    _ref.invalidate(semestersProvider);
  }
}
