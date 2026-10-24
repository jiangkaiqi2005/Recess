/// 课程平台的用途。[key] 是持久化与备份 JSON 中使用的稳定键，不随文案变化。
enum CoursePlatformPurpose {
  onlineCourse('online_course', '网课'),
  lab('lab', '实验'),
  homework('homework', '作业'),
  group('group', '课程群'),
  other('other', '其他');

  final String key;
  final String label;

  const CoursePlatformPurpose(this.key, this.label);

  /// 按持久化键解析；未知键返回 null，由调用方决定跳过或回退。
  static CoursePlatformPurpose? fromKey(String? key) {
    for (final purpose in values) {
      if (purpose.key == key) return purpose;
    }
    return null;
  }
}

/// 课程平台：同一学期内某门课（按课程名）使用的一个外部平台，
/// 例如“网课：学习通”。归属规则见 docs/adr/0001。
class CoursePlatform {
  final CoursePlatformPurpose purpose;
  final String name; // 非空
  final String? url;

  const CoursePlatform({required this.purpose, required this.name, this.url})
    : assert(name != '', 'name must not be empty');

  /// 备份与 JSON 导入共用的条目格式。
  Map<String, dynamic> toJson() => {
    'purpose': purpose.key,
    'name': name,
    'url': url,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursePlatform &&
          purpose == other.purpose &&
          name == other.name &&
          url == other.url;

  @override
  int get hashCode => Object.hash(purpose, name, url);
}

/// 同一学期内按课程名分组的课程平台：课程名 → 该课的平台（组内有序）。
typedef CoursePlatformGroups = Map<String, List<CoursePlatform>>;

/// 课程平台链接仅允许 http/https，防止导入文件携带任意协议的 URI
///（如 intent://、content://）被外部打开。
bool isAllowedPlatformUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// 解析 JSON 中的 `platforms` 字段：`{"<课程名>": [{"purpose", "name", "url"}]}`。
///
/// 备份恢复与 JSON 课表导入共用。用途键未知、平台名为空或条目不是对象时跳过
/// 该条，并把原因追加到 [skipped]；链接协议非 http/https 时保留条目但忽略
/// 链接，同样记入 [skipped]；字段整体不是对象时视为没有平台。
CoursePlatformGroups parseCoursePlatformGroups(
  Object? raw, {
  List<String>? skipped,
}) {
  final CoursePlatformGroups result = {};
  if (raw is! Map) return result;
  for (final entry in raw.entries) {
    final courseName = entry.key.toString().trim();
    final items = entry.value;
    if (courseName.isEmpty || items is! List) {
      skipped?.add('课程平台「$courseName」：格式非法');
      continue;
    }
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        skipped?.add('课程平台「$courseName」第${i + 1}条：非对象');
        continue;
      }
      final purpose = CoursePlatformPurpose.fromKey(
        item['purpose']?.toString(),
      );
      final name = item['name']?.toString().trim() ?? '';
      if (purpose == null || name.isEmpty) {
        skipped?.add('课程平台「$courseName」第${i + 1}条：用途或平台名非法');
        continue;
      }
      var url = item['url']?.toString().trim();
      if (url != null && url.isNotEmpty && !isAllowedPlatformUrl(url)) {
        url = null;
        skipped?.add('课程平台「$courseName」第${i + 1}条：链接协议不允许，已忽略');
      }
      result
          .putIfAbsent(courseName, () => [])
          .add(
            CoursePlatform(
              purpose: purpose,
              name: name,
              url: url == null || url.isEmpty ? null : url,
            ),
          );
    }
  }
  return result;
}
