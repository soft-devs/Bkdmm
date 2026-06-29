# Workspace API 详情

## WorkspaceView

主工作区视图，采用 IDEA 风格布局设计。

### 关键属性

| 属性 | 类型 | 描述 |
|------|------|------|
| key | Key? | Widget key |

### 关键方法

| 方法 | 参数 | 返回值 | 描述 |
|------|------|--------|------|
| initState | - | void | 初始化，检查是否有标签页 |
| build | context | Widget | 构建主布局 |
| _buildTabContent | project, tdTheme | Widget | 构建标签内容区域 |
| _buildEmptyTabContent | project, tdTheme | Widget | 构建空标签提示 |
| _buildEntityEditor | tab, project, tdTheme | Widget | 构建实体编辑器视图 |
| _buildModuleView | tab, project, tdTheme | Widget | 构建模块视图 |
| _buildERDiagram | module, tdTheme | Widget | 构建 ER 图画布 |
| _buildRelationView | tab, project, tdTheme | Widget | 构建关系视图 |
| _buildSettingsView | tdTheme | Widget | 构建设置视图 |
| _buildDatatypeView | tdTheme | Widget | 构建数据类型视图 |
| _buildPropertiesPanel | project, tdTheme | Widget | 构建右侧属性面板 |
| _buildStatusBar | project, projectState, tdTheme | Widget | 构建底部状态栏 |
| _showAddModuleDialog | - | Future<void> | 显示创建模块对话框 |
| _showAddEntityDialog | module | Future<void> | 显示创建表对话框 |

---

## LayoutNotifier (layoutProvider)

布局状态管理器，控制左侧视图、右侧面板、底部视图的显示与隐藏。

### 状态

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| activeLeftView | String? | 'module_tree' | 当前激活的左侧视图 ID |
| leftViewVisibility | Map<String, bool> | {} | 左侧视图可见性映射 |
| leftViewWidth | double | 260 | 左侧视图宽度 |
| rightViewVisible | bool | true | 右侧视图是否可见 |
| rightViewWidth | double | 280 | 右侧视图宽度 |
| activeBottomView | String? | null | 当前激活的底部视图 ID |
| bottomViewVisibility | Map<String, bool> | {} | 底部视图可见性映射 |
| bottomViewHeight | double | 200 | 底部视图高度 |
| iconBarWidth | double | 48 | 图标栏宽度 |

### 左侧视图方法

| 方法 | 参数 | 描述 |
|------|------|------|
| showLeftView | viewId | 显示指定左侧视图 |
| hideLeftView | - | 隐藏左侧视图 |
| toggleLeftView | viewId | 切换左侧视图显示状态 |
| setLeftViewWidth | width | 设置左侧视图宽度 (200-400) |

### 右侧视图方法

| 方法 | 参数 | 描述 |
|------|------|------|
| showRightView | - | 显示右侧属性面板 |
| hideRightView | - | 隐藏右侧属性面板 |
| toggleRightView | - | 切换右侧面板显示状态 |
| setRightViewWidth | width | 设置右侧面板宽度 (200-400) |

### 底部视图方法

| 方法 | 参数 | 描述 |
|------|------|------|
| showBottomView | viewId | 显示指定底部视图 |
| hideBottomView | - | 隐藏底部视图 |
| toggleBottomView | viewId | 切换底部视图显示状态 |
| setBottomViewHeight | height | 设置底部视图高度 (100-400) |

### 全局方法

| 方法 | 描述 |
|------|------|
| hideAllViews | 隐藏所有视图 |
| restoreDefaultLayout | 恢复默认布局 |
| handleViewShortcut | 处理视图快捷键 |

---

## TabNotifier (tabProvider)

标签页状态管理器，支持多标签页的打开、关闭、切换。

### 状态

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| tabs | List<WorkspaceTab> | [] | 标签页列表 |
| activeTabId | String? | null | 当前激活的标签 ID |
| maxVisibleTabs | int | 10 | 最大可见标签数 |

### 标签操作方法

| 方法 | 参数 | 描述 |
|------|------|------|
| openTab | tab | 打开标签或聚焦已存在标签 |
| openEntity | entity, moduleId | 打开实体编辑器标签 |
| openModule | module | 打开模块视图标签 |
| openRelation | moduleId, moduleName | 打开关系图标签 |
| openSettings | - | 打开设置标签 |
| openDatatype | - | 打开数据类型标签 |
| closeTab | tabId | 关闭指定标签 |
| closeAllTabs | - | 关闭所有标签 |
| closeOtherTabs | - | 关闭其他标签 |
| closeTabsToRight | - | 关闭右侧标签 |
| closeTabsToLeft | - | 关闭左侧标签 |

### 标签导航方法

| 方法 | 描述 |
|------|------|
| setActiveTab | 设置激活标签 |
| nextTab | 切换到下一个标签 |
| previousTab | 切换到上一个标签 |
| reorderTabs | 重排标签顺序 |

### 标签创建方法

| 方法 | 参数 | 返回值 | 描述 |
|------|------|--------|------|
| createTab | type, title, ... | WorkspaceTab | 创建新标签对象 |
| updateTabTitle | tabId, title, subtitle | void | 更新标签标题 |

### 派生 Providers

| Provider | 类型 | 描述 |
|----------|------|------|
| activeTabProvider | Provider<WorkspaceTab?> | 当前激活标签 |
| tabCountProvider | Provider<int> | 标签数量 |

---

## ModuleTree

模块树组件，展示项目的模块和表结构。

### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| project | Project | 项目数据 |

### 内部状态

| 属性 | 类型 | 描述 |
|------|------|------|
| _expandedModules | Set<String> | 展开的模块 ID 集合 |
| _selectedModuleId | String? | 选中的模块 ID |
| _selectedEntityId | String? | 选中的实体 ID |

### 回调

| 回调 | 参数 | 描述 |
|------|------|------|
| _toggleExpand | moduleId | 切换模块展开状态 |
| _selectModule | module | 选中模块并打开标签 |
| _selectEntity | entity, module | 选中实体并打开标签 |

---

## ModuleTreeItem

模块树项组件，显示单个模块及其下属实体。

### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| module | Module | 模块数据 |
| isExpanded | bool | 是否展开 |
| isSelected | bool | 是否选中 |
| selectedEntityId | String? | 选中的实体 ID |
| onToggleExpand | VoidCallback | 切换展开回调 |
| onSelectModule | VoidCallback | 选中模块回调 |
| onSelectEntity | Function(Entity) | 选中实体回调 |
| onDeleteModule | VoidCallback | 删除模块回调 |
| onDeleteEntity | Function(Entity) | 删除实体回调 |
| onRenameModule | VoidCallback | 重命名模块回调 |
| onRenameEntity | Function(Entity) | 重命名实体回调 |
| onOpenRelation | VoidCallback | 打开关系图回调 |
| tdTheme | TDThemeData | TDesign 主题数据 |

---

## WorkspaceTabBar

标签栏组件，支持滚动、右键菜单、快捷键。

### 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| onNewTab | VoidCallback? | null | 新建标签回调 |
| onSettingsTab | VoidCallback? | null | 设置标签回调 |
| showScrollButtons | bool | true | 是否显示滚动按钮 |

### 内部组件

| 组件 | 描述 |
|------|------|
| _TabItem | 单个标签项 |
| TabShortcuts | 标签导航快捷键处理器 |

---

## IconBar

图标栏主组件，控制左侧视图和底部视图的切换。

### 布局

- 上部区域 (UpperSection): 控制左侧视图
- 分割线
- 下部区域 (LowerSection): 控制底部视图

---

## WorkspaceShortcuts

工作区快捷键处理器。

### 支持的快捷键

| 快捷键 | 动作 |
|--------|------|
| Alt+1 | 切换模块树 |
| Alt+D | 切换数据类型视图 |
| Alt+P | 切换属性面板 |
| Alt+C | 切换控制台 |
| Alt+L | 切换日志 |
| Alt+O | 切换输出 |
| Ctrl+Shift+F12 | 隐藏所有视图 |
| Shift+Escape | 隐藏当前视图 |