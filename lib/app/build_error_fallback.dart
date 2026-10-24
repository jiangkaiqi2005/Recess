import 'package:flutter/material.dart';

import 'package:recess/app/router.dart' show rootNavigatorKey;

/// 界面构建失败的统一兜底入口，安装为应用根部的 [ErrorWidget.builder]。
///
/// 异常本身仍经过 Flutter 原有错误报告通道（builder 只接管出错位置的
/// 显示，不吞掉诊断）。按实际布局约束选择表现：空间充足时给出完整说明
/// 和「返回上一页」入口；空间受限（如周视图单节课程卡，约 46x52 逻辑
/// 像素）时退化为单行紧凑提示，不硬塞图标、说明或按钮，也不挤压周围
/// 正常内容。
Widget buildErrorFallback(FlutterErrorDetails details) {
  return const _BuildErrorFallback();
}

class _BuildErrorFallback extends StatelessWidget {
  const _BuildErrorFallback();

  /// 完整说明（图标 + 标题 + 恢复说明 + 按钮）所需的最小空间。
  static const double _fullMinWidth = 220;
  static const double _fullMinHeight = 180;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy =
            constraints.maxWidth >= _fullMinWidth &&
            constraints.maxHeight >= _fullMinHeight;
        return roomy ? const _FullErrorView() : const _CompactErrorView();
      },
    );
  }
}

/// 完整兜底：错误图标、标题「页面暂时无法显示」与恢复说明。
///
/// 仅当 Navigator 存在且确实可以返回时才显示「返回上一页」按钮；全局
/// 构建失败时 Navigator 未必已挂载，因此先从自身上下文取，取不到再退
/// 回应用根 Navigator，仍没有就视为无上一页，提示重新打开应用。
class _FullErrorView extends StatelessWidget {
  const _FullErrorView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigator =
        Navigator.maybeOf(context) ?? rootNavigatorKey.currentState;
    final canGoBack = navigator != null && navigator.canPop();

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                '页面暂时无法显示',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                canGoBack ? '返回上一页后重试' : '请重新打开应用',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (canGoBack) ...[
                const SizedBox(height: 16),
                FilledButton(
                  // 只退出当前失败页面，不重建、刷新或清空返回后的页面。
                  onPressed: navigator.pop,
                  child: const Text('返回上一页'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 紧凑兜底：受限空间里只显示单行「暂时无法显示」。
class _CompactErrorView extends StatelessWidget {
  const _CompactErrorView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '暂时无法显示',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
