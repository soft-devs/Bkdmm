/// 日志查看器状态栏
///
/// 显示日志统计信息
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../providers/log_viewer_provider.dart';

/// 日志查看器状态栏
class LogViewerStatusBar extends ConsumerWidget {
  const LogViewerStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final state = ref.watch(logViewerProvider);
    final stats = state.stats;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(
          top: BorderSide(color: tdTheme.componentBorderColor),
        ),
      ),
      child: Row(
        children: [
          // 总数
          TDText(
            '共 ${state.totalCount} 条',
            font: tdTheme.fontMarkExtraSmall,
            textColor: tdTheme.textColorSecondary,
          ),

          const SizedBox(width: 8),

          // 过滤后数量
          if (state.filter != const LogFilter())
            TDText(
              '已过滤: ${state.filteredCount} 条',
              font: tdTheme.fontMarkExtraSmall,
              textColor: tdTheme.brandNormalColor,
            ),

          const Spacer(),

          // 各级别统计
          _buildLevelStats(stats, tdTheme),
        ],
      ),
    );
  }

  Widget _buildLevelStats(LogStats stats, TDThemeData tdTheme) {
    final levels = [
      ConsoleLogLevel.error,
      ConsoleLogLevel.warning,
      ConsoleLogLevel.info,
      ConsoleLogLevel.debug,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: levels.map((level) {
        final count = stats.count(level);
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getLevelIcon(level),
                size: 12,
                color: level.color,
              ),
              const SizedBox(width: 2),
              TDText(
                '$count',
                font: tdTheme.fontMarkExtraSmall,
                textColor: level.color,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getLevelIcon(ConsoleLogLevel level) {
    switch (level) {
      case ConsoleLogLevel.error:
        return TDIcons.close_circle;
      case ConsoleLogLevel.warning:
        return TDIcons.info_circle;
      case ConsoleLogLevel.info:
        return TDIcons.check_circle;
      case ConsoleLogLevel.debug:
        return TDIcons.search;
      default:
        return TDIcons.circle;
    }
  }
}