import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'tables/course_platform_table.dart';
import 'tables/course_table.dart';
import 'tables/semester_table.dart';

part 'app_database.g.dart';

/// 应用主数据库。单一实例，进程级生命周期。
///
/// 首次启动无学期时，[seedDefaultSemester] 写入一个默认激活学期，
/// 让用户立刻拥有可操作的「当前周」，避免空状态困惑。
@DriftDatabase(tables: [Courses, Semesters, CoursePlatforms])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// 版本 2：新增课程平台表。
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 1 → 2 只新建课程平台表，已有课程与学期保持不动。
          if (from < 2) await m.createTable(coursePlatforms);
        },
      );

  /// 若不存在任何学期，写入一个默认激活学期（开学日取最近周一，18 周）。
  /// 每次检查；数据库事务串行执行，避免并发读取重复播种。
  Future<void> seedDefaultSemester() async {
    await transaction(() async {
      final count = await (select(semesters)
            ..where((s) => s.isActive.equals(true)))
          .get();
      if (count.isNotEmpty) return;

      final anySemester = await select(semesters).get();
      if (anySemester.isNotEmpty) return;

      final now = DateTime.now();
      // 最近一个周一（weekday==1 为周一）
      final daysSinceMonday = (now.weekday - DateTime.monday) % 7;
      final lastMonday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysSinceMonday));

      final semesterId = const Uuid().v4();
      await into(semesters).insert(
        SemestersCompanion.insert(
          id: semesterId,
          name: '我的学期',
          startDate: lastMonday,
          totalWeeks: 18,
          isActive: const Value(true),
        ),
      );
    });
  }
}

/// 默认在应用文档目录创建 SQLite 文件，后台 isolate 打开以保证启动流畅。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'recess.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
