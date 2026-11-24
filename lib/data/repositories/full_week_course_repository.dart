import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/mappers.dart';

/// 整周课数据访问，只以领域模型 [FullWeekCourse] 与外界交互。
class FullWeekCourseRepository {
  final db.AppDatabase _db;

  FullWeekCourseRepository(this._db);

  /// 监听某学期全部整周课，按最早上课周、课程名排序。
  Stream<List<FullWeekCourse>> watch(String semesterId) =>
      (_db.select(_db.fullWeekCourses)
        ..where((c) => c.semesterId.equals(semesterId))).watch().map(_sorted);

  Future<List<FullWeekCourse>> getAll(String semesterId) async => _sorted(
    await (_db.select(_db.fullWeekCourses)
      ..where((c) => c.semesterId.equals(semesterId))).get(),
  );

  Future<void> delete(String id) async {
    await (_db.delete(_db.fullWeekCourses)..where((c) => c.id.equals(id))).go();
  }

  /// 用 [courses] 替换指定学期的全部整周课（替换导入使用）。
  /// 调用方负责把它和课程替换放进同一事务。
  Future<void> replaceForSemester(
    String semesterId,
    Iterable<FullWeekCourse> courses,
  ) async {
    final replacements = _validatedBatch(semesterId, courses);
    await (_db.delete(_db.fullWeekCourses)
      ..where((c) => c.semesterId.equals(semesterId))).go();
    await _insertAll(replacements);
  }

  /// 向指定学期追加整周课（合并导入使用）。
  Future<void> addAll(String semesterId, Iterable<FullWeekCourse> courses) =>
      _insertAll(_validatedBatch(semesterId, courses));

  Future<void> _insertAll(List<FullWeekCourse> courses) async {
    if (courses.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.fullWeekCourses,
        courses.map((c) => c.toCompanion()).toList(),
      );
    });
  }

  static List<FullWeekCourse> _sorted(List<db.FullWeekCourse> rows) {
    int firstWeek(FullWeekCourse c) => c.weeks.isEmpty ? 0 : c.weeks.first;
    return rows.map((r) => r.toDomain()).toList()..sort((a, b) {
      final byWeek = firstWeek(a).compareTo(firstWeek(b));
      return byWeek != 0 ? byWeek : a.name.compareTo(b.name);
    });
  }

  /// 与课程批量写入相同的校验：id 非空且唯一、全部属于 [semesterId]。
  List<FullWeekCourse> _validatedBatch(
    String semesterId,
    Iterable<FullWeekCourse> courses,
  ) {
    if (semesterId.isEmpty) {
      throw ArgumentError.value(semesterId, 'semesterId', 'must not be empty');
    }
    final list = courses.toList(growable: false);
    final ids = <String>{};
    for (final course in list) {
      if (course.id.isEmpty) {
        throw ArgumentError('FullWeekCourse.id must not be empty');
      }
      if (course.semesterId != semesterId) {
        throw ArgumentError(
          'FullWeekCourse ${course.id} belongs to semester '
          '${course.semesterId}, not $semesterId',
        );
      }
      if (!ids.add(course.id)) {
        throw ArgumentError('Duplicate full-week course id: ${course.id}');
      }
    }
    return list;
  }
}
