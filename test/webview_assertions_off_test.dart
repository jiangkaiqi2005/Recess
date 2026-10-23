import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('断言关闭的真实Dart进程仍遵守相同教务校验和诊断', () async {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final package = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((p) => p['name'] == 'flutter_test');
    final flutterRoot =
        Directory.fromUri(
          configFile.uri.resolve(package['rootUri'] as String),
        ).parent.parent;
    final dart =
        '${flutterRoot.path}/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}';
    final result = await Process.run(
      dart,
      ['test/fixtures/webview_assertions_probe.dart'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final actual = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final debug = await Process.run(
      dart,
      ['--enable-asserts', 'test/fixtures/webview_assertions_probe.dart'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    expect(debug.exitCode, 0, reason: debug.stderr.toString());
    final debugResult =
        jsonDecode(debug.stdout as String) as Map<String, dynamic>;
    expect(debugResult.remove('assertions'), isTrue);
    expect({...actual}..remove('assertions'), debugResult);
    expect(actual, {
      'assertions': false,
      'accepted': 2,
      'name': '高 数',
      'weeks': [1, 2, 3],
      'skipped': 15,
      'reasons': {
        '节次超出第1–16节': 2,
        '节次缺失或无效': 2,
        '结束节次早于开始节次': 1,
        '课程名为空或无效': 1,
        '周次缺失或无效': 5,
        '星期缺失或无效': 3,
        '课程记录格式无效': 1,
      },
      'conflicts': 1,
      'canSubmit': false,
    });
  });
}
