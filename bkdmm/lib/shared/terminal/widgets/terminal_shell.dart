/// 终端 Shell 主组件
///
/// 使用 xterm + flutter_pty 实现嵌入式终端
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:xterm/xterm.dart';

/// 终端 Shell 主组件
class TerminalShell extends ConsumerStatefulWidget {
  const TerminalShell({super.key});

  @override
  ConsumerState<TerminalShell> createState() => _TerminalShellState();
}

class _TerminalShellState extends ConsumerState<TerminalShell> {
  late Terminal _terminal;
  Pty? _pty;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _startPty();
  }

  @override
  void dispose() {
    _stopPty();
    super.dispose();
  }

  Future<void> _startPty() async {
    try {
      // 获取 shell 可执行文件
      final shell = _getShell();

      // 创建 PTY
      _pty = Pty.start(
        shell,
        workingDirectory: Directory.current.path,
        environment: {
          ...Platform.environment,
          'TERM': 'xterm-256color',
          'LANG': 'en_US.UTF-8',
        },
        rows: 25,
        columns: 80,
      );

      setState(() {
        _isRunning = true;
      });

      // 监听 PTY 输出并写入终端
      _pty!.output
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen((data) {
        if (data.isNotEmpty) {
          _terminal.write(data);
        }
      });

      // 监听终端输入并发送到 PTY
      _terminal.onOutput = (data) {
        if (_pty != null) {
          _pty!.write(const Utf8Encoder().convert(data));
        }
      };

      // 监听终端大小变化
      _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        _pty?.resize(height, width);
      };

      // 监听进程退出
      _pty!.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _isRunning = false;
          });
          _terminal.write('\r\n[系统] 终端已退出 (退出码: $code)\r\n');
        }
      });
    } catch (e) {
      _terminal.write('\r\n[错误] 启动终端失败: $e\r\n');
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _stopPty() {
    if (_pty != null) {
      _pty!.kill(ProcessSignal.sigterm);
      _pty = null;
    }
    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  String _getShell() {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL'] ?? 'bash';
    }
    if (Platform.isWindows) {
      return 'cmd.exe';
    }
    return 'sh';
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Column(
      children: [
        // 工具栏
        _TerminalToolBar(
          tdTheme: tdTheme,
          isRunning: _isRunning,
          onClear: () {
            _terminal.buffer.eraseDisplay();
          },
          onRestart: () async {
            _stopPty();
            _terminal.buffer.eraseDisplay();
            await _startPty();
          },
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
              _terminal,
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
