import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/course/presentation/course_edit_screen.dart';

/// 每个字段的一种修改方式：如何改，以及改完后页面上应能看到什么。
typedef _FieldCase =
    (
      String label,
      Future<void> Function(WidgetTester) act,
      Future<void> Function(WidgetTester) expectVisible,
    );

/// 课程编辑退出保护：关闭按钮、系统返回与手势共用同一路由级守卫，
/// 未保存判定按初始快照与草稿的实际差异，改回初值即放行。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;

  const seeded = Course(
    id: 'c1',
    semesterId: 's1',
    name: '操作系统',
    teacher: '张三',
    location: '教三-201',
    notes: '带书',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    weeks: [1, 2],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpEdit(WidgetTester tester, String entry) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await SemesterRepository(database).upsert(
        Semester(
          id: 's1',
          name: '学期',
          startDate: DateTime(2026, 9, 1),
          totalWeeks: 18,
        ),
      );
      await SemesterRepository(database).setActive('s1');
      if (entry != '新建') {
        await CourseRepository(database).upsert(seeded);
      }
    });
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('首页')),
        GoRoute(
          path: '/edit',
          builder:
              (_, __) => CourseEditScreen(
                courseId: switch (entry) {
                  '编辑' => 'c1',
                  '复制' => 'copy:c1',
                  _ => null,
                },
              ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  Future<List<Course>> coursesInDb(WidgetTester tester) async {
    final courses = await tester.runAsync(
      () => CourseRepository(database).getCourses('s1'),
    );
    return courses!;
  }

  Finder textField(int index) => find.byType(TextField).at(index);

  Finder unselectedSwatch() => find.byWidgetPredicate((widget) {
    if (widget is! Container || widget.decoration is! BoxDecoration) {
      return false;
    }
    final decoration = widget.decoration! as BoxDecoration;
    return decoration.shape == BoxShape.circle && decoration.border == null;
  });

  Future<void> pickSection(
    WidgetTester tester, {
    required int dropdownIndex,
    required String section,
  }) async {
    await tester.tap(find.byType(DropdownButton<int>).at(dropdownIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(section).last);
    await tester.pumpAndSettle();
  }

  Future<void> addPlatform(WidgetTester tester, String name) async {
    await tester.tap(find.text('添加平台'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '平台名'), name);
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  }

  final fieldCases = <_FieldCase>[
    (
      '课程名',
      (tester) => tester.enterText(textField(0), '编译原理'),
      (tester) async =>
          expect(find.widgetWithText(TextField, '编译原理'), findsOneWidget),
    ),
    (
      '教师',
      (tester) => tester.enterText(textField(1), '李四'),
      (tester) async =>
          expect(find.widgetWithText(TextField, '李四'), findsOneWidget),
    ),
    (
      '教室',
      (tester) => tester.enterText(textField(2), '教一-101'),
      (tester) async =>
          expect(find.widgetWithText(TextField, '教一-101'), findsOneWidget),
    ),
    (
      '备注',
      (tester) => tester.enterText(textField(3), '自带电脑'),
      (tester) async =>
          expect(find.widgetWithText(TextField, '自带电脑'), findsOneWidget),
    ),
    (
      '星期',
      (tester) => tester.tap(find.widgetWithText(ChoiceChip, '周三')),
      (tester) async => expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '周三'))
            .selected,
        isTrue,
      ),
    ),
    (
      '起始节次',
      (tester) => pickSection(tester, dropdownIndex: 0, section: '第3节'),
      (tester) async {
        expect(find.textContaining('第3节'), findsWidgets);
      },
    ),
    (
      '结束节次',
      (tester) => pickSection(tester, dropdownIndex: 1, section: '第4节'),
      (tester) async {
        expect(find.textContaining('第4节'), findsWidgets);
      },
    ),
    (
      '上课周次',
      (tester) => tester.tap(find.widgetWithText(TextButton, '清空')),
      (tester) async => expect(find.text('已选 0 周'), findsOneWidget),
    ),
    (
      '卡片颜色',
      (tester) => tester.tap(unselectedSwatch().first),
      (tester) async {
        expect(
          find.descendant(
            of: unselectedSwatch().first,
            matching: find.byIcon(Icons.check),
          ),
          findsNothing,
        );
      },
    ),
    (
      '课程平台',
      (tester) => addPlatform(tester, '学习通'),
      (tester) async => expect(find.text('网课 · 学习通'), findsOneWidget),
    ),
  ];

  for (final entry in ['新建', '编辑', '复制']) {
    for (final (label, act, expectVisible) in fieldCases) {
      testWidgets('$entry：修改「$label」后关闭按钮先弹未保存提醒', (tester) async {
        await pumpEdit(tester, entry);

        await act(tester);
        await tester.pumpAndSettle();
        await expectVisible(tester);

        // 点关闭 → 出现提醒，而非直接退出。
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('放弃修改？'), findsOneWidget);
        expect(find.text('首页'), findsNothing);

        // 继续编辑：留在本页，草稿完整保留，数据库没有任何写入。
        await tester.tap(find.text('继续编辑'));
        await tester.pumpAndSettle();
        expect(find.text('放弃修改？'), findsNothing);
        expect(find.text('课程名称'), findsOneWidget);
        await expectVisible(tester);
        final courses = await coursesInDb(tester);
        expect(courses.where((c) => c.id != 'c1'), isEmpty);
        for (final c in courses.where((c) => c.id == 'c1')) {
          expect(c.name, '操作系统');
          expect(c.teacher, '张三');
        }
      });
    }
  }

  testWidgets('未修改时关闭按钮直接退出', (tester) async {
    await pumpEdit(tester, '编辑');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('编辑：系统返回键同样弹提醒，放弃后不写库', (tester) async {
    await pumpEdit(tester, '编辑');
    await tester.enterText(textField(1), '李四');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);

    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
    final courses = await coursesInDb(tester);
    expect(courses.single.id, 'c1');
    expect(courses.single.teacher, '张三');
  });

  testWidgets('新建：系统返回弹提醒，放弃后不写库', (tester) async {
    await pumpEdit(tester, '新建');
    await tester.enterText(textField(0), '新课程');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
    expect(await coursesInDb(tester), isEmpty);
  });

  testWidgets('编辑：把全部修改改回初值后直接放行', (tester) async {
    await pumpEdit(tester, '编辑');

    // 平台加完再删，其余字段逐个改回。
    await addPlatform(tester, '学习通');
    await tester.tap(find.byTooltip('删除平台').first);
    await tester.pumpAndSettle();

    await tester.enterText(textField(0), '编译原理');
    await tester.enterText(textField(0), '操作系统');
    await tester.enterText(textField(1), '李四');
    await tester.enterText(textField(1), '张三');
    await tester.enterText(textField(2), '教一-101');
    await tester.enterText(textField(2), '教三-201');
    await tester.enterText(textField(3), '自带电脑');
    await tester.enterText(textField(3), '带书');

    await tester.tap(find.widgetWithText(ChoiceChip, '周三'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '周一'));
    await tester.pumpAndSettle();

    await pickSection(tester, dropdownIndex: 0, section: '第3节');
    await pickSection(tester, dropdownIndex: 0, section: '第1节');
    await pickSection(tester, dropdownIndex: 1, section: '第2节');

    await tester.tap(find.widgetWithText(FilterChip, '5'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '5'));
    await tester.pumpAndSettle();

    await tester.tap(unselectedSwatch().first);
    await tester.pump();
    // 改回初始蓝（亮色主题下色板显示即原值）。
    await tester.tap(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.shape == BoxShape.circle &&
            decoration.color == const Color(0xFF4399F1);
      }).first,
    );
    await tester.pump();

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect((await coursesInDb(tester)).single.name, '操作系统');
  });

  testWidgets('编辑：周次快捷操作（全选/清空/单周/双周/反选/逐周）都触发提醒', (tester) async {
    for (final action in ['全选', '清空', '单周', '双周', '反选']) {
      await pumpEdit(tester, '编辑');
      await tester.tap(find.widgetWithText(TextButton, action));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('放弃修改？'), findsOneWidget, reason: action);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
    }

    // 逐周勾选（编辑基准为第 1、2 周，点第 5 周是新增）。
    await pumpEdit(tester, '编辑');
    await tester.tap(find.widgetWithText(FilterChip, '5'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, '5')).selected,
      isTrue,
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);
  });

  testWidgets('编辑：修改后保存仍直接退出且写入数据库（守卫不拦截保存）', (tester) async {
    await pumpEdit(tester, '编辑');
    await tester.enterText(textField(1), '李四');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect((await coursesInDb(tester)).single.teacher, '李四');
  });

  testWidgets('编辑：修改后删除课程直接退出且课程被删除（守卫不拦截删除）', (tester) async {
    await pumpEdit(tester, '编辑');
    await tester.enterText(textField(1), '李四');
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除课程'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect(await coursesInDb(tester), isEmpty);
  });
}
