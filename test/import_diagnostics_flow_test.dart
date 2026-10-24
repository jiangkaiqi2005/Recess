import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/import/application/import_provider.dart';
import 'package:recess/features/import/presentation/import_screen.dart';

/// 文件导入结果反馈：预览/错误/失败/完成各状态都如实呈现诊断，
/// 完成页按合并与替换分别报数，换文件不继承旧诊断。
/// 高位接缝：可编程文件选择器 + 真实 JSON/ICS 解析器 + 内存数据库。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late ProviderContainer container;
  late _ImportPicker picker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    picker = _ImportPicker();
    FilePicker.platform = picker;
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    await container
        .read(semesterRepositoryProvider)
        .upsert(
          Semester(
            id: 's1',
            name: '学期',
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

  /// 混合文件：1 条有效 + 1 条跳过（缺 name）+ 1 条部分忽略（周次越界）。
  void pickMixedJson() {
    picker.content = jsonEncode({
      'courses': [
        {
          'name': '高数',
          'dayOfWeek': 1,
          'startSection': 1,
          'endSection': 2,
          'weeks': [1, 2],
        },
        {
          'dayOfWeek': 2,
          'startSection': 1,
          'endSection': 2,
          'weeks': [1],
        },
        {
          'name': '越界周',
          'dayOfWeek': 3,
          'startSection': 1,
          'endSection': 2,
          'weeks': [1, 19],
        },
      ],
    });
  }

  Future<void> pumpImport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ImportScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 经页面「选择文件」按钮发起导入，轮询等待解析完成（预览或错误）。
  Future<void> pickFile(WidgetTester tester) async {
    await tester.tap(find.text('选择文件'));
    await tester.pump();
    for (var i = 0; i < 200; i++) {
      final status = container.read(importProvider).status;
      if (status == ImportStatus.preview || status == ImportStatus.error) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> confirmImport(
    WidgetTester tester, {
    required String confirmButton,
  }) async {
    final n = container.read(importProvider).selectedCount;
    await tester.tap(find.text('导入 $n 门'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, confirmButton));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('混合文件：预览展示诊断摘要，可查看原因，不阻断有效课程提交', (tester) async {
    await tester.runAsync(() async {
      pickMixedJson();
      await pumpImport(tester);
      await pickFile(tester);

      // 摘要：1 条未导入 + 1 条部分忽略。
      expect(find.textContaining('未完整导入'), findsOneWidget);
      expect(find.textContaining('跳过 1 条'), findsOneWidget);
      expect(find.textContaining('部分忽略 1 条'), findsOneWidget);
      // 未展开时不显示具体原因，点击「查看原因」后逐条可见。
      expect(find.text('第2条：缺少 name'), findsNothing);
      await tester.tap(find.text('查看原因'));
      await tester.pumpAndSettle();
      expect(find.text('第2条：缺少 name'), findsOneWidget);
      expect(find.textContaining('第3条：'), findsOneWidget);
      expect(find.textContaining('超出学期范围'), findsOneWidget);

      // 有效课程（含部分忽略的越界周）仍可选择、可提交。
      expect(find.text('高数'), findsOneWidget);
      expect(find.text('导入 2 门'), findsOneWidget);
      await confirmImport(tester, confirmButton: '替换');
      expect(find.text('已用 2 门课程替换当前课表'), findsOneWidget);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).map((c) => c.name),
        unorderedEquals(['高数', '越界周']),
      );
      // 完成页仍提供诊断摘要与原因入口。
      expect(find.textContaining('未完整导入'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('全部记录无效：错误页展示具体原因，返回后可重新选择', (tester) async {
    await tester.runAsync(() async {
      picker.content = jsonEncode({
        'courses': [
          {
            'dayOfWeek': 1,
            'startSection': 1,
            'endSection': 2,
            'weeks': [1],
          },
          {
            'name': '坏星期',
            'dayOfWeek': 9,
            'startSection': 1,
            'endSection': 2,
            'weeks': [1],
          },
        ],
      });
      await pumpImport(tester);
      await pickFile(tester);

      expect(find.textContaining('未能从文件中解析出任何课程'), findsOneWidget);
      expect(find.text('第1条：缺少 name'), findsOneWidget);
      expect(find.text('第2条：dayOfWeek 非法'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('提交失败返回预览后诊断仍然可见，重试可成功', (tester) async {
    await tester.runAsync(() async {
      pickMixedJson();
      await pumpImport(tester);
      await pickFile(tester);
      await database.customStatement('''
        CREATE TRIGGER fail_insert BEFORE INSERT ON courses
        BEGIN SELECT RAISE(ABORT, 'course rejected'); END;
      ''');
      await confirmImport(tester, confirmButton: '替换');
      expect(find.textContaining('导入失败'), findsOneWidget);
      expect(find.text('导入 2 门'), findsOneWidget);
      // 返回预览后诊断仍在。
      expect(find.textContaining('未完整导入'), findsOneWidget);
      await tester.tap(find.text('查看原因'));
      await tester.pumpAndSettle();
      expect(find.text('第2条：缺少 name'), findsOneWidget);

      await database.customStatement('DROP TRIGGER fail_insert');
      await confirmImport(tester, confirmButton: '替换');
      expect(find.text('已用 2 门课程替换当前课表'), findsOneWidget);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).map((c) => c.name),
        unorderedEquals(['高数', '越界周']),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('合并导入完成页如实说明追加结果，替换页说明替换结果', (tester) async {
    await tester.runAsync(() async {
      await container
          .read(courseRepositoryProvider)
          .upsert(
            const Course(
              id: 'old-1',
              semesterId: 's1',
              name: '旧课',
              dayOfWeek: 5,
              startSection: 1,
              endSection: 2,
              weeks: [1],
            ),
          );
      pickMixedJson();

      // 合并：保留现有课表，追加新课程。
      await pumpImport(tester);
      await pickFile(tester);
      await tester.tap(find.text('合并'));
      await tester.pumpAndSettle();
      await confirmImport(tester, confirmButton: '追加');
      expect(find.text('已在现有课表中追加 2 门课程'), findsOneWidget);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).map((c) => c.name),
        unorderedEquals(['旧课', '高数', '越界周']),
      );
      expect(find.textContaining('未完整导入'), findsOneWidget);

      // 替换：原有课程被替换。
      // 完成/错误态没有再选文件的 UI 入口，直接走 provider 接缝。
      await container.read(importProvider.notifier).pickAndParse();
      await tester.pumpAndSettle();
      await tester.tap(find.text('替换'));
      await tester.pumpAndSettle();
      await confirmImport(tester, confirmButton: '替换');
      expect(find.text('已用 2 门课程替换当前课表'), findsOneWidget);
      expect(
        (await container
            .read(courseRepositoryProvider)
            .getCourses('s1')).map((c) => c.name),
        unorderedEquals(['高数', '越界周']),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('ICS 文件同样提供诊断（按源事件计数）', (tester) async {
    await tester.runAsync(() async {
      picker.extension = 'ics';
      picker.content = '''BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:高数
DTSTART:20260907T080000
DTEND:20260907T094000
RRULE:FREQ=WEEKLY;COUNT=2
END:VEVENT
BEGIN:VEVENT
SUMMARY:提前课
DTSTART:20260801T080000
DTEND:20260801T094000
RRULE:FREQ=WEEKLY;BYDAY=MO,WE;COUNT=2
END:VEVENT
END:VCALENDAR''';
      await pumpImport(tester);
      await pickFile(tester);

      expect(find.text('共解析 1 门'), findsOneWidget);
      expect(find.textContaining('未完整导入'), findsOneWidget);
      await tester.tap(find.text('查看原因'));
      await tester.pumpAndSettle();
      // BYDAY 双日事件按 1 条源记录计，不放大。
      expect(find.text('第2个事件「提前课」：开始日期早于开学日'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('换文件不继承上一文件的诊断', (tester) async {
    await tester.runAsync(() async {
      pickMixedJson();
      await pumpImport(tester);
      await pickFile(tester);
      expect(find.textContaining('未完整导入'), findsOneWidget);

      // 从完成状态再选一个干净的新文件。
      await confirmImport(tester, confirmButton: '替换');
      expect(find.textContaining('未完整导入'), findsOneWidget);
      picker.content = jsonEncode({
        'courses': [
          {
            'name': '新课',
            'dayOfWeek': 1,
            'startSection': 1,
            'endSection': 2,
            'weeks': [1],
          },
        ],
      });
      // 完成/错误态没有再选文件的 UI 入口，直接走 provider 接缝。
      await container.read(importProvider.notifier).pickAndParse();
      await tester.pumpAndSettle();
      expect(find.textContaining('未完整导入'), findsNothing);
      expect(find.textContaining('超出学期范围'), findsNothing);
      expect(find.text('共解析 1 门'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _ImportPicker extends FilePicker {
  String? content;
  String extension = 'json';

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
    if (content == null) return null;
    final bytes = Uint8List.fromList(utf8.encode(content!));
    return FilePickerResult([
      PlatformFile(
        name: 'courses.$extension',
        size: bytes.length,
        bytes: bytes,
      ),
    ]);
  }
}
