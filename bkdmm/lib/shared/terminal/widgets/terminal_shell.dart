/// 终端 Shell 主组件
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'terminal_output.dart';
import '../providers/terminal_provider.dart';
import '../models/terminal_state.dart';

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
        Expanded(
          child: TerminalOutput(),
        ),

        // 分隔线
        Container(
          height: 1,
          color: tdTheme.componentBorderColor,
        ),

        // 命令输入
        _TerminalInput(tdTheme: tdTheme),
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

/// 终端命令输入组件
class _TerminalInput extends ConsumerStatefulWidget {
  final TDThemeData tdTheme;

  const _TerminalInput({required this.tdTheme});

  @override
  ConsumerState<_TerminalInput> createState() => _TerminalInputState();
}

class _TerminalInputState extends ConsumerState<_TerminalInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCommandSubmit(String value) {
    if (value.trim().isEmpty) return;

    ref.read(terminalProvider.notifier).executeCommand(value);
    _controller.clear();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final notifier = ref.read(terminalProvider.notifier);

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // 上键：导航到上一个命令
      notifier.navigateHistoryUp();
      _controller.text = ref.read(terminalProvider).currentInput;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // 下键：导航到下一个命令
      notifier.navigateHistoryDown();
      _controller.text = ref.read(terminalProvider).currentInput;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(terminalProvider);

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Row(
          children: [
            // 提示符
            Text(
              _getPrompt(state),
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 13,
                color: Color(0xFF4EC9B0),
              ),
            ),
            const SizedBox(width: 4),
            // 输入框
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: state.isRunning,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                  color: Color(0xFFD4D4D4),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                cursorColor: const Color(0xFFD4D4D4),
                onSubmitted: _handleCommandSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrompt(TerminalState state) {
    if (state.workingDirectory.isEmpty) {
      return '>';
    }
    // 显示简化的工作目录
    final parts = state.workingDirectory.split(RegExp(r'[/\\]'));
    final shortPath = parts.isNotEmpty ? parts.last : state.workingDirectory;
    return '$shortPath>';
  }
}
