/// 日志查看器 Shell 主组件
///
/// 整合过滤栏、日志列表和状态栏
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'log_filter_bar.dart';
import 'log_list_view.dart';
import 'log_viewer_status_bar.dart';

/// 日志查看器 Shell 主组件
class LogViewerShell extends ConsumerWidget {
  const LogViewerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);

    return Column(
      children: [
        // 过滤工具栏
        const LogFilterBar(),

        // 分隔线
        Container(
          height: 1,
          color: tdTheme.componentBorderColor,
        ),

        // 日志列表
        const Expanded(
          child: LogListView(),
        ),

        // 状态栏
        const LogViewerStatusBar(),
      ],
    );
  }
}