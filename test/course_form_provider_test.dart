import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/data/app_database.dart' as db;
import 'package:hormone/data/repositories/course_platform_repository.dart';
import 'package:hormone/data/repositories/course_repository.dart';
import 'package:hormone/features/course/application/course_form_provider.dart';

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

  test('保存时课程名变了，平台跟着迁移到新名下', () async {
    final form = CourseFormNotifier(courses, platforms)..init(existing);
    form.setName('操作系统原理');

    expect(await form.save(), isTrue);

    expect(await platforms.getPlatforms('s1', '操作系统原理'), [online]);
    expect(await platforms.getPlatforms('s1', '操作系统'), isEmpty);
  });

  test('编辑过的平台列表随保存写到当前课程名下', () async {
    final form = CourseFormNotifier(courses, platforms)..init(existing);
    form.setName('操作系统原理');

    await form.save(platforms: [online, homework]);

    expect(
      await platforms.getPlatforms('s1', '操作系统原理'),
      [online, homework],
    );
  });

  test('新建课程时平台同样随保存写入', () async {
    final form = CourseFormNotifier(courses, platforms)
      ..init(existing.copyWith(id: '', name: '编译原理'));

    await form.save(platforms: [homework]);

    expect(await platforms.getPlatforms('s1', '编译原理'), [homework]);
    // 新建课程不触发改名迁移。
    expect(await platforms.getPlatforms('s1', '操作系统'), [online]);
  });

  test('没有改动平台时保存不覆盖已有平台', () async {
    final form = CourseFormNotifier(courses, platforms)..init(existing);
    form.setLocation('D1210');

    await form.save();

    expect(await platforms.getPlatforms('s1', '操作系统'), [online]);
  });
}
