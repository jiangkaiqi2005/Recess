import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:recess/data/providers/database_providers.dart';

/// 数据导出服务：将全部学期 + 课程 + 课程平台导出为 JSON，并通过系统分享面板
/// 交给用户保存。JSON 内容由 [BackupRepository.exportJson] 生成。
class ExportService {
  final Ref _ref;
  ExportService(this._ref);

  /// 导出全部数据并弹出系统分享面板。返回分享的结果。
  Future<ShareResult> exportToJson() async {
    final json = await _ref.read(backupRepositoryProvider).exportJson();

    // 写到系统缓存目录，普通用户无法访问应用私有目录，必须交由系统分享面板
    // 转存（下载/云盘/微信等）。
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/recess_backup_$dateStr.json');
    await file.writeAsString(json);

    final xFile = XFile(file.path,
        mimeType: 'application/json', name: 'recess_backup_$dateStr.json');
    return Share.shareXFiles([xFile]);
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});
