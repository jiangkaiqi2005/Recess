import 'package:drift/drift.dart';

/// 整周课持久化表。
///
/// 整周课没有星期和节次，因此不放进 `Courses` 表里存占位值，
/// 见 docs/adr/0003-full-week-courses-separate-table.md。
/// [weeks] 与课程表相同，以逗号分隔的整数字符串存储。
class FullWeekCourses extends Table {
  TextColumn get id => text()();

  TextColumn get semesterId => text()();

  TextColumn get name => text()();

  TextColumn get teacher => text().nullable()();

  TextColumn get location => text().nullable()();

  TextColumn get weeks => text().withDefault(const Constant(''))();

  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF5B8DEF))();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
