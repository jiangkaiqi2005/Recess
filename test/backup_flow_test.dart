import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/backup_repository.dart';
import 'package:recess/data/repositories/course_platform_repository.dart';
import 'package:recess/data/repositories/course_repository.dart';
import 'package:recess/data/repositories/semester_repository.dart';
import 'package:recess/features/settings/presentation/settings_screen.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/settings/application/backup_service.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';
import 'package:recess/features/schedule/presentation/week_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late db.AppDatabase database;
  late SemesterRepository semesters;
  late CourseRepository courses;
  late CoursePlatformRepository platforms;
  late ProviderContainer container;
  late _BackupPicker picker;
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Recess',
      packageName: 'io.github.jiangkaiqi2005.recess',
      version: '1.2.4',
      buildNumber: '24',
      buildSignature: 'test',
    );
    picker = _BackupPicker();
    FilePicker.platform = picker;
    database = db.AppDatabase(NativeDatabase.memory());
    semesters = SemesterRepository(database);
    courses = CourseRepository(database);
    platforms = CoursePlatformRepository(database);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    for (final channel in [shareChannel, pathChannel]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseRestore(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('从备份恢复'), 250);
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();
  }

  Future<void> waitForFeedback(WidgetTester tester) async {
    for (
      var attempt = 0;
      attempt < 100 && find.byType(SnackBar).evaluate().isEmpty;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  const validBackup =
      '{"app":"recess","semesters":[{"id":"new-s",'
      '"name":"新学期","startDate":"2026-09-07","totalWeeks":18}]}';

  Future<Map> snapshot() async {
    final result =
        jsonDecode(await container.read(backupRepositoryProvider).exportJson())
            as Map;
    result.remove('exportedAt');
    return result;
  }

  Future<Map> seedOldData() async {
    await semesters.upsert(
      Semester(
        id: 'old-s',
        name: '旧学期',
        startDate: DateTime(2020),
        totalWeeks: 18,
      ),
    );
    await semesters.setActive('old-s');
    await courses.upsert(
      const Course(
        id: 'old-c',
        semesterId: 'old-s',
        name: '旧课程',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
      ),
    );
    return snapshot();
  }

  testWidgets('系统分享的真实 UTF-8 文件可从设置恢复中文英文和 emoji', (tester) async {
    await tester.runAsync(() async {
      const course = Course(
        id: 'c1',
        semesterId: 's1',
        name: '高等数学 Calculus',
        teacher: '张老师',
        location: '教三 201',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        startTime: '08:05',
        endTime: '09:40',
        weeks: [1, 3, 5],
        colorValue: 0x80123456,
        notes: '带课本 review 📚',
      );
      const platform = CoursePlatform(
        purpose: CoursePlatformPurpose.onlineCourse,
        name: '学习通 MOOC',
        url: 'https://example.com/course?q=数学',
      );
      await semesters.upsert(
        Semester(
          id: 's1',
          name: '2026 秋学期 🍂',
          startDate: DateTime(2026, 9, 7),
          totalWeeks: 18,
          currentWeekOverride: 3,
        ),
      );
      await semesters.upsert(
        Semester(
          id: 's2',
          name: '2027 春学期',
          startDate: DateTime(2027, 3, 1),
          totalWeeks: 16,
        ),
      );
      await semesters.setActive('s2');
      await courses.upsert(course);
      await platforms.replacePlatforms('s1', course.name, [platform]);
      final directory = await Directory.systemTemp.createTemp(
        'recess_backup_flow_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final shared = Completer<File>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (_) async => directory.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, (call) async {
            shared.complete(
              File((call.arguments['paths'] as List).single as String),
            );
            return 'saved';
          });
      await container.read(backupServiceProvider).exportToJson();
      picker.bytes =
          await (await shared.future.timeout(
            const Duration(seconds: 10),
          )).readAsBytes();
      final exported = jsonDecode(utf8.decode(picker.bytes!)) as Map;
      expect((exported['semesters'] as List).first['name'], '2026 秋学期 🍂');
      await openSettings(tester);
      await chooseRestore(tester);
      expect(find.text('恢复备份？'), findsOneWidget);
      await tester.tap(find.text('恢复'));
      await waitForFeedback(tester);
      expect(find.text('已恢复 2 个学期、1 门课程'), findsOneWidget);
      expect((await semesters.getSemesters()).map((s) => s.name), [
        '2026 秋学期 🍂',
        '2027 春学期',
      ]);
      expect((await semesters.getActiveSemester())?.id, 's2');
      expect(await courses.getCourses('s1'), [course]);
      expect(await platforms.getPlatforms('s1', course.name), [platform]);
    });
  });

  test('恢复应用入口使已加载的学期列表激活学期和课表获得新数据', () async {
    await semesters.upsert(
      Semester(
        id: 'old-s',
        name: '旧学期',
        startDate: DateTime(2020),
        totalWeeks: 18,
      ),
    );
    await semesters.setActive('old-s');
    await courses.upsert(
      const Course(
        id: 'old-c',
        semesterId: 'old-s',
        name: '旧课程',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
      ),
    );
    final active = container.listen(activeSemesterProvider, (_, __) {});
    final list = container.listen(semestersProvider, (_, __) {});
    final schedule = container.listen(scheduleCoursesProvider, (_, __) {});
    addTearDown(active.close);
    addTearDown(list.close);
    addTearDown(schedule.close);
    await container.read(activeSemesterProvider.future);
    await container.read(semestersProvider.future);
    expect(
      (await container.read(scheduleCoursesProvider.future)).single.name,
      '旧课程',
    );

    final result = await container
        .read(backupServiceProvider)
        .restore(
          BackupFile.parse(
            jsonEncode({
              'app': 'recess',
              'semesters': [
                {
                  'id': 'new-s',
                  'name': '新学期',
                  'startDate': '2026-09-07',
                  'totalWeeks': 18,
                  'isActive': true,
                  'courses': [
                    {
                      'id': 'new-c',
                      'name': '新课程',
                      'dayOfWeek': 1,
                      'startSection': 1,
                      'endSection': 2,
                      'weeks': [1],
                    },
                  ],
                },
              ],
            }),
          ),
        );

    expect(result.semesterCount, 1);
    expect(result.courseCount, 1);
    expect((await container.read(activeSemesterProvider.future))?.name, '新学期');
    expect((await container.read(semestersProvider.future)).single.name, '新学期');
    expect(
      (await container.read(scheduleCoursesProvider.future)).single.name,
      '新课程',
    );
  });

  final invalidUtf8 = utf8.encode(validBackup.replaceFirst('新学期', 'X'));
  invalidUtf8[invalidUtf8.indexOf(0x58)] = 0xff;
  for (final invalid
      in <String, List<int>>{
        '非法 UTF-8': invalidUtf8,
        '非法 JSON': utf8.encode('not json'),
        '错误应用标记': utf8.encode(validBackup.replaceFirst('recess', 'other')),
        '缺少学期数据': utf8.encode('{"app":"recess","semesters":[]}'),
        '非法学期日期': utf8.encode(
          validBackup.replaceFirst('2026-09-07', 'bad-date'),
        ),
      }.entries) {
    testWidgets('${invalid.key}在覆盖确认前拒绝并保留现有数据', (tester) async {
      await tester.runAsync(() async {
        final before = await seedOldData();
        picker.bytes = Uint8List.fromList(invalid.value);
        await openSettings(tester);
        await chooseRestore(tester);
        expect(find.text('恢复备份？'), findsNothing);
        expect(find.textContaining('备份文件无效：'), findsOneWidget);
        expect(await snapshot(), before);
      });
    });
  }

  for (final cancelSelection in [true, false]) {
    testWidgets('取消${cancelSelection ? '选择' : '确认'}不恢复也不报告成功', (tester) async {
      await tester.runAsync(() async {
        final before = await seedOldData();
        picker.bytes =
            cancelSelection
                ? null
                : Uint8List.fromList(utf8.encode(validBackup));
        await openSettings(tester);
        await chooseRestore(tester);
        if (!cancelSelection) {
          expect(find.text('恢复备份？'), findsOneWidget);
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
        }
        expect(find.text('恢复备份？'), findsNothing);
        expect(find.textContaining('已恢复'), findsNothing);
        expect(await snapshot(), before);
      });
    });
  }

  testWidgets('激活失败显示恢复失败且保留旧数据', (tester) async {
    await tester.runAsync(() async {
      final before = await seedOldData();
      await database.customStatement('''
        CREATE TRIGGER fail_activation BEFORE UPDATE OF is_active ON semesters
        BEGIN SELECT RAISE(ABORT, 'forced activation failure'); END;
      ''');
      picker.bytes = Uint8List.fromList(utf8.encode(validBackup));
      await openSettings(tester);
      await chooseRestore(tester);
      await tester.tap(find.text('恢复'));
      await waitForFeedback(tester);
      expect(find.textContaining('恢复失败：'), findsOneWidget);
      expect(find.textContaining('已恢复'), findsNothing);
      expect(await snapshot(), before);
    });
  });

  testWidgets('设置恢复成功后学期列表和课表显示新数据', (tester) async {
    await tester.runAsync(() async {
      await seedOldData();
      await container.read(activeSemesterProvider.future);
      await container.read(semestersProvider.future);
      picker.bytes = Uint8List.fromList(
        utf8.encode(
          validBackup.replaceFirst(
            '"totalWeeks":18',
            '"totalWeeks":18,"courses":[{"id":"new-c",'
                '"name":"新课程","dayOfWeek":1,"startSection":1,"endSection":2,"weeks":[1]}]',
          ),
        ),
      );
      await openSettings(tester);
      await chooseRestore(tester);
      await tester.tap(find.text('恢复'));
      await waitForFeedback(tester);
      expect(find.text('已恢复 1 个学期、1 门课程'), findsOneWidget);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SemesterScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('新学期'), findsOneWidget);
      expect(find.text('旧学期'), findsNothing);
      await container.read(activeSemesterProvider.future);
      await container.read(scheduleCoursesProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: WeekView(selectedWeek: 1)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('新课程'), findsOneWidget);
      expect(find.text('旧课程'), findsNothing);
    });
  });
}

class _BackupPicker extends FilePicker {
  Uint8List? bytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      bytes == null
          ? null
          : FilePickerResult([
            PlatformFile(
              name: 'backup.json',
              size: bytes!.length,
              bytes: bytes,
            ),
          ]);
}
