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

    test('允许地址合法的 mailto 链接', () {
      expect(isAllowedPlatformUrl('mailto:t@cqu.edu.cn'), isTrue);
      expect(isAllowedPlatformUrl('mailto:t@cqu.edu.cn?subject=作业'), isTrue);
    });

    test('拒绝地址不完整的 mailto 链接与裸邮箱', () {
      expect(isAllowedPlatformUrl('mailto:'), isFalse);
      expect(isAllowedPlatformUrl('mailto:t'), isFalse);
      expect(isAllowedPlatformUrl('mailto:t@cqu'), isFalse);
      expect(isAllowedPlatformUrl('mailto:@cqu.edu.cn'), isFalse);
      expect(isAllowedPlatformUrl('t@cqu.edu.cn'), isFalse);
    });
  });

  group('normalizePlatformUrl', () {
    test('裸邮箱补成 mailto，其余只去空白', () {
      expect(normalizePlatformUrl(' t@cqu.edu.cn '), 'mailto:t@cqu.edu.cn');
      expect(normalizePlatformUrl('mailto:t@cqu.edu.cn'), 'mailto:t@cqu.edu.cn');
      expect(normalizePlatformUrl(' https://a.b '), 'https://a.b');
      expect(normalizePlatformUrl('https://a.b/@x'), 'https://a.b/@x');
    });
  });

  group('platformUrlLabel', () {
    test('mailto 只显示地址，其余原样', () {
      expect(platformUrlLabel('mailto:t@cqu.edu.cn'), 't@cqu.edu.cn');
      expect(platformUrlLabel('https://a.b'), 'https://a.b');
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
      expect(
        diagnostics.map((d) => (d.kind, d.message)),
        [
          (
            ImportDiagnosticKind.partial,
            '课程平台「高数」第1条：链接协议不允许，已忽略',
          ),
        ],
      );
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

    test('裸邮箱导入后补成 mailto', () {
      final diagnostics = <ImportDiagnostic>[];
      final groups = parseCoursePlatformGroups({
        '物理': [
          {'purpose': 'homework', 'name': '交作业', 'url': 't@cqu.edu.cn'},
        ],
      }, diagnostics: diagnostics);

      expect(diagnostics, isEmpty);
      expect(groups['物理']!.single.url, 'mailto:t@cqu.edu.cn');
    });
  });
}
