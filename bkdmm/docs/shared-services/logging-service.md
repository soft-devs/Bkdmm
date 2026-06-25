# 日志服务模块 (Logging Service)

## 概述

Bkdmm 日志服务基于 `logger` 包封装，提供：
- 开发环境彩色控制台输出
- 生产环境文件日志 (自动轮转)
- 敏感信息脱敏
- Riverpod 状态日志

## 文件结构

```
lib/shared/services/logging/
├── logging.dart           # 模块导出
├── logging_config.dart    # 配置类
├── logging_outputs.dart   # 输出器
├── logging_service.dart   # 主服务
└── logging_example.dart   # 使用示例
```

## 快速开始

### 1. 初始化

```dart
// main.dart
await LoggingService.init(
  config: LoggingConfig.development(),
);
```

### 2. 基本使用

```dart
import 'package:bkdmm/shared/services/services.dart';

// 基本日志
logging.i('应用启动完成', tag: 'App');
logging.e('文件读取失败', error: e, tag: 'FileService');

// 性能计时
final timer = logging.timer('加载项目');
await loadProject();
timer.stop();

// Riverpod 状态日志
ref.listen(projectProvider, (prev, next) {
  logging.provider('projectProvider', prev, next);
});
```

## 配置选项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `production` | 生产环境模式 | `false` |
| `minLevel` | 最小日志级别 | `LogLevel.debug` |
| `enableConsole` | 控制台输出 | `true` |
| `enableFile` | 文件输出 | `true` |
| `maxFileSizeKB` | 文件大小限制 | `10240` (10MB) |
| `retentionDays` | 保留天数 | `7` |

## 预设配置

```dart
LoggingConfig.development()  // 开发环境: 控制台输出
LoggingConfig.production()   // 生产环境: 文件日志
LoggingConfig.test()         // 测试环境: 禁用日志
```

## 日志级别

- `debug` - 调试信息 (`logging.d()`)
- `info` - 一般信息 (`logging.i()`)
- `warning` - 警告 (`logging.w()`)
- `error` - 错误 (`logging.e()`)
- `fatal` - 致命错误 (`logging.f()`)

## 输出格式

### 开发环境

```
14:32:45.123  INFO  🚀 [AuthService] 用户登录成功
14:32:46.789  ERROR ❌ [FileService] 文件读取失败
                      └─ Exception: 文件不存在
```

### 生产环境

```
[2024-01-15 14:32:45.123] [INFO ] [AuthService] 用户登录成功
[2024-01-15 14:32:46.789] [ERROR] [FileService] 文件读取失败
```

## 文件轮转

日志文件存储在 `%APPDATA%/bkdmm/logs/` 目录：

```
logs/
├── bkdmm-2024-01-15.log     # 当天日志
├── bkdmm-2024-01-14.log     # 昨天日志
└── ...                       # 保留 7 天
```

## 敏感信息脱敏

```dart
LoggingService.setSensitiveFields(['password', 'token']);

logging.i('用户数据: {"password": "secret"}');
// 输出: 用户数据: {"password": "***"}
```

## API 参考

### LoggingService

| 方法 | 说明 |
|------|------|
| `init()` | 初始化日志服务 |
| `destroy()` | 销毁日志服务 |
| `setSensitiveFields()` | 设置敏感字段 |
| `maskSensitive()` | 脱敏处理 |

### AppLog (全局变量 `logging`)

| 方法 | 说明 |
|------|------|
| `d()` | Debug 日志 |
| `i()` | Info 日志 |
| `w()` | Warning 日志 |
| `e()` | Error 日志 |
| `f()` | Fatal 日志 |
| `provider()` | Riverpod 状态日志 |
| `timer()` | 性能计时器 |

### RiverpodLogObserver

用于 ProviderScope 的日志观察者：

```dart
runApp(
  ProviderScope(
    observers: [RiverpodLogObserver()],
    child: MyApp(),
  ),
);
```

## 依赖

- `logger: ^2.7.0` - 核心日志库
- `path_provider: ^2.1.0` - 文件路径 (已有)

## 最佳实践

1. **使用标签**: 为不同模块设置 tag，便于过滤
2. **错误处理**: 记录 error 和 stackTrace
3. **性能计时**: 对耗时操作使用 timer
4. **敏感信息**: 配置脱敏字段
5. **日志级别**: 开发用 debug，生产用 info+

## 参考文档

- [设计文档](../design/logging-service-design.md)
- [logger 包文档](https://pub.dev/packages/logger)