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

/// 首次 getCourse 抛错的课程仓库，用于构造「第一次失败、第二次成功」。
class _FlakyCourseRepository extends CourseRepository {
  _FlakyCourseRepository(super.database);

  bool _failedOnce = false;

  @override
  Future<Course?> getCourse(String id) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw StateError('forced course read failure');
    }
    return super.getCourse(id);
  }
}

/// 课程编辑初始化失败：易懂错误说明 + 重试；重试按原路由参数重新初始化，
/// 成功后表单与课程平台只初始化一次，不被重复覆盖。
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

  Future<void> pumpEdit(WidgetTester tester) async {
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
      teacher: '张三',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: [1, 2],
    ));
    await CoursePlatformRepository(database).replacePlatforms(
      's1',
      '操作系统',
      const [
        CoursePlatform(
          purpose: CoursePlatformPurpose.onlineCourse,
          name: '学习通',
        ),
      ],
    );

    final flaky = _FlakyCourseRepository(database);
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
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          courseRepositoryProvider.overrideWithValue(flaky),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  testWidgets('初始化失败显示易懂错误与重试，重试后按原课程恢复表单', (tester) async {
    await pumpEdit(tester);

    // 失败态：易懂说明 + 重试入口，不显示原始异常，也不出现半截表单。
    expect(find.text('课程加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.textContaining('forced course read failure'), findsNothing);
    expect(find.text('课程名称'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    // 重试按原路由参数（编辑 c1）恢复初始课程与课程平台草稿。
    expect(find.text('课程加载失败'), findsNothing);
    expect(find.widgetWithText(TextField, '操作系统'), findsOneWidget);
    expect(find.widgetWithText(TextField, '张三'), findsOneWidget);
    expect(find.text('网课 · 学习通'), findsOneWidget);
    expect(find.text('编辑课程'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重试成功后表单只初始化一次，后续编辑不被重复覆盖', (tester) async {
    await pumpEdit(tester);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '编译原理');
    await tester.pumpAndSettle();

    // 若初始化被重复执行，课程名会被初始值「操作系统」覆盖回去。
    expect(find.widgetWithText(TextField, '编译原理'), findsOneWidget);
    expect(find.text('课程加载失败'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
