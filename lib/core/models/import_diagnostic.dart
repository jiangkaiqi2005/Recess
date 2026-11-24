/// 文件导入诊断的类别：区分「整条记录被跳过」与「记录保留但部分信息被忽略」。
enum ImportDiagnosticKind {
  /// 整条记录未导入。
  skipped,

  /// 记录已保留，但部分信息（如平台链接）被忽略。
  partial,
}

/// 一条文件导入诊断：哪条源记录、发生了什么。文案统一以「记录」称呼源条目，
/// 不把所有诊断都称为课程（见 GLOSSARY.md 的用语约定）。
class ImportDiagnostic {
  final ImportDiagnosticKind kind;

  /// 源记录标识，如「第2条」「课程平台「高数」第1条」。
  final String record;

  /// 该记录被跳过或部分忽略的原因。
  final String reason;

  const ImportDiagnostic({
    required this.kind,
    required this.record,
    required this.reason,
  });

  String get message => '$record：$reason';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportDiagnostic &&
          kind == other.kind &&
          record == other.record &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(kind, record, reason);

  @override
  String toString() => message;
}
