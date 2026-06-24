# features/workspace - 工作区

多 Tab 工作区管理，包含模块树、标签页和属性面板。

## 概述

该模块是项目编辑的主界面，提供三栏布局：左侧模块树、中间 Tab 区域、右侧属性面板。

## 文件结构

```
features/workspace/
├── workspace.dart             # 模块导出
├── views/
│   └── workspace_view.dart    # 工作区主视图
├── providers/
│   └── tab_provider.dart      # Tab 状态管理
└── widgets/
    ├── module_tree.dart       # 模块树组件
    └── tab_bar.dart           # Tab 栏组件
```

## 布局结构

```
┌─────────────────────────────────────────────────────────────┐
│ MenuBar (项目名 + 保存按钮 + 更多操作菜单)                     │
├─────────┬─────────────────────────────────┬─────────────────┤
│ Module  │ Tab Bar (可关闭、可滚动)          │ Properties Panel│
│ Tree    ├─────────────────────────────────┤ (可隐藏)         │
│         │                                   │                 │
│ - Module│         Tab Content Area          │ Entity Info     │
│   - Table│                                   │ Statistics      │
│   - Table│  (EntityEditor / ERDiagram / ...) │ Timestamps      │
│         │                                   │                 │
├─────────┴─────────────────────────────────┴─────────────────┤
│ StatusBar (项目信息 + Tab数量 + 保存状态)                     │
└─────────────────────────────────────────────────────────────┘
```

## WorkspaceView

工作区主视图，整合所有子组件。

### 功能

- **菜单栏** - 项目名称、保存、关闭、设置等操作
- **模块树** - 显示项目模块和实体结构
- **Tab 区域** - 多标签页编辑
- **属性面板** - 显示选中项的属性
- **状态栏** - 显示项目状态信息

### Tab 类型

| 类型 | 说明 |
|------|------|
| entity | 实体编辑器 |
| module | 模块视图 (ER图) |
| relation | 关系视图 |
| settings | 项目设置 |
| datatype | 数据类型管理 |

## TabProvider

管理 Tab 状态。

### 状态类

```dart
class TabState {
  final List<WorkspaceTab> tabs;   // 所有打开的 Tab
  final int activeIndex;           // 当前激活的 Tab 索引
}
```

### WorkspaceTab

```dart
class WorkspaceTab {
  final String id;                 // Tab 唯一标识
  final String title;              // Tab 标题
  final TabType type;              // Tab 类型
  final String? moduleId;          // 所属模块 ID
  final String? entityId;          // 实体 ID (entity Tab)
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `openModule(Module module)` | 打开模块 Tab |
| `openEntity(Module module, Entity entity)` | 打开实体 Tab |
| `openSettings()` | 打开设置 Tab |
| `openDatatype()` | 打开数据类型 Tab |
| `closeTab(String id)` | 关闭指定 Tab |
| `closeAllTabs()` | 关闭所有 Tab |
| `switchTab(String id)` | 切换 Tab |

## ModuleTree

左侧模块树组件。

### 功能

- 显示模块和实体树状结构
- 双击打开模块/实体 Tab
- 右键菜单：添加模块、添加实体、删除
- 支持展开/折叠

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| project | Project | 项目数据 |
| onAddModule | VoidCallback | 添加模块回调 |
| onAddEntity | Function(Module) | 添加实体回调 |
| onSelectModule | Function(Module) | 选择模块回调 |

## WorkspaceTabBar

Tab 栏组件。

### 功能

- 显示所有打开的 Tab
- Tab 可关闭 (×按钮)
- Tab 可滚动 (超出宽度)
- 新建 Tab 按钮
- 设置 Tab 按钮

### 键盘快捷键

| 快捷键 | 功能 |
|------|------|
| Ctrl+S | 保存项目 |
| Ctrl+W | 关闭当前 Tab |
| Ctrl+Tab | 切换到下一个 Tab |

## 注意事项

1. **Tab 状态同步** - Tab 内容需与 projectProvider 状态同步
2. **关闭项目** - 关闭项目时需先关闭所有 Tab
3. **属性面板** - 可隐藏，隐藏后编辑区域扩大
4. **Tab 数量限制** - 建议 Tab 数量不超过 20 个避免性能问题
5. **快捷键** - 使用 TabShortcuts 包裹以支持键盘操作