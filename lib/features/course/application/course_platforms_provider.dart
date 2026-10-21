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

/// 编辑页的平台列表始终对应「当前课程名」下的平台：
///
/// - 当前名下已有平台（数据库或本页改过的草稿）时显示它们，改动也作用于它们；
/// - 编辑已有课程并改成一个还没有平台的新名字时，显示原课程名下的平台，
///   与保存时的改名迁移（见 `CoursePlatformRepository.migrateOnRename`）一致；
/// - 其余情况为空列表。
///
/// 草稿按课程名分别保存，来回改名不会丢失已做的改动；保存时只写当前名的草稿。
class CoursePlatformsFormNotifier extends StateNotifier<List<CoursePlatform>> {
  final CoursePlatformRepository _repo;
  CoursePlatformsFormNotifier(this._repo) : super(const []);

  String _semesterId = '';
  String? _originalName;
  String? _currentName;
  final Map<String, List<CoursePlatform>> _drafts = {};

  /// 保存时要写到当前课程名下的列表；null 表示没有改动，不写平台。
  List<CoursePlatform>? get pendingForCurrentName => _drafts[_currentName];

  /// [originalName] 为编辑已有课程时的原课程名，新建/复制课程时为 null。
  Future<void> init({
    required String semesterId,
    required String courseName,
    String? originalName,
  }) {
    _semesterId = semesterId;
    _originalName = originalName?.trim();
    return setCourseName(courseName);
  }

  /// 课程名输入变化时调用，按新名字重新解析要显示的平台。
  Future<void> setCourseName(String courseName) async {
    final name = courseName.trim();
    if (name == _currentName) return;
    _currentName = name;
    final platforms = await _resolve(name);
    // 只采用最新名字的结果；解析期间用户已对该名字做了改动则不覆盖。
    if (!mounted || _currentName != name) return;
    state = _drafts[name] ?? platforms;
  }

  void add(CoursePlatform platform) => _set([...state, platform]);

  void replaceAt(int index, CoursePlatform platform) =>
      _set([...state]..[index] = platform);

  void removeAt(int index) => _set([...state]..removeAt(index));

  void _set(List<CoursePlatform> platforms) {
    final name = _currentName;
    if (name != null) _drafts[name] = platforms;
    state = platforms;
  }

  Future<List<CoursePlatform>> _resolve(String name) async {
    final draft = _drafts[name];
    if (draft != null) return draft;
    if (_semesterId.isEmpty || name.isEmpty) return const [];
    final own = await _repo.getPlatforms(_semesterId, name);
    if (own.isNotEmpty) return own;
    final original = _originalName;
    if (original == null || original.isEmpty || original == name) {
      return const [];
    }
    // 改名到空名下：保存时原名下的平台会迁移过来。原名有草稿时草稿随名字
    // 一起带过来，并记为新名的草稿，保证保存时写入的正是用户看到的列表。
    final originalDraft = _drafts[original];
    if (originalDraft != null) {
      _drafts[name] = originalDraft;
      return originalDraft;
    }
    return _repo.getPlatforms(_semesterId, original);
  }
}
