// 界面构建失败兜底的行为验收（issue #6）。
//
// 只断言外部行为：可见文案、按钮有无、返回后的正常页面、紧凑区域是否
// 溢出，以及真实应用根是否安装兜底；不断言错误组件的私有名称或结构。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:recess/app/build_error_fallback.dart';
import 'package:recess/core/theme/app_theme.dart';
import 'package:recess/main.dart';

/// 临时正常页面：带可识别按钮，可进入故障页。
class _NormalPage extends StatelessWidget {
  const _NormalPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => context.push('/fail'),
              child: const Text('打开故障页'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/cramped'),
              child: const Text('打开受限故障页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 故障页面：在 build 阶段主动抛异常。
class _FailPage extends StatelessWidget {
  const _FailPage();

  @override
  Widget build(BuildContext context) {
    throw StateError('forced build failure');
  }
}

/// 受限故障页面：失败区域 320x190（宽度足够、高度低于完整说明的最小
/// 内容高度但高于课程卡），用于验证空间判断按内容实际需要降级。
class _CrampedFailPage extends StatelessWidget {
  const _CrampedFailPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: SizedBox(width: 320, height: 190, child: _FailPage())),
    );
  }
}

Widget _hostApp(String initialLocation, {ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(path: '/', builder: (context, state) => const _NormalPage()),
          GoRoute(path: '/fail', builder: (context, state) => const _FailPage()),
          GoRoute(
            path: '/cramped',
            builder: (context, state) => const _CrampedFailPage(),
          ),
        ],
      ),
    ),
  );
}

/// 课程卡大小的受限区域中的正常页面（周视图单节卡约 46x52 逻辑像素）。
Widget _hostLocalFailure(ThemeData theme) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Column(
          children: [
            Text('上方正常内容'),
            SizedBox(width: 46, height: 52, child: _FailPage()),
            Text('下方正常内容'),
          ],
        ),
      ),
    ),
  );
}

/// 取指定文案所在错误兜底的背景色（最近的 ColoredBox 祖先）。
Color _backgroundColorOf(WidgetTester tester, String text) {
  return tester
      .widget<ColoredBox>(
        find
            .ancestor(of: find.text(text), matching: find.byType(ColoredBox))
            .first,
      )
      .color;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 文件开始时先记下框架默认 builder；根装配测试需要先恢复它，
  // 才能证明安装来自真实生产入口而非测试环境。
  late final ErrorWidgetBuilder frameworkDefaultBuilder;
  setUpAll(() {
    frameworkDefaultBuilder = ErrorWidget.builder;
  });

  // 行为测试自行安装 builder，必须保存并恢复原值。
  setUp(() {
    final original = ErrorWidget.builder;
    ErrorWidget.builder = buildErrorFallback;
    addTearDown(() => ErrorWidget.builder = original);
  });

  group('完整状态', () {
    testWidgets('有上一页的故障页显示完整说明与返回按钮，点击后回到之前的正常页面', (tester) async {
      await tester.pumpWidget(_hostApp('/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开故障页'));
      await tester.pump(); // 故障页在 build 阶段抛异常
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();

      expect(find.text('页面暂时无法显示'), findsOneWidget);
      expect(find.text('返回上一页后重试'), findsOneWidget);
      final backButton = find.widgetWithText(FilledButton, '返回上一页');
      expect(backButton, findsOneWidget);
      // 浅色主题下文字沿用主题令牌。
      final title = tester.widget<Text>(find.text('页面暂时无法显示'));
      expect(title.style?.color, AppColors.textLight);
      final note = tester.widget<Text>(find.text('返回上一页后重试'));
      expect(note.style?.color, AppColors.textMutedLight);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('打开故障页'), findsOneWidget);
      // 恢复后不应出现新的未处理异常。
      expect(tester.takeException(), isNull);
    });

    testWidgets('初始路由即故障页时提示请重新打开应用且不显示任何按钮', (tester) async {
      await tester.pumpWidget(_hostApp('/fail'));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());

      expect(find.text('页面暂时无法显示'), findsOneWidget);
      expect(find.text('请重新打开应用'), findsOneWidget);
      expect(find.text('返回上一页后重试'), findsNothing);
      expect(find.text('返回上一页'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('重试'), findsNothing);
      expect(find.text('回到课表'), findsNothing);
      // 不显示异常对象、堆栈或错误信息。
      expect(find.textContaining('forced build failure'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('紧凑状态', () {
    testWidgets('课程卡大小的区域只显示紧凑提示，不溢出且不影响周围内容', (tester) async {
      await tester.pumpWidget(_hostLocalFailure(AppTheme.light));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());

      expect(find.text('暂时无法显示'), findsOneWidget);
      expect(find.text('页面暂时无法显示'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('上方正常内容'), findsOneWidget);
      expect(find.text('下方正常内容'), findsOneWidget);
      final compact = tester.widget<Text>(find.text('暂时无法显示'));
      expect(compact.style?.color, AppColors.textMutedLight);
      // 紧凑提示没有引发布局溢出等新异常。
      expect(tester.takeException(), isNull);
    });

    testWidgets('深色主题下紧凑状态使用主题文字与表面色', (tester) async {
      await tester.pumpWidget(_hostLocalFailure(AppTheme.dark));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());

      final compact = tester.widget<Text>(find.text('暂时无法显示'));
      expect(compact.style?.color, AppColors.textMutedDark);
      expect(_backgroundColorOf(tester, '暂时无法显示'),
          AppTheme.dark.colorScheme.surface);
      expect(tester.takeException(), isNull);
    });

    testWidgets('高度不足以容纳完整说明时降级为紧凑提示且不溢出', (tester) async {
      await tester.pumpWidget(_hostApp('/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开受限故障页'));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();

      // 320x190 的区域放不下完整说明（默认字号下最小内容高度约 198），
      // 应显示紧凑提示，而不是塞下完整态导致按钮被裁切。
      expect(find.text('暂时无法显示'), findsOneWidget);
      expect(find.text('页面暂时无法显示'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      // 没有布局溢出等新异常。
      expect(tester.takeException(), isNull);
    });
  });

  group('深色主题完整状态', () {
    testWidgets('深色主题下完整说明使用主题文字与背景色', (tester) async {
      await tester.pumpWidget(_hostApp('/fail', themeMode: ThemeMode.dark));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());

      final title = tester.widget<Text>(find.text('页面暂时无法显示'));
      expect(title.style?.color, AppColors.textDark);
      final note = tester.widget<Text>(find.text('请重新打开应用'));
      expect(note.style?.color, AppColors.textMutedDark);
      expect(_backgroundColorOf(tester, '页面暂时无法显示'),
          AppTheme.dark.scaffoldBackgroundColor);
      expect(tester.takeException(), isNull);
    });
  });

  group('根装配', () {
    testWidgets('真实 RecessApp 启动后安装了全局构建失败兜底', (tester) async {
      // 先恢复框架默认，确保接下来的安装来自真实 RecessApp。
      ErrorWidget.builder = frameworkDefaultBuilder;

      await tester.pumpWidget(const ProviderScope(child: RecessApp()));
      await tester.pump();

      expect(identical(ErrorWidget.builder, frameworkDefaultBuilder), isFalse);
    });
  });
}
