import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:recess/features/notification/application/reminder_scheduler.dart';
import 'package:recess/features/schedule/domain/schedule_helpers.dart';
import 'package:recess/features/schedule/presentation/course_detail_sheet.dart';
import 'package:recess/features/schedule/presentation/schedule_screen.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  final today = DateTime.now();
  const days = ['一', '二', '三', '四', '五', '六', '日'];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
    await container
        .read(courseRepositoryProvider)
        .upsert(
          Course(
            id: 'c',
            semesterId: 's',
            name: '钟点对照课',
            dayOfWeek: today.weekday,
            startSection: 1,
            endSection: 2,
            weeks: const [1],
            startTime: '08:30',
            endTime: '09:00',
          ),
        );
    await container.read(sectionTimesProvider.notifier).setAllTimes(const {
      1: SectionTime('08:00', 45),
      2: SectionTime('08:55', 45),
    });
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  for (final entry in ['周视图', '今日课程', '搜索']) {
    testWidgets('$entry打开详情使用显式钟点，周视图刻度仍是全局节次', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // 等待真实数据库课程流后再操作公开页面。
      for (var i = 0; i < 30 && find.text('钟点对照课').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('08:00'), findsWidgets);
      expect(find.text('09:40'), findsWidgets);
      if (entry == '今日课程') {
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('今日课程'));
        await tester.pumpAndSettle();
        expect(find.text('08:30-09:00'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('钟点对照课'),
          ),
        );
      } else if (entry == '搜索') {
        await tester.tap(find.byTooltip('搜索课程'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '钟点对照');
        await tester.pumpAndSettle();
        await tester.tap(find.text('钟点对照课'));
      } else {
        await tester.tap(find.text('钟点对照课').hitTestable());
      }
      await tester.pumpAndSettle();
      expect(
        find.text('周${days[today.weekday - 1]} 第1-2节 (08:30-09:00)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['顺延', '模板', '重置']) {
    testWidgets('$change后详情、今日和提醒跟随节次，已存教务快照保持原值', (tester) async {
      final submission = ImportSubmission.webview(
        previewContext: WebviewPreviewContext.fromSemester(
          Semester(
            id: 's',
            name: '测试学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
          ),
        ),
        semesterId: 's',
        mode: ImportMode.replace,
        courses: [
          ImportCourse(
            name: '教务快照',
            dayOfWeek: 1,
            startSection: 1,
            endSection: 2,
            weeks: [1],
            source: 'webview',
          ),
        ],
        sectionTimes: container.read(sectionTimesProvider),
      );
      await tester.runAsync(() async {
        await container.read(importCommitProvider).commit(submission);
        await container
            .read(courseRepositoryProvider)
            .upsert(
              const Course(
                id: 'fallback',
                semesterId: 's',
                name: '节次课程',
                dayOfWeek: 1,
                startSection: 1,
                endSection: 2,
                weeks: [1],
              ),
            );
        final notifier = container.read(sectionTimesProvider.notifier);
        if (change == '顺延') {
          await notifier.shiftFromFirstStart('08:30');
        } else if (change == '模板') {
          await notifier.applyTemplate(sectionTimeTemplates[1]);
        } else {
          await notifier.shiftFromFirstStart('09:00');
          await notifier.resetToDefault();
        }
      });
      final courses =
          (await tester.runAsync(
            () => container.read(courseRepositoryProvider).getCourses('s'),
          ))!;
      final sections = container.read(sectionTimesProvider);
      final statuses = todayCourseSlots(
        courses: courses,
        currentWeek: 1,
        now: DateTime(2026, 9, 7, 9, 45),
        sectionTimes: sections,
      );
      expect(
        {for (final slot in statuses) slot.course.name: slot.status},
        {
          '教务快照': CourseStatus.done,
          '节次课程': change == '重置' ? CourseStatus.done : CourseStatus.ongoing,
        },
      );
      final reminders = computeReminders(
        courses: courses,
        semester: Semester(
          id: 's',
          name: '测试学期',
          startDate: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
        sectionTimes: sections,
        now: DateTime(2026, 9, 7, 7),
        leadMinutes: 10,
      );
      expect(
        {for (final r in reminders) r.title: r.trigger},
        {
          '教务快照': DateTime(2026, 9, 7, 7, 50),
          '节次课程':
              change == '顺延'
                  ? DateTime(2026, 9, 7, 8, 20)
                  : DateTime(2026, 9, 7, 7, 50),
        },
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => Column(
                      children: [
                        for (final course in courses)
                          TextButton(
                            onPressed:
                                () => showCourseDetailSheet(
                                  context,
                                  course,
                                  sections,
                                ),
                            child: Text(course.name),
                          ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('节次课程'));
      await tester.pumpAndSettle();
      final range =
          change == '顺延'
              ? '08:30-10:10'
              : change == '模板'
              ? '08:00-11:15'
              : '08:00-09:40';
      expect(find.text('周一 第1-2节 ($range)'), findsOneWidget);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('教务快照'));
      await tester.pumpAndSettle();
      expect(find.text('周一 第1-2节 (08:00-09:40)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
