# Workspace 数据模型

## LayoutState

布局状态数据模型，管理整个工作区的视图布局。

### 属性定义

```dart
class LayoutState {
  // ========== 左侧视图 ==========
  /// 当前激活的左侧视图ID
  final String? activeLeftView;

  /// 左侧视图可见性映射
  final Map<String, bool> leftViewVisibility;

  /// 左侧视图宽度
  final double leftViewWidth;

  // ========== 右侧视图 ==========
  /// 右侧视图是否可见
  final bool rightViewVisible;

  /// 右侧视图宽度
  final double rightViewWidth;

  // ========== 底部视图 ==========
  /// 当前激活的底部视图ID
  final String? activeBottomView;

  /// 底部视图可见性映射
  final Map<String, bool> bottomViewVisibility;

  /// 底部视图高度
  final double bottomViewHeight;

  // ========== 图标栏 ==========
  /// 图标栏宽度
  final double iconBarWidth;

  // ========== 视图配置 ==========
  /// 左侧视图配置列表
  final List<ViewConfig> leftViewConfigs;

  /// 底部视图配置列表
  final List<ViewConfig> bottomViewConfigs;
}
```

### 默认值

| 属性 | 默认值 |
|------|--------|
| activeLeftView | null |
| leftViewVisibility | {} |
| leftViewWidth | 260 |
| rightViewVisible | true |
| rightViewWidth | 280 |
| activeBottomView | null |
| bottomViewVisibility | {} |
| bottomViewHeight | 200 |
| iconBarWidth | 48 |
| leftViewConfigs | [] |
| bottomViewConfigs | [] |

### 辅助方法

| 方法 | 返回值 | 描述 |
|------|--------|------|
| isLeftViewVisible(viewId) | bool | 检查左侧视图是否可见 |
| isBottomViewVisible(viewId) | bool | 检查底部视图是否可见 |
| hasAnyViewOpen() | bool | 检查是否有任何视图打开 |
| copyWith(...) | LayoutState | 创建副本 |

---

## ViewConfig

视图配置数据模型，定义单个视图的属性。

### 属性定义

```dart
class ViewConfig {
  /// 视图ID
  final String id;

  /// 视图标题
  final String title;

  /// 图标
  final IconData icon;

  /// 快捷键
  final String shortcut;

  /// 视图位置
  final ViewPosition position;

  /// 默认是否可见
  final bool isDefaultVisible;

  /// 默认宽度
  final double defaultWidth;

  /// 默认高度
  final double defaultHeight;

  /// 排序顺序
  final int order;
}
```

### 默认值

| 属性 | 默认值 |
|------|--------|
| isDefaultVisible | true |
| defaultWidth | 260 |
| defaultHeight | 200 |
| order | 0 |

---

## ViewPosition

视图位置枚举。

```dart
enum ViewPosition {
  /// 左侧视图
  left,

  /// 右侧视图
  right,

  /// 底部视图
  bottom,
}
```

---

## TabState

标签页状态数据模型。

### 属性定义

```dart
class TabState {
  /// 标签页列表
  final List<WorkspaceTab> tabs;

  /// 当前激活的标签ID
  final String? activeTabId;

  /// 最大可见标签数
  final int maxVisibleTabs;
}
```

### 默认值

| 属性 | 默认值 |
|------|--------|
| tabs | [] |
| activeTabId | null |
| maxVisibleTabs | 10 |

### 派生属性

| 属性 | 类型 | 描述 |
|------|------|------|
| hasTabs | bool | 是否有标签页 |
| activeTab | WorkspaceTab? | 当前激活的标签 |
| activeIndex | int | 当前激活标签的索引 |

### 辅助方法

| 方法 | 返回值 | 描述 |
|------|--------|------|
| hasTab(id) | bool | 检查标签是否存在 |
| getTab(id) | WorkspaceTab? | 获取指定标签 |
| isEntityOpen(entityId) | bool | 检查实体是否已打开 |
| isModuleOpen(moduleId) | bool | 检查模块是否已打开 |

---

## WorkspaceTab

单个标签数据模型。

### 属性定义

```dart
class WorkspaceTab {
  /// 标签ID
  final String id;

  /// 标签类型
  final TabType type;

  /// 标签标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 图标标识
  final String? icon;

  /// 所属模块ID
  final String? moduleId;

  /// 所属实体ID
  final String? entityId;
}
```

### 工厂构造函数

| 构造函数 | 参数 | 描述 |
|----------|------|------|
| forEntity | id, entity, moduleId | 创建实体标签 |
| forModule | id, module | 创建模块标签 |
| forRelation | id, moduleId, moduleName | 创建关系图标签 |
| settings | id | 创建设置标签 |
| datatype | id | 创建数据类型标签 |

### 序列化

| 方法 | 描述 |
|------|------|
| toJson() | 转换为 JSON |
| fromJson(json) | 从 JSON 解析 |

---

## TabType

标签类型枚举。

```dart
enum TabType {
  /// 实体编辑器
  entity,

  /// 关系图
  relation,

  /// 设置
  settings,

  /// 模块视图
  module,

  /// 数据类型
  datatype,
}
```

---

## ViewConfigs 常量

视图配置常量集合，定义所有可用的视图。

### 左侧视图

| ID | 标题 | 快捷键 | 默认可见 | 排序 |
|----|------|--------|----------|------|
| module_tree | 模块树 | Alt+1 | true | 1 |
| datatype | 数据类型 | Alt+D | false | 2 |

### 底部视图

| ID | 标题 | 快捷键 | 默认可见 | 排序 |
|----|------|--------|----------|------|
| terminal | 终端 | Alt+T | false | 1 |
| log | 日志 | Alt+L | false | 2 |
| output | 输出 | Alt+O | false | 3 |

### 快捷键映射

```dart
static const Map<String, String> shortcutToViewId = {
  'Alt+1': 'module_tree',
  'Alt+D': 'datatype',
  'Alt+P': 'properties',
  'Alt+T': 'terminal',
  'Alt+L': 'log',
  'Alt+O': 'output',
};
```

### 辅助方法

| 方法 | 返回值 | 描述 |
|------|--------|------|
| defaultLeftVisibility | Map<String, bool> | 获取左侧视图默认可见性 |
| defaultBottomVisibility | Map<String, bool> | 获取底部视图默认可见性 |
| getLeftViewById(id) | ViewConfig? | 根据 ID 获取左侧视图配置 |
| getBottomViewById(id) | ViewConfig? | 根据 ID 获取底部视图配置 |