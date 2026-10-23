import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/core/utils/week_calculator.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/backup_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/semester/application/semester_form_provider.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  test('首次直接读取学期列表包含默认激活学期', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final list = await container.read(semestersProvider.future);
    expect(list, hasLength(1));
    expect(list.single.name, '我的学期');
    expect(
      (await container.read(activeSemesterProvider.future))?.id,
      list.single.id,
    );
  });

  SemesterFormNotifier formFor(db.AppDatabase database, Semester semester) {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    container.listen(semesterFormProvider, (_, __) {});
    return container.read(semesterFormProvider.notifier)..init(semester);
  }

  test('缩短总周数同步调整手动当前周并在保存重读后保留手动模式', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final original = Semester(
      id: 'manual',
      name: '学期',
      startDate: DateTime(2026, 9, 7),
      totalWeeks: 18,
      currentWeekOverride: 12,
    );
    await semesters.upsert(original, activate: true);
    final form = formFor(database, original)..setTotalWeeks(8);
    expect(form.state.totalWeeks, 8);
    expect(form.state.currentWeekOverride, 8);
    await form.save();
    final saved = (await semesters.getActiveSemester())!;
    expect(saved.totalWeeks, 8);
    expect(saved.currentWeekOverride, 8);
  });

  test('直接保存入口也维护总周数与手动覆盖，不依赖表单步进操作', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    await semesters.upsert(Semester(
      id: 'manual',
      name: '学期',
      startDate: DateTime(2026, 9, 7),
      totalWeeks: 8,
      currentWeekOverride: 12,
    ), activate: true);
    expect((await semesters.getActiveSemester())!.currentWeekOverride, 8);
  });

  test('旧非法覆盖进入表单即为合法手动值，保存后重读一致', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final original = Semester(
      id: 'legacy', name: '旧学期', startDate: DateTime(2026, 9, 7),
      totalWeeks: 8, currentWeekOverride: -3,
    );
    final form = formFor(database, original);
    expect(form.state.currentWeekOverride, 1);
    await form.save();
    expect((await SemesterRepository(database).getSemesters()).single.currentWeekOverride, 1);
  });

  test('表单设置越界覆盖后保存状态与持久化一致，清空仍为自动模式', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final form = formFor(database, Semester(
      id: 'manual', name: '学期', startDate: DateTime(2026, 9, 7), totalWeeks: 8,
    ))..setCurrentWeekOverride(12);
    await form.save();
    expect(form.state.currentWeekOverride, 8);
    expect((await SemesterRepository(database).getSemesters()).single.currentWeekOverride, 8);
    form.setCurrentWeekOverride(null);
    await form.save();
    expect(form.state.currentWeekOverride, isNull);
    expect((await SemesterRepository(database).getSemesters()).single.currentWeekOverride, isNull);
  });

  for (final sample in [
    (name: '合法覆盖缩短后不变', total: 18, manual: 5, target: 8, expectedTotal: 8, expected: 5),
    (name: '扩大学期保留手动周', total: 8, manual: 5, target: 20, expectedTotal: 20, expected: 5),
    (name: '缩到最小总周数', total: 18, manual: 12, target: 1, expectedTotal: 1, expected: 1),
    (name: '旧低值保持手动模式', total: 18, manual: -3, target: 8, expectedTotal: 8, expected: 1),
    (name: '旧高值保持手动模式', total: 18, manual: 40, target: 8, expectedTotal: 8, expected: 8),
    (name: '无覆盖缩短仍为自动模式', total: 18, manual: null, target: 8, expectedTotal: 8, expected: null),
    (name: '总周数沿用既有上界', total: 18, manual: 12, target: 40, expectedTotal: 30, expected: 12),
    (name: '总周数沿用既有下界', total: 18, manual: 12, target: 0, expectedTotal: 1, expected: 1),
  ]) {
    test('${sample.name}，表单与保存重读一致', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final form = formFor(database, Semester(
        id: 's', name: '学期', startDate: DateTime(2026, 9, 7),
        totalWeeks: sample.total, currentWeekOverride: sample.manual,
      ))..setTotalWeeks(sample.target);
      expect(form.state.totalWeeks, sample.expectedTotal);
      expect(form.state.currentWeekOverride, sample.expected);
      await form.save();
      final saved = (await SemesterRepository(database).getSemesters()).single;
      expect(saved.totalWeeks, sample.expectedTotal);
      expect(saved.currentWeekOverride, sample.expected);
    });
  }

  test('旧非法手动周读取有效但不修库，仅既有保存持久化修正', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repo = SemesterRepository(database);
    await repo.upsert(Semester(
      id: 'legacy', name: '旧学期', startDate: DateTime(2026, 9, 7),
      totalWeeks: 8, currentWeekOverride: 8,
    ), activate: true);
    // 模拟保存规则加入前留下的数据，不通过新保存入口生成异常值。
    await database.customStatement('UPDATE semesters SET current_week_override = 12 WHERE id = ?', ['legacy']);
    final read = (await repo.getActiveSemester())!;
    expect(read.currentWeekOverride, 12);
    expect(currentWeekOf(read, DateTime(2026, 9, 7)), 8);
    expect((await repo.getSemesters()).single.currentWeekOverride, 12);
    await formFor(database, read).save();
    expect((await repo.getActiveSemester())!.currentWeekOverride, 8);
  });

  test('表单保存并激活后已加载的列表激活学期和课表同步刷新', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final original = Semester(
      id: 's1',
      name: '旧学期',
      startDate: DateTime(2026, 9, 7),
      totalWeeks: 18,
    );
    await semesters.upsert(original, activate: true);
    await CourseRepository(database).upsert(
      const Course(
        id: 'c1',
        semesterId: 's1',
        name: '旧课程',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
      ),
    );
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    container.listen(activeSemesterProvider, (_, __) {});
    container.listen(semestersProvider, (_, __) {});
    container.listen(scheduleCoursesProvider, (_, __) {});
    container.listen(semesterFormProvider, (_, __) {});
    await container.read(activeSemesterProvider.future);
    await container.read(semestersProvider.future);
    expect(
      (await container.read(scheduleCoursesProvider.future)).single.name,
      '旧课程',
    );
    final form = container.read(semesterFormProvider.notifier)
      ..init(original.copyWith(id: '', name: '新学期'));
    final id = await form.save(activate: true);
    expect((await container.read(activeSemesterProvider.future))?.id, id);
    expect(
      (await container.read(semestersProvider.future)).map((s) => s.name),
      ['新学期', '旧学期'],
    );
    expect(await container.read(scheduleCoursesProvider.future), isEmpty);
    await form.delete();
    expect((await container.read(activeSemesterProvider.future))?.id, 's1');
    expect((await container.read(semestersProvider.future)).single.name, '旧学期');
    expect(
      (await container.read(scheduleCoursesProvider.future)).single.name,
      '旧课程',
    );
  });

  test('同一进程删除最后学期后并发读取仍只有一个默认激活学期', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final firstReads = await Future.wait(
      List.generate(12, (_) => semesters.getActiveSemester()),
    );
    expect(firstReads.map((s) => s?.id).toSet(), hasLength(1));
    final originalId = firstReads.first!.id;
    await semesters.delete(originalId);
    final reads = await Future.wait(
      List.generate(12, (_) => semesters.getActiveSemester()),
    );
    expect(reads, everyElement(isNotNull));
    expect(reads.map((s) => s!.id).toSet(), hasLength(1));
    final current = reads.first!;
    expect(current.id, isNot(originalId));
    expect(current.name, '我的学期');
    expect(current.totalWeeks, 18);
    final now = DateTime.now();
    final start = current.startDate;
    expect(start.weekday, DateTime.monday);
    expect(start.hour, 0);
    expect(start.minute, 0);
    expect(start.second, 0);
    expect(start.isAfter(now), isFalse);
    expect(now.difference(start).inDays, lessThan(7));
    expect((await semesters.getSemesters()).single.id, current.id);
    expect((await semesters.getActiveSemester())?.id, current.id);
  });

  for (final table in ['course_platforms', 'semesters']) {
    test('$table 删除失败时学期课程平台和原激活状态全部保留', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final semesters = SemesterRepository(database);
      final courses = CourseRepository(database);
      final platforms = CoursePlatformRepository(database);
      final semester = Semester(
        id: 's1',
        name: '原学期',
        startDate: DateTime(2026, 9, 7),
        totalWeeks: 18,
      );
      await semesters.upsert(semester);
      await semesters.setActive('s1');
      await courses.upsert(
        const Course(
          id: 'c1',
          semesterId: 's1',
          name: '操作系统',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
        ),
      );
      await platforms.replacePlatforms('s1', '操作系统', [
        const CoursePlatform(
          purpose: CoursePlatformPurpose.onlineCourse,
          name: '学习通',
        ),
      ]);
      final backup = BackupRepository(database);
      Future<Map> snapshot() async =>
          (jsonDecode(await backup.exportJson()) as Map)..remove('exportedAt');
      final before = await snapshot();
      await database.customStatement('''
      CREATE TRIGGER fail_delete BEFORE DELETE ON $table
      BEGIN SELECT RAISE(ABORT, 'forced platform delete failure'); END;
    ''');
      final notifier = formFor(database, semester);
      await expectLater(notifier.delete(), throwsA(isA<Exception>()));
      expect(await snapshot(), before);
      expect((await semesters.getActiveSemester())?.id, 's1');
    });
  }

  for (final editing in [false, true]) {
    test('${editing ? '编辑' : '新建'}保存并激活失败时保留全部旧数据和原激活学期', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final semesters = SemesterRepository(database);
      final original = Semester(
        id: 's1',
        name: '原学期',
        startDate: DateTime(2026, 9, 7),
        totalWeeks: 18,
      );
      await semesters.upsert(original);
      await semesters.setActive('s1');
      final backup = BackupRepository(database);
      Future<Map> snapshot() async =>
          (jsonDecode(await backup.exportJson()) as Map)..remove('exportedAt');
      final before = await snapshot();
      await database.customStatement('''
        CREATE TRIGGER fail_activation BEFORE UPDATE OF is_active ON semesters
        WHEN NEW.is_active = 1
        BEGIN SELECT RAISE(ABORT, 'forced activation failure'); END;
      ''');
      final notifier = formFor(
        database,
        editing ? original : original.copyWith(id: ''),
      )..setName('未提交学期');
      await expectLater(
        notifier.save(activate: true),
        throwsA(isA<Exception>()),
      );
      expect(await snapshot(), before);
      expect((await semesters.getActiveSemester())?.id, 's1');
    });
  }

  test('删除学期时连同该学期的课程与课程平台一起删除', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final courses = CourseRepository(database);
    final platforms = CoursePlatformRepository(database);

    final doomed = Semester(
      id: 's1',
      name: '要删的学期',
      startDate: DateTime(2026, 9, 1),
      totalWeeks: 18,
    );
    await semesters.upsert(doomed);
    await semesters.upsert(
      Semester(
        id: 's2',
        name: '保留的学期',
        startDate: DateTime(2026, 2, 1),
        totalWeeks: 18,
      ),
    );
    await semesters.setActive('s1');
    await courses.upsert(
      const Course(
        id: 'c1',
        semesterId: 's1',
        name: '操作系统',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
      ),
    );
    const platform = CoursePlatform(
      purpose: CoursePlatformPurpose.onlineCourse,
      name: '学习通',
    );
    await platforms.replacePlatforms('s1', '操作系统', [platform]);
    await platforms.replacePlatforms('s2', '操作系统', [platform]);

    final notifier = formFor(database, doomed);
    await notifier.delete();

    expect((await semesters.getSemesters()).map((s) => s.id), ['s2']);
    expect(await courses.getCourses('s1'), isEmpty);
    expect(await platforms.getPlatforms('s1', '操作系统'), isEmpty);
    expect(await platforms.getPlatforms('s2', '操作系统'), [platform]);
    final exported =
        jsonDecode(await BackupRepository(database).exportJson()) as Map;
    expect((exported['semesters'] as List).single['isActive'], isTrue);
    expect((await semesters.getActiveSemester())?.id, 's2');
  });

  test('删除非激活学期保留当前学期和其他同名课程及平台', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final courses = CourseRepository(database);
    final platforms = CoursePlatformRepository(database);
    final doomed = Semester(
      id: 'first',
      name: '删除',
      startDate: DateTime(2026),
      totalWeeks: 18,
    );
    final current = doomed.copyWith(id: 'current', name: '当前');
    await semesters.upsert(doomed);
    await semesters.upsert(current, activate: true);
    const course = Course(
      id: 'c1',
      semesterId: 'current',
      name: '操作系统',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
    );
    const platform = CoursePlatform(
      purpose: CoursePlatformPurpose.onlineCourse,
      name: '学习通',
    );
    await courses.upsert(course);
    await courses.upsert(course.copyWith(id: 'delete-c', semesterId: 'first'));
    await platforms.replacePlatforms('first', '操作系统', [platform]);
    await platforms.replacePlatforms('current', '操作系统', [platform]);
    await formFor(database, doomed).delete();
    expect((await semesters.getActiveSemester())?.id, 'current');
    expect(await courses.getCourses('current'), [course]);
    expect(await platforms.getPlatforms('current', '操作系统'), [platform]);
    expect(await courses.getCourses('first'), isEmpty);
    expect(await platforms.getPlatforms('first', '操作系统'), isEmpty);
  });

  test('删除激活学期按原有首个学期策略激活而非按日期挑选', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final first = Semester(
      id: 'first',
      name: '首个',
      startDate: DateTime(2020),
      totalWeeks: 18,
    );
    await semesters.upsert(first);
    await semesters.upsert(
      first.copyWith(id: 'latest', startDate: DateTime(2030)),
    );
    final doomed = first.copyWith(id: 'doomed');
    await semesters.upsert(doomed, activate: true);
    await formFor(database, doomed).delete();
    final exported =
        jsonDecode(await BackupRepository(database).exportJson()) as Map;
    final active = (exported['semesters'] as List).where(
      (s) => s['isActive'] == true,
    );
    expect(active.single['id'], 'first');
  });

  test('删除最后学期时默认学期创建失败也回滚删除', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final semesters = SemesterRepository(database);
    final original = (await semesters.getActiveSemester())!;
    final backup = BackupRepository(database);
    Future<Map> snapshot() async =>
        (jsonDecode(await backup.exportJson()) as Map)..remove('exportedAt');
    final before = await snapshot();
    await database.customStatement('''
      CREATE TRIGGER fail_seed BEFORE INSERT ON semesters
      BEGIN SELECT RAISE(ABORT, 'forced seed failure'); END;
    ''');
    await expectLater(
      formFor(database, original).delete(),
      throwsA(isA<Exception>()),
    );
    expect(await snapshot(), before);
    expect((await semesters.getActiveSemester())?.id, original.id);
  });
}
