import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    await container
        .read(semesterRepositoryProvider)
        .upsert(
          Semester(
            id: 'old',
            name: '旧学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
          ),
          activate: true,
        );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> openSemesters(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SemesterScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Map> snapshot() async =>
      (jsonDecode(await container.read(backupRepositoryProvider).exportJson())
            as Map)
        ..remove('exportedAt');

  Future<void> waitForSheetClosed(WidgetTester tester) async {
    for (
      var attempt = 0;
      attempt < 100 && find.byType(SemesterEditSheet).evaluate().isNotEmpty;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('创建并激活失败保留编辑页和旧学期并显示失败', (tester) async {
    await tester.runAsync(() async {
      await openSemesters(tester);
      final before = await snapshot();
      await database.customStatement('''
        CREATE TRIGGER fail_activation BEFORE UPDATE OF is_active ON semesters
        WHEN NEW.is_active = 1
        BEGIN SELECT RAISE(ABORT, 'forced activation failure'); END;
      ''');
      await tester.tap(find.byTooltip('添加学期'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '新学期');
      await tester.tap(find.text('保存后设为当前学期'));
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SemesterEditSheet), findsOneWidget);
      expect(find.textContaining('保存失败'), findsOneWidget);
      expect(await snapshot(), before);
      expect((await container.read(activeSemesterProvider.future))?.id, 'old');
    });
  });

  testWidgets('删除失败保留编辑页与数据并显示失败', (tester) async {
    await tester.runAsync(() async {
      await openSemesters(tester);
      final before = await snapshot();
      await database.customStatement('''
        CREATE TRIGGER fail_delete BEFORE DELETE ON semesters
        BEGIN SELECT RAISE(ABORT, 'forced delete failure'); END;
      ''');
      await tester.tap(find.text('旧学期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除学期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SemesterEditSheet), findsOneWidget);
      expect(find.textContaining('删除失败'), findsOneWidget);
      expect(await snapshot(), before);
    });
  });

  testWidgets('保存学期后列表显示新名称删除最后学期后立即显示默认学期', (tester) async {
    await tester.runAsync(() async {
      await openSemesters(tester);
      await tester.tap(find.text('旧学期'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '改名后学期');
      await tester.tap(find.text('保存'));
      await waitForSheetClosed(tester);
      expect(find.byType(SemesterEditSheet), findsNothing);
      expect(find.text('改名后学期'), findsOneWidget);
      expect(find.text('旧学期'), findsNothing);
      await tester.tap(find.text('改名后学期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除学期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await waitForSheetClosed(tester);
      expect(find.byType(SemesterEditSheet), findsNothing);
      expect(find.text('改名后学期'), findsNothing);
      expect(find.text('我的学期'), findsOneWidget);
      expect(find.text('当前'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
