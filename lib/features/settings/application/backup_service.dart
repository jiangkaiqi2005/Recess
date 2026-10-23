import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:recess/data/providers/database_providers.dart';
import 'package:recess/data/repositories/backup_repository.dart';
import 'package:recess/features/semester/application/semester_providers.dart';

/// 备份应用入口：导出文件交给系统分享，恢复完整提交后刷新课表状态。
class BackupService {
  final Ref _ref;
  BackupService(this._ref);

  Future<RestoreResult> restore(BackupFile backup) async {
    final result = await _ref
        .read(backupRepositoryProvider)
        .restoreBackup(backup);
    // 应用级监听继续负责小组件和提醒，页面无需维护缓存清单。
    _ref.invalidate(activeSemesterProvider);
    _ref.invalidate(scheduleCoursesProvider);
    _ref.invalidate(semestersProvider);
    return result;
  }

  /// 导出全部数据并弹出系统分享面板。返回分享的结果。
  Future<ShareResult> exportToJson() async {
    final bytes = await _ref.read(backupRepositoryProvider).exportBytes();

    // 写到系统缓存目录，普通用户无法访问应用私有目录，必须交由系统分享面板
    // 转存（下载/云盘/微信等）。
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/recess_backup_$dateStr.json');
    await file.writeAsBytes(bytes);

    final xFile = XFile(
      file.path,
      mimeType: 'application/json',
      name: 'recess_backup_$dateStr.json',
    );
    return Share.shareXFiles([xFile]);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
