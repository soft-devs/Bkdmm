/// 日志配置类
///
/// 定义日志服务的各项配置参数
library;

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志配置
class LoggingConfig {
  /// 是否为生产环境
  final bool production;

  /// 最小日志级别 (低于此级别的日志将被过滤)
  final LogLevel minLevel;

  /// 日志文件目录名
  final String logDirectoryName;

  /// 单个日志文件最大大小 (KB)
  final int maxFileSizeKB;

  /// 保留日志天数
  final int retentionDays;

  /// 是否启用控制台输出
  final bool enableConsole;

  /// 是否启用文件输出
  final bool enableFile;

  /// 是否启用 UI 控制台输出 (LogViewer)
  final bool enableUiConsole;

  /// 敏感字段列表 (这些字段的值将被脱敏)
  final List<String> sensitiveFields;

  /// 是否打印堆栈跟踪
  final bool printStackTrace;

  /// 方法调用栈深度
  final int methodCount;

  const LoggingConfig({
    this.production = false,
    this.minLevel = LogLevel.debug,
    this.logDirectoryName = 'logs',
    this.maxFileSizeKB = 10 * 1024, // 10MB
    this.retentionDays = 7,
    this.enableConsole = true,
    this.enableFile = true,
    this.enableUiConsole = true,
    this.sensitiveFields = const ['password', 'token', 'apiKey', 'secret'],
    this.printStackTrace = true,
    this.methodCount = 5,
  });

  /// 开发环境配置
  factory LoggingConfig.development() => const LoggingConfig(
        production: false,
        minLevel: LogLevel.debug,
        enableConsole: true,
        enableFile: false, // 开发时可不写文件
        enableUiConsole: true,
        methodCount: 8,
      );

  /// 生产环境配置
  factory LoggingConfig.production() => const LoggingConfig(
        production: true,
        minLevel: LogLevel.info, // 生产环境从 info 开始
        enableConsole: false, // 生产环境不输出控制台
        enableFile: true,
        enableUiConsole: true,
        methodCount: 3,
      );

  /// 测试环境配置
  factory LoggingConfig.test() => const LoggingConfig(
        production: false,
        minLevel: LogLevel.warning,
        enableConsole: false,
        enableFile: false,
        enableUiConsole: false,
      );
}
