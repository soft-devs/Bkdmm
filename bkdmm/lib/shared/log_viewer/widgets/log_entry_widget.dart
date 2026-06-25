/// 单条日志组件
///
/// 显示一条日志，包含时间戳、级别标签和内容
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../models/log_entry.dart';

/// 单条日志渲染组件
class LogEntryWidget extends StatelessWidget {
  /// 日志条目数据
  final LogEntry entry;

  /// 行索引（用于交替背景色）
  final int index;

  /// TDesign 主题数据
  final TDThemeData tdTheme;

  const LogEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    // 交替背景色
    final backgroundColor = index % 2 == 0
        ? tdTheme.bgColorContainer
        : tdTheme.bgColorSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: tdTheme.componentBorderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间戳
          SizedBox(
            width: 90,
            child: TDText(
              entry.formattedTime,
              font: tdTheme.fontMarkExtraSmall,
              textColor: tdTheme.textColorSecondary,
            ),
          ),

          const SizedBox(width: 8),

          // 级别标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: entry.level.backgroundColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: TDText(
              entry.level.label,
              font: tdTheme.fontMarkExtraSmall,
              textColor: entry.level.color,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 8),

          // 图标
          TDText(
            entry.level.icon,
            font: tdTheme.fontBodySmall,
          ),

          const SizedBox(width: 4),

          // 日志内容（可选择复制）
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: entry.styledSpans,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                  color: tdTheme.textColorPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日志详情组件（用于展开显示错误详情）
class LogDetailWidget extends StatelessWidget {
  final LogEntry entry;
  final TDThemeData tdTheme;

  const LogDetailWidget({
    super.key,
    required this.entry,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border.all(color: tdTheme.componentBorderColor),
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间戳
          _buildDetailRow(
            '时间',
            entry.formattedFullTime,
            tdTheme.textColorSecondary,
          ),

          // 来源
          if (entry.source != null)
            _buildDetailRow(
              '来源',
              entry.source!,
              tdTheme.textColorSecondary,
            ),

          // 错误信息
          if (entry.error != null)
            _buildDetailRow(
              '错误',
              entry.error.toString(),
              tdTheme.errorNormalColor,
            ),

          // 堆栈跟踪（最多显示5行）
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 8),
            TDText(
              '堆栈跟踪:',
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.textColorSecondary,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tdTheme.bgColorContainer,
                borderRadius: BorderRadius.circular(tdTheme.radiusSmall),
              ),
              child: SelectableText(
                entry.stackTrace!.toString().split('\n').take(5).join('\n'),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  color: tdTheme.textColorSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TDText(
            '$label: ',
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
            fontWeight: FontWeight.w600,
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}