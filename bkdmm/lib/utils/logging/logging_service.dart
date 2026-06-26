/// Bkdmm 日志服务
///
/// 提供统一的日志记录功能，支持：
/// - 开发环境彩色控制台输出
/// - 生产环境文件日志 (自动轮转)
/// - 敏感信息脱敏
/// - Riverpod 状态日志
/// - UI 日志流输出
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../shared/log_viewer/models/log_entry.dart';
import 'logging_config.dart';
import 'logging_outputs.dart';

/// 全局日志实例 (便捷访问)
late AppLog logging;

/// 日志服务类
class LoggingService {
  static Logger? _logger;
  static LoggingConfig? _config;
  static bool _initialized = false;

  /// 敏感字段列表
  static final List<String> _sensitiveFields = [];

  /// UI 日志流控制器
  static final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  /// UI 日志流 (供 LogViewer 订阅)
  static Stream<LogEntry> get logStream => _logStreamController.stream;

  /// 初始化日志服务
  ///
  /// [config] 日志配置，默认使用开发环境配置
  /// [logDirectory] 自定义日志目录路径
  static Future<void> init({
    LoggingConfig? config,
    String? logDirectory,
  }) async {
    if (_initialized) {
      return;
    }

    _config = config ?? LoggingConfig.development();

    // 构建输出器
    final outputs = <LogOutput>[];

    if (_config!.enableConsole) {
      outputs.add(ConsoleOutput());
    }

    if (_config!.enableFile) {
      final logDir = logDirectory ?? await getLogDirectory();
      outputs.add(RotatingFileOutput(
        logDirectory: logDir,
        maxFileSizeKB: _config!.maxFileSizeKB,
        retentionDays: _config!.retentionDays,
        fileNamePrefix: 'bkdmm',
      ));
    }

    // 添加 UI 控制台输出器
    if (_config!.enableUiConsole) {
      outputs.add(UiConsoleOutput(
        onLog: (entry) {
          _logStreamController.add(entry);
        },
      ));
    }

    // 创建 Logger 实例
    _logger = Logger(
      filter: _BkdmmLogFilter(_config!),
      printer: _config!.production
          ? FilePrinter(methodCount: _config!.methodCount)
          : DevPrinter(
              methodCount: _config!.methodCount,
              printStackTrace: _config!.printStackTrace,
            ),
      output: outputs.length > 1 ? BkdmmMultiOutput(outputs) : outputs.first,
    );

    // 设置全局便捷访问
    logging = AppLog._(_logger!);

    _initialized = true;

    // 记录初始化日志
    logging.i('日志服务初始化完成', tag: 'LoggingService');
  }

  /// 销毁日志服务
  static Future<void> destroy() async {
    await _logger?.close();
    await _logStreamController.close();
    _logger = null;
    _initialized = false;
  }

  /// 设置敏感字段列表
  static void setSensitiveFields(List<String> fields) {
    _sensitiveFields.clear();
    _sensitiveFields.addAll(fields);
  }

  /// 获取敏感字段列表
  static List<String> get sensitiveFields => List.unmodifiable(_sensitiveFields);

  /// 脱敏处理
  static String maskSensitive(String message) {
    var result = message;
    for (final field in _sensitiveFields) {
      // 匹配 JSON 格式: "field": "value"
      final jsonPattern = RegExp('"$field"\\s*:\\s*"[^"]*"');
      result = result.replaceAll(jsonPattern, '"$field": "***"');

      // 匹配键值对格式: field=value
      final kvPattern = RegExp('$field\\s*=\\s*\\S+');
      result = result.replaceAll(kvPattern, '$field=***');
    }
    return result;
  }
}

/// 日志过滤器
class _BkdmmLogFilter extends LogFilter {
  final LoggingConfig config;

  _BkdmmLogFilter(this.config);

  @override
  bool shouldLog(LogEvent event) {
    // 根据配置的最小级别过滤
    return event.level.index >= _levelToIndex(config.minLevel);
  }

  int _levelToIndex(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Level.debug.index;
      case LogLevel.info:
        return Level.info.index;
      case LogLevel.warning:
        return Level.warning.index;
      case LogLevel.error:
        return Level.error.index;
      case LogLevel.fatal:
        return Level.fatal.index;
    }
  }
}

/// 应用日志类 (便捷封装)
class AppLog {
  final Logger _logger;

  AppLog._(this._logger);

  /// Debug 级别日志
  void d(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Info 级别日志
  void i(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Warning 级别日志
  void w(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志
  void e(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Fatal 级别日志
  void f(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.fatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 记录 Riverpod 状态变更
  void provider(
    String providerName,
    dynamic previousValue,
    dynamic newValue,
  ) {
    final prevStr = _formatValue(previousValue);
    final newValStr = _formatValue(newValue);

    d(
      'Provider "$providerName" updated: $prevStr → $newValStr',
      tag: 'Riverpod',
    );
  }

  /// 创建性能计时器
  LogTimer timer(String operation) {
    return LogTimer._(operation, this);
  }

  /// 内部日志方法
  void _log(
    Level level,
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final msgStr = message.toString();

    // 脱敏处理
    final maskedMsg = LoggingService.maskSensitive(msgStr);

    // 添加标签
    final finalMsg = tag != null ? '[$tag] $maskedMsg' : maskedMsg;

    _logger.log(level, finalMsg, error: error, stackTrace: stackTrace);
  }

  /// 格式化值用于日志输出
  String _formatValue(dynamic value) {
    if (value == null) {
      return 'null';
    }
    final str = value.toString();
    if (str.length > 50) {
      return '${str.substring(0, 50)}...';
    }
    return str;
  }
}

/// 性能计时器
class LogTimer {
  final String _operation;
  final AppLog _log;
  final Stopwatch _stopwatch;

  LogTimer._(this._operation, this._log) : _stopwatch = Stopwatch()..start();

  /// 停止计时并记录日志
  void stop() {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    _log.d('⏱️ $_operation completed in ${elapsed}ms');
  }

  /// 停止计时并记录日志 (带警告阈值)
  void stopWithThreshold({int warningMs = 1000, int errorMs = 3000}) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;

    if (elapsed > errorMs) {
      _log.w('⏱️ $_operation completed in ${elapsed}ms (slow!)');
    } else if (elapsed > warningMs) {
      _log.d('⏱️ $_operation completed in ${elapsed}ms (warning)');
    } else {
      _log.d('⏱️ $_operation completed in ${elapsed}ms');
    }
  }
}

/// Riverpod 日志观察者
///
/// 用于 ProviderScope 的 observers 参数
///
/// 示例:
/// ```dart
/// runApp(
///   ProviderScope(
///     observers: [RiverpodLogObserver()],
///     child: MyApp(),
///   ),
/// );
/// ```
class RiverpodLogObserver extends ProviderObserver {
  final bool logProviderAdded;
  final bool logProviderUpdated;
  final bool logProviderDisposed;

  RiverpodLogObserver({
    this.logProviderAdded = false,
    this.logProviderUpdated = true,
    this.logProviderDisposed = false,
  });

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (logProviderAdded) {
      logging.d('Provider added: ${provider.name ?? provider.runtimeType}', tag: 'Riverpod');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (logProviderUpdated) {
      logging.provider(
        provider.name ?? provider.runtimeType.toString(),
        previousValue,
        newValue,
      );
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (logProviderDisposed) {
      logging.d('Provider disposed: ${provider.name ?? provider.runtimeType}', tag: 'Riverpod');
    }
  }
}
