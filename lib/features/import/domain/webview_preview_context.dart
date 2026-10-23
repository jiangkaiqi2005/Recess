import 'package:recess/core/models/semester.dart';

/// 抓取、预览与提交共同使用的学期设置快照。
class WebviewPreviewContext {
  final String semesterId;
  final int totalWeeks;
  final DateTime startDate;

  WebviewPreviewContext.fromSemester(Semester semester)
    : semesterId = semester.id,
      totalWeeks = semester.totalWeeks,
      startDate = semester.startDate;

  bool matches(Semester? semester) =>
      semester != null &&
      semester.id == semesterId &&
      semester.totalWeeks == totalWeeks &&
      semester.startDate == startDate;
}
