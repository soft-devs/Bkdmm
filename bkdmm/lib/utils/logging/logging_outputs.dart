/// 自定义日志输出器
///
/// 提供控制台和文件输出功能
library;

import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/log_viewer/models/log_entry.dart';

/// 日志级别颜色映射 (ANSI 颜色码)
class LogColors {
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String bgRed = '\x1B[41m';
  static const String bgYellow = '\x1B[43m';

  /// 获取日志级别对应的颜色
  static String forLevel(Level level) {
    switch (level) {
      case Level.trace:
        return cyan;
      case Level.debug:
        return blue;
      case Level.info:
        return green;
      case Level.warning:
        return yellow;
      case Level.error:
        return red;
      case Level.fatal:
        return bgRed;
      default:
        return white;
    }
  }

  /// 获取日志级别对应的图标
  static String iconForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return '📝';
      case Level.debug:
        return '🔍';
      case Level.info:
        return '🚀';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      default:
        return '•';
    }
  }
}

/// 开发环境控制台输出器
///
/// 带颜色和图标的彩色输出
class DevPrinter extends LogPrinter {
  final int methodCount;
  final bool printStackTrace;

  DevPrinter({
    this.methodCount = 5,
    this.printStackTrace = true,
  });

  @override
  List<String> log(LogEvent event) {
    final color = LogColors.forLevel(event.level);
    final icon = LogColors.iconForLevel(event.level);
    final timestamp = _formatTime(event.time);
    final levelStr = event.level.name.toUpperCase().padRight(5);

    final lines = <String>[];

    // 主日志行
    final message = event.message.toString();
    lines.add('$color$timestamp $levelStr $icon ${LogColors.reset}$message');

    // 错误信息
    if (event.error != null) {
      lines.add('${LogColors.red}├─ Error: ${event.error}${LogColors.reset}');
    }

    // 堆栈跟踪
    if (event.stackTrace != null && printStackTrace) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < methodCount; i++) {
        if (stackLines[i].trim().isNotEmpty) {
          lines.add('${LogColors.white}│ ${stackLines[i].trim()}${LogColors.reset}');
        }
      }
    }

    return lines;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}

/// 文件输出器
///
/// 支持按日期轮转的文件日志输出
class RotatingFileOutput extends LogOutput {
  final String logDirectory;
  final int maxFileSizeKB;
  final int retentionDays;
  final String fileNamePrefix;

  File? _currentFile;
  String? _currentDate;
  IOSink? _sink;

  RotatingFileOutput({
    required this.logDirectory,
    this.maxFileSizeKB = 10 * 1024, // 10MB
    this.retentionDays = 7,
    this.fileNamePrefix = 'bkdmm',
  });

  @override
  Future<void> init() async {
    await _ensureLogDirectory();
    await _cleanOldLogs();
    await _openCurrentFile();
  }

  @override
  void output(OutputEvent event) {
    if (_sink == null) return;

    // 检查是否需要轮转 (日期变更或文件大小)
    _checkRotation();

    // 写入日志
    for (final line in event.lines) {
      _sink!.writeln(line);
    }

    // 错误级别立即刷新
    if (event.level == Level.error || event.level == Level.fatal) {
      _sink!.flush();
    }
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _currentFile = null;
  }

  /// 确保日志目录存在
  Future<void> _ensureLogDirectory() async {
    final dir = Directory(logDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 打开当前日志文件
  Future<void> _openCurrentFile() async {
    final today = _getDateString();
    _currentDate = today;

    final fileName = '$fileNamePrefix-$today.log';
    _currentFile = File(p.join(logDirectory, fileName));
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  /// 检查是否需要轮转
  Future<void> _checkRotation() async {
    final today = _getDateString();

    // 日期变更，创建新文件
    if (today != _currentDate) {
      await _rotateFile(today);
      return;
    }

    // 检查文件大小
    if (_currentFile != null && await _currentFile!.exists()) {
      final size = await _currentFile!.length();
      if (size > maxFileSizeKB * 1024) {
        await _rotateBySize();
      }
    }
  }

  /// 按日期轮转文件
  Future<void> _rotateFile(String newDate) async {
    await _sink?.flush();
    await _sink?.close();

    _currentDate = newDate;
    final fileName = '$fileNamePrefix-$newDate.log';
    _currentFile = File(p.join(logDirectory, fileName));
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  /// 按大小轮转文件
  Future<void> _rotateBySize() async {
    await _sink?.flush();
    await _sink?.close();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$fileNamePrefix-$_currentDate-$timestamp.log';
    _currentFile = File(p.join(logDirectory, fileName));
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  /// 清理过期日志
  Future<void> _cleanOldLogs() async {
    final dir = Directory(logDirectory);
    if (!await dir.exists()) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final files = await dir.list().toList();

    for (final file in files) {
      if (file is File && file.path.endsWith('.log')) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
        }
      }
    }
  }

  String _getDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

/// 文件日志格式化器
///
/// 生成纯文本格式的日志行 (无颜色码)
class FilePrinter extends LogPrinter {
  final int methodCount;

  FilePrinter({this.methodCount = 3});

  @override
  List<String> log(LogEvent event) {
    final lines = <String>[];
    final timestamp = _formatTimestamp(event.time);
    final level = event.level.name.toUpperCase().padRight(5);

    // 主日志行
    lines.add('[$timestamp] [$level] ${event.message}');

    // 错误信息
    if (event.error != null) {
      lines.add('  Error: ${event.error}');
    }

    // 堆栈跟踪
    if (event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < methodCount; i++) {
        if (stackLines[i].trim().isNotEmpty) {
          lines.add('  at ${stackLines[i].trim()}');
        }
      }
    }

    return lines;
  }

  String _formatTimestamp(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}

/// 组合输出器
///
/// 同时输出到多个目标
class BkdmmMultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  BkdmmMultiOutput(this.outputs);

  @override
  Future<void> init() async {
    for (final output in outputs) {
      await output.init();
    }
  }

  @override
  void output(OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    for (final output in outputs) {
      await output.destroy();
    }
  }
}

/// 获取日志目录路径
Future<String> getLogDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  return p.join(appDir.path, 'bkdmm', 'logs');
}

/// UI 控制台输出器
///
/// 将日志输出到 Flutter UI 控制台组件
///
/// 注意：这个输出器接收的是 Printer 格式化后的 lines，
/// 所以消息已经包含时间戳、级别和颜色码。
/// LogEntry 会解析 ANSI 颜色码并正确显示。
class UiConsoleOutput extends LogOutput {
  /// 日志回调函数
  final void Function(LogEntry entry) onLog;

  UiConsoleOutput({required this.onLog});

  @override
  void output(OutputEvent event) {
    final now = DateTime.now();

    // DevPrinter 输出的第一行是主消息行
    // 格式: ANSI颜色 时间戳 级别 图标 ANSI重置 消息内容
    // 例如: \x1B[32m10:33:17.074 INFO  🚀 \x1B[0m日志服务初始化完成
    for (final line in event.lines) {
      if (line.trim().isEmpty) continue;

      final entry = LogEntry(
        id: '${now.millisecondsSinceEpoch}_${line.hashCode}',
        timestamp: now,
        level: _mapLevel(event.level),
        rawMessage: line,
      );
      onLog(entry);
    }
  }

  /// 将 logger 包的 Level 映射到 ConsoleLogLevel
  ConsoleLogLevel _mapLevel(Level level) {
    switch (level) {
      case Level.trace:
        return ConsoleLogLevel.trace;
      case Level.debug:
        return ConsoleLogLevel.debug;
      case Level.info:
        return ConsoleLogLevel.info;
      case Level.warning:
        return ConsoleLogLevel.warning;
      case Level.error:
        return ConsoleLogLevel.error;
      case Level.fatal:
        return ConsoleLogLevel.fatal;
      default:
        return ConsoleLogLevel.info;
    }
  }
}
