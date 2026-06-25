/// 终端 Shell 主组件
///
/// 整合终端输出和工具栏
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'terminal_output.dart';
import '../providers/terminal_provider.dart';

/// 终端 Shell 主组件
class TerminalShell extends ConsumerWidget {
  const TerminalShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);

    return Column(
      children: [
        // 工具栏
        _TerminalToolBar(tdTheme: tdTheme),

        // 分隔线
        Container(
          height: 1,
          color: tdTheme.componentBorderColor,
        ),

        // 终端输出
        const Expanded(
          child: TerminalOutput(),
        ),
      ],
    );
  }
}

/// 终端工具栏
class _TerminalToolBar extends StatelessWidget {
  final TDThemeData tdTheme;

  const _TerminalToolBar({required this.tdTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: tdTheme.bgColorSecondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 清空按钮
          TDButton(
            icon: TDIcons.delete,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              // TODO: 实现清空终端
            },
          ),

          const Spacer(),

          // 状态指示
          TDText(
            'Bash',
            font: tdTheme.fontMarkExtraSmall,
            textColor: tdTheme.textColorSecondary,
          ),
        ],
      ),
    );
  }
}
