import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/import/application/import_commit.dart';
import 'package:recess/features/import/domain/import_course.dart';
import 'package:recess/features/import/domain/webview_preview_context.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';
import 'package:recess/features/widget/application/widget_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late db.AppDatabase database;
  late ProviderContainer container;
  late Map<String, Object?> saved;
  String? widgetName;
  const channel = MethodChannel('home_widget');
  const updates = MethodChannel('home_widget/updates');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    saved = {};
    widgetName = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initiallyLaunchedFromHomeWidget') return null;
      final arguments = call.arguments as Map;
      if (call.method == 'saveWidgetData') {
        saved[arguments['id'] as String] = arguments['data'];
      } else if (call.method == 'updateWidget') {
        widgetName = arguments['android'] as String?;
      }
      return true;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      updates,
      (call) async => null,
    );
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    await container
        .read(semesterRepositoryProvider)
        .upsert(
          Semester(
            id: 's',
            name: '测试学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
            currentWeekOverride: 1,
          ),
          activate: true,
        );
    await container.read(sectionTimesProvider.notifier).setAllTimes(const {
      1: SectionTime('08:00', 45),
      2: SectionTime('08:55', 45),
    });
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(updates, null);
  });

  Course course(String name, {String? startTime, String? endTime}) => Course(
    id: name,
    semesterId: 's',
    name: name,
    dayOfWeek: DateTime.now().weekday,
    startSection: 1,
    endSection: 2,
    weeks: const [1],
    startTime: startTime,
    endTime: endTime,
  );

  test('小组件实际payload逐端使用当前节次回退并保留显式钟点', () async {
    for (final c in [
      course('无显式'),
      course('显式', startTime: '08:30', endTime: '09:00'),
      course('只开始', startTime: '08:30'),
      course('只结束', endTime: '09:00'),
    ]) {
      await container.read(courseRepositoryProvider).upsert(c);
    }
    await container.read(widgetServiceProvider).updateTodayWidget();
    final items = jsonDecode(saved['courses'] as String) as List;
    expect(
      {for (final item in items) item['name']: item['time']},
      {
        '无显式': '08:00-09:40',
        '显式': '08:30-09:00',
        '只开始': '08:30-09:40',
        '只结束': '08:00-09:00',
      },
    );
    expect(saved['widget_title'], '今天 · 第1周');
    expect(widgetName, 'CourseWidgetProvider');
  });

  test('小组件保留空串和无效显式文本，缺少端点才显示节次', () async {
    for (final c in [
      course('空开始', startTime: ''),
      course('坏结束', endTime: '不是钟点'),
      course('缺节次').copyWith(startSection: 15, endSection: 16),
    ]) {
      await container.read(courseRepositoryProvider).upsert(c);
    }
    await container.read(widgetServiceProvider).updateTodayWidget();
    final items = jsonDecode(saved['courses'] as String) as List;
    expect(
      {for (final item in items) item['name']: item['time']},
      {'空开始': '-09:40', '坏结束': '08:00-不是钟点', '缺节次': '第15-16节'},
    );
  });

  for (final change in ['顺延', '模板', '重置']) {
    test('小组件在$change后使用新节次，WebView已存显式快照保持原值', () async {
      final submission = ImportSubmission.webview(
        semesterId: 's',
        previewContext: WebviewPreviewContext.fromSemester(
          Semester(
            id: 's',
            name: '测试学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
          ),
        ),
        mode: ImportMode.merge,
        courses: [
          ImportCourse(
            name: '教务快照',
            dayOfWeek: DateTime.now().weekday,
            startSection: 1,
            endSection: 2,
            weeks: [1],
            source: 'webview',
          ),
        ],
        sectionTimes: container.read(sectionTimesProvider),
      );
      await container.read(importCommitProvider).commit(submission);
      await container.read(courseRepositoryProvider).upsert(course('节次课程'));
      final notifier = container.read(sectionTimesProvider.notifier);
      late String expectedRange;
      if (change == '顺延') {
        await notifier.shiftFromFirstStart('08:30');
        expectedRange = '08:30-10:10';
      } else if (change == '模板') {
        await notifier.applyTemplate(sectionTimeTemplates[1]);
        expectedRange = '08:00-11:15';
      } else {
        await notifier.shiftFromFirstStart('09:00');
        await notifier.resetToDefault();
        expectedRange = '08:00-09:40';
      }
      await container.read(widgetServiceProvider).updateTodayWidget();
      final items = jsonDecode(saved['courses'] as String) as List;
      expect(
        {for (final item in items) item['name']: item['time']},
        {'教务快照': '08:00-09:40', '节次课程': expectedRange},
      );
      final stored = await container
          .read(courseRepositoryProvider)
          .getCourse(submission.courses.single.id);
      expect(stored!.startTime, '08:00');
      expect(stored.endTime, '09:40');
    });
  }
}
