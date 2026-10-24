import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/constants/app_constants.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';
import 'package:recess/features/settings/presentation/section_time_editor.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> openEditor(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SectionTimeEditor())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// 预置一份非默认的已保存节次时间（第 1 节 09:30，其余留空）。
  Future<List<String>> seedCustomTimes() async {
    final stored = List.generate(
      AppConstants.maxSections,
      (i) => i == 0 ? '09:30,45' : ',45',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_section_times_v2', stored);
    return stored;
  }

  Future<void> pickStart(
    WidgetTester tester,
    int section,
    String hour,
    String minute,
  ) async {
    await tester.tap(find.byKey(ValueKey('section-start-$section')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), hour);
    await tester.enterText(fields.at(1), minute);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('默认开启同步，修改第一节立即更新后续节次和结束时间', (tester) async {
    final container = await openEditor(tester);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await pickStart(tester, 1, '08', '30');

    final times = container.read(sectionTimesProvider);
    expect(times[1]?.startTime, '08:30');
    expect(times[2]?.startTime, '09:25');
    expect(times[5]?.startTime, '14:30');
    expect(times[13]?.startTime, isEmpty);
    expect(find.text('09:25'), findsOneWidget);
    expect(find.text('→ 10:10'), findsOneWidget);
  });

  testWidgets('关闭同步后只修改第一节，再开启时保留当前间隔', (tester) async {
    final container = await openEditor(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await pickStart(tester, 1, '08', '10');
    expect(container.read(sectionTimesProvider)[2]?.startTime, '08:55');

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await pickStart(tester, 1, '08', '30');
    expect(container.read(sectionTimesProvider)[2]?.startTime, '09:15');
  });

  testWidgets('同步开关不影响其他节次的单独编辑', (tester) async {
    final container = await openEditor(tester);
    await pickStart(tester, 2, '09', '10');

    final times = container.read(sectionTimesProvider);
    expect(times[1]?.startTime, '08:00');
    expect(times[2]?.startTime, '09:10');
    expect(times[3]?.startTime, '10:00');
  });

  testWidgets('取消时间选择不改变课表', (tester) async {
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    await tester.tap(find.byKey(const ValueKey('section-start-1')));
    await tester.pumpAndSettle();
    expect(find.text('调整第一节并同步顺延'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(sectionTimesProvider), same(before));
  });

  testWidgets('跨天时显示原因并保留整张时间表', (tester) async {
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    await pickStart(tester, 1, '23', '00');

    expect(find.text('无法同步顺延'), findsOneWidget);
    expect(find.textContaining('超出当天'), findsOneWidget);
    expect(container.read(sectionTimesProvider), same(before));
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('恢复默认先弹覆盖确认，取消后状态与已保存配置完全不变', (tester) async {
    final stored = await seedCustomTimes();
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();

    expect(find.text('恢复默认节次时间'), findsOneWidget);
    expect(find.textContaining('全部节次时间将被覆盖'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('恢复默认节次时间'), findsNothing);
    expect(container.read(sectionTimesProvider), same(before));
    expect(container.read(sectionTimesProvider)[1]?.startTime, '09:30');
    expect(find.text('09:30'), findsOneWidget);
    expect(prefs.getStringList('custom_section_times_v2'), stored);
  });

  testWidgets('点击遮罩关闭恢复默认确认后不产生任何变化', (tester) async {
    final stored = await seedCustomTimes();
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();
    // 点击对话框遮罩（对话框居中，四角必然在遮罩上）。
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('恢复默认节次时间'), findsNothing);
    expect(container.read(sectionTimesProvider), same(before));
    expect(prefs.getStringList('custom_section_times_v2'), stored);
  });

  testWidgets('确认恢复默认后回到默认节次时间并清除已保存配置', (tester) async {
    await seedCustomTimes();
    final container = await openEditor(tester);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();

    final times = container.read(sectionTimesProvider);
    expect(times[1]?.timeRange, '08:00-08:45');
    expect(times[2]?.timeRange, '08:55-09:40');
    expect(find.text('08:00'), findsOneWidget);
    expect(prefs.containsKey('custom_section_times_v2'), isFalse);
  });

  testWidgets('选定模板先弹应用确认，取消后状态与持久化不变', (tester) async {
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('模板'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 分钟大节课制'));
    await tester.pumpAndSettle();

    // 选择模板后先确认，确认文案包含模板名与覆盖说明。
    expect(find.text('应用节次模板'), findsOneWidget);
    expect(find.textContaining('90 分钟大节课制'), findsOneWidget);
    expect(find.textContaining('全部节次时间将被覆盖'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(container.read(sectionTimesProvider), same(before));
    expect(container.read(sectionTimesProvider)[2]?.startTime, '08:55');
    expect(prefs.containsKey('custom_section_times_v2'), isFalse);
  });

  testWidgets('点击遮罩关闭模板应用确认后不应用模板', (tester) async {
    final container = await openEditor(tester);
    final before = container.read(sectionTimesProvider);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('模板'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('标准 45 分钟制'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('应用节次模板'), findsNothing);
    expect(container.read(sectionTimesProvider), same(before));
    expect(prefs.containsKey('custom_section_times_v2'), isFalse);
  });

  testWidgets('确认应用模板后按模板写入状态与持久化', (tester) async {
    final container = await openEditor(tester);
    final prefs = await SharedPreferences.getInstance();

    await tester.tap(find.text('模板'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 分钟大节课制'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    final times = container.read(sectionTimesProvider);
    expect(times[1]?.timeRange, '08:00-09:30');
    expect(times[2]?.timeRange, '09:45-11:15');
    expect(times[7]?.startTime, isEmpty);
    final saved = prefs.getStringList('custom_section_times_v2');
    expect(saved?[0], '08:00,90');
    expect(saved?[1], '09:45,90');
  });
}
