import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/full_week_course.dart';
import 'package:recess/core/models/semester.dart';
import 'package:recess/features/schedule/presentation/week_view.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final semester = Semester(
    id: 'semester',
    name: '测试学期',
    startDate: DateTime(2026, 8, 31),
    totalWeeks: 20,
  );
  const fullWeek = [
    FullWeekCourse(
      id: 'os',
      semesterId: 'semester',
      name: '操作系统课程设计',
      weeks: [17],
    ),
    FullWeekCourse(
      id: 'net',
      semesterId: 'semester',
      name: '计算机网络课程设计',
      weeks: [17],
    ),
  ];
  const lecture = Course(
    id: 'lecture',
    semesterId: 'semester',
    name: '边缘计算',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    weeks: [14],
  );

  Future<void> pumpWeek(WidgetTester tester, int week) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSemesterProvider.overrideWith((ref) async => semester),
          scheduleCoursesProvider.overrideWith(
            (ref) => Stream.value(const [lecture]),
          ),
          scheduleFullWeekCoursesProvider.overrideWith(
            (ref) => Stream.value(fullWeek),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: WeekView(selectedWeek: week)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('只有整周课的周显示全天行，不再显示「本周暂无课程」', (tester) async {
    await pumpWeek(tester, 17);

    expect(find.byKey(const Key('week-view-all-day-row')), findsOneWidget);
    expect(find.text('操作系统课程设计 · 整周'), findsOneWidget);
    expect(find.text('计算机网络课程设计 · 整周'), findsOneWidget);
    expect(find.text('本周暂无课程'), findsNothing);
    expect(find.text('本周没有按节次安排的课程'), findsOneWidget);

    await tester.tap(find.text('操作系统课程设计 · 整周'));
    await tester.pumpAndSettle();
    expect(find.text('整周，教务系统没有给出具体星期和节次'), findsOneWidget);
    expect(find.text('17'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '编辑课程'), findsOneWidget);
  });

  testWidgets('不在整周课周次内时没有全天行', (tester) async {
    await pumpWeek(tester, 14);

    expect(find.byKey(const Key('week-view-all-day-row')), findsNothing);
    expect(find.textContaining('边缘计算'), findsOneWidget);
  });
}
