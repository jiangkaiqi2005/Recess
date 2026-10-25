import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:recess/features/import/domain/webview_course_parser.dart';
import 'package:recess/features/import/data/json_importer.dart';
import 'package:recess/features/notification/application/reminder_scheduler.dart';
import 'package:recess/features/schedule/domain/schedule_helpers.dart';
import 'package:recess/features/schedule/presentation/course_detail_sheet.dart';
import 'package:recess/features/schedule/presentation/schedule_screen.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/schedule/presentation/week_view.dart';
import 'package:recess/features/widget/application/widget_service.dart';
import 'package:recess/features/course/application/course_form_provider.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  final today = DateTime.now();
  const days = ['一', '二', '三', '四', '五', '六', '日'];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        widgetServiceProvider.overrideWith((ref) => WidgetService(ref, now: () => DateTime(2026, 10, 25, 12))),
      ],
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
            useExplicitTimes: true,
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

  for (final app in [null, 'recess']) {
    test('${app ?? '普通JSON'}明确空开始端导入后不回退或生成臆造提醒', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final saved = <String, Object?>{};
      const channel = MethodChannel('home_widget');
      const updates = MethodChannel('home_widget/updates');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'saveWidgetData') {
          final args = call.arguments as Map;
          saved[args['id'] as String] = args['data'];
        }
        return true;
      });
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        updates,
        (_) async => null,
      );
      addTearDown(() {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        binding.defaultBinaryMessenger.setMockMethodCallHandler(updates, null);
      });
      final semester = Semester(
        id: 's',
        name: '测试学期',
        startDate: DateTime(2026, 9, 7),
        totalWeeks: 18,
      );
      await container
          .read(semesterRepositoryProvider)
          .upsert(semester, activate: true);
      await container.read(sectionTimesProvider.notifier).setAllTimes(const {
        6: SectionTime('14:25', 45),
        9: SectionTime('17:20', 45),
      });
      final imported = JsonCourseImporter.parse(
        jsonEncode({
          if (app != null) 'app': app,
          'courses': [
            {
              'name': '明确空钟点',
              'dayOfWeek': 7,
              'startSection': 6,
              'endSection': 9,
              'weeks': [7],
              'useExplicitTimes': true,
              'startTime': '',
              'endTime': '19:45',
            },
          ],
        }),
      );
      await container
          .read(importCommitProvider)
          .commit(
            ImportSubmission.file(
              semesterId: 's',
              mode: ImportMode.replace,
              courses: imported.courses,
            ),
          );
      final courses = await container
          .read(courseRepositoryProvider)
          .getCourses('s');
      final times = container.read(sectionTimesProvider);
      expect(
        computeReminders(
          courses: courses,
          semester: semester,
          sectionTimes: times,
          now: DateTime(2026, 10, 25, 12),
          leadMinutes: 10,
        ),
        isEmpty,
      );
      expect(
        todayCourseSlots(
          courses: courses,
          currentWeek: 7,
          sectionTimes: times,
          now: DateTime(2026, 10, 25, 15),
        ).single.status,
        CourseStatus.upcoming,
      );
      await container.read(widgetServiceProvider).updateWidget();
      final payload =
          (jsonDecode(saved['occurrences'] as String) as List).single as Map;
      expect(payload['start'], '');
      expect(payload['end'], '2026-10-25T19:45');
    });
  }

  for (final order in ['导入前', '导入后']) {
    testWidgets('$order修改学校作息，第6–9节详情、今日、提醒和小组件一致', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final saved = <String, Object?>{};
      const channel = MethodChannel('home_widget');
      const updates = MethodChannel('home_widget/updates');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        updates,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          updates,
          null,
        ),
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'saveWidgetData') {
          final args = call.arguments as Map;
          saved[args['id'] as String] = args['data'];
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final sections = container.read(sectionTimesProvider.notifier);
      Future<void> setSchoolTimes() async {
        await sections.setSectionStart(6, '14:25');
        await sections.setSectionDuration(6, 45);
        await sections.setSectionStart(9, '17:20');
        await sections.setSectionDuration(9, 45);
      }

      await tester.runAsync(() async {
        await sections.resetToDefault();
        final semester = Semester(
          id: 's',
          name: '测试学期',
          startDate: DateTime(2026, 9, 7),
          totalWeeks: 18,
        );
        await container
            .read(semesterRepositoryProvider)
            .upsert(semester, activate: true);
        if (order == '导入前') await setSchoolTimes();
        final preview = previewWebviewCourses([
          {
            'name': '计算机网络',
            'teacher': '唐小丰、李双庆',
            'location': 'DS3304',
            'dayOfWeek': 7,
            'startSection': 6,
            'endSection': 9,
            'weeks': [7, 9, 11, 13],
          },
        ], WebviewPreviewContext.fromSemester(semester));
        await container
            .read(importCommitProvider)
            .commit(
              ImportSubmission.webview(
                semesterId: 's',
                mode: ImportMode.replace,
                courses: preview.courses,
                previewContext: preview.context,
              ),
            );
        if (order == '导入后') await setSchoolTimes();
      });
      final courses = (await tester.runAsync(
        () => container.read(courseRepositoryProvider).getCourses('s'),
      ))!;
      final times = container.read(sectionTimesProvider);
      for (final sample in [
        (hour: 14, minute: 24, status: CourseStatus.upcoming),
        (hour: 14, minute: 25, status: CourseStatus.ongoing),
        (hour: 18, minute: 5, status: CourseStatus.done),
      ]) {
        expect(
          todayCourseSlots(
            courses: courses,
            currentWeek: 7,
            now: DateTime(2026, 10, 25, sample.hour, sample.minute),
            sectionTimes: times,
          ).single.status,
          sample.status,
        );
      }
      expect(
        computeReminders(
          courses: courses,
          semester: Semester(
            id: 's',
            name: '测试学期',
            startDate: DateTime(2026, 9, 7),
            totalWeeks: 18,
          ),
          sectionTimes: times,
          now: DateTime(2026, 10, 25, 12),
          leadMinutes: 10,
        ).first.trigger,
        DateTime(2026, 10, 25, 14, 15),
      );
      await tester.runAsync(() async {
        final service = container.read(widgetServiceProvider);
        await service.updateWidget();
        await service.updateWidget();
      });
      final payload =
          (jsonDecode(saved['occurrences'] as String) as List).first as Map;
      expect(payload['date'], '2026-10-25');
      expect(payload['start'], '2026-10-25T14:25');
      expect(payload['end'], '2026-10-25T18:05');
      await tester.runAsync(
        () => container.read(activeSemesterProvider.future),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: WeekView(selectedWeek: 7)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 30 && find.byType(CourseCard).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byType(CourseCard));
      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();
      expect(find.text('周日 第6-9节 (14:25-18:05)'), findsOneWidget);
      expect(find.textContaining('14:55-19:45'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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

  for (final explicit in [false, true]) {
    for (final entry in ['编辑', '复制']) {
      testWidgets('$entry保存并重载后保留${explicit ? '独立钟点' : '跟随作息'}语义', (
        tester,
      ) async {
        final result = (await tester.runAsync(() async {
          final repo = container.read(courseRepositoryProvider);
          final original = (await repo.getCourse(
            'c',
          ))!.copyWith(useExplicitTimes: explicit);
          await repo.upsert(original);
          final initial = await container.read(
            courseInitialProvider(entry == '编辑' ? 'c' : 'copy:c').future,
          );
          final subscription = container.listen(courseFormProvider, (_, __) {});
          addTearDown(subscription.close);
          final form = container.read(courseFormProvider.notifier);
          form.init(initial);
          form.setStartSection(2);
          form.setEndSection(2);
          expect(await form.save(), true);
          return (await repo.getCourses(
            's',
          )).singleWhere((c) => c.name == initial.name);
        }))!;
        expect(result.useExplicitTimes, explicit);
        expect((result.startTime, result.endTime), ('08:30', '09:00'));
        expect(result.id.isNotEmpty, true);
        if (entry == '复制') expect(result.id, isNot('c'));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showCourseDetailSheet(
                      context,
                      result,
                      container.read(sectionTimesProvider),
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
        final range = explicit ? '08:30-09:00' : '08:55-09:40';
        expect(
          find.text('周${days[today.weekday - 1]} 第2-2节 ($range)'),
          findsOneWidget,
        );
      });
    }
  }

  for (final change in ['顺延', '模板', '重置']) {
    testWidgets('$change后教务课程的详情、今日和提醒一起跟随节次', (tester) async {
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
          '教务快照': change == '重置' ? CourseStatus.done : CourseStatus.ongoing,
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
          '教务快照':
              change == '顺延'
                  ? DateTime(2026, 9, 7, 8, 20)
                  : DateTime(2026, 9, 7, 7, 50),
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
      expect(find.text('周一 第1-2节 ($range)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
