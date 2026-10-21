import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hormone/core/models/course.dart';
import 'package:hormone/core/models/course_platform.dart';
import 'package:hormone/features/course/application/course_platforms_provider.dart';
import 'package:hormone/features/schedule/presentation/course_detail_sheet.dart';

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

  Future<void> openSheet(WidgetTester tester, Course course) async {
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
                onPressed: () => showCourseDetailSheet(context, course, {}),
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
    expect(find.text('已复制链接'), findsOneWidget);
  });
}
