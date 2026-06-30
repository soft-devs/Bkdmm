/// 终端 Shell 主组件
///
/// 使用全局 TerminalService 管理 PTY 进程，Widget 只负责显示
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:xterm/xterm.dart';
import '../providers/terminal_service_provider.dart';

/// 终端 Shell 主组件
class TerminalShell extends ConsumerWidget {
  const TerminalShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final terminalState = ref.watch(terminalServiceProvider);
    final terminalService = ref.read(terminalServiceProvider.notifier);

    return Column(
      children: [
        // 工具栏
        _TerminalToolBar(
          tdTheme: tdTheme,
          isRunning: terminalState.isRunning,
          onClear: terminalService.clear,
          onRestart: terminalService.restart,
        ),

        // 分隔线
        Container(
          height: 1,
          color: tdTheme.componentBorderColor,
        ),

        // 终端视图
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E),
            child: TerminalView(
              terminalState.terminal,
              autofocus: true,
              hardwareKeyboardOnly: true,
              textStyle: const TerminalStyle(
                fontSize: 14,
              ),
              theme: const TerminalTheme(
                cursor: Color(0xFFD4D4D4),
                selection: Color(0xFF264F78),
                foreground: Color(0xFFD4D4D4),
                background: Color(0xFF1E1E1E),
                black: Color(0xFF000000),
                red: Color(0xFFCD3131),
                green: Color(0xFF0DBC79),
                yellow: Color(0xFFE5E510),
                blue: Color(0xFF2472C8),
                magenta: Color(0xFFBC3FBC),
                cyan: Color(0xFF11A8CD),
                white: Color(0xFFE5E5E5),
                brightBlack: Color(0xFF666666),
                brightRed: Color(0xFFF14C4C),
                brightGreen: Color(0xFF23D18B),
                brightYellow: Color(0xFFF5F543),
                brightBlue: Color(0xFF3B8EEA),
                brightMagenta: Color(0xFFD670D6),
                brightCyan: Color(0xFF29B8DB),
                brightWhite: Color(0xFFE5E5E5),
                searchHitBackground: Color(0xFF264F78),
                searchHitBackgroundCurrent: Color(0xFF264F78),
                searchHitForeground: Color(0xFFD4D4D4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 终端工具栏
class _TerminalToolBar extends StatelessWidget {
  final TDThemeData tdTheme;
  final bool isRunning;
  final VoidCallback onClear;
  final VoidCallback onRestart;

  const _TerminalToolBar({
    required this.tdTheme,
    required this.isRunning,
    required this.onClear,
    required this.onRestart,
  });

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
            onTap: onClear,
          ),

          // 重启按钮
          TDButton(
            icon: TDIcons.refresh,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: onRestart,
          ),

          const Spacer(),

          // 状态指示
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          TDText(
            Platform.isWindows ? 'CMD' : 'Bash',
            font: tdTheme.fontMarkExtraSmall,
            textColor: tdTheme.textColorSecondary,
          ),
        ],
      ),
    );
  }
}