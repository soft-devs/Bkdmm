/// 日志服务使用示例
///
/// 演示如何在项目中使用日志服务
library;

// ignore_for_file: avoid_print, unused_local_variable

import 'package:bkdmm/utils/logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// 1. 初始化 (在 main.dart 中)
/// ============================================================

Future<void> exampleInit() async {
  // 开发环境初始化 (控制台输出)
  await LoggingService.init(
    config: LoggingConfig.development(),
  );

  // 生产环境初始化 (文件输出)
  await LoggingService.init(
    config: LoggingConfig.production(),
  );

  // 自定义配置
  await LoggingService.init(
    config: const LoggingConfig(
      production: false,
      minLevel: LogLevel.debug,
      enableConsole: true,
      enableFile: true,
      maxFileSizeKB: 5 * 1024, // 5MB
      retentionDays: 14,
    ),
  );
}

/// ============================================================
/// 2. 基本日志记录
/// ============================================================

void exampleBasicLogging() {
  // Debug 级别 - 开发调试信息
  logging.d('这是调试信息');
  logging.d('带标签的调试信息', tag: 'MyService');

  // Info 级别 - 一般信息
  logging.i('应用启动完成');
  logging.i('用户登录成功', tag: 'AuthService');

  // Warning 级别 - 警告信息
  logging.w('配置文件不存在，使用默认配置');
  logging.w('API 响应超时', tag: 'ApiService');

  // Error 级别 - 错误信息
  logging.e('文件读取失败');
  logging.e(
    '数据库连接失败',
    tag: 'DatabaseService',
    error: Exception('Connection refused'),
  );

  // Fatal 级别 - 致命错误
  logging.f(
    '应用无法启动',
    tag: 'App',
    error: Exception('Missing required config'),
    stackTrace: StackTrace.current,
  );
}

/// ============================================================
/// 3. 错误处理
/// ============================================================

Future<void> exampleErrorHandling() async {
  try {
    // 模拟可能抛出异常的操作
    await someRiskyOperation();
  } catch (e, stackTrace) {
    // 记录错误和堆栈跟踪
    logging.e(
      '操作失败',
      tag: 'ExampleService',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

Future<void> someRiskyOperation() async {
  throw Exception('Something went wrong');
}

/// ============================================================
/// 4. 性能计时
/// ============================================================

Future<void> examplePerformanceTiming() async {
  // 基本计时
  final timer = logging.timer('加载项目数据');
  await Future.delayed(const Duration(milliseconds: 500));
  timer.stop(); // 输出: ⏱️ 加载项目数据 completed in 500ms

  // 带阈值的计时
  final timer2 = logging.timer('保存数据');
  await Future.delayed(const Duration(milliseconds: 1500));
  timer2.stopWithThreshold(
    warningMs: 1000, // 超过 1s 输出 warning
    errorMs: 3000, // 超过 3s 输出 error
  );
}

/// ============================================================
/// 5. Riverpod 状态日志
/// ============================================================

// 创建一个 Provider
final counterProvider = StateProvider<int>((ref) => 0);

void exampleRiverpodLogging(WidgetRef ref) {
  // 方式 1: 使用 RiverpodLogObserver (推荐)
  // 在 ProviderScope 中添加观察者，自动记录所有 Provider 变更

  // 方式 2: 手动记录特定 Provider 变更
  ref.listen<int>(counterProvider, (previous, next) {
    logging.provider('counterProvider', previous, next);
  });

  // 方式 3: 在 Provider 内部记录
  // 在业务逻辑中手动调用 logging
}

/// ProviderScope 配置示例
void exampleProviderScope() {
  // 在 main.dart 中
  // runApp(
  //   ProviderScope(
  //     observers: [
  //       RiverpodLogObserver(
  //         logProviderAdded: true,
  //         logProviderUpdated: true,
  //         logProviderDisposed: false,
  //       ),
  //     ],
  //     child: MyApp(),
  //   ),
  // );
}

/// ============================================================
/// 6. 敏感信息脱敏
/// ============================================================

void exampleSensitiveData() {
  // 配置敏感字段
  LoggingService.setSensitiveFields(['password', 'token', 'apiKey']);

  // 自动脱敏 JSON 格式
  logging.i('用户数据: {"username": "admin", "password": "secret123"}');
  // 输出: 用户数据: {"username": "admin", "password": "***"}

  // 自动脱敏键值对格式
  logging.i('API 配置: apiKey=my-secret-key');
  // 输出: API 配置: apiKey=***
}

/// ============================================================
/// 7. 在服务类中使用
/// ============================================================

class ExampleService {
  static const _tag = 'ExampleService';

  Future<void> loadData() async {
    logging.i('开始加载数据', tag: _tag);

    try {
      final timer = logging.timer('loadData');

      // 执行加载逻辑
      await Future.delayed(const Duration(milliseconds: 300));

      timer.stop();
      logging.i('数据加载完成', tag: _tag);
    } catch (e, stackTrace) {
      logging.e(
        '数据加载失败',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// ============================================================
/// 8. 日志输出示例
/// ============================================================

/// 开发环境控制台输出:
/// ```
/// 14:32:45.123  INFO  🚀 [AuthService] 用户登录成功
/// 14:32:45.456  DEBUG 🔍 [Riverpod] Provider "projectProvider" updated: null → Project(name: "Demo")
/// 14:32:46.789  ERROR ❌ [FileService] 文件读取失败
///                       └─ Exception: 文件不存在
/// ```

/// 生产环境日志文件:
/// ```
/// [2024-01-15 14:32:45.123] [INFO ] [AuthService] 用户登录成功
/// [2024-01-15 14:32:46.789] [ERROR] [FileService] 文件读取失败
///   Exception: 文件不存在
///   at FileService.readFile (file_service.dart:42)
/// ```
