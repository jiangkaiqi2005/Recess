import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/import/application/course_capture_orientation.dart';
import 'package:recess/features/import/application/webview_import_provider.dart';
import 'package:recess/features/import/presentation/import_screen.dart';
import 'package:recess/features/import/presentation/webview_import_screen.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FilePicker.platform = _CoursePicker();
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    await container
        .read(semesterRepositoryProvider)
        .upsert(
          Semester(
            id: 'old',
            name: '旧学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
          ),
          activate: true,
        );
    await container
        .read(courseRepositoryProvider)
        .upsert(
          const Course(
            id: 'old-course',
            semesterId: 'old',
            name: '旧课程',
            teacher: '旧教师',
            location: '旧教室',
            dayOfWeek: 1,
            startSection: 1,
            endSection: 2,
            weeks: [1, 2],
          ),
        );
    await container
        .read(coursePlatformRepositoryProvider)
        .replacePlatforms('old', '旧课程', const [
          CoursePlatform(
            purpose: CoursePlatformPurpose.homework,
            name: '旧平台',
            url: 'https://example.com/old',
          ),
        ]);
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> mount(WidgetTester tester, Widget screen) async {
    await container.read(activeSemesterProvider.future);
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitUntil(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 100 && !ready(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(ready(), isTrue);
  }

  Future<Map> oldContents() async {
    final data =
        jsonDecode(await container.read(backupRepositoryProvider).exportJson())
            as Map;
    final old = (data['semesters'] as List).cast<Map>().singleWhere(
      (semester) => semester['id'] == 'old',
    );
    return old..remove('isActive');
  }

  Future<void> createFromImport(WidgetTester tester, String name) async {
    await tester.tap(find.text('新建学期'));
    await tester.pumpAndSettle();
    expect(find.byType(SemesterEditSheet), findsOneWidget);
    expect(find.text('保存后设为当前学期'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, '学期名称'), name);
    await tester.pump();
    await tester.tap(find.text('创建'));
    await waitUntil(
      tester,
      () => find.byType(SemesterEditSheet).evaluate().isEmpty,
    );
    await waitUntil(
      tester,
      () => find.text('将导入到：$name').evaluate().isNotEmpty,
    );
  }

  testWidgets('文件起始页新建当前学期后替换导入仅写新学期且旧课程平台不变', (tester) async {
    await tester.runAsync(() async {
      await mount(tester, const ImportScreen());
      final before = await oldContents();
      expect(find.text('将导入到：旧学期'), findsOneWidget);
      await createFromImport(tester, '新学期');
      expect(find.text('将导入到：新学期'), findsOneWidget);
      final current =
          (await container
              .read(semesterRepositoryProvider)
              .getActiveSemester())!;
      expect(current.name, '新学期');
      expect(current.id, isNot('old'));

      await tester.tap(find.text('选择文件'));
      await waitUntil(tester, () => find.text('导入 1 门').evaluate().isNotEmpty);
      expect(find.textContaining('将导入到：'), findsNothing);
      expect(find.text('新建学期'), findsNothing);
      expect(find.text('替换模式：所选课程将替换当前学期的原有课表。'), findsOneWidget);
      await tester.tap(find.text('导入 1 门'));
      await waitUntil(
        tester,
        () => find.widgetWithText(FilledButton, '替换').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(FilledButton, '替换'));
      await waitUntil(
        tester,
        () => find.text('已用 1 门课程替换当前课表').evaluate().isNotEmpty,
      );
      final imported = await container
          .read(courseRepositoryProvider)
          .getCourses(current.id);
      expect(imported.map((course) => course.name), ['新课程']);
      expect(imported.single.semesterId, current.id);
      expect(await oldContents(), before);
      expect(
        await container.read(semesterRepositoryProvider).getSemesters(),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('教务选学校可新建并更新目标登录抓取预览均无新建入口', (tester) async {
    await tester.runAsync(() async {
      await mount(
        tester,
        WebviewImportScreen(
          orientationController: CourseCaptureOrientationController(
            setPreferredOrientations: (_) async {},
          ),
        ),
      );
      expect(find.text('将导入到：旧学期'), findsOneWidget);
      await createFromImport(tester, '教务新学期');
      expect(find.text('从教务系统导入'), findsOneWidget);
      expect(find.text('将导入到：教务新学期'), findsOneWidget);
      expect(
        (await container.read(semesterRepositoryProvider).getActiveSemester())
            ?.name,
        '教务新学期',
      );

      final notifier = container.read(webviewImportProvider.notifier);
      notifier.startLogin();
      await tester.pumpAndSettle();
      expect(find.text('登录'), findsOneWidget);
      expect(find.textContaining('将导入到：'), findsNothing);
      expect(find.text('新建学期'), findsNothing);
      notifier.setExtracting(true);
      await tester.pump();
      expect(find.textContaining('将导入到：'), findsNothing);
      expect(find.text('新建学期'), findsNothing);
      final semester =
          (await container
              .read(semesterRepositoryProvider)
              .getActiveSemester())!;
      notifier.showValidatedPreview(
        previewWebviewCourses([
          {
            'name': '教务课程',
            'dayOfWeek': 1,
            'startSection': 1,
            'endSection': 2,
            'weeks': [1],
          },
        ], WebviewPreviewContext.fromSemester(semester)),
      );
      await tester.pumpAndSettle();
      expect(find.text('选择导入课程'), findsOneWidget);
      expect(find.textContaining('将导入到：'), findsNothing);
      expect(find.text('新建学期'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('导入页新建当前学期失败保留原目标和所有数据', (tester) async {
    await tester.runAsync(() async {
      await mount(tester, const ImportScreen());
      final before = await oldContents();
      await database.customStatement('''
        CREATE TRIGGER fail_activation BEFORE UPDATE OF is_active ON semesters
        WHEN NEW.is_active = 1
        BEGIN SELECT RAISE(ABORT, 'forced activation failure'); END;
      ''');
      await tester.tap(find.text('新建学期'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '失败学期');
      await tester.pump();
      await tester.tap(find.text('创建'));
      await waitUntil(
        tester,
        () => find.textContaining('保存失败').evaluate().isNotEmpty,
      );
      expect(find.byType(SemesterEditSheet), findsOneWidget);
      expect(find.text('将导入到：旧学期'), findsOneWidget);
      expect(
        (await container.read(semesterRepositoryProvider).getActiveSemester())
            ?.id,
        'old',
      );
      expect(
        await container.read(semesterRepositoryProvider).getSemesters(),
        hasLength(1),
      );
      expect(await oldContents(), before);
      expect(tester.takeException(), isNull);
    });
  });
}

class _CoursePicker extends FilePicker {
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
  }) async {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'courses': [
            {
              'name': '新课程',
              'dayOfWeek': 2,
              'startSection': 3,
              'endSection': 4,
              'weeks': [1, 2],
              'color': '#123456',
              'startTime': '10:05',
              'endTime': '11:40',
            },
          ],
        }),
      ),
    );
    return FilePickerResult([
      PlatformFile(name: 'courses.json', size: bytes.length, bytes: bytes),
    ]);
  }
}
