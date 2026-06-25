/// 终端状态管理
///
/// 使用 Riverpod 管理终端状态
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/terminal_state.dart';
import '../models/command_history.dart';
import '../services/shell_service.dart';
import '../../log_viewer/services/log_buffer.dart';

/// 终端状态管理器
class TerminalNotifier extends StateNotifier<TerminalState> {
  /// Shell 服务
  final ShellService _shellService;

  /// 命令历史
  final CommandHistory _commandHistory;

  /// 输出缓冲区
  final LogBuffer<TerminalLine> _outputBuffer;

  /// 最大输出行数
  final int maxLines;

  /// 创建终端状态管理器
  TerminalNotifier({
    this.maxLines = 500,
  })  : _shellService = ShellService(),
        _commandHistory = CommandHistory(),
        _outputBuffer = LogBuffer<TerminalLine>(maxLines),
        super(const TerminalState()) {
    // 设置输出回调
    _shellService.onOutput = _handleOutput;
    _shellService.onExit = _handleExit;
  }

  /// 启动终端
  Future<void> start() async {
    state = state.copyWith(
      status: TerminalStatus.starting,
      clearError: true,
    );

    // 添加启动消息
    _addSystemLine('正在启动 ${state.shellType.label}...');

    // 更新工作目录
    _shellService.changeDirectory(state.workingDirectory);

    final success = await _shellService.start();

    if (success) {
      state = state.copyWith(
        status: TerminalStatus.running,
        workingDirectory: _shellService.workingDirectory,
      );

      _addSystemLine('${state.shellType.label} 已启动');
      _addSystemLine('工作目录: ${state.workingDirectory}');
    } else {
      state = state.copyWith(
        status: TerminalStatus.error,
        errorMessage: '启动 Shell 失败',
      );

      _addSystemLine('启动失败', isError: true);
    }
  }

  /// 停止终端
  Future<void> stop() async {
    if (!state.isRunning) return;

    state = state.copyWith(status: TerminalStatus.stopping);

    _addSystemLine('正在停止终端...');

    await _shellService.stop();

    state = state.copyWith(status: TerminalStatus.stopped);
  }

  /// 切换 Shell 类型
  Future<void> switchShell(ShellType newType) async {
    if (state.shellType == newType && state.isRunning) return;

    _addSystemLine('切换到 ${newType.label}...');

    // 停止当前 Shell
    await _shellService.stop();

    // 更新状态
    state = state.copyWith(
      shellType: newType,
      status: TerminalStatus.idle,
    );

    // 启动新 Shell
    await start();
  }

  /// 执行命令
  void executeCommand(String command) {
    if (!state.isRunning || command.trim().isEmpty) return;

    // 添加命令行到输出
    _addCommandLine(command);

    // 添加到历史
    _commandHistory.add(command);
    state = state.copyWith(
      commandHistory: _commandHistory.history,
      currentInput: '',
      historyIndex: -1,
    );

    // 执行命令
    _shellService.execute(command);
  }

  /// 更新当前输入
  void updateInput(String input) {
    state = state.copyWith(currentInput: input);
  }

  /// 导航到上一个命令（上键）
  void navigateHistoryUp() {
    final history = state.commandHistory;
    if (history.isEmpty) return;

    int newIndex = state.historyIndex;
    if (newIndex < 0) {
      newIndex = history.length - 1;
    } else if (newIndex > 0) {
      newIndex--;
    }

    state = state.copyWith(
      currentInput: history[newIndex],
      historyIndex: newIndex,
    );
  }

  /// 导航到下一个命令（下键）
  void navigateHistoryDown() {
    final history = state.commandHistory;
    if (history.isEmpty || state.historyIndex < 0) return;

    int newIndex = state.historyIndex;
    if (newIndex < history.length - 1) {
      newIndex++;
      state = state.copyWith(
        currentInput: history[newIndex],
        historyIndex: newIndex,
      );
    } else {
      // 到达底部，清空输入
      state = state.copyWith(
        currentInput: '',
        historyIndex: -1,
      );
    }
  }

  /// 清空输出
  void clearOutput() {
    _outputBuffer.clear();
    state = state.copyWith(lines: []);
  }

  /// 清空历史
  void clearHistory() {
    _commandHistory.clear();
    state = state.copyWith(commandHistory: []);
  }

  /// 设置工作目录
  void setWorkingDirectory(String directory) {
    if (Directory(directory).existsSync()) {
      state = state.copyWith(workingDirectory: directory);
      _shellService.changeDirectory(directory);
    }
  }

  /// 处理 Shell 输出
  void _handleOutput(String line, bool isError) {
    _addOutputLine(line, isError: isError);
  }

  /// 处理 Shell 退出
  void _handleExit(int exitCode) {
    state = state.copyWith(status: TerminalStatus.stopped);
    _addSystemLine('终端已退出 (退出码: $exitCode)');
  }

  /// 添加输出行
  void _addOutputLine(String text, {bool isError = false}) {
    final line = TerminalLine(
      id: '${DateTime.now().millisecondsSinceEpoch}_${text.hashCode}',
      rawText: text,
      type: isError ? TerminalLineType.error : TerminalLineType.output,
      timestamp: DateTime.now(),
    );

    _outputBuffer.add(line);
    state = state.copyWith(lines: _outputBuffer.getAll());
  }

  /// 添加命令行
  void _addCommandLine(String command) {
    final prompt = _shellService.shellType == ShellType.powershell
        ? 'PS ${state.workingDirectory}> '
        : '${state.workingDirectory}> ';

    final line = TerminalLine(
      id: '${DateTime.now().millisecondsSinceEpoch}_${command.hashCode}',
      rawText: '$prompt$command',
      type: TerminalLineType.command,
      timestamp: DateTime.now(),
    );

    _outputBuffer.add(line);
    state = state.copyWith(lines: _outputBuffer.getAll());
  }

  /// 添加系统消息行
  void _addSystemLine(String message, {bool isError = false}) {
    final line = TerminalLine(
      id: '${DateTime.now().millisecondsSinceEpoch}_${message.hashCode}',
      rawText: '[系统] $message',
      type: isError ? TerminalLineType.error : TerminalLineType.system,
      timestamp: DateTime.now(),
    );

    _outputBuffer.add(line);
    state = state.copyWith(lines: _outputBuffer.getAll());
  }

  /// 销毁资源
  @override
  void dispose() {
    _shellService.dispose();
    super.dispose();
  }
}

/// 终端 Provider
final terminalProvider =
    StateNotifierProvider.autoDispose<TerminalNotifier, TerminalState>((ref) {
  final notifier = TerminalNotifier();

  // 启动终端
  notifier.start();

  // 在销毁时停止终端
  ref.onDispose(() {
    notifier.stop();
  });

  return notifier;
});

/// 便捷访问：终端是否运行
final terminalIsRunningProvider = Provider<bool>((ref) {
  return ref.watch(terminalProvider).isRunning;
});

/// 便捷访问：终端输出行
final terminalLinesProvider = Provider<List<TerminalLine>>((ref) {
  return ref.watch(terminalProvider).lines;
});

/// 便捷访问：命令历史
final terminalHistoryProvider = Provider<List<String>>((ref) {
  return ref.watch(terminalProvider).commandHistory;
});