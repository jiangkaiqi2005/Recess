import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/data/app_database.dart' as db;
import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/features/notification/application/notification_service.dart';
import 'package:recess/features/notification/application/reminder_settings_provider.dart';
import 'package:recess/features/settings/application/section_times_provider.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  test('作息变化后取消旧提醒并按学校开始时间重排，独立端点保持不变', () async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    final database = db.AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });
    final date = DateTime.now().add(const Duration(days: 1));
    final day = DateTime(date.year, date.month, date.day);
    await container
        .read(semesterRepositoryProvider)
        .upsert(
          Semester(id: 's', name: '提醒学期', startDate: day, totalWeeks: 1),
          activate: true,
        );
    const following = Course(
      id: 'follow',
      semesterId: 's',
      name: '教务课程',
      dayOfWeek: 1,
      startSection: 6,
      endSection: 9,
      weeks: [1],
      startTime: '14:55',
      endTime: '19:45',
    );
    await container
        .read(courseRepositoryProvider)
        .upsert(following.copyWith(dayOfWeek: day.weekday));
    await container
        .read(courseRepositoryProvider)
        .upsert(
          following.copyWith(
            id: 'file',
            name: '独立钟点课程',
            dayOfWeek: day.weekday,
            useExplicitTimes: true,
          ),
        );
    final settings = container.read(reminderSettingsProvider.notifier);
    await settings.setEnabled(true);
    await settings.setLeadMinutes(10);
    final sections = container.read(sectionTimesProvider.notifier);
    await sections.setSectionStart(6, '14:25');
    await sections.setSectionStart(9, '17:20');
    final service = container.read(notificationServiceProvider);
    await service.reschedule();
    DateTime scheduledInstant(Map args) {
      final clock = DateTime.parse('${args['scheduledDateTime']}Z');
      return tz.TZDateTime(
        tz.getLocation(args['timeZoneName'] as String),
        clock.year,
        clock.month,
        clock.day,
        clock.hour,
        clock.minute,
      ).toUtc();
    }

    Map<String, DateTime> scheduledTimes() => {
      for (final call in calls.where((c) => c.method == 'zonedSchedule'))
        (call.arguments as Map)['title'] as String: scheduledInstant(
          call.arguments as Map,
        ),
    };
    final first = scheduledTimes();
    expect(
      first['教务课程'],
      DateTime(day.year, day.month, day.day, 14, 15).toUtc(),
    );
    expect(
      first['独立钟点课程'],
      DateTime(day.year, day.month, day.day, 14, 45).toUtc(),
    );
    calls.clear();
    await sections.setSectionStart(6, '14:35');
    await service.reschedule();
    expect(calls.any((c) => c.method == 'cancelAll'), true);
    expect(
      scheduledTimes()['教务课程'],
      DateTime(day.year, day.month, day.day, 14, 25).toUtc(),
    );
    expect(
      scheduledTimes()['独立钟点课程'],
      DateTime(day.year, day.month, day.day, 14, 45).toUtc(),
    );
  });
}
