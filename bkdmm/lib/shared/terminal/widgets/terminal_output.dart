/// 终端输出显示组件
///
/// 显示终端输出行，支持 ANSI 渲染
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../models/terminal_state.dart';
import '../providers/terminal_provider.dart';
import '../../log_viewer/services/ansi_parser.dart';

/// 终端输出显示组件
class TerminalOutput extends ConsumerStatefulWidget {
  const TerminalOutput({super.key});

  @override
  ConsumerState<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends ConsumerState<TerminalOutput> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final lines = ref.watch(terminalLinesProvider);

    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });

    if (lines.isEmpty) {
      return _buildEmptyState(tdTheme);
    }

    return Container(
      color: const Color(0xFF1E1E1E), // 终端背景色
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          return _TerminalLineWidget(
            line: lines[index],
            tdTheme: tdTheme,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
    final state = ref.watch(terminalProvider);

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.terminal,
              size: 48,
              color: tdTheme.textColorSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              state.status == TerminalStatus.starting
                  ? '正在启动终端...'
                  : '终端已就绪',
              style: TextStyle(
                color: tdTheme.textColorSecondary,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单行终端输出组件
class _TerminalLineWidget extends StatelessWidget {
  final TerminalLine line;
  final TDThemeData tdTheme;

  const _TerminalLineWidget({
    required this.line,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    // 根据行类型选择样式
    TextStyle baseStyle;
    if (line.isCommand) {
      baseStyle = const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        color: Color(0xFF4EC9B0), // 命令颜色
      );
    } else if (line.isError) {
      baseStyle = const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        color: Color(0xFFFF6B6B), // 错误颜色
      );
    } else if (line.isSystem) {
      baseStyle = const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        color: Color(0xFF6A9955), // 系统消息颜色
      );
    } else {
      baseStyle = const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        color: Color(0xFFD4D4D4), // 普通输出颜色
      );
    }

    // 解析 ANSI 颜色
    final spans = AnsiParser.parse(line.rawText, baseStyle: baseStyle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: SelectableText.rich(
        TextSpan(children: spans, style: baseStyle),
      ),
    );
  }
}
