import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hormone/core/constants/app_constants.dart';
import 'package:hormone/core/models/course.dart';
import 'package:hormone/features/schedule/presentation/week_view.dart';

void main() {
  const course = Course(
    id: 'course-card-test',
    semesterId: 'semester',
    name: '云计算与大数据',
    teacher: '张老师',
    location: '前湖校区教一101',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 2,
    colorValue: 0xFF5B8DEF,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required Size size,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: const CourseCard(
                course: course,
                onTap: _noop,
                onLongPress: _noop,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('卡片是实色圆角色块，只显示课名和“@教室”，文字为白色', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester, size: const Size(42, 104));

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CourseCard),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, courseCardColor(const Color(0xFF5B8DEF),
        Brightness.light));
    expect(material.borderRadius, BorderRadius.circular(6));
    expect(material.shape, isNull);

    final text = tester.widget<Text>(find.byKey(const Key('course-card-text')));
    final span = text.textSpan! as TextSpan;
    expect(span.toPlainText(), '云计算与大数据\n@前湖校区教一101');
    expect(span.toPlainText(), isNot(contains('张老师')));
    expect(text.style?.color, Colors.white);
    expect(text.style?.fontWeight, FontWeight.w600);
    final location = span.children!.last as TextSpan;
    expect(location.style?.fontWeight, FontWeight.w500);
    expect(location.style?.color, Colors.white.withValues(alpha: 0.9));

    // 旧版的色条、教师行和独立教室区都已移除。
    expect(find.byKey(const Key('course-card-color-rail')), findsNothing);
    expect(find.byKey(const Key('course-card-teacher')), findsNothing);
    expect(find.byKey(const Key('course-card-location')), findsNothing);

    // 语义标签继续包含教师。
    expect(
      find.bySemanticsLabel('云计算与大数据，周一，第1到2节，前湖校区教一101，张老师'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('按卡片高度计算最大行数，矮卡片截断不溢出', (tester) async {
    await pumpCard(tester, size: const Size(42, 104));
    final tall = tester.widget<Text>(find.byKey(const Key('course-card-text')));

    await pumpCard(tester, size: const Size(42, 48));
    final short = tester.widget<Text>(find.byKey(const Key('course-card-text')));

    expect(short.maxLines, greaterThanOrEqualTo(1));
    expect(tall.maxLines, greaterThan(short.maxLines!));
    expect(tester.takeException(), isNull);
  });

  test('色板中每种颜色推导出的底色与白字对比度不低于 3:1（浅色与深色）', () {
    for (final value in AppConstants.coursePalette) {
      for (final brightness in Brightness.values) {
        final background = courseCardColor(Color(value), brightness);
        expect(
          _contrastRatio(Colors.white, background),
          greaterThanOrEqualTo(3.0),
          reason: '${value.toRadixString(16)} 在 $brightness 下白字对比度不足',
        );
      }
    }
  });

  test('底色保留色相，深色模式下更暗', () {
    const base = Color(0xFFF2A25C);
    final light = courseCardColor(base, Brightness.light);
    final dark = courseCardColor(base, Brightness.dark);

    final baseHsl = HSLColor.fromColor(base);
    expect(HSLColor.fromColor(light).hue, closeTo(baseHsl.hue, 1));
    expect(
      HSLColor.fromColor(dark).lightness,
      lessThan(HSLColor.fromColor(light).lightness),
    );
  });

  test('本身已足够深的颜色不再压暗', () {
    const deep = Color(0xFF1A237E);
    expect(
      courseCardColor(deep, Brightness.light).toARGB32(),
      deep.toARGB32(),
    );
  });
}

void _noop() {}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
