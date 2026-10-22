import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/features/course/application/course_platforms_provider.dart';
import 'package:recess/features/schedule/presentation/course_detail_sheet.dart';
import 'package:recess/features/schedule/presentation/course_search_delegate.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

void main() {
  for (final sample in [
    (raw: 0xFFF08C7C, light: 0xFF4BA89A, dark: 0xFF298B7E),
    (raw: 0xFFE3753F, light: 0xFFE3753F, dark: 0xFFC3581D),
    (raw: 0x80123456, light: 0x80123456, dark: 0x80123456),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('搜索和详情色标一致：${sample.raw.toRadixString(16)} / $brightness', (
        tester,
      ) async {
        final course = Course(
          id: 'c1',
          semesterId: 's1',
          name: '操作系统',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [1],
          colorValue: sample.raw,
        );
        final expected = Color(
          brightness == Brightness.dark ? sample.dark : sample.light,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scheduleCoursesProvider.overrideWith(
                (ref) => Stream.value([course]),
              ),
              coursePlatformsProvider.overrideWith(
                (ref, key) => Stream.value([]),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    ref.watch(scheduleCoursesProvider);
                    return Column(
                      children: [
                        TextButton(
                          child: const Text('搜索'),
                          onPressed:
                              () => showSearch<Course?>(
                                context: context,
                                delegate: CourseSearchDelegate(ref),
                                query: '操作系统',
                              ),
                        ),
                        TextButton(
                          child: const Text('详情'),
                          onPressed:
                              () => showCourseDetailSheet(context, course, {}),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('搜索'));
        await tester.pumpAndSettle();
        final leading =
            tester.widget<ListTile>(find.byType(ListTile)).leading!
                as Container;
        expect((leading.decoration! as BoxDecoration).color, expected);
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('详情'));
        await tester.pumpAndSettle();
        final marker = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 16 &&
              widget.constraints?.maxHeight == 16 &&
              widget.decoration is BoxDecoration,
        );
        final detail = tester.widget<Container>(marker);
        expect((detail.decoration! as BoxDecoration).color, expected);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
