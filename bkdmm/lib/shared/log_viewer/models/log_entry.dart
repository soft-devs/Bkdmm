/// 控制台日志条目模型
///
/// 表示单条日志，支持 ANSI 颜色码解析
library;

import 'package:flutter/material.dart';

import '../services/ansi_parser.dart';

/// 日志级别枚举
///
/// 与 logger 包的 Level 对应
enum ConsoleLogLevel {
  trace('TRACE', '📝'),
  debug('DEBUG', '🔍'),
  info('INFO', '🚀'),
  warning('WARN', '⚠️'),
  error('ERROR', '❌'),
  fatal('FATAL', '💀');

  final String label;
  final String icon;

  const ConsoleLogLevel(this.label, this.icon);

  /// 获取日志级别对应的颜色
  Color get color => switch (this) {
        ConsoleLogLevel.trace => const Color(0xFF00BCD4), // Cyan
        ConsoleLogLevel.debug => const Color(0xFF2196F3), // Blue
        ConsoleLogLevel.info => const Color(0xFF4CAF50), // Green
        ConsoleLogLevel.warning => const Color(0xFFFF9800), // Orange
        ConsoleLogLevel.error => const Color(0xFFF44336), // Red
        ConsoleLogLevel.fatal => const Color(0xFF9C27B0), // Purple
      };

  /// 获取日志级别对应的背景色（浅色）
  Color get backgroundColor => color.withValues(alpha: 0.1);

  /// 从 logger 包的 Level 转换
  static ConsoleLogLevel fromLoggerLevel(String levelName) {
    return switch (levelName.toLowerCase()) {
      'trace' => ConsoleLogLevel.trace,
      'debug' => ConsoleLogLevel.debug,
      'info' => ConsoleLogLevel.info,
      'warning' => ConsoleLogLevel.warning,
      'error' => ConsoleLogLevel.error,
      'fatal' => ConsoleLogLevel.fatal,
      _ => ConsoleLogLevel.info,
    };
  }
}

/// 日志条目
class LogEntry {
  /// 唯一标识
  final String id;

  /// 时间戳
  final DateTime timestamp;

  /// 日志级别
  final ConsoleLogLevel level;

  /// 原始消息（可能包含 ANSI 转义序列）
  final String rawMessage;

  /// 日志来源（可选）
  final String? source;

  /// 日志分类（可选）
  final String? category;

  /// 错误对象（可选）
  final Object? error;

  /// 堆栈跟踪（可选）
  final StackTrace? stackTrace;

  /// 清理后的纯文本消息（无 ANSI 码）
  late final String cleanMessage = AnsiParser.strip(rawMessage);

  /// 解析后的样式文本片段
  late final List<TextSpan> styledSpans;

  /// 基础样式
  final TextStyle baseStyle;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.rawMessage,
    this.source,
    this.category,
    this.error,
    this.stackTrace,
    TextStyle? baseStyle,
  }) : baseStyle = baseStyle ??
            const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 13,
            ) {
    styledSpans = AnsiParser.parse(rawMessage, baseStyle: this.baseStyle);
  }

  /// 格式化时间戳为可读字符串
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// 格式化完整时间戳
  String get formattedFullTime {
    return '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '$formattedTime';
  }

  @override
  String toString() {
    return '[$formattedTime] [${level.label}] $cleanMessage';
  }

  /// 导出为纯文本格式
  String toExportString() {
    final buffer = StringBuffer();
    buffer.write('[$formattedFullTime] [${level.label}]');
    if (source != null) {
      buffer.write(' [$source]');
    }
    buffer.write(' $cleanMessage');
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write(
          '\n  StackTrace:\n${stackTrace.toString().split('\n').take(5).map((l) => '    $l').join('\n')}');
    }
    return buffer.toString();
  }
}
