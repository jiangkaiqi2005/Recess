import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/data/providers/database_providers.dart';
import 'package:hormone/data/repositories/course_platform_repository.dart';

/// 某门课（学期 + 课程名）的课程平台流，详情面板使用。
final coursePlatformsProvider = StreamProvider.autoDispose
    .family<List<CoursePlatform>, ({String semesterId, String courseName})>(
  (ref, key) => ref
      .watch(coursePlatformRepositoryProvider)
      .watchPlatforms(key.semesterId, key.courseName),
);

/// 课程编辑页里正在编辑的平台列表。改动只留在内存里，随「保存」一起写库。
final coursePlatformsFormProvider = StateNotifierProvider.autoDispose<
    CoursePlatformsFormNotifier, List<CoursePlatform>>(
  (ref) =>
      CoursePlatformsFormNotifier(ref.watch(coursePlatformRepositoryProvider)),
);

class CoursePlatformsFormNotifier extends StateNotifier<List<CoursePlatform>> {
  final CoursePlatformRepository _repo;
  CoursePlatformsFormNotifier(this._repo) : super(const []);

  bool _loaded = false;

  /// 用户是否改动过列表；没改动时保存不写平台，交给改名迁移处理。
  bool get changed => _changed;
  bool _changed = false;

  /// 读取课程名下已有的平台（仅一次；用户已开始编辑则不覆盖）。
  Future<void> load(String semesterId, String courseName) async {
    if (_loaded) return;
    _loaded = true;
    if (semesterId.isEmpty || courseName.trim().isEmpty) return;
    final platforms = await _repo.getPlatforms(semesterId, courseName);
    if (mounted && !_changed) state = platforms;
  }

  void add(CoursePlatform platform) => _set([...state, platform]);

  void replaceAt(int index, CoursePlatform platform) =>
      _set([...state]..[index] = platform);

  void removeAt(int index) => _set([...state]..removeAt(index));

  void _set(List<CoursePlatform> platforms) {
    _changed = true;
    state = platforms;
  }
}
