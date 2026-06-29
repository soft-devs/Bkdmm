# shared/providers - 状态管理

## 概述

使用 Riverpod 进行全局状态管理，提供项目、历史、设置等核心状态。

## Provider清单

| Provider | 文件 | 说明 |
|----------|------|------|
| projectNotifierProvider | project_provider.dart | 项目状态管理 |
| currentProjectProvider | project_provider.dart | 当前项目 |
| historyNotifierProvider | history_provider.dart | 项目历史 |
| settingsProvider | settings_provider.dart | 全局设置 |
| projectSettingsProvider | settings_provider.dart | 项目设置 |

## 核心Provider详解

### projectNotifierProvider

项目状态的核心管理器，提供完整的项目操作流程。

**状态结构**:
```dart
class ProjectState {
  final Project? project;           // 当前项目
  final String? projectPath;        // 项目文件路径
  final bool isDirty;               // 是否有未保存更改
  final bool isLoading;             // 是否正在加载/保存
  final String? error;              // 错误信息
  final DateTime? lastSavedAt;      // 最后保存时间
  final DateTime? lastAutoSavedAt;  // 最后自动保存时间
  final ProjectStatistics? statistics; // 项目统计
  final List<ProjectHistory> recentProjects; // 最近项目列表
}
```

**常用方法**:
- `createProject()` - 创建新项目
- `openProject(path)` - 打开项目
- `saveProject()` - 保存项目
- `saveProjectAs(path)` - 另存为
- `closeProject()` - 关闭项目
- `addModule(module)` - 添加模块
- `updateModule(id, module)` - 更新模块
- `removeModule(id)` - 删除模块

### historyNotifierProvider

管理项目打开历史。

**状态**: `List<ProjectHistory>`

**常用方法**:
- `refresh()` - 刷新历史列表
- `add(history)` - 添加历史记录
- `remove(path)` - 删除历史记录
- `clear()` - 清空历史

### settingsProvider

全局应用设置。

**状态结构**:
```dart
class AppSettings {
  final String themeMode;           // 主题模式: light/dark/system
  final Color? accentColor;         // 强调色
  final double editorFontSize;      // 编辑器字体大小
  final bool showLineNumbers;       // 显示行号
  final bool enableCodeCompletion;  // 代码补全
  final int autoSaveInterval;       // 自动保存间隔(秒)
  final String? defaultDatabase;    // 默认数据库类型
  // 默认字段配置
  final bool defaultFieldsRevision;
  final bool defaultFieldsCreatedBy;
  final bool defaultFieldsCreatedTime;
  final bool defaultFieldsUpdatedBy;
  final bool defaultFieldsUpdatedTime;
}
```

### projectSettingsProvider

项目级别设置，可继承全局设置。

**状态结构**:
```dart
class ProjectSettings {
  final bool inheritDefaultDatabase; // 是否继承全局数据库设置
  final bool inheritDefaultFields;   // 是否继承全局字段设置
  final String? defaultDatabase;      // 项目默认数据库
  // 项目默认字段配置
  final bool? defaultFieldsRevision;
  final bool? defaultFieldsCreatedBy;
  final bool? defaultFieldsCreatedTime;
  final bool? defaultFieldsUpdatedBy;
  final bool? defaultFieldsUpdatedTime;
}
```

## 使用示例

```dart
// 读取状态
final project = ref.watch(currentProjectProvider);
final isDirty = ref.watch(isProjectDirtyProvider);

// 调用方法
ref.read(projectNotifierProvider.notifier).saveProject();
ref.read(historyNotifierProvider.notifier).refresh();

// 监听变化
ref.listen<ProjectState>(projectNotifierProvider, (prev, next) {
  if (next.isDirty && !prev?.isDirty) {
    // 项目变为脏状态
  }
});
```

## 状态更新模式

```dart
// 通过Notifier更新
ref.read(projectNotifierProvider.notifier).updateModule(id, module);

// 设置Provider直接更新
ref.read(settingsProvider.notifier).setThemeMode('dark');
```

## 坑点

1. **read vs watch**: 调用方法用 `ref.read()`，显示状态用 `ref.watch()`
2. **状态不可变**: 状态更新必须通过Notifier的方法，不可直接赋值
3. **异步操作**: 保存/加载操作是异步的，需要等待完成
4. **错误处理**: 监听 `error` 字段显示错误信息

## 详细文档

- [data-model.md](data-model.md) - Provider状态结构详解
- [pitfalls.md](pitfalls.md) - 已知坑点