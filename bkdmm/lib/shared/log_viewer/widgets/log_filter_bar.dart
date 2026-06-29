/// 日志过滤工具栏
///
/// 提供日志级别过滤、搜索和操作按钮
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../providers/log_viewer_provider.dart';

/// 日志过滤工具栏
class LogFilterBar extends ConsumerWidget {
  const LogFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final state = ref.watch(logViewerProvider);
    final filter = state.filter;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 日志级别过滤按钮组
          _buildLevelFilterButtons(context, ref, filter, tdTheme),

          const SizedBox(width: 12),

          // 分隔线
          Container(
            width: 1,
            height: 20,
            color: tdTheme.componentBorderColor,
          ),

          const SizedBox(width: 12),

          // 搜索框
          Expanded(
            child: TDInput(
              size: TDInputSize.small,
              hintText: '搜索日志...',
              leftIcon: Icon(TDIcons.search, size: 16),
              onChanged: (text) {
                ref.read(logViewerProvider.notifier).setSearchText(text);
              },
            ),
          ),

          const SizedBox(width: 8),

          // 暂停/继续按钮
          TDButton(
            icon: state.isPaused ? TDIcons.play_circle : TDIcons.pause_circle,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: state.isPaused ? TDButtonTheme.primary : TDButtonTheme.defaultTheme,
            onTap: () => ref.read(logViewerProvider.notifier).togglePause(),
          ),

          // 清空按钮
          TDButton(
            icon: TDIcons.delete,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => _showClearConfirmDialog(context, ref),
          ),

          // 导出按钮
          TDButton(
            icon: TDIcons.download,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => _exportLogs(context, ref),
          ),
        ],
      ),
    );
  }

  /// 构建日志级别过滤按钮组
  Widget _buildLevelFilterButtons(
    BuildContext context,
    WidgetRef ref,
    LogFilter filter,
    TDThemeData tdTheme,
  ) {
    final levels = [
      (ConsoleLogLevel.trace, 'T'),
      (ConsoleLogLevel.debug, 'D'),
      (ConsoleLogLevel.info, 'I'),
      (ConsoleLogLevel.warning, 'W'),
      (ConsoleLogLevel.error, 'E'),
      (ConsoleLogLevel.fatal, 'F'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: levels.map((item) {
        final (level, label) = item;
        final isSelected = filter.levels.contains(level);

        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: GestureDetector(
            onTap: () => ref.read(logViewerProvider.notifier).toggleLevel(level),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? level.backgroundColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? level.color : tdTheme.componentBorderColor,
                ),
              ),
              child: Center(
                child: TDText(
                  label,
                  font: tdTheme.fontMarkExtraSmall,
                  textColor: isSelected ? level.color : tdTheme.textColorSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 显示清空确认对话框
  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('确定要清空所有日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(logViewerProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 导出日志
  void _exportLogs(BuildContext context, WidgetRef ref) {
    final logText = ref.read(logViewerProvider.notifier).exportLogs();

    // 复制到剪贴板
    Clipboard.setData(ClipboardData(text: logText));
    TDToast.showSuccess('日志已复制到剪贴板', context: context);
  }
}
