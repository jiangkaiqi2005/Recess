import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/import_diagnostic.dart';

void main() {
  group('isAllowedPlatformUrl', () {
    test('允许 host 非空的 http/https 链接', () {
      expect(isAllowedPlatformUrl('https://a.b'), isTrue);
      expect(isAllowedPlatformUrl('http://a.b'), isTrue);
    });

    test('拒绝任意协议或非完整地址', () {
      expect(isAllowedPlatformUrl('intent://x'), isFalse);
      expect(isAllowedPlatformUrl('file:///sdcard/x'), isFalse);
      expect(isAllowedPlatformUrl('content://x'), isFalse);
      expect(isAllowedPlatformUrl('高数'), isFalse);
      expect(isAllowedPlatformUrl('https://'), isFalse);
      expect(isAllowedPlatformUrl(' javascript:alert(1)'), isFalse);
    });
  });

  group('parseCoursePlatformGroups', () {
    test('协议非法的条目保留但 url 置空，记为部分忽略', () {
      final diagnostics = <ImportDiagnostic>[];
      final groups = parseCoursePlatformGroups({
        '高数': [
          {'purpose': 'online_course', 'name': '学习通', 'url': 'intent://bad'},
        ],
      }, diagnostics: diagnostics);

      final list = groups['高数']!;
      expect(list, hasLength(1));
      expect(list.single.name, '学习通');
      expect(list.single.url, isNull);
      expect(diagnostics.map((d) => (d.kind, d.message)), [
        (ImportDiagnosticKind.partial, '课程平台「高数」第1条：链接协议不允许，已忽略'),
      ]);
    });

    test('合法 https 与无 url 的记录不受影响', () {
      final diagnostics = <ImportDiagnostic>[];
      final groups = parseCoursePlatformGroups({
        '英语': [
          {'purpose': 'homework', 'name': '雨课堂', 'url': 'https://x.y/z'},
          {'purpose': 'lab', 'name': '本地实验'},
        ],
      }, diagnostics: diagnostics);

      expect(diagnostics, isEmpty);
      final list = groups['英语']!;
      expect(list[0].url, 'https://x.y/z');
      expect(list[1].url, isNull);
    });
  });
}
