import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/core/models/semester.dart';
import 'package:hormone/data/app_database.dart' as db;
import 'package:hormone/data/providers/database_providers.dart';
import 'package:hormone/data/repositories/course_platform_repository.dart';
import 'package:hormone/data/repositories/course_repository.dart';
import 'package:hormone/data/repositories/semester_repository.dart';
import 'package:hormone/features/course/presentation/course_edit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('编辑页添加平台后随“保存”写到当前课程名下', (tester) async {
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
      await CourseRepository(database).upsert(const Course(
        id: 'c1',
        semesterId: 's1',
        name: '操作系统',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        weeks: [1],
      ));
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
}
