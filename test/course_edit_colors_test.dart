import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/semester.dart';
import 'package:hormone/data/app_database.dart' as db;
import 'package:hormone/data/providers/database_providers.dart';
import 'package:hormone/data/repositories/course_repository.dart';
import 'package:hormone/data/repositories/semester_repository.dart';
import 'package:hormone/features/course/presentation/course_edit_screen.dart';

void main() {
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
  tearDown(() => database.close());

  Future<void> pumpEdit(
    WidgetTester tester,
    int rawColor, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      final semesters = SemesterRepository(database);
      await semesters.upsert(
        Semester(
          id: 's1',
          name: '学期',
          startDate: DateTime(2026, 9, 1),
          totalWeeks: 18,
        ),
      );
      await semesters.setActive('s1');
      await CourseRepository(
        database,
      ).upsert(course.copyWith(colorValue: rawColor));
    });
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('首页')),
        GoRoute(
          path: '/edit',
          builder: (_, __) => const CourseEditScreen(courseId: 'c1'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(brightness: brightness),
        ),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  Finder swatch(int color) => find.byWidgetPredicate((widget) {
    if (widget is! Container || widget.decoration is! BoxDecoration)
      return false;
    final decoration = widget.decoration! as BoxDecoration;
    return decoration.shape == BoxShape.circle &&
        decoration.color == Color(color);
  });

  Future<void> saveAndExpect(WidgetTester tester, int color) async {
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(
      () => CourseRepository(database).getCourse('c1'),
    );
    expect(saved?.colorValue, color);
    expect(find.text('首页'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  for (final sample in [
    (raw: 0xFFC08CE8, displayed: 0xFF4399F1, brightness: Brightness.light),
    (raw: 0xFFF08C7C, displayed: 0xFF298B7E, brightness: Brightness.dark),
    (raw: 0xFFE3753F, displayed: 0xFFE3753F, brightness: Brightness.light),
  ]) {
    testWidgets('编辑 ${sample.raw.toRadixString(16)} 识别对应色样，未改色保存保留原值', (
      tester,
    ) async {
      await pumpEdit(tester, sample.raw, brightness: sample.brightness);
      final circles = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      expect(circles, findsNWidgets(8));
      final selected = tester.widget<Container>(swatch(sample.displayed));
      expect((selected.decoration! as BoxDecoration).border, isNotNull);
      expect(
        find.descendant(
          of: swatch(sample.displayed),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await saveAndExpect(tester, sample.raw);
    });
  }

  testWidgets('深色编辑旧课程主动选择新色，保存浅色标识，选中态随之变化', (tester) async {
    await pumpEdit(tester, 0xFFF08C7C, brightness: Brightness.dark);
    await tester.tap(swatch(0xFFC3581D));
    await tester.pump();
    expect(
      find.descendant(
        of: swatch(0xFFC3581D),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: swatch(0xFF298B7E),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    await saveAndExpect(tester, 0xFFE3753F);
  });

  testWidgets('自定义颜色不误选色板，直接保存仍保留自定义 ARGB', (tester) async {
    await pumpEdit(tester, 0x80123456);
    for (final color in [
      0xFF4399F1,
      0xFF4BA89A,
      0xFFE3753F,
      0xFF7C83E7,
      0xFFE36679,
      0xFF46A4C1,
      0xFFB28C6D,
      0xFF53A88D,
    ]) {
      final sample = tester.widget<Container>(swatch(color));
      expect((sample.decoration! as BoxDecoration).border, isNull);
    }
    await saveAndExpect(tester, 0x80123456);
  });
}
