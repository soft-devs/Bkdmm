# utils - 工具类

## 概述

提供 ID 生成器和日志服务等工具类。

## 模块清单

| 模块 | 描述 | 关键功能 |
|------|------|----------|
| IdGenerator | ID生成器 | generate() 生成唯一UUID |
| LoggingService | 日志服务 | init(), info(), error() |
| LoggingConfig | 日志配置 | development(), production() |
| LoggingOutputs | 日志输出 | ConsoleOutput, FileOutput |

## IdGenerator

生成唯一标识符，用于 Entity/Field/Index 的 ID。

```dart
final id = IdGenerator.generate(); // 返回 32 位 UUID
```

## LoggingService

结构化日志服务，支持多输出通道。

```dart
// 初始化
await LoggingService.init(config: LoggingConfig.development());

// 日志输出
logging.i('信息日志', tag: 'Module');
logging.e('错误日志', error: exception, tag: 'Module');
```

## 日志级别

- `i()` - 信息
- `d()` - 调试
- `w()` - 警告
- `e()` - 错误