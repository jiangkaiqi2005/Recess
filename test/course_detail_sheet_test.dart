import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/features/course/application/course_platforms_provider.dart';
import 'package:recess/features/schedule/presentation/course_detail_sheet.dart';
import 'package:recess/features/settings/domain/section_time.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const withPlatforms = Course(
    id: 'c1',
    semesterId: 's1',
    name: '操作系统',
    teacher: '何静媛',
    dayOfWeek: 2,
    startSection: 3,
    endSection: 4,
    weeks: [1, 2, 3],
    notes: '带电脑',
  );
  const withoutPlatforms = Course(
    id: 'c2',
    semesterId: 's1',
    name: '形势与政策',
    dayOfWeek: 2,
    startSection: 1,
    endSection: 2,
    weeks: [1],
  );

  Future<void> openSheet(WidgetTester tester, Course course,
      {Map<int, SectionTime> sectionTimes = const {}}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursePlatformsProvider.overrideWith((ref, key) {
            expect(key.semesterId, 's1');
            return Stream.value(
              key.courseName == '操作系统'
                  ? const [
                      CoursePlatform(
                        purpose: CoursePlatformPurpose.onlineCourse,
                        name: '学习通',
                        url: 'https://mooc1.chaoxing.com',
                      ),
                      CoursePlatform(
                        purpose: CoursePlatformPurpose.group,
                        name: 'QQ 群',
                      ),
                    ]
                  : const [],
            );
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCourseDetailSheet(context, course, sectionTimes),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  testWidgets('详情优先显示课程显式钟点，而不是冲突的全局节次钟点', (tester) async {
    await openSheet(tester,
      withoutPlatforms.copyWith(startTime: '08:30', endTime: '09:00'),
      sectionTimes: const {1: SectionTime('08:00', 45), 2: SectionTime('08:55', 45)},
    );
    expect(find.text('周二 第1-2节 (08:30-09:00)'), findsOneWidget);
  });

  for (final sample in [
    (start: '08:30', end: null, text: ' (08:30-09:40)'),
    (start: null, end: '09:00', text: ' (08:00-09:00)'),
    (start: null, end: null, text: ' (08:00-09:40)'),
    (start: '', end: null, text: ''),
    (start: null, end: '', text: ''),
    (start: '不是钟点', end: '09:00', text: ' (不是钟点-09:00)'),
  ]) {
    testWidgets('详情逐端来源及原有文字降级：${sample.start}/${sample.end}', (tester) async {
      await openSheet(tester,
        withoutPlatforms.copyWith(startTime: sample.start, endTime: sample.end),
        sectionTimes: const {1: SectionTime('08:00', 45), 2: SectionTime('08:55', 45)},
      );
      expect(find.text('周二 第1-2节${sample.text}'), findsOneWidget);
    });
  }

  testWidgets('详情无钟点时继续显示星期与节次', (tester) async {
    await openSheet(tester, withoutPlatforms);
    expect(find.text('周二 第1-2节'), findsOneWidget);
  });

  testWidgets('详情面板在周次和备注之间显示课程平台', (tester) async {
    await openSheet(tester, withPlatforms);

    expect(find.text('课程平台'), findsOneWidget);
    expect(find.text('网课 · 学习通'), findsOneWidget);
    expect(find.text('https://mooc1.chaoxing.com'), findsOneWidget);
    expect(find.text('课程群 · QQ 群'), findsOneWidget);
    expect(find.byIcon(Icons.smart_display_outlined), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    // 只有带链接的条目显示打开图标。
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);

    final weeksY = tester.getTopLeft(find.text('周次')).dy;
    final platformY = tester.getTopLeft(find.text('课程平台')).dy;
    final notesY = tester.getTopLeft(find.text('备注')).dy;
    expect(platformY, greaterThan(weeksY));
    expect(platformY, lessThan(notesY));
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有平台时显示弱化提示', (tester) async {
    await openSheet(tester, withoutPlatforms);

    expect(find.text('还没有填写，可在“编辑课程”里添加'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长按有链接的条目复制链接并提示', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await openSheet(tester, withPlatforms);
    await tester.longPress(find.text('网课 · 学习通'));
    await tester.pumpAndSettle();

    expect(copied, 'https://mooc1.chaoxing.com');
    // 提示显示在弹层自己的 Scaffold 里，而不是被弹层挡住的下层页面。
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('已复制链接'),
      ),
      findsOneWidget,
    );
    final snackBar = tester.getRect(find.byType(SnackBar));
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(snackBar.bottom, lessThanOrEqualTo(sheet.bottom));
    expect(snackBar.top, greaterThanOrEqualTo(sheet.top));
  });

  testWidgets('打开链接失败时在弹层上方提示', (tester) async {
    // 测试环境默认走 url_launcher 的 MethodChannel 实现，这里让它报告打开失败。
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    String? launched;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        launched = (call.arguments as Map)['url'] as String?;
        return false;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await openSheet(tester, withPlatforms);
    await tester.tap(find.text('网课 · 学习通'));
    await tester.pumpAndSettle();

    expect(launched, 'https://mooc1.chaoxing.com');
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('无法打开链接：https://mooc1.chaoxing.com'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('短内容的面板仍按内容高度显示，按钮可点', (tester) async {
    await openSheet(tester, withoutPlatforms);

    final sheet = tester.getRect(find.byType(BottomSheet));
    // 默认 800 高的测试窗口里，弹层上限为 9/16；内容较少时应明显更矮。
    expect(sheet.height, lessThan(800 * 9 / 16));
    // 铺在上层的透明 Scaffold 不拦截触摸。
    expect(find.text('编辑课程').hitTestable(), findsOneWidget);
    expect(find.text('复制课程').hitTestable(), findsOneWidget);
  });
}
