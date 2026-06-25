# Bkdmm 日志工具设计方案

## 一、需求分析

### 项目需求
- **开发环境**: Windows 11 桌面应用
- **技术栈**: Flutter 3.8+ / Riverpod / Hive
- **日志需求**:
  - 开发时彩色控制台输出，便于调试
  - 生产环境文件日志，支持问题排查
  - 日志分级 (debug/info/warning/error)
  - 与 Riverpod 状态管理集成
  - 支持日志文件轮转，避免无限增长

## 二、方案对比

### 主流 Flutter 日志库对比

| 功能特性 | logger | talker | logging (dart-lang) | logging_appenders |
|---------|--------|--------|---------------------|-------------------|
| **彩色控制台** | ✅ 优秀 | ✅ 优秀 | ⚠️ 需手动配置 | ✅ 良好 |
| **文件日志** | ✅ 内置 | ⚠️ 仅导出 | ❌ 无 | ✅ 内置 |
| **日志轮转** | ✅ AdvancedFileOutput | ❌ 无 | ❌ 无 | ✅ RotatingFileAppender |
| **Riverpod集成** | ❌ 需手动 | ✅ **原生支持** | ❌ 无 | ❌ 无 |
| **UI日志查看** | ❌ 无 | ✅ TalkerScreen | ❌ 无 | ❌ 无 |
| **错误追踪** | ⚠️ 基础 | ✅ 完整 | ⚠️ 基础 | ⚠️ 基础 |
| **包大小** | 轻量 | 中等 | 轻量 | 轻量 |

## 三、推荐方案

### 方案 A: 纯 logger 方案 (推荐 - 简洁)

**优点**: 单一依赖，文件日志开箱即用，轻量级
**缺点**: 需手动集成 Riverpod

```yaml
dependencies:
  logger: ^2.7.0
```

### 方案 B: talker + logger 组合 (推荐 - 功能完整)

**优点**: 原生 Riverpod 集成，UI 日志查看器，错误追踪完整
**缺点**: 两个依赖，稍重

```yaml
dependencies:
  talker_flutter: ^5.1.17
  talker_riverpod_logger: ^5.1.17
```

### 方案 C: 自定义封装 (本方案采用)

基于 `logger` 封装，添加:
- 项目特定日志格式
- Riverpod 状态变更日志
- 文件日志轮转
- 敏感信息脱敏

## 四、实施方案 (方案 C)

### 4.1 添加依赖

```yaml
# pubspec.yaml
dependencies:
  logger: ^2.7.0
  path_provider: ^2.1.0  # 已有
```

### 4.2 日志服务设计

```
lib/shared/services/
├── logging_service.dart      # 日志服务主文件
├── logging_config.dart       # 日志配置
└── logging_outputs.dart      # 自定义输出器
```

### 4.3 核心功能

#### LogConfig - 日志配置
- 日志级别控制 (开发/生产不同级别)
- 文件路径配置
- 轮转策略 (大小/时间)
- 敏感字段脱敏规则

#### LoggingService - 日志服务
- 全局单例访问
- 初始化 (开发/生产模式)
- 分级日志方法 (d/i/w/e)
- Riverpod 状态日志
- 性能计时日志

#### 自定义输出器
- **DevOutput**: 彩色控制台输出 (开发环境)
- **FileOutput**: 文件日志输出 (生产环境)
- **RotatingFileOutput**: 日志轮转输出

### 4.4 日志格式设计

```
[2024-01-15 14:32:45.123] [INFO ] [main] Application started
[2024-01-15 14:32:45.456] [DEBUG] [Riverpod] Provider "projectProvider" updated
[2024-01-15 14:32:46.789] [ERROR] [FileService] Failed to read file: C:\test.json
├── FileNotFoundException: The system cannot find the file specified
└── at FileService.readFile (file_service.dart:42)
```

### 4.5 使用示例

```dart
// 初始化 (main.dart)
await LoggingService.init(production: false);

// 基本日志
AppLog.i('项目加载完成', tag: 'ProjectService');
AppLog.e('文件读取失败', error: e, tag: 'FileService');

// Riverpod 状态日志
ref.listen<Project>(projectProvider, (prev, next) {
  AppLog.d('项目状态变更: ${prev?.name} → ${next?.name}', tag: 'Riverpod');
});

// 性能计时
final timer = AppLog.timer('加载所有实体');
await _loadEntities();
timer.stop();  // 自动记录耗时
```

### 4.6 文件日志轮转

```
logs/
├── bkdmm-2024-01-15.log     # 当天日志
├── bkdmm-2024-01-14.log     # 昨天日志
├── bkdmm-2024-01-13.log     # 前天日志
└── ...                       # 保留最近 7 天
```

轮转策略:
- 按日期自动分割
- 单文件最大 10MB
- 保留最近 7 天日志
- 自动清理过期日志

### 4.7 敏感信息脱敏

```dart
// 配置脱敏规则
LoggingService.setSensitiveFields(['password', 'token', 'apiKey']);

// 自动脱敏
AppLog.i('用户登录: {"username": "admin", "password": "***"}');
```

## 五、文件结构

```
lib/shared/services/
├── logging_service.dart       # 主服务 (200行)
├── logging_config.dart        # 配置类 (50行)
├── logging_outputs.dart       # 输出器 (150行)
└── services.dart              # 导出文件 (更新)

test/shared/services/
└── logging_service_test.dart  # 单元测试
```

## 六、集成步骤

1. 添加依赖到 `pubspec.yaml`
2. 创建日志服务文件
3. 在 `main.dart` 初始化
4. 替换现有 `print()` 调用
5. 添加 Riverpod 日志观察者

## 七、预期效果

### 开发环境
```
14:32:45.123  INFO  🚀 [ProjectService] 项目加载完成
14:32:45.456  DEBUG 🔍 [Riverpod] projectProvider → Project(name: "Demo")
14:32:46.789  ERROR ❌ [FileService] 文件读取失败
                      └─ FileNotFoundException: 系统找不到指定的文件
```

### 生产环境日志文件
```
[2024-01-15 14:32:45.123] [INFO ] [ProjectService] 项目加载完成
[2024-01-15 14:32:46.789] [ERROR] [FileService] 文件读取失败
FileNotFoundException: The system cannot find the file specified
  at FileService.readFile (file_service.dart:42)
  at ProjectService.loadProject (project_service.dart:28)
```

## 八、备选方案

如果需要更强大的功能 (UI 日志查看、错误追踪)，可升级为 **talker** 方案:

```yaml
dependencies:
  talker_flutter: ^5.1.17
  talker_riverpod_logger: ^5.1.17
```

优势:
- 内置 Riverpod 观察者
- 应用内日志查看界面
- 支持日志分享
- 可集成 Sentry/Crashlytics

---

**建议**: 先实施方案 C (logger 封装)，满足基本需求。如后续需要 UI 日志查看器或更强大的错误追踪，再迁移到 talker。
