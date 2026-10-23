import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/schedule/application/schedule_providers.dart';
import 'package:recess/features/schedule/presentation/schedule_screen.dart';
import 'package:recess/features/schedule/presentation/week_view.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // 让今天落在第 3 周。
  final semesterStart =
      today.subtract(Duration(days: today.weekday - 1 + 7 * 2));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpSchedule(
    WidgetTester tester, {
    DateTime? startDate,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = SemesterRepository(database);
    await tester.runAsync(() async {
      await repo.upsert(Semester(
        id: 'semester',
        name: '测试学期',
        startDate: startDate ?? semesterStart,
        totalWeeks: 18,
      ));
      await repo.setActive('semester');
    });
    const course = Course(
      id: 'course',
      semesterId: 'semester',
      name: '高等数学',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: [3, 4],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          scheduleCoursesProvider.overrideWith(
            (ref) => Stream.value(const [course]),
          ),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder weekCell(String week) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(week),
      );

  Future<void> openWeekMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('schedule-week-menu')));
    await tester.pumpAndSettle();
  }

  testWidgets('顶栏标题是今天日期和查看周，右侧依次为添加、搜索、更多', (tester) async {
    await pumpSchedule(tester);

    expect(tester.getSize(find.byType(AppBar)).height, 56);
    expect(find.text('${today.year}/${today.month}/${today.day}'),
        findsOneWidget);
    expect(find.text('第 3 周'), findsOneWidget);
    // 学期名、旧切周栏、学期进度条和浮动按钮都不在主页出现。
    expect(find.text('测试学期'), findsNothing);
    expect(find.byKey(const Key('schedule-week-selector')), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    final actions = [Icons.add, Icons.search, Icons.more_vert]
        .map((icon) => tester.getCenter(find.byIcon(icon)).dx)
        .toList();
    expect(actions[0], lessThan(actions[1]));
    expect(actions[1], lessThan(actions[2]));
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('今日课程'), findsOneWidget);
    expect(find.text('课程抓取说明'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('查看本周时菜单没有“回到本周”，翻到别的周后出现并能回到本周',
      (tester) async {
    await pumpSchedule(tester);

    await openWeekMenu(tester);
    expect(find.text('跳转到第几周'), findsOneWidget);
    expect(find.text('修改当前周'), findsOneWidget);
    expect(find.text('回到本周'), findsNothing);
    await tester.tapAt(const Offset(180, 700));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('第 4 周   当前为第 3 周'), findsOneWidget);

    await openWeekMenu(tester);
    expect(find.text('回到本周'), findsOneWidget);
    await tester.tap(find.text('回到本周'));
    await tester.pumpAndSettle();

    expect(find.text('第 3 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻页只更新周标题，不重建 PageView', (tester) async {
    await pumpSchedule(tester);
    final pageView = tester.widget<PageView>(find.byType(PageView));

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(tester.widget<PageView>(find.byType(PageView)), same(pageView));
    expect(find.text('第 4 周   当前为第 3 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('横向轻拖回弹保留周视图元素和纵向滚动位置', (tester) async {
    await pumpSchedule(tester);
    await tester.binding.setSurfaceSize(const Size(360, 500));
    await tester.pumpAndSettle();
    final currentWeek = find.byKey(const ValueKey(3));
    final verticalScroll = find.descendant(
      of: currentWeek,
      matching: find.byKey(const Key('week-view-vertical-scroll')),
    );
    final scrollable = find.descendant(
      of: verticalScroll,
      matching: find.byType(Scrollable),
    );

    await tester.drag(verticalScroll, const Offset(0, -100));
    await tester.pumpAndSettle();
    final element = tester.element(currentWeek);
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await tester.drag(find.byType(PageView), const Offset(-60, 0));
    await tester.pumpAndSettle();

    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 2);
    expect(tester.element(currentWeek), same(element));
    expect(tester.state<ScrollableState>(scrollable).position.pixels,
        closeTo(offset, 0.000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻页用缩放和背景色遮罩淡化，静止页不加效果', (tester) async {
    await pumpSchedule(tester);
    final background = Theme.of(tester.element(find.byType(PageView)))
        .scaffoldBackgroundColor;
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final currentPage = find.descendant(
      of: find.byType(PageView),
      matching: find.byWidgetPredicate((widget) =>
          widget is AnimatedBuilder &&
          widget.child is WeekView &&
          (widget.child as WeekView).selectedWeek == 3),
    );
    final scale = find.descendant(
      of: currentPage,
      matching: find.ancestor(
        of: find.byKey(const ValueKey(3)),
        matching: find.byType(Transform),
      ),
    );
    final mask = find.descendant(
      of: currentPage,
      matching: find.byType(ColoredBox),
    );
    expect(tester.widget<Transform>(scale).transform.isIdentity(), isTrue);
    expect(mask, findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-120, 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(currentPage, findsOneWidget);
    final distance = (pageView.controller!.page! - 2).abs();
    expect(distance, inExclusiveRange(0, 1));
    final transform = tester.widget<Transform>(scale).transform;
    expect(transform.entry(0, 0), closeTo(1 - distance * 0.012, 0.000001));
    expect(transform.entry(1, 1), closeTo(1 - distance * 0.012, 0.000001));
    final color = tester.widget<ColoredBox>(mask).color;
    expect(color.withValues(alpha: 1), background.withValues(alpha: 1));
    expect(color.a, closeTo(distance * 0.08, 0.000001));
    final ignorePointer = find.ancestor(
      of: mask,
      matching: find.byType(IgnorePointer),
    );
    expect(tester.widget<IgnorePointer>(ignorePointer.first).ignoring, isTrue);
    expect(find.byType(WeekView), findsWidgets);
    expect(
      find.ancestor(of: find.byType(WeekView), matching: find.byType(Opacity)),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(currentPage, findsOneWidget);
    expect(tester.widget<Transform>(scale).transform.isIdentity(), isTrue);
    expect(mask, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首屏异步定位和外部查看周变化都同步到对应页', (tester) async {
    await pumpSchedule(tester);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 2);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScheduleScreen)),
    );

    container.read(selectedWeekProvider.notifier).goTo(6, totalWeeks: 18);
    await tester.pumpAndSettle();

    expect(tester.widget<PageView>(find.byType(PageView)), same(pageView));
    expect(pageView.controller!.page, 5);
    expect(find.text('第 6 周   当前为第 3 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换激活学期更新总周数并定位到新学期当前周', (tester) async {
    await pumpSchedule(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScheduleScreen)),
    );
    final repo = SemesterRepository(database);
    await tester.runAsync(() async {
      await repo.upsert(Semester(
        id: 'new-semester',
        name: '新学期',
        startDate: semesterStart.subtract(const Duration(days: 14)),
        totalWeeks: 8,
      ));
      await repo.setActive('new-semester');
    });
    container.invalidate(activeSemesterProvider);
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 8);
    expect(pageView.controller!.page, 4);
    expect(find.text('第 5 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('“跳转到第几周”用选周网格翻到对应周', (tester) async {
    await pumpSchedule(tester);

    await openWeekMenu(tester);
    await tester.tap(find.text('跳转到第几周'));
    await tester.pumpAndSettle();
    await tester.tap(weekCell('5'));
    await tester.pumpAndSettle();

    expect(find.text('第 5 周   当前为第 3 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('“修改当前周”写入学期的手动当前周并翻到该周', (tester) async {
    await pumpSchedule(tester);

    await openWeekMenu(tester);
    await tester.tap(find.text('修改当前周'));
    await tester.pumpAndSettle();
    await tester.tap(weekCell('7'));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(
      () => SemesterRepository(database).getActiveSemester(),
    );
    expect(saved?.currentWeekOverride, 7);
    expect(find.text('第 7 周'), findsOneWidget);
    expect(find.text('当前周已改为第 7 周'), findsOneWidget);

    await openWeekMenu(tester);
    expect(find.text('回到本周'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('修改当前周保存失败保持旧周数并提示失败', (tester) async {
    await pumpSchedule(tester);
    await tester.runAsync(() => database.customStatement('''
      CREATE TRIGGER fail_week_save BEFORE UPDATE ON semesters
      BEGIN SELECT RAISE(ABORT, 'forced week save failure'); END;
    '''));
    await openWeekMenu(tester);
    await tester.tap(find.text('修改当前周'));
    await tester.pumpAndSettle();
    await tester.tap(weekCell('7'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('第 3 周'), findsOneWidget);
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(find.text('当前周已改为第 7 周'), findsNothing);
    final saved = await tester.runAsync(
      () => SemesterRepository(database).getActiveSemester(),
    );
    expect(saved?.currentWeekOverride, isNull);
  });

  testWidgets('开学前没有当前周：标题不带“当前为第 N 周”，菜单没有“回到本周”',
      (tester) async {
    await pumpSchedule(
      tester,
      startDate: today.add(Duration(days: 8 - today.weekday + 14)),
    );

    expect(find.text('第 1 周'), findsOneWidget);
    expect(find.textContaining('当前为第'), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('第 2 周'), findsOneWidget);

    await openWeekMenu(tester);
    expect(find.text('回到本周'), findsNothing);
    expect(find.text('跳转到第几周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('学期已结束时同样不显示当前周后缀', (tester) async {
    await pumpSchedule(
      tester,
      startDate: today.subtract(const Duration(days: 7 * 30)),
    );

    expect(find.textContaining('当前为第'), findsNothing);
    await openWeekMenu(tester);
    expect(find.text('回到本周'), findsNothing);
  });
}
