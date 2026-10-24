import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';

/// 首次 getSemesters 抛错的学期仓库，用于构造「第一次失败、第二次成功」。
class _FlakySemesterRepository extends SemesterRepository {
  _FlakySemesterRepository(super.database);

  bool _failedOnce = false;

  @override
  Future<List<Semester>> getSemesters() async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw StateError('forced semester list failure');
    }
    return super.getSemesters();
  }
}

/// 学期管理加载失败：易懂错误说明 + 重试入口；重试必须覆盖真正失败的
/// 数据源（学期列表或当前学期），而不是只重建表层列表。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    final repo = SemesterRepository(database);
    await repo.upsert(Semester(
      id: 'old',
      name: '旧学期',
      startDate: DateTime(2026, 9, 7),
      totalWeeks: 18,
    ));
    await repo.upsert(
      Semester(
        id: 'current',
        name: '当前学期',
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

  Future<ProviderContainer> openSemesters(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        ...overrides,
      ],
    );
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SemesterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('当前学期数据源首次失败时重试覆盖根因，恢复学期列表', (tester) async {
    var activeCalls = 0;
    await openSemesters(
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

    // 当前学期失败会让整页不可用：显示易懂错误与重试，不显示原始异常。
    expect(find.text('学期加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('当前学期'), findsNothing);
    expect(
      find.textContaining('forced active semester failure'),
      findsNothing,
    );

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    // 重试重新加载了当前学期（根因），列表随之恢复并标出当前学期。
    expect(find.text('学期加载失败'), findsNothing);
    expect(find.text('旧学期'), findsOneWidget);
    expect(find.text('当前学期'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('当前学期'),
          matching: find.byType(InkWell),
        ),
        matching: find.text('当前'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('学期列表数据源首次失败时重试后显示真实列表', (tester) async {
    final flaky = _FlakySemesterRepository(database);
    await openSemesters(
      tester,
      overrides: [semesterRepositoryProvider.overrideWithValue(flaky)],
    );

    expect(find.text('学期加载失败'), findsOneWidget);
    expect(find.textContaining('forced semester list failure'), findsNothing);
    expect(find.text('旧学期'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('学期加载失败'), findsNothing);
    expect(find.text('旧学期'), findsOneWidget);
    expect(find.text('当前学期'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
