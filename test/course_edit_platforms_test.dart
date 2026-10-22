import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/course/presentation/course_edit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;

  const course = Course(
    id: 'c1',
    semesterId: 's1',
    name: '操作系统',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    weeks: [1],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpEdit(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await SemesterRepository(database).upsert(Semester(
        id: 's1',
        name: '学期',
        startDate: DateTime(2026, 9, 1),
        totalWeeks: 18,
      ));
      await SemesterRepository(database).setActive('s1');
      await CourseRepository(database).upsert(course);
      await seed?.call();
    });

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('首页')),
        GoRoute(
          path: '/edit',
          builder: (_, __) => const CourseEditScreen(courseId: 'c1'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  testWidgets('编辑页添加平台后随“保存”写到当前课程名下', (tester) async {
    await pumpEdit(tester);

    expect(find.text('本学期所有名为“操作系统”的课程共享这些平台'), findsOneWidget);

    await tester.tap(find.text('添加平台'));
    await tester.pumpAndSettle();
    // 平台名必填。
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('请填写平台名'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<CoursePlatformPurpose>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('实验').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '平台名'),
      '头歌',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '链接（可选）'),
      'https://www.educoder.net',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('实验 · 头歌'), findsOneWidget);
    expect(find.byIcon(Icons.science_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(
      () => CoursePlatformRepository(database).getPlatforms('s1', '操作系统'),
    );
    expect(saved, const [
      CoursePlatform(
        purpose: CoursePlatformPurpose.lab,
        name: '头歌',
        url: 'https://www.educoder.net',
      ),
    ]);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('改课程名后列表与提示都换成新名字下的平台', (tester) async {
    await pumpEdit(tester, seed: () async {
      final platforms = CoursePlatformRepository(database);
      await platforms.replacePlatforms('s1', '操作系统', const [
        CoursePlatform(
          purpose: CoursePlatformPurpose.onlineCourse,
          name: '学习通',
        ),
      ]);
      await platforms.replacePlatforms('s1', '编译原理', const [
        CoursePlatform(purpose: CoursePlatformPurpose.lab, name: '头歌'),
      ]);
    });
    expect(find.text('网课 · 学习通'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '操作系统'),
      '编译原理',
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('本学期所有名为“编译原理”的课程共享这些平台'), findsOneWidget);
    expect(find.text('实验 · 头歌'), findsOneWidget);
    expect(find.text('网课 · 学习通'), findsNothing);
  });
}
