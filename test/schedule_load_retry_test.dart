import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/schedule/presentation/schedule_screen.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

/// 首次 watchCourses 调用抛错的课程仓库，用于构造「第一次失败、第二次成功」。
class _FlakyCourseRepository extends CourseRepository {
  _FlakyCourseRepository(super.database);

  bool _failedOnce = false;

  @override
  Stream<List<Course>> watchCourses(String semesterId) {
    if (!_failedOnce) {
      _failedOnce = true;
      throw StateError('forced course load failure');
    }
    return super.watchCourses(semesterId);
  }
}

/// 课表加载失败：易懂错误说明 + 重试入口；重试命中真正失败的数据源，
/// 成功后显示真实课程，且不重置查看周、不把上游失败当成无课程。
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

  Future<void> seedCourse(String weeks) async {
    final repo = SemesterRepository(database);
    await repo.upsert(Semester(
      id: 'semester',
      name: '测试学期',
      startDate: semesterStart,
      totalWeeks: 18,
    ));
    await repo.setActive('semester');
    await CourseRepository(database).upsert(Course(
      id: 'course',
      semesterId: 'semester',
      name: '高等数学',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: weeks.split(',').map(int.parse).toList(),
    ));
  }

  Future<ProviderContainer> pumpSchedule(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('课程数据源失败显示易懂错误，重试后显示真实课程且不重置查看周',
      (tester) async {
    await tester.runAsync(() => seedCourse('3,4'));
    final flaky = _FlakyCourseRepository(database);
    await pumpSchedule(
      tester,
      overrides: [courseRepositoryProvider.overrideWithValue(flaky)],
    );

    // 失败态：易懂说明 + 重试入口，不显示原始异常，也不误报「尚未导入课程」。
    expect(find.text('课表加载失败'), findsWidgets);
    expect(find.text('尚未导入课程'), findsNothing);
    expect(find.textContaining('forced course load failure'), findsNothing);
    expect(find.text('重试'), findsWidgets);

    // 失败态下仍可翻页；翻到第 4 周后重试不应重置查看周。
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('第 4 周   当前为第 3 周'), findsOneWidget);

    await tester.tap(find.text('重试').first);
    await tester.pumpAndSettle();

    expect(find.text('课表加载失败'), findsNothing);
    expect(find.text('高等数学'), findsWidgets);
    expect(find.text('第 4 周   当前为第 3 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('当前学期上游失败时不当成无课程，重试后课表恢复', (tester) async {
    await tester.runAsync(() => seedCourse('3'));
    var activeCalls = 0;
    await pumpSchedule(
      tester,
      overrides: [
        activeSemesterProvider.overrideWith((ref) async {
          activeCalls++;
          if (activeCalls == 1) {
            throw Exception('forced active semester failure');
          }
          return ref.watch(semesterRepositoryProvider).getActiveSemester();
        }),
      ],
    );

    // 上游失败必须呈现为加载失败，而不是空课表。
    expect(find.text('课表加载失败'), findsWidgets);
    expect(find.text('尚未导入课程'), findsNothing);
    expect(
      find.textContaining('forced active semester failure'),
      findsNothing,
    );

    await tester.tap(find.text('重试').first);
    await tester.pumpAndSettle();

    expect(find.text('课表加载失败'), findsNothing);
    expect(find.text('高等数学'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
