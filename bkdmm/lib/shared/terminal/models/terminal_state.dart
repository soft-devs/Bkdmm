/// 终端状态模型
///
/// 定义终端的状态和输出行
library;

/// Shell 类型
enum ShellType {
  cmd('CMD', 'cmd.exe'),
  powershell('PowerShell', 'powershell.exe');

  final String label;
  final String executable;

  const ShellType(this.label, this.executable);
}

/// 终端运行状态
enum TerminalStatus {
  /// 未启动
  idle,

  /// 正在启动
  starting,

  /// 运行中
  running,

  /// 正在停止
  stopping,

  /// 已停止
  stopped,

  /// 错误
  error,
}

/// 终端输出行
class TerminalLine {
  /// 唯一标识
  final String id;

  /// 原始文本内容（可能包含 ANSI 码）
  final String rawText;

  /// 行类型
  final TerminalLineType type;

  /// 时间戳
  final DateTime timestamp;

  const TerminalLine({
    required this.id,
    required this.rawText,
    this.type = TerminalLineType.output,
    required this.timestamp,
  });

  /// 是否是命令行
  bool get isCommand => type == TerminalLineType.command;

  /// 是否是错误行
  bool get isError => type == TerminalLineType.error;

  /// 是否是系统消息
  bool get isSystem => type == TerminalLineType.system;
}

/// 终端行类型
enum TerminalLineType {
  /// 用户输入的命令
  command,

  /// 标准输出
  output,

  /// 错误输出
  error,

  /// 系统消息
  system,
}

/// 终端状态
class TerminalState {
  /// 输出行列表
  final List<TerminalLine> lines;

  /// 当前 Shell 类型
  final ShellType shellType;

  /// 运行状态
  final TerminalStatus status;

  /// 当前工作目录
  final String workingDirectory;

  /// 错误消息
  final String? errorMessage;

  /// 命令历史
  final List<String> commandHistory;

  /// 当前输入的命令
  final String currentInput;

  /// 历史索引（用于上下键导航）
  final int historyIndex;

  const TerminalState({
    this.lines = const [],
    this.shellType = ShellType.cmd,
    this.status = TerminalStatus.idle,
    this.workingDirectory = '',
    this.errorMessage,
    this.commandHistory = const [],
    this.currentInput = '',
    this.historyIndex = -1,
  });

  /// 是否正在运行
  bool get isRunning => status == TerminalStatus.running;

  /// 是否已启动
  bool get isStarted => status != TerminalStatus.idle;

  /// 复制并修改状态
  TerminalState copyWith({
    List<TerminalLine>? lines,
    ShellType? shellType,
    TerminalStatus? status,
    String? workingDirectory,
    String? errorMessage,
    List<String>? commandHistory,
    String? currentInput,
    int? historyIndex,
    bool clearError = false,
  }) {
    return TerminalState(
      lines: lines ?? this.lines,
      shellType: shellType ?? this.shellType,
      status: status ?? this.status,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      commandHistory: commandHistory ?? this.commandHistory,
      currentInput: currentInput ?? this.currentInput,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  @override
  String toString() {
    return 'TerminalState(status: $status, lines: ${lines.length}, wd: $workingDirectory)';
  }
}
