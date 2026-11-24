import 'dart:convert';
import 'package:recess/core/models/semester.dart';
import 'package:recess/features/import/domain/webview_course_parser.dart';

void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }());
  final context = WebviewPreviewContext.fromSemester(
    Semester(
      id: 's',
      name: '学期',
      startDate: DateTime(2026, 9, 7),
      totalWeeks: 18,
    ),
  );
  Map<String, dynamic> course(Map<String, dynamic> change) => {
    'name': '  高 数  ',
    'dayOfWeek': 1,
    'startSection': 1,
    'endSection': 16,
    'weeks': [3, 1, 3, 2],
    ...change,
  };
  final preview = previewWebviewCourses(
    decodeWebviewExtractResult(
      jsonEncode(
        jsonEncode([
          course({}),
          course({'startSection': 17, 'endSection': 17}),
          course({'endSection': 17}),
          course({'startSection': 4, 'endSection': 3}),
          course({'name': ' '}),
          course({'weeks': []}),
          course({
            'weeks': [1, 2.5],
          }),
          course({
            'weeks': [0],
          }),
          course({
            'weeks': [-1],
          }),
          course({
            'weeks': ['1'],
          }),
          course({'dayOfWeek': 8}),
          course({'dayOfWeek': 0}),
          course({})..remove('dayOfWeek'),
          course({})..remove('startSection'),
          course({})..remove('endSection'),
          course({
            'weeks': [19],
          }),
          42,
        ]),
      ),
    ),
    context,
  );
  print(
    jsonEncode({
      'assertions': assertions,
      'accepted': preview.courses.length,
      'name': preview.courses.first.name,
      'weeks': preview.courses.first.weeks,
      'skipped': preview.skippedCount,
      'reasons': preview.skippedReasons,
      'conflicts': preview.weekConflicts.length,
      'canSubmit': preview.canSubmit,
    }),
  );
}
