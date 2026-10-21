import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/data/app_database.dart' as db;
import 'package:hormone/data/repositories/course_platform_repository.dart';
import 'package:hormone/data/repositories/course_repository.dart';
import 'package:hormone/features/course/application/course_form_provider.dart';
import 'package:hormone/features/course/application/course_platforms_provider.dart';

void main() {
  late db.AppDatabase database;
  late CourseRepository courses;
  late CoursePlatformRepository platforms;

  const online = CoursePlatform(
    purpose: CoursePlatformPurpose.onlineCourse,
    name: '学习通',
  );
  const homework = CoursePlatform(
    purpose: CoursePlatformPurpose.homework,
    name: '雨课堂',
  );
  const lab = CoursePlatform(
    purpose: CoursePlatformPurpose.lab,
    name: '头歌',
  );
  const existing = Course(
    id: 'c1',
    semesterId: 's1',
    name: '操作系统',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    weeks: [1],
  );

  setUp(() async {
    database = db.AppDatabase(NativeDatabase.memory());
    courses = CourseRepository(database);
    platforms = CoursePlatformRepository(database);
    await courses.upsert(existing);
    await platforms.replacePlatforms('s1', '操作系统', [online]);
  });

  tearDown(() async {
    await database.close();
  });

  /// 按编辑页的方式组装两个表单：课程表单 + 平台表单。
  Future<(CourseFormNotifier, CoursePlatformsFormNotifier)> openForm(
    Course initial,
  ) async {
    final form = CourseFormNotifier(courses)..init(initial);
    final platformForm = CoursePlatformsFormNotifier(platforms);
    await platformForm.init(
      semesterId: initial.semesterId,
      courseName: initial.name,
      originalName: initial.id.isEmpty ? null : initial.name,
    );
    return (form, platformForm);
  }

  Future<void> rename(
    CourseFormNotifier form,
    CoursePlatformsFormNotifier platformForm,
    String name,
  ) async {
    form.setName(name);
    await platformForm.setCourseName(name);
  }

  Future<bool?> save(
    CourseFormNotifier form,
    CoursePlatformsFormNotifier platformForm,
  ) =>
      form.save(platforms: platformForm.pendingForCurrentName);

  test('保存时课程名变了，平台跟着迁移到新名下', () async {
    final (form, platformForm) = await openForm(existing);
    await rename(form, platformForm, '操作系统原理');
    // 列表预览迁移后的结果。
    expect(platformForm.state, [online]);

    expect(await save(form, platformForm), isTrue);

    expect(await platforms.getPlatforms('s1', '操作系统原理'), [online]);
    expect(await platforms.getPlatforms('s1', '操作系统'), isEmpty);
  });

  test('改名后再改平台：写到新名下的正是看到的列表', () async {
    final (form, platformForm) = await openForm(existing);
    platformForm.add(homework);
    await rename(form, platformForm, '操作系统原理');
    expect(platformForm.state, [online, homework]);

    await save(form, platformForm);

    expect(
      await platforms.getPlatforms('s1', '操作系统原理'),
      [online, homework],
    );
  });

  test('新建课程填已有课程名并添加平台，保留该名下原有平台', () async {
    final (form, platformForm) =
        await openForm(existing.copyWith(id: '', name: ''));
    await rename(form, platformForm, '操作系统');
    expect(platformForm.state, [online]);

    platformForm.add(homework);
    await save(form, platformForm);

    expect(await platforms.getPlatforms('s1', '操作系统'), [online, homework]);
  });

  test('复制课程改回原名并添加平台，保留原名下的平台', () async {
    final (form, platformForm) =
        await openForm(existing.copyWith(id: '', name: '操作系统（副本）'));
    expect(platformForm.state, isEmpty);
    await rename(form, platformForm, '操作系统');
    expect(platformForm.state, [online]);

    platformForm.add(homework);
    await save(form, platformForm);

    expect(await platforms.getPlatforms('s1', '操作系统'), [online, homework]);
    expect(await platforms.getPlatforms('s1', '操作系统（副本）'), isEmpty);
  });

  test('把有平台的课改名成另一门有平台的课：显示并编辑目标名下的平台，不被原列表覆盖',
      () async {
    await courses.upsert(existing.copyWith(id: 'c2', name: '编译原理'));
    await platforms.replacePlatforms('s1', '编译原理', [lab]);
    final (form, platformForm) = await openForm(existing);
    platformForm.add(homework); // 在原名下做的改动

    await rename(form, platformForm, '编译原理');
    expect(platformForm.state, [lab]);
    platformForm.add(online);
    await save(form, platformForm);

    expect(await platforms.getPlatforms('s1', '编译原理'), [lab, online]);
    // 原名已无课程使用，按 C5 删除。
    expect(await platforms.getPlatforms('s1', '操作系统'), isEmpty);
  });

  test('来回改名不丢失某个名字下已做的改动', () async {
    final (form, platformForm) = await openForm(existing);
    platformForm.add(homework);
    await rename(form, platformForm, '操作');
    await rename(form, platformForm, '操作系统');

    expect(platformForm.state, [online, homework]);
  });

  test('新建课程时平台同样随保存写入，且不触发改名迁移', () async {
    final (form, platformForm) =
        await openForm(existing.copyWith(id: '', name: ''));
    await rename(form, platformForm, '编译原理');
    platformForm.add(homework);

    await save(form, platformForm);

    expect(await platforms.getPlatforms('s1', '编译原理'), [homework]);
    expect(await platforms.getPlatforms('s1', '操作系统'), [online]);
  });

  test('没有改动平台时保存不覆盖已有平台', () async {
    final (form, platformForm) = await openForm(existing);
    form.setLocation('D1210');

    expect(platformForm.pendingForCurrentName, isNull);
    await save(form, platformForm);

    expect(await platforms.getPlatforms('s1', '操作系统'), [online]);
  });

  test('写平台失败时整次保存回滚，课程不会只改名一半', () async {
    final form = CourseFormNotifier(courses)..init(existing);
    form.setName('操作系统原理');
    await database.customStatement('DROP TABLE course_platforms');

    await expectLater(form.save(platforms: [homework]), throwsA(anything));

    expect((await courses.getCourse('c1'))?.name, '操作系统');
  });
}
