# features/home - 首页

项目入口页面，显示项目历史和快速操作入口。

## 概述

该模块是应用的首页，提供创建项目、打开项目、查看历史记录等功能。

## 文件结构

```
features/home/
├── home_view.dart             # 首页视图
└── widgets/
    └── history_list_tile.dart # 历史记录列表项组件
```

## HomeView

首页主视图。

### 布局

```
┌─────────────────────────────────────────────────────────────┐
│ Logo + 应用名称                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ 新建项目     │  │ 打开项目     │  │ 从文件导入   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ 最近项目                                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 项目名称      │ 路径              │ 最后打开时间          │ │
│ ├───────────────┼───────────────────┼─────────────────────┤ │
│ │ My Project    │ /path/to/project  │ 2024-01-15 10:30    │ │
│ │ Test DB       │ /path/to/test     │ 2024-01-14 15:20    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ 清空历史记录                                                 │
└─────────────────────────────────────────────────────────────┘
```

### 功能

- **新建项目** - 打开创建项目对话框
- **打开项目** - 打开文件选择器选择项目文件
- **最近项目** - 显示项目历史记录列表
- **快速打开** - 点击历史记录快速打开项目
- **删除历史** - 从历史记录中移除项目

### 代码示例

```dart
class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildQuickActions(context, ref),
          _buildRecentProjects(historyState, ref),
        ],
      ),
    );
  }
}
```

## HistoryListTile

历史记录列表项组件。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| history | ProjectHistory | 历史记录数据 |
| onTap | VoidCallback? | 点击回调 |
| onDelete | VoidCallback? | 删除回调 |

### 显示内容

- 项目名称
- 项目路径
- 最后打开时间
- 删除按钮

## 状态管理

首页使用 `historyProvider` 管理项目历史：

```dart
// 读取历史记录
final history = ref.watch(historyProvider);

// 打开项目后添加历史
ref.read(historyProvider.notifier).addHistory(ProjectHistory(
  projectId: project.id,
  projectName: project.name,
  projectPath: path,
  lastOpened: DateTime.now(),
));

// 删除历史记录
ref.read(historyProvider.notifier).removeHistory(projectId);

// 清空所有历史
ref.read(historyProvider.notifier).clearHistory();
```

## 路由

首页是应用的根路由 `/`，打开项目后导航到 `/workspace`。

```dart
// 打开项目后导航
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const WorkspaceView()),
);
```

## 注意事项

1. **历史记录数量** - 默认最多保存 20 条历史记录
2. **文件有效性** - 历史记录中的文件可能已被删除，打开前需检查
3. **路径显示** - 长路径需要截断显示
4. **空状态** - 无历史记录时显示提示信息
5. **快捷键** - 支持 Ctrl+N 新建项目，Ctrl+O 打开项目