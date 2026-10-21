import 'package:drift/drift.dart';

/// 课程平台持久化表。
///
/// 按「学期 id + 课程名」归属（课程名 trim 后精确匹配），而不是挂在单条课程
/// 记录上：同一门课在一周内的多个时段共享一组平台（见 docs/adr/0001）。
/// [sortOrder] 保持同一组内的显示顺序。
class CoursePlatforms extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get semesterId => text()();

  TextColumn get courseName => text()();

  /// 用途的稳定键，见 `CoursePlatformPurpose.key`。
  TextColumn get purpose => text()();

  TextColumn get name => text()();

  TextColumn get url => text().nullable()();

  IntColumn get sortOrder => integer()();
}
