# shared/providers - 状态管理层

Riverpod 状态管理，提供全局状态和业务逻辑。

## 概述

该模块使用 Riverpod 进行状态管理，所有 Provider 使用 `StateNotifier` 模式管理状态。

## Provider 列表

| Provider | 文件 | 说明 |
|----------|------|------|
| projectProvider | project_provider.dart | 项目状态管理 |
| historyProvider | history_provider.dart | 项目历史记录管理 |
| settingsProvider | settings_provider.dart | 应用设置管理 |

## projectProvider

管理当前打开的项目状态。

### 状态类

```dart
class ProjectState {
  final Project? project;        // 当前项目
  final bool isLoading;          // 加载状态
  final String? error;           // 错误信息
  final bool isDirty;            // 是否有未保存的更改
  final DateTime? lastSavedAt;   // 最后保存时间
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `openProject(String path)` | 打开项目文件 |
| `createProject(...)` | 创建新项目 |
| `saveProject()` | 保存当前项目 |
| `closeProject()` | 关闭当前项目 |
| `addModule(Module module)` | 添加模块 |
| `updateModule(String id, Module module)` | 更新模块 |
| `removeModule(String id)` | 删除模块 |
| `createNewModule(...)` | 创建新模块实例 |

### 使用示例

```dart
// 读取状态
final projectState = ref.watch(projectProvider);
final project = projectState.project;

// 调用方法
ref.read(projectProvider.notifier).saveProject();
ref.read(projectProvider.notifier).addModule(module);
```

## historyProvider

管理项目历史记录。

### 状态类

```dart
class HistoryState {
  final List<ProjectHistory> recentProjects;  // 最近项目列表
  final int maxHistory;                       // 最大历史记录数
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `loadHistory()` | 加载历史记录 |
| `addHistory(ProjectHistory history)` | 添加历史记录 |
| `removeHistory(String projectId)` | 删除历史记录 |
| `clearHistory()` | 清空历史记录 |

## settingsProvider

管理应用设置。

### 状态类

```dart
class Settings {
  final ThemeMode themeMode;          // 主题模式
  final Color? accentColor;           // 强调色
  final String? defaultProjectPath;   // 默认项目路径
  final String language;              // 语言
  final bool autoSave;                // 自动保存
  final int autoSaveInterval;         // 自动保存间隔(秒)
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `loadSettings()` | 加载设置 |
| `setThemeMode(ThemeMode mode)` | 设置主题模式 |
| `setAccentColor(Color? color)` | 设置强调色 |
| `setLanguage(String lang)` | 设置语言 |

## 依赖关系

```
projectProvider
├── → StorageService (Hive存储)
├── → FileService (文件读写)
└── → HistoryService (历史记录)

historyProvider
└── → StorageService

settingsProvider
└── → StorageService
```

## 注意事项

1. **Provider 生命周期** - 使用 `ProviderScope` 包裹应用根组件
2. **状态不可变** - 状态对象使用 `copyWith()` 更新
3. **异步操作** - 文件操作为异步方法，需使用 `async/await`
4. **错误处理** - 状态中的 `error` 字段存储错误信息，UI 需处理显示
