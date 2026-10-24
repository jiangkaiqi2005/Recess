// Smoke test for the recess app shell.
//
// This verifies the root widget tree builds without throwing. Detailed
// business-logic coverage lives in the unit test suites under test/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recess/main.dart';

void main() {
  testWidgets('RecessApp builds without throwing', (WidgetTester tester) async {
    // RecessApp 会在根部安装全局构建失败兜底（ErrorWidget.builder）。
    // 测试框架在测试体一结束就校验该全局未被改动，因此必须在体内
    // （而非 addTearDown）手动恢复原值。
    final originalBuilder = ErrorWidget.builder;

    // Build the real app root inside a Riverpod scope. The router resolves
    // asynchronously; we only assert the widget tree mounts successfully.
    await tester.pumpWidget(const ProviderScope(child: RecessApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    ErrorWidget.builder = originalBuilder;
  });
}
