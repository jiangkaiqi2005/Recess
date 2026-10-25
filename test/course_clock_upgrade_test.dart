import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/notification/application/reminder_scheduler.dart';
import 'package:recess/features/schedule/presentation/course_detail_sheet.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';
import 'package:recess/features/widget/application/widget_service.dart';

void main() {
  testWidgets('真实版本2数据库升级与重启后自动跟随学校作息，原数据完整保留', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final directory = await tester.runAsync(
      () => Directory.systemTemp.createTemp('recess_clock_upgrade_'),
    );
    final file = File('${directory!.path}/recess.sqlite');
    final saved = <String, Object?>{};
    const channel = MethodChannel('home_widget');
    const updates = MethodChannel('home_widget/updates');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        saved[args['id'] as String] = args['data'];
      }
      return true;
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      updates,
      (_) async => null,
    );
    addTearDown(() async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        updates,
        null,
      );
      await tester.runAsync(() => directory.delete(recursive: true));
    });
    var database = db.AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('''
        CREATE TABLE courses (
          id TEXT NOT NULL PRIMARY KEY, semester_id TEXT NOT NULL,
          name TEXT NOT NULL, teacher TEXT, location TEXT,
          day_of_week INTEGER NOT NULL, start_section INTEGER NOT NULL,
          end_section INTEGER NOT NULL, start_time TEXT, end_time TEXT,
          weeks TEXT NOT NULL DEFAULT '', color_value INTEGER NOT NULL DEFAULT 4284190191,
          notes TEXT);
        CREATE TABLE semesters (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, start_date INTEGER NOT NULL,
          total_weeks INTEGER NOT NULL, current_week_override INTEGER,
          is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1)));
        CREATE TABLE course_platforms (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, semester_id TEXT NOT NULL,
          course_name TEXT NOT NULL, purpose TEXT NOT NULL, name TEXT NOT NULL,
          url TEXT, sort_order INTEGER NOT NULL);
      ''');
          raw.execute('INSERT INTO semesters VALUES (?, ?, ?, ?, ?, ?)', [
            's',
            '2026 秋',
            DateTime(2026, 9, 7).millisecondsSinceEpoch ~/ 1000,
            18,
            null,
            1,
          ]);
          raw.execute('''
        INSERT INTO courses VALUES
          ('network', 's', '计算机网络', '唐小丰、李双庆', 'DS3304', 7, 6, 9,
           '14:55', '19:45', '7,9,11,13', 2150818884, '保留备注'),
          ('old-file', 's', '旧文件课程', NULL, NULL, 7, 6, 9,
           '12:34', '13:45', '7', 4284190191, NULL);
        INSERT INTO course_platforms VALUES
          (1, 's', '计算机网络', 'online_course', '学习通', 'https://example.com/course', 0);
        PRAGMA user_version = 2;
      ''');
        },
      ),
    );
    for (final stage in ['首次升级', '重启']) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          widgetServiceProvider.overrideWith(
            (ref) => WidgetService(ref, now: () => DateTime(2026, 10, 25, 12)),
          ),
        ],
      );
      try {
        final courses =
            (await tester.runAsync(() async {
              final notifier = container.read(sectionTimesProvider.notifier);
              if (stage == '首次升级') {
                await notifier.setSectionStart(6, '14:25');
                await notifier.setSectionStart(9, '17:20');
              } else {
                // 等待持久化作息加载，不改变其内容。
                await notifier.setSectionDuration(6, 45);
              }
              return container.read(courseRepositoryProvider).getCourses('s');
            }))!;
        final network = courses.singleWhere((c) => c.id == 'network');
        expect(
          network,
          const Course(
            id: 'network',
            semesterId: 's',
            name: '计算机网络',
            teacher: '唐小丰、李双庆',
            location: 'DS3304',
            dayOfWeek: 7,
            startSection: 6,
            endSection: 9,
            startTime: '14:55',
            endTime: '19:45',
            weeks: [7, 9, 11, 13],
            colorValue: 2150818884,
            notes: '保留备注',
          ),
          reason: stage,
        );
        final oldFile = courses.singleWhere((c) => c.id == 'old-file');
        expect(
          (oldFile.startTime, oldFile.endTime, oldFile.useExplicitTimes),
          ('12:34', '13:45', false),
        );
        final platforms = await tester.runAsync(
          () => container
              .read(coursePlatformRepositoryProvider)
              .getPlatforms('s', '计算机网络'),
        );
        expect(platforms, const [
          CoursePlatform(
            purpose: CoursePlatformPurpose.onlineCourse,
            name: '学习通',
            url: 'https://example.com/course',
          ),
        ]);
        final semester =
            (await tester.runAsync(
              () =>
                  container
                      .read(semesterRepositoryProvider)
                      .getActiveSemester(),
            ))!;
        expect(
          (
            semester.id,
            semester.name,
            semester.startDate,
            semester.totalWeeks,
          ),
          ('s', '2026 秋', DateTime(2026, 9, 7), 18),
        );
        final times = container.read(sectionTimesProvider);
        final reminders = computeReminders(
          courses: courses,
          semester: semester,
          sectionTimes: times,
          now: DateTime(2026, 10, 25, 12),
          leadMinutes: 10,
        );
        expect(reminders.map((r) => r.trigger).toSet(), {
          DateTime(2026, 10, 25, 14, 15),
        });
        await tester.runAsync(
          () => container.read(widgetServiceProvider).updateWidget(),
        );
        final payload =
            (jsonDecode(saved['occurrences'] as String) as List).first as Map;
        expect(
          (payload['start'], payload['end']),
          ('2026-10-25T14:25', '2026-10-25T18:05'),
        );
        if (stage == '重启') {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder:
                        (context) => TextButton(
                          onPressed:
                              () => showCourseDetailSheet(
                                context,
                                network,
                                times,
                              ),
                          child: const Text('打开'),
                        ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('打开'));
          await tester.pumpAndSettle();
          expect(
            find.text('周日 第6-9节 (14:25-18:05)'),
            findsOneWidget,
            reason: stage,
          );
        }
      } finally {
        if (stage == '首次升级') {
          await tester.runAsync(() async {
            container.dispose();
            await database.close();
          });
        } else {
          addTearDown(() async {
            container.dispose();
            await database.close();
          });
        }
      }
      if (stage == '首次升级') database = db.AppDatabase(NativeDatabase(file));
    }
  });
}
