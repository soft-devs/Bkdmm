# Workspace 模块

## 模块描述

Workspace 模块是 Bkdmm 应用的主工作区界面，负责整个项目的编辑环境。它采用 IDEA 风格的布局设计，包含：

- **布局管理**：左侧视图、右侧属性面板、底部视图的控制与切换
- **模块树**：展示项目的模块和表结构
- **标签栏**：多标签页管理，支持实体编辑器、模块视图、关系图等
- **工具栏**：顶部菜单栏、图标栏
- **快捷键系统**：视图切换、文件操作快捷键

## 布局结构

```
+-----------------------------------------------------+
| TopMenuBar (文件管理 | 视图管理 | 项目名 | 操作)    |
+----+------------------------------------------------+
|Icon| Tab Bar                                        |
|Bar +------------------------------------------------+
|    |                                                |
|左视|         Tab Content Area                       |
|图控|                                                |
|制  |                                                |
|----+------------------------------------------------+
|底视| BottomViewContainer (控制台/日志/输出)         |
|图控|                                                |
|制  |                                                |
+----+------------------------------------------------+
| StatusBar                                           |
+-----------------------------------------------------+
```

## 子目录结构

```
workspace/
|-- workspace.dart              # 模块导出文件
|-- views/
|   |-- workspace_view.dart     # 主工作区视图
|-- providers/
|   |-- layout_provider.dart    # 布局状态管理
|   |-- tab_provider.dart       # 标签页状态管理
|-- models/
|   |-- layout_state.dart       # 布局状态数据模型
|   |-- view_config.dart        # 视图配置数据模型
|-- constants/
|   |-- view_configs.dart       # 视图配置常量
|-- widgets/
|   |-- module_tree.dart        # 模块树组件
|   |-- module_tree_item.dart   # 模块树项组件
|   |-- tab_bar.dart            # 标签栏组件
|   |-- property_section.dart   # 属性分区组件
|   |-- property_field.dart     # 属性字段组件
|   |-- stat_tile.dart          # 统计卡片组件
|   |-- icon_bar/
|   |   |-- icon_bar.dart       # 图标栏主组件
|   |   |-- icon_bar_button.dart # 图标栏按钮
|   |   |-- upper_section.dart  # 上部区域(左侧视图控制)
|   |   |-- lower_section.dart  # 下部区域(底部视图控制)
|   |-- toolbar/
|   |   |-- top_menu_bar.dart   # 顶部菜单栏
|   |   |-- file_menu.dart      # 文件菜单
|   |   |-- view_menu.dart      # 视图菜单
|   |-- left_view/
|   |   |-- left_view_container.dart # 左侧视图容器
|   |-- bottom_view/
|   |   |-- bottom_view_container.dart # 底部视图容器
|   |-- shortcuts/
|   |   |-- workspace_shortcuts.dart # 工作区快捷键
|-- dialogs/
|   |-- module_dialogs.dart     # 模块/实体对话框
```

## 依赖关系

### 外部依赖

- `flutter_riverpod` - 状态管理
- `tdesign_flutter` - UI 组件库

### 内部依赖

- `shared/models/` - Project, Module, Entity 等数据模型
- `shared/providers/` - projectProvider 等全局状态
- `shared/widgets/` - TDPopupMenuButton 等共享组件
- `shared/utils/` - ResponsiveUtils 等工具
- `shared/services/` - StorageService 存储服务
- `shared/terminal/` - TerminalShell 终端组件
- `shared/log_viewer/` - LogViewerShell 日志组件
- `features/modeling/entity_editor/` - EntityEditorView 实体编辑器
- `features/modeling/er_diagram/` - ERDiagramCanvas ER 图画布
- `features/datatype/` - DataTypeView 数据类型视图
- `features/settings/` - SettingsView 设置视图

## API 索引表

### Views

| 名称 | 文件 | 描述 |
|------|------|------|
| WorkspaceView | views/workspace_view.dart | 主工作区视图，IDEA 风格布局 |

### Providers

| 名称 | 文件 | 描述 |
|------|------|------|
| layoutProvider | providers/layout_provider.dart | 布局状态管理 |
| tabProvider | providers/tab_provider.dart | 标签页状态管理 |
| activeTabProvider | providers/tab_provider.dart | 当前激活标签 |
| tabCountProvider | providers/tab_provider.dart | 标签数量 |

### Widgets

| 名称 | 文件 | 描述 |
|------|------|------|
| ModuleTree | widgets/module_tree.dart | 模块树组件 |
| ModuleTreeItem | widgets/module_tree_item.dart | 模块树项 |
| EntityTreeItem | widgets/module_tree_item.dart | 实体树项 |
| WorkspaceTabBar | widgets/tab_bar.dart | 标签栏组件 |
| TabShortcuts | widgets/tab_bar.dart | 标签快捷键处理器 |
| PropertySection | widgets/property_section.dart | 属性分区标题 |
| PropertyField | widgets/property_field.dart | 属性字段显示 |
| StatTile | widgets/stat_tile.dart | 统计卡片 |
| IconBar | widgets/icon_bar/icon_bar.dart | 图标栏主组件 |
| IconBarButton | widgets/icon_bar/icon_bar_button.dart | 图标栏按钮 |
| UpperSection | widgets/icon_bar/upper_section.dart | 上部区域 |
| LowerSection | widgets/icon_bar/lower_section.dart | 下部区域 |
| TopMenuBar | widgets/toolbar/top_menu_bar.dart | 顶部菜单栏 |
| FileMenuButton | widgets/toolbar/file_menu.dart | 文件菜单 |
| ViewMenuButton | widgets/toolbar/view_menu.dart | 视图菜单 |
| LeftViewContainer | widgets/left_view/left_view_container.dart | 左侧视图容器 |
| BottomViewContainer | widgets/bottom_view/bottom_view_container.dart | 底部视图容器 |
| WorkspaceShortcuts | widgets/shortcuts/workspace_shortcuts.dart | 工作区快捷键 |

### Dialogs

| 名称 | 文件 | 描述 |
|------|------|------|
| showAddModuleDialog | dialogs/module_dialogs.dart | 创建模块对话框 |
| showAddEntityDialog | dialogs/module_dialogs.dart | 创建表对话框 |
| showDeleteModuleDialog | dialogs/module_dialogs.dart | 删除模块对话框 |
| showDeleteEntityDialog | dialogs/module_dialogs.dart | 删除表对话框 |
| showRenameModuleDialog | dialogs/module_dialogs.dart | 重命名模块对话框 |
| showRenameEntityDialog | dialogs/module_dialogs.dart | 重命名表对话框 |

### Models

| 名称 | 文件 | 描述 |
|------|------|------|
| LayoutState | models/layout_state.dart | 布局状态数据模型 |
| ViewConfig | models/view_config.dart | 视图配置数据模型 |
| ViewPosition | models/view_config.dart | 视图位置枚举 |
| TabState | providers/tab_provider.dart | 标签页状态数据模型 |
| WorkspaceTab | providers/tab_provider.dart | 单个标签数据模型 |
| TabType | providers/tab_provider.dart | 标签类型枚举 |

### Constants

| 名称 | 文件 | 描述 |
|------|------|------|
| ViewConfigs | constants/view_configs.dart | 视图配置常量集合 |
| WorkspaceShortcutKeys | widgets/shortcuts/workspace_shortcuts.dart | 快捷键常量定义 |
| WorkspaceShortcutHelp | widgets/shortcuts/workspace_shortcuts.dart | 快捷键帮助信息 |