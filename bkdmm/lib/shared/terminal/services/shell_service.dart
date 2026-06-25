/// Shell 进程管理服务
///
/// 使用 dart:io Process 启动和管理 Shell 进程
library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import '../models/terminal_state.dart';

/// Shell 进程管理服务
class ShellService {
  /// 当前进程
  Process? _process;

  /// 标准输入
  IOSink? _stdin;

  /// 标准输出订阅
  StreamSubscription<String>? _stdoutSubscription;

  /// 标准错误订阅
  StreamSubscription<String>? _stderrSubscription;

  /// 输出回调
  void Function(String line, bool isError)? onOutput;

  /// 进程退出回调
  void Function(int exitCode)? onExit;

  /// 当前工作目录
  String _workingDirectory;

  /// 当前 Shell 类型
  ShellType _shellType;

  /// 是否正在运行
  bool get isRunning => _process != null;

  /// 获取当前工作目录
  String get workingDirectory => _workingDirectory;

  /// 获取当前 Shell 类型
  ShellType get shellType => _shellType;

  /// 创建 Shell 服务
  ShellService({
    String? workingDirectory,
    ShellType shellType = ShellType.cmd,
  })  : _workingDirectory = workingDirectory ?? Directory.current.path,
        _shellType = shellType;

  /// 启动 Shell
  Future<bool> start() async {
    if (isRunning) {
      return true; // 已经在运行
    }

    try {
      // 启动进程
      _process = await Process.start(
        _shellType.executable,
        [],
        runInShell: true,
        environment: Platform.environment,
        workingDirectory: _workingDirectory,
      );

      _stdin = _process!.stdin;

      // 监听标准输出
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput?.call(line, false);
      });

      // 监听标准错误
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput?.call(line, true);
      });

      // 监听进程退出
      _process!.exitCode.then((code) {
        onExit?.call(code);
        _cleanup();
      });

      return true;
    } catch (e) {
      _cleanup();
      return false;
    }
  }

  /// 执行命令
  void execute(String command) {
    if (!isRunning || _stdin == null) {
      return;
    }

    // 写入命令
    _stdin!.writeln(command);
    _stdin!.flush();
  }

  /// 停止 Shell
  Future<void> stop() async {
    if (!isRunning) {
      return;
    }

    // 发送退出命令
    if (_shellType == ShellType.powershell) {
      _stdin?.writeln('exit');
    } else {
      _stdin?.writeln('exit');
    }

    await _stdin?.flush();

    // 等待进程退出
    await Future.delayed(const Duration(milliseconds: 500));

    // 强制终止
    _process?.kill(ProcessSignal.sigkill);

    _cleanup();
  }

  /// 切换 Shell 类型
  Future<bool> switchShell(ShellType newType) async {
    if (_shellType == newType && isRunning) {
      return true;
    }

    // 停止当前 Shell
    await stop();

    // 切换类型
    _shellType = newType;

    // 启动新 Shell
    return start();
  }

  /// 更改工作目录
  void changeDirectory(String newDirectory) {
    if (Directory(newDirectory).existsSync()) {
      _workingDirectory = newDirectory;
    }
  }

  /// 清理资源
  void _cleanup() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _stdin = null;
    _process = null;
    _stdoutSubscription = null;
    _stderrSubscription = null;
  }

  /// 销毁服务
  Future<void> dispose() async {
    await stop();
    onOutput = null;
    onExit = null;
  }
}
