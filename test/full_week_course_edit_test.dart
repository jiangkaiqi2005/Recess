import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/full_week_course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/course/application/course_form_provider.dart';
import 'package:recess/features/course/presentation/course_edit_screen.dart';

/// 整周课复用课程编辑页：能改名称、教师、教室、周次、颜色、备注，
/// 不显示星期、节次和课程平台，保存写回整周课表。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;

  const fullWeek = FullWeekCourse(
    id: 'f1',
    semesterId: 's1',
    name: '硬件综合设计',
    weeks: [18, 19, 20],
    colorValue: 0xFF5B8DEF,
  );
  const sameNameLecture = Course(
    id: 'c1',
    semesterId: 's1',
    name: '硬件综合设计',
    dayOfWeek: 2,
    startSection: 1,
    endSection: 2,
    weeks: [1],
    colorValue: 0xFF5B8DEF,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> seed() async {
    await SemesterRepository(database).upsert(
      Semester(
        id: 's1',
        name: '学期',
        startDate: DateTime(2026, 8, 31),
        totalWeeks: 20,
      ),
      activate: true,
    );
    await FullWeekCourseRepository(database).addAll('s1', const [fullWeek]);
    await CourseRepository(database).upsert(sameNameLecture);
  }

  Future<void> pumpEdit(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(seed);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('首页')),
        GoRoute(
          path: '/edit',
          builder: (_, __) =>
              CourseEditScreen(courseId: fullWeekCourseEditExtra('f1')),
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

  testWidgets('编辑整周课：不显示星期、节次和平台，改教师教室后写回整周课表', (
    tester,
  ) async {
    await pumpEdit(tester);

    expect(find.text('编辑整周课'), findsOneWidget);
    expect(find.text('星期'), findsNothing);
    expect(find.text('节次'), findsNothing);
    expect(find.text('课程平台'), findsNothing);
    expect(find.text('上课周次'), findsOneWidget);
    expect(find.text('已选 3 周'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '王老师');
    await tester.enterText(fields.at(2), '实验楼-305');
    await tester.enterText(fields.at(3), '带开发板');
    await tester.tap(find.widgetWithText(FilterChip, '17'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);

    final stored = await tester.runAsync(
      () => FullWeekCourseRepository(database).get('f1'),
    );
    expect(stored, isNotNull);
    expect(stored!.teacher, '王老师');
    expect(stored.location, '实验楼-305');
    expect(stored.notes, '带开发板');
    expect(stored.weeks, [17, 18, 19, 20]);
    // 没有多写出一门普通课，同名普通课也没被改动。
    final lectures = await tester.runAsync(
      () => CourseRepository(database).getCourses('s1'),
    );
    expect(lectures, [sameNameLecture]);
  });

  testWidgets('编辑整周课：删除只删整周课', (tester) async {
    await pumpEdit(tester);

    await tester.tap(find.text('删除课程'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);

    final stored = await tester.runAsync(
      () => FullWeekCourseRepository(database).get('f1'),
    );
    expect(stored, isNull);
    final lectures = await tester.runAsync(
      () => CourseRepository(database).getCourses('s1'),
    );
    expect(lectures, [sameNameLecture]);
  });

  test('整周课改颜色时同步到同名普通课，颜色没变时不动同名课', () async {
    await seed();
    final repo = FullWeekCourseRepository(database);

    await repo.save(
      const FullWeekCourse(
        id: 'f1',
        semesterId: 's1',
        name: '硬件综合设计',
        weeks: [18, 19, 20],
        colorValue: 0xFF4BA89A,
      ),
    );
    expect(
      (await CourseRepository(database).getCourse('c1'))!.colorValue,
      0xFF5B8DEF,
    );

    await repo.save(
      const FullWeekCourse(
        id: 'f1',
        semesterId: 's1',
        name: '硬件综合设计',
        weeks: [18, 19, 20],
        colorValue: 0xFFE57373,
      ),
      syncColor: true,
    );
    expect((await repo.get('f1'))!.colorValue, 0xFFE57373);
    expect(
      (await CourseRepository(database).getCourse('c1'))!.colorValue,
      0xFFE57373,
    );
  });
}
