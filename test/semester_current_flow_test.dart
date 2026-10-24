import 'dart:convert';

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
import 'package:recess/features/schedule/presentation/schedule_screen.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    for (final id in ['old', 'current']) {
      final label = id == 'old' ? '旧学期' : '当前学期';
      await container
          .read(semesterRepositoryProvider)
          .upsert(
            Semester(
              id: id,
              name: label,
              startDate: DateTime(2026, 9, 7),
              totalWeeks: 18,
              currentWeekOverride: 1,
            ),
            activate: id == 'current',
          );
      await container
          .read(courseRepositoryProvider)
          .upsert(
            Course(
              id: 'course-$id',
              semesterId: id,
              name: '$label课程',
              teacher: '$label教师',
              location: '$label教室',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: const [1],
            ),
          );
      await container.read(coursePlatformRepositoryProvider).replacePlatforms(
        id,
        '$label课程',
        [
          CoursePlatform(
            purpose: CoursePlatformPurpose.homework,
            name: '$label平台',
          ),
        ],
      );
    }
    router = GoRouter(
      initialLocation: '/semester',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ScheduleScreen()),
        GoRoute(path: '/semester', builder: (_, __) => const SemesterScreen()),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    container.dispose();
    await database.close();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Map> contentSnapshot() async {
    final data =
        jsonDecode(await container.read(backupRepositoryProvider).exportJson())
            as Map;
    data.remove('exportedAt');
    for (final semester in data['semesters'] as List) {
      (semester as Map).remove('isActive');
    }
    return data;
  }

  Future<void> waitForSheetClosed(WidgetTester tester) async {
    for (
      var i = 0;
      i < 100 && find.byType(SemesterEditSheet).evaluate().isNotEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(SemesterEditSheet), findsNothing);
  }

  testWidgets('只有非当前学期可设为当前且切换不保存草稿或改变课程平台', (tester) async {
    await tester.runAsync(() async {
      await mount(tester);
      final before = await contentSnapshot();
      await tester.tap(find.text('当前学期'));
      await tester.pumpAndSettle();
      expect(find.text('设为当前学期'), findsNothing);
      await tester.tapAt(const Offset(24, 40));
      await tester.pumpAndSettle();
      await tester.tap(find.text('旧学期'));
      await tester.pumpAndSettle();
      expect(find.text('设为当前学期'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '未保存的名称');
      await tester.pump();
      await tester.tap(find.text('设为当前学期'));
      await waitForSheetClosed(tester);
      final currentCard =
          find
              .ancestor(of: find.text('旧学期'), matching: find.byType(InkWell))
              .first;
      expect(
        find.descendant(of: currentCard, matching: find.text('当前')),
        findsOneWidget,
      );
      expect(find.text('当前'), findsOneWidget);
      expect(find.text('未保存的名称'), findsNothing);
      expect(await contentSnapshot(), before);
      expect(
        (await container.read(semesterRepositoryProvider).getActiveSemester())!
            .id,
        'old',
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('来回设置当前学期后课表显示对应课程且保留两学期数据', (tester) async {
    await tester.runAsync(() async {
      await mount(tester);
      final before = await contentSnapshot();
      for (final label in ['旧学期', '当前学期']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('设为当前学期'));
        await waitForSheetClosed(tester);
        await container.read(activeSemesterProvider.future);
        router.go('/');
        await tester.pumpAndSettle();
        await container.read(scheduleCoursesProvider.future);
        for (var i = 0;
            i < 100 && find.textContaining('${label}课程').evaluate().isEmpty;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.textContaining('${label}课程'), findsOneWidget);
        expect(
          find.textContaining(label == '旧学期' ? '当前学期课程' : '旧学期课程'),
          findsNothing,
        );
        expect(await contentSnapshot(), before);
        router.go('/semester');
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('设为当前学期失败显示失败并保留原当前学期及全部数据', (tester) async {
    await tester.runAsync(() async {
      await mount(tester);
      final before = await contentSnapshot();
      await database.customStatement('''
        CREATE TRIGGER fail_activation BEFORE UPDATE OF is_active ON semesters
        WHEN NEW.is_active = 1
        BEGIN SELECT RAISE(ABORT, 'forced activation failure'); END;
      ''');
      await tester.tap(find.text('旧学期'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '未保存的名称');
      await tester.pump();
      await tester.tap(find.text('设为当前学期'));
      for (
        var i = 0;
        i < 100 && find.textContaining('保存失败').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(SemesterEditSheet), findsOneWidget);
      expect(find.textContaining('保存失败'), findsOneWidget);
      expect(await contentSnapshot(), before);
      expect(
        (await container.read(semesterRepositoryProvider).getActiveSemester())!
            .id,
        'current',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
