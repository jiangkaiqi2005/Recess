import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/features/schedule/presentation/week_view.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('课表显示到最后一个设了时间的节次并可纵向滚动，星期栏保持固定', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final semester = Semester(
      id: 'semester',
      name: '测试学期',
      startDate: DateTime(2026, 8, 24),
      totalWeeks: 18,
    );
    const course = Course(
      id: 'course',
      semesterId: 'semester',
      name: '高等数学',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: [1],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSemesterProvider.overrideWith((ref) async => semester),
          scheduleCoursesProvider.overrideWith(
            (ref) => Stream.value(const [course]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeekView(selectedWeek: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollView = find.byKey(const Key('week-view-vertical-scroll'));
    final timeAxis = find.byKey(const Key('week-view-time-axis'));
    final section12 = find.byKey(const ValueKey('section-axis-12'));
    final mondayHeader = find.text('周一');
    expect(scrollView, findsOneWidget);
    expect(tester.getSize(timeAxis).width, 36);
    // 月份在时间轴那一格里水平居中。
    final monthLabel = find.byKey(const Key('week-view-month-label'));
    expect(tester.widget<Text>(monthLabel).data, '8月');
    expect(tester.getCenter(monthLabel).dx,
        moreOrLessEquals(tester.getCenter(timeAxis).dx, epsilon: 0.5));
    expect(section12, findsOneWidget);
    // 默认时间表只给 1-12 节设了时间，课程也都在 12 节以内。
    expect(find.byKey(const ValueKey('section-axis-13')), findsNothing);
    final scroll = tester.widget<SingleChildScrollView>(scrollView);
    expect(scroll.padding, const EdgeInsets.only(bottom: 24));

    final headerY = tester.getTopLeft(mondayHeader).dy;
    final sectionY = tester.getTopLeft(section12).dy;
    await tester.drag(scrollView, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(section12).dy, lessThan(sectionY));
    expect(tester.getTopLeft(mondayHeader).dy, headerY);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有课程晚于最后一个设了时间的节次时，显示到该课程结束', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final semester = Semester(
      id: 'semester',
      name: '测试学期',
      startDate: DateTime(2026, 8, 24),
      totalWeeks: 18,
    );
    const late = Course(
      id: 'late',
      semesterId: 'semester',
      name: '晚课',
      dayOfWeek: 2,
      startSection: 13,
      endSection: 14,
      // 不在第 1 周上，也照样决定节次数。
      weeks: [2],
    );
    const course = Course(
      id: 'course',
      semesterId: 'semester',
      name: '高等数学',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: [1],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSemesterProvider.overrideWith((ref) async => semester),
          scheduleCoursesProvider.overrideWith(
            (ref) => Stream.value(const [course, late]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeekView(selectedWeek: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('section-axis-14')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('week-view-vertical-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const ValueKey('section-axis-14')), findsOneWidget);
    expect(find.byKey(const ValueKey('section-axis-15')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
