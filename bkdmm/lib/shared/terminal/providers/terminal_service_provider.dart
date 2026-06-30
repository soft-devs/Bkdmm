/// 全局终端服务
///
/// 管理 PTY 进程，独立于 Widget 生命周期
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

/// 终端服务状态
class TerminalServiceState {
  /// Terminal 实例（用于显示）
  final Terminal terminal;

  /// PTY 进程
  final Pty? pty;

  /// 是否运行中
  final bool isRunning;

  /// 错误消息
  final String? errorMessage;

  const TerminalServiceState({
    required this.terminal,
    this.pty,
    this.isRunning = false,
    this.errorMessage,
  });

  TerminalServiceState copyWith({
    Pty? pty,
    bool? isRunning,
    String? errorMessage,
    bool clearError = false,
    bool clearPty = false,
  }) {
    return TerminalServiceState(
      terminal: terminal,
      pty: clearPty ? null : (pty ?? this.pty),
      isRunning: isRunning ?? this.isRunning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 全局终端服务管理器
class TerminalService extends StateNotifier<TerminalServiceState> {
  TerminalService() : super(TerminalServiceState(terminal: Terminal(maxLines: 10000))) {
    _startPty();
  }

  /// 启动 PTY
  Future<void> _startPty() async {
    try {
      final shell = _getShell();

      final pty = Pty.start(
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

      state = state.copyWith(pty: pty, isRunning: true, clearError: true);

      // 监听 PTY 输出
      pty.output.cast<List<int>>().transform(const Utf8Decoder()).listen((data) {
        if (data.isNotEmpty) {
          state.terminal.write(data);
        }
      });

      // 监听终端输入
      state.terminal.onOutput = (data) {
        if (state.pty != null) {
          state.pty!.write(const Utf8Encoder().convert(data));
        }
      };

      // 监听大小变化
      state.terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        state.pty?.resize(height, width);
      };

      // 监听退出
      pty.exitCode.then((code) {
        if (!mounted) return;
        state = state.copyWith(isRunning: false, clearPty: true);
        state.terminal.write('\r\n[系统] 终端已退出 (退出码: $code)\r\n');
      });
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: e.toString(),
      );
      state.terminal.write('\r\n[错误] 启动终端失败: $e\r\n');
    }
  }

  /// 重启终端
  Future<void> restart() async {
    _stopPty();
    state.terminal.buffer.eraseDisplay();
    await _startPty();
  }

  /// 清空显示
  void clear() {
    state.terminal.buffer.eraseDisplay();
  }

  /// 停止 PTY
  void _stopPty() {
    if (state.pty != null) {
      state.pty!.kill(ProcessSignal.sigterm);
      state = state.copyWith(isRunning: false, clearPty: true);
    }
  }

  /// 获取 shell 可执行文件
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
  void dispose() {
    _stopPty();
    super.dispose();
  }
}

/// 全局终端服务 Provider
///
/// 使用 keepAlive 保持状态，不随 Widget 销毁
final terminalServiceProvider = StateNotifierProvider<TerminalService, TerminalServiceState>(
  (ref) => TerminalService(),
);