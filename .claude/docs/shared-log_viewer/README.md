# shared/log_viewer - 日志查看器

## 概述

日志查看器模块提供完整的日志显示、过滤和管理功能。支持 ANSI 颜色码解析、日志级别过滤、关键词搜索、环形缓冲区存储等功能。

**主要特性：**
- ANSI 转义序列解析与渲染
- 日志级别过滤 (TRACE/DEBUG/INFO/WARN/ERROR/FATAL)
- 关键词搜索
- 环形缓冲区存储（自动淘汰旧日志）
- 自动滚动到底部
- 日志导出功能
- 暂停/恢复日志接收

## 架构

```
log_viewer/
|-- log_viewer.dart          # 模块入口，统一导出
|-- models/
|   |-- log_entry.dart       # 日志条目模型
|   |-- log_filter.dart      # 过滤条件模型 + 日志统计
|-- services/
|   |-- ansi_parser.dart     # ANSI 解析器
|   |-- log_buffer.dart      # 环形缓冲区
|-- providers/
|   |-- log_viewer_provider.dart  # Riverpod 状态管理
|-- widgets/
    |-- log_viewer_shell.dart     # 主组件外壳
    |-- log_list_view.dart        # 日志列表视图
    |-- log_entry_widget.dart     # 单条日志组件
    |-- log_filter_bar.dart       # 过滤工具栏
    |-- log_viewer_status_bar.dart # 状态栏
```

## API 索引

### Models

#### ConsoleLogLevel (枚举)

日志级别枚举，与 logger 包的 Level 对应。

| 级别 | 标签 | 图标 | 颜色 |
|------|------|------|------|
| trace | TRACE | 📝 | Cyan (#00BCD4) |
| debug | DEBUG | 🔍 | Blue (#2196F3) |
| info | INFO | 🚀 | Green (#4CAF50) |
| warning | WARN | ⚠️ | Orange (#FF9800) |
| error | ERROR | ❌ | Red (#F44336) |
| fatal | FATAL | 💀 | Purple (#9C27B0) |

```dart
// 从 logger 包级别字符串转换
ConsoleLogLevel.fromLoggerLevel('error'); // ConsoleLogLevel.error

// 获取级别颜色
level.color;           // 前景色
level.backgroundColor;  // 背景色（带透明度）
```

#### LogEntry

单条日志条目模型。

| 属性 | 类型 | 描述 |
|------|------|------|
| `id` | String | 唯一标识 |
| `timestamp` | DateTime | 时间戳 |
| `level` | ConsoleLogLevel | 日志级别 |
| `rawMessage` | String | 原始消息（含 ANSI 码） |
| `cleanMessage` | String | 清理后的纯文本（只读） |
| `styledSpans` | List\<TextSpan\> | 解析后的样式片段（只读） |
| `source` | String? | 日志来源 |
| `category` | String? | 日志分类 |
| `error` | Object? | 错误对象 |
| `stackTrace` | StackTrace? | 堆栈跟踪 |

```dart
final entry = LogEntry(
  id: uuid.v4(),
  timestamp: DateTime.now(),
  level: ConsoleLogLevel.info,
  rawMessage: '\x1B[32mSuccess\x1B[0m',
);

entry.formattedTime;      // "14:30:25.123"
entry.formattedFullTime;  // "2026-06-29 14:30:25.123"
entry.cleanMessage;       // "Success" (无 ANSI 码)
entry.styledSpans;        // 带颜色的 TextSpan 列表
entry.toExportString();   // 导出格式
```

#### LogFilter

日志过滤条件模型。

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `levels` | Set\<ConsoleLogLevel\> | 全部级别 | 允许的日志级别 |
| `searchText` | String? | null | 搜索关键词 |
| `source` | String? | null | 来源过滤 |
| `startTime` | DateTime? | null | 开始时间 |
| `endTime` | DateTime? | null | 结束时间 |

```dart
// 默认过滤器（显示所有级别）
const filter = LogFilter.defaultFilter;

// 只显示错误和致命错误
const filter = LogFilter.errorsOnly;

// 切换日志级别
filter.toggleLevel(ConsoleLogLevel.debug);

// 设置搜索关键词
filter.withSearch('error');

// 检查日志是否匹配
filter.matches(entry); // bool
```

#### LogStats

日志统计信息。

| 属性 | 类型 | 描述 |
|------|------|------|
| `counts` | Map\<ConsoleLogLevel, int\> | 各级别数量 |
| `total` | int | 总数量 |

```dart
final stats = LogStats.fromEntries(entries);
stats.count(ConsoleLogLevel.error);  // 错误数量
stats.total;                          // 总数量
```

### Services

#### LogBuffer\<T\>

环形缓冲区，固定大小，自动淘汰旧数据。

| 属性/方法 | 类型 | 描述 |
|-----------|------|------|
| `maxSize` | int | 最大容量 |
| `length` | int | 当前元素数量 |
| `isEmpty` | bool | 是否为空 |
| `isFull` | bool | 是否已满 |
| `add(T)` | void | 添加元素（满时覆盖最旧） |
| `addAll(Iterable<T>)` | void | 批量添加 |
| `getAll()` | List\<T\> | 获取所有元素（按顺序） |
| `getLatest(int n)` | List\<T\> | 获取最新 N 个 |
| `getEarliest(int n)` | List\<T\> | 获取最早 N 个 |
| `get(int index)` | T? | 获取指定索引元素 |
| `clear()` | void | 清空缓冲区 |
| `find(test)` | T? | 查找第一个匹配 |
| `where(test)` | List\<T\> | 过滤元素 |

```dart
// 创建缓冲区（最多 1000 条）
final buffer = LogBuffer<LogEntry>(1000);

// 添加日志
buffer.add(entry);

// 获取所有日志
final all = buffer.getAll();

// 获取最新 100 条
final latest = buffer.getLatest(100);

// 列表转缓冲区
final buffer = list.toLogBuffer(1000);
```

#### AnsiParser

ANSI 转义序列解析器。

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `parse(String, {TextStyle?})` | List\<TextSpan\> | 解析为样式文本片段 |
| `strip(String)` | String | 去除 ANSI 码，返回纯文本 |
| `hasAnsi(String)` | bool | 检查是否包含 ANSI 码 |
| `colorize(String, int)` | String | 创建带 ANSI 颜色的文本 |
| `style(String, {int? colorCode, bool bold})` | String | 创建带样式的文本 |

```dart
// 解析 ANSI 文本
final spans = AnsiParser.parse('\x1B[31mError\x1B[0m', baseStyle: style);

// 去除 ANSI 码
final clean = AnsiParser.strip('\x1B[31mError\x1B[0m'); // "Error"

// 检查是否包含 ANSI
AnsiParser.hasAnsi(text); // true/false

// 创建 ANSI 文本
AnsiParser.colorize('Error', AnsiColors.red);
AnsiParser.style('Bold', colorCode: 32, bold: true);
```

#### AnsiColors (常量类)

预定义 ANSI 颜色码。

```dart
// 标准颜色 (30-37)
AnsiColors.black, red, green, yellow, blue, magenta, cyan, white

// 高亮颜色 (90-97)
AnsiColors.brightBlack, brightRed, brightGreen, ...

// 样式码
AnsiColors.reset, bold, dim, italic, underline, blink
```

### Providers

#### logViewerProvider

主状态 Provider (StateNotifierProvider)。

```dart
// 监听状态
final state = ref.watch(logViewerProvider);
state.entries;      // 过滤后的日志列表
state.filter;       // 当前过滤条件
state.isPaused;     // 是否暂停
state.autoScroll;   // 是否自动滚动
state.stats;        // 统计信息

// 操作
ref.read(logViewerProvider.notifier).addLog(entry);
ref.read(logViewerProvider.notifier).setFilter(filter);
ref.read(logViewerProvider.notifier).toggleLevel(level);
ref.read(logViewerProvider.notifier).setSearchText('error');
ref.read(logViewerProvider.notifier).resetFilter();
ref.read(logViewerProvider.notifier).togglePause();
ref.read(logViewerProvider.notifier).clear();
ref.read(logViewerProvider.notifier).exportLogs(); // 导出为文本
```

#### 便捷 Providers

```dart
// 日志列表
final entries = ref.watch(logEntriesProvider);

// 过滤条件
final filter = ref.watch(logFilterProvider);

// 是否暂停
final isPaused = ref.watch(logIsPausedProvider);

// 统计信息
final stats = ref.watch(logStatsProvider);
```

### Widgets

#### LogViewerShell

主组件外壳，整合所有子组件。

```dart
const LogViewerShell()
```

#### LogListView

日志列表视图，使用虚拟滚动优化性能。

```dart
const LogListView()

// 自动滚动
state.autoScroll; // 控制是否自动滚动到底部
```

#### LogEntryWidget

单条日志渲染组件。

| 参数 | 类型 | 描述 |
|------|------|------|
| `entry` | LogEntry | 日志条目数据 |
| `index` | int | 行索引（用于交替背景色） |
| `tdTheme` | TDThemeData | TDesign 主题数据 |

```dart
LogEntryWidget(
  entry: entry,
  index: 0,
  tdTheme: TDTheme.of(context),
)
```

#### LogDetailWidget

日志详情组件（展开显示错误详情）。

```dart
LogDetailWidget(
  entry: errorEntry,
  tdTheme: TDTheme.of(context),
)
```

#### LogFilterBar

过滤工具栏，包含级别按钮、搜索框、操作按钮。

```dart
const LogFilterBar()
```

#### LogViewerStatusBar

状态栏，显示日志统计信息。

```dart
const LogViewerStatusBar()
```

## 使用示例

### 基础使用

```dart
// 在页面中使用
class LogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const LogViewerShell();
  }
}
```

### 集成到底部面板

```dart
// 在底部视图中使用
BottomViewContainer(
  viewId: 'log_viewer',
  child: LogViewerShell(),
)
```

### 手动添加日志

```dart
// 通过 Provider 添加日志
ref.read(logViewerProvider.notifier).addLog(LogEntry(
  id: uuid.v4(),
  timestamp: DateTime.now(),
  level: ConsoleLogLevel.error,
  rawMessage: 'Something went wrong',
  error: exception,
  stackTrace: stackTrace,
));
```

### 过滤日志

```dart
// 只显示错误和警告
ref.read(logViewerProvider.notifier).setFilter(LogFilter(
  levels: {ConsoleLogLevel.error, ConsoleLogLevel.warning},
));

// 搜索关键词
ref.read(logViewerProvider.notifier).setSearchText('exception');
```

## 数据流

```
LoggingService.logStream
        |
        v
  LogViewerNotifier (订阅日志流)
        |
        v
  LogBuffer<LogEntry> (环形缓冲区)
        |
        v
  LogFilter.matches() (过滤)
        |
        v
  LogViewerState.entries (过滤后列表)
        |
        v
  LogListView (显示)
```

## 性能优化

1. **环形缓冲区**: 固定内存占用，自动淘汰旧日志
2. **固定行高**: ListView 使用 `itemExtent` 优化
3. **无状态解析**: AnsiParser 不创建中间对象
4. **选择性重建**: 使用细粒度 Provider 减少重建范围