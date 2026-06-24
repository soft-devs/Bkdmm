# Bkdmm 工作区视图重构工作流设计

## 一、需求分析

### 1.1 新布局结构

```
┌─────────────────────────────────────────────────────────────────────┐
│  顶部菜单栏                                                         │
│  [文件管理 ▼] │ [视图管理 ▼] │ ... 其他操作按钮                     │
├────┬────────────────────────────────────────────────────────────┬────┤
│    │  中间左侧视图 │         中间内容视图         │ 中间右侧视图 │    │
│ 图 │  (可切换显示) │                           │ (可切换显示) │ 图 │
│ 标 │              │                           │              │ 标 │
│ 栏 │              │                           │              │ 栏 │
│    │              │                           │              │    │
│ ↑  │              │                           │              │ ↓  │
│ 上 │              │                           │              │ 下 │
│ 部 │              │                           │              │ 部 │
│    │              │                           │              │    │
├────┴────────────────────────────────────────────────────────────┴────┤
│  底部视图 (可切换显示)                                              │
│  [控制台] [日志] [输出] ...                                         │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 核心组件定义

| 组件 | 说明 | 状态管理 |
|------|------|---------|
| **顶部菜单栏** | 文件管理 + 视图管理 | 固定显示 |
| **左侧图标栏** | 纵向图标按钮，上下分区 | 固定显示 |
| **中间左侧视图** | 模块树、数据类型等 | 可切换显示/隐藏 |
| **中间内容视图** | 编辑器主区域 | 保持现有实现 |
| **中间右侧视图** | 属性面板等 | 可切换显示/隐藏 |
| **底部视图** | 控制台、日志等 | 可切换显示/隐藏 |

---

## 二、详细设计

### 2.1 顶部菜单栏设计

```
┌─────────────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐                               │
│  │ 文件管理   ▼ │  │ 视图管理   ▼ │   [保存] [生成] [设置] [更多] │
│  └──────────────┘  └──────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘

文件管理菜单:
┌─────────────────────┐
│ 新建项目            │
│ 打开项目            │
│ 打开最近项目...     │
│ ─────────────────── │
│ 保存项目      Ctrl+S│
│ 另存为...           │
│ ─────────────────── │
│ 项目设置            │
│ ─────────────────── │
│ 关闭项目            │
└─────────────────────┘

视图管理菜单:
┌─────────────────────┐
│ 左侧视图            │
│   ☑ 模块树    Alt+1 │
│   ☐ 数据类型  Alt+D │
│ ─────────────────── │
│ 右侧视图            │
│   ☑ 属性面板  Alt+P │
│ ─────────────────── │
│ 底部视图            │
│   ☐ 控制台    Alt+C │
│   ☐ 日志      Alt+L │
│   ☐ 输出      Alt+O │
│ ─────────────────── │
│ 全部隐藏 Ctrl+Shift+F12│
│ 恢复默认布局        │
└─────────────────────┘
```

### 2.2 左侧图标栏设计

```
┌────────┐
│  上部  │  ← 控制左侧视图
│  图标  │
│ ────── │
│  [📊]1 │  模块树 (Alt+1)
│  [📋]D │  数据类型 (Alt+D)
│        │
│ ═══════│  ← 分割线
│        │
│  下部  │  ← 控制底部视图
│  图标  │
│ ────── │
│  [⚙]C  │  控制台 (Alt+C)
│  [📝]L │  日志 (Alt+L)
│  [📤]O │  输出 (Alt+O)
└────────┘

图标状态:
- 高亮背景 = 视图已打开
- 灰色背景 = 视图已隐藏
- 数字徽章 = 快捷键提示
```

### 2.3 视图映射关系

```
图标栏上部 → 左侧视图:
┌────────┐        ┌─────────────────┐
│ [📊]1  │  →     │ 模块树面板      │
│ [📋]D  │  →     │ 数据类型面板    │
└────────┘        └─────────────────┘

图标栏下部 → 底部视图:
┌────────┐        ┌─────────────────┐
│ [⚙]C   │  →     │ 控制台面板      │
│ [📝]L  │  →     │ 日志面板        │
│ [📤]O  │  →     │ 输出面板        │
└────────┘        └─────────────────┘

右侧视图: (保留现有属性面板)
┌─────────────────┐
│ 属性面板        │  ← 通过视图管理菜单或 Alt+P 控制
└─────────────────┘
```

---

## 三、实现工作流

### 3.1 工作流概览

```
Phase 1: 状态管理重构
   ↓
Phase 2: 左侧图标栏实现
   ↓
Phase 3: 顶部菜单栏实现
   ↓
Phase 4: 视图切换逻辑
   ↓
Phase 5: 底部视图集成
   ↓
Phase 6: 快捷键系统
   ↓
Phase 7: 测试和优化
```

### 3.2 详细工作流步骤

#### Phase 1: 状态管理重构 (1天)

**任务:**
1. 创建新的布局状态管理 Provider
2. 定义视图配置模型
3. 实现视图切换逻辑

**输出文件:**
```
lib/features/workspace/
├── providers/
│   ├── layout_provider.dart       # 布局状态管理
│   └── view_config_provider.dart  # 视图配置
├── models/
│   ├── view_config.dart           # 视图配置模型
│   └── layout_state.dart          # 布局状态模型
```

**模型设计:**
```dart
/// 视图配置
class ViewConfig {
  final String id;
  final String title;
  final IconData icon;
  final String shortcut;
  final ViewPosition position;  // left, right, bottom
  final bool isDefaultVisible;
  final double defaultWidth;
  final double defaultHeight;
}

/// 视图位置
enum ViewPosition {
  left,    // 左侧视图
  right,   // 右侧视图
  bottom,  // 底部视图
}

/// 布局状态
class LayoutState {
  // 左侧视图
  final String? activeLeftView;     // 当前激活的左侧视图
  final Map<String, bool> leftViewVisibility;  // 各左侧视图可见性
  
  // 右侧视图
  final bool rightViewVisible;      // 右侧视图是否可见
  final double rightViewWidth;      // 右侧视图宽度
  
  // 底部视图
  final String? activeBottomView;   // 当前激活的底部视图
  final Map<String, bool> bottomViewVisibility; // 各底部视图可见性
  final double bottomViewHeight;    // 底部视图高度
  
  // 图标栏
  final double iconBarWidth;        // 图标栏宽度 (48px)
}
```

---

#### Phase 2: 左侧图标栏实现 (1天)

**任务:**
1. 创建图标栏组件
2. 实现上下分区布局
3. 实现图标按钮和状态显示

**输出文件:**
```
lib/features/workspace/
├── widgets/
│   ├── icon_bar/
│   │   ├── icon_bar.dart          # 图标栏主组件
│   │   ├── icon_button.dart       # 图标按钮组件
│   │   ├── upper_section.dart     # 上部图标区
│   │   └── lower_section.dart     # 下部图标区
```

**组件设计:**
```dart
/// 图标栏
class IconBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);
    
    return Container(
      width: 48,
      color: tdTheme.bgColorContainer,
      child: Column(
        children: [
          // 上部图标区 (控制左侧视图)
          UpperSection(
            views: layoutState.leftViewConfigs,
            activeView: layoutState.activeLeftView,
            onViewToggle: (viewId) => _toggleLeftView(ref, viewId),
          ),
          
          // 分割线
          Divider(height: 1, color: tdTheme.componentBorderColor),
          
          // 下部图标区 (控制底部视图)
          LowerSection(
            views: layoutState.bottomViewConfigs,
            activeView: layoutState.activeBottomView,
            onViewToggle: (viewId) => _toggleBottomView(ref, viewId),
          ),
        ],
      ),
    );
  }
}
```

---

#### Phase 3: 顶部菜单栏实现 (1天)

**任务:**
1. 创建顶部菜单栏组件
2. 实现文件管理下拉菜单
3. 实现视图管理下拉菜单

**输出文件:**
```
lib/features/workspace/
├── widgets/
│   ├── toolbar/
│   │   ├── top_menu_bar.dart      # 顶部菜单栏
│   │   ├── file_menu.dart         # 文件管理菜单
│   │   └── view_menu.dart         # 视图管理菜单
```

**组件设计:**
```dart
/// 顶部菜单栏
class TopMenuBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    
    return Container(
      height: 40,
      color: tdTheme.bgColorContainer,
      child: Row(
        children: [
          // 文件管理菜单
          FileMenuButton(),
          
          SizedBox(width: 8),
          
          // 视图管理菜单
          ViewMenuButton(),
          
          Spacer(),
          
          // 其他操作按钮
          TDButton(icon: TDIcons.save, type: text, onTap: _saveProject),
          TDButton(icon: TDIcons.code, type: text, onTap: _generateCode),
          TDButton(icon: TDIcons.setting, type: text, onTap: _openSettings),
        ],
      ),
    );
  }
}

/// 视图管理菜单
class ViewMenuButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(layoutProvider);
    
    return TDPopupMenuButton(
      content: '视图管理',
      items: _buildMenuItems(layoutState),
      onSelected: (value) => _handleMenuAction(ref, value),
    );
  }
  
  List<TDPopupMenuItem> _buildMenuItems(LayoutState state) {
    return [
      // 左侧视图
      TDPopupMenuItem(value: 'left_header', label: '── 左侧视图 ──', disabled: true),
      ...state.leftViewConfigs.map((v) =>
        TDPopupMenuItem(
          value: 'left_${v.id}',
          icon: v.icon,
          label: '${v.title}    ${v.shortcut}',
          checked: state.leftViewVisibility[v.id],
        ),
      ),
      
      TDPopupMenuItem.divider(),
      
      // 右侧视图
      TDPopupMenuItem(value: 'right_header', label: '── 右侧视图 ──', disabled: true),
      TDPopupMenuItem(
        value: 'right_properties',
        icon: TDIcons.info_circle,
        label: '属性面板    Alt+P',
        checked: state.rightViewVisible,
      ),
      
      TDPopupMenuItem.divider(),
      
      // 底部视图
      TDPopupMenuItem(value: 'bottom_header', label: '── 底部视图 ──', disabled: true),
      ...state.bottomViewConfigs.map((v) =>
        TDPopupMenuItem(
          value: 'bottom_${v.id}',
          icon: v.icon,
          label: '${v.title}    ${v.shortcut}',
          checked: state.bottomViewVisibility[v.id],
        ),
      ),
      
      TDPopupMenuItem.divider(),
      
      // 布局操作
      TDPopupMenuItem(value: 'hide_all', icon: TDIcons.fullscreen, label: '全部隐藏'),
      TDPopupMenuItem(value: 'restore', icon: TDIcons.refresh, label: '恢复默认布局'),
    ];
  }
}
```

---

#### Phase 4: 视图切换逻辑实现 (1天)

**任务:**
1. 实现左侧视图切换逻辑
2. 实现底部视图切换逻辑
3. 实现视图显示/隐藏动画

**输出文件:**
```
lib/features/workspace/
├── widgets/
│   ├── view_container/
│   │   ├── left_view_container.dart   # 左侧视图容器
│   │   ├── bottom_view_container.dart # 底部视图容器
│   │   └── view_panel.dart            # 视图面板基类
```

**视图切换逻辑:**
```dart
/// 左侧视图切换
void toggleLeftView(WidgetRef ref, String viewId) {
  final layoutState = ref.read(layoutProvider);
  
  // 如果点击的是当前激活的视图，则隐藏
  if (layoutState.activeLeftView == viewId) {
    ref.read(layoutProvider.notifier).hideLeftView();
  } else {
    // 否则激活该视图
    ref.read(layoutProvider.notifier).showLeftView(viewId);
  }
}

/// 底部视图切换
void toggleBottomView(WidgetRef ref, String viewId) {
  final layoutState = ref.read(layoutProvider);
  
  // 如果点击的是当前激活的视图，则隐藏
  if (layoutState.activeBottomView == viewId) {
    ref.read(layoutProvider.notifier).hideBottomView();
  } else {
    // 否则激活该视图
    ref.read(layoutProvider.notifier).showBottomView(viewId);
  }
}

/// 左侧视图容器
class LeftViewContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(layoutProvider);
    final activeView = layoutState.activeLeftView;
    
    // 无激活视图时返回空
    if (activeView == null) {
      return SizedBox.shrink();
    }
    
    // 根据激活视图ID返回对应面板
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: _getViewPanel(activeView, ref),
    );
  }
  
  Widget _getViewPanel(String viewId, WidgetRef ref) {
    switch (viewId) {
      case 'module_tree':
        return ModuleTreePanel();
      case 'datatype':
        return DataTypePanel();
      default:
        return SizedBox.shrink();
    }
  }
}
```

---

#### Phase 5: 底部视图集成 (1天)

**任务:**
1. 创建底部视图容器
2. 集成现有日志功能
3. 创建控制台和输出面板

**输出文件:**
```
lib/features/workspace/
├── widgets/
│   ├── bottom_views/
│   │   ├── console_panel.dart     # 控制台面板
│   │   ├── log_panel.dart         # 日志面板
│   │   ├── output_panel.dart      # 输出面板
```

**底部视图设计:**
```dart
/// 底部视图容器
class BottomViewContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(layoutProvider);
    final activeView = layoutState.activeBottomView;
    
    if (activeView == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      height: layoutState.bottomViewHeight,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tdTheme.componentBorderColor)),
      ),
      child: Column(
        children: [
          // 视图标签栏
          _buildViewTabs(layoutState, ref),
          
          // 视图内容
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: _getViewPanel(activeView),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewTabs(LayoutState state, WidgetRef ref) {
    return Container(
      height: 32,
      child: Row(
        children: state.bottomViewConfigs.map((v) =>
          _ViewTab(
            config: v,
            isActive: state.activeBottomView == v.id,
            onTap: () => ref.read(layoutProvider.notifier).showBottomView(v.id),
          ),
        ).toList(),
      ),
    );
  }
}
```

---

#### Phase 6: 快捷键系统 (0.5天)

**任务:**
1. 定义快捷键映射
2. 实现快捷键处理
3. 集成到工作区

**快捷键设计:**
```dart
/// 工作区快捷键
class WorkspaceShortcuts {
  static const Map<String, String> viewShortcuts = {
    'Alt+1': 'module_tree',      // 模块树
    'Alt+D': 'datatype',         // 数据类型
    'Alt+P': 'properties',       // 属性面板
    'Alt+C': 'console',          // 控制台
    'Alt+L': 'log',              // 日志
    'Alt+O': 'output',           // 输出
  };
  
  static const Map<String, String> actionShortcuts = {
    'Ctrl+Shift+F12': 'hide_all_views',  // 隐藏所有视图
    'Shift+Escape': 'hide_current_view', // 隐藏当前视图
    'F12': 'last_view',                   // 最后一个视图
  };
}

/// 快捷键处理器
void handleShortcut(WidgetRef ref, String shortcut) {
  // 视图切换
  if (WorkspaceShortcuts.viewShortcuts.containsKey(shortcut)) {
    final viewId = WorkspaceShortcuts.viewShortcuts[shortcut]!;
    _toggleViewByShortcut(ref, viewId);
  }
  
  // 布局操作
  if (WorkspaceShortcuts.actionShortcuts.containsKey(shortcut)) {
    final action = WorkspaceShortcuts.actionShortcuts[shortcut]!;
    _handleLayoutAction(ref, action);
  }
}
```

---

#### Phase 7: 测试和优化 (1天)

**任务:**
1. 视图切换测试
2. 快捷键测试
3. 响应式布局测试
4. 性能优化

**测试清单:**
```
功能测试:
☐ 点击图标栏切换左侧视图
☐ 点击图标栏切换底部视图
☐ 视图管理菜单操作
☐ 文件管理菜单操作
☐ 快捷键切换视图
☐ 快捷键隐藏/恢复视图
☐ 视图宽度调整
☐ 视图高度调整

响应式测试:
☐ 紧凑模式 (< 1024px)
☐ 标准模式 (1024-1440px)
☐ 宽屏模式 (> 1440px)

性能测试:
☐ 视图切换动画流畅度
☐ 多视图同时打开性能
☐ 内存使用情况
```

---

## 四、文件结构规划

```
lib/features/workspace/
├── workspace.dart                    # 模块导出
├── views/
│   └── workspace_view.dart           # 工作区主视图 (重构)
├── providers/
│   ├── layout_provider.dart          # 布局状态管理 (新增)
│   ├── view_config_provider.dart     # 视图配置 (新增)
│   └── tab_provider.dart             # Tab 状态管理 (保留)
├── models/
│   ├── layout_state.dart             # 布局状态模型 (新增)
│   ├── view_config.dart              # 视图配置模型 (新增)
│   └── view_position.dart            # 视图位置枚举 (新增)
├── widgets/
│   ├── icon_bar/
│   │   ├── icon_bar.dart             # 图标栏主组件 (新增)
│   │   ├── icon_button.dart          # 图标按钮 (新增)
│   │   ├── upper_section.dart        # 上部图标区 (新增)
│   │   └── lower_section.dart        # 下部图标区 (新增)
│   ├── toolbar/
│   │   ├── top_menu_bar.dart         # 顶部菜单栏 (新增)
│   │   ├── file_menu.dart            # 文件管理菜单 (新增)
│   │   └── view_menu.dart            # 视图管理菜单 (新增)
│   ├── view_container/
│   │   ├── left_view_container.dart  # 左侧视图容器 (新增)
│   │   ├── bottom_view_container.dart# 底部视图容器 (新增)
│   │   └── right_view_container.dart # 右侧视图容器 (新增)
│   ├── left_views/
│   │   ├── module_tree_panel.dart    # 模块树面板 (重构)
│   │   └── datatype_panel.dart       # 数据类型面板 (新增)
│   ├── bottom_views/
│   │   ├── console_panel.dart        # 控制台面板 (新增)
│   │   ├── log_panel.dart            # 日志面板 (新增)
│   │   └── output_panel.dart         # 输出面板 (新增)
│   ├── tab_bar.dart                  # Tab 栏组件 (保留)
│   └── module_tree.dart              # 模块树组件 (保留，调整)
├── services/
│   └ layout_persistence_service.dart # 布局持久化 (新增)
└── constants/
    └ view_configs.dart               # 视图配置常量 (新增)
```

---

## 五、实施时间表

| Phase | 任务 | 预计工时 | 依赖 |
|-------|------|---------|------|
| Phase 1 | 状态管理重构 | 1天 | 无 |
| Phase 2 | 左侧图标栏实现 | 1天 | Phase 1 |
| Phase 3 | 顶部菜单栏实现 | 1天 | Phase 1 |
| Phase 4 | 视图切换逻辑 | 1天 | Phase 1, 2 |
| Phase 5 | 底部视图集成 | 1天 | Phase 1, 4 |
| Phase 6 | 快捷键系统 | 0.5天 | Phase 1-5 |
| Phase 7 | 测试和优化 | 1天 | Phase 1-6 |

**总预计工时:** 5.5天

---

## 六、兼容性策略

### 6.1 渐进式迁移

```
步骤:
1. 保留现有 WorkspaceView 作为 WorkspaceViewLegacy
2. 创建新的 WorkspaceView 作为 WorkspaceViewNew
3. 提供设置选项切换新旧视图
4. 验证稳定后移除旧版本
```

### 6.2 数据兼容

```
布局配置:
- 独立存储，不影响项目数据
- 支持导入/导出布局配置
- 默认布局内置，无需配置
```

---

## 七、验收标准

### 7.1 功能验收

```
✓ 左侧图标栏正常显示和切换
✓ 顶部菜单栏菜单操作正常
✓ 左侧视图切换流畅
✓ 底部视图切换流畅
✓ 右侧视图显示/隐藏正常
✓ 快捷键功能正常
✓ 视图管理菜单复选框状态正确
✓ 布局持久化正常
```

### 7.2 性能验收

```
✓ 视图切换延迟 < 200ms
✓ 内存占用无显著增加
✓ 动画流畅无卡顿
```

### 7.3 UI验收

```
✓ 符合 TDesign 设计规范
✓ 亮色/暗色主题适配正常
✓ 响应式布局适配正常
```

---

**文档版本:** v1.0
**创建日期:** 2024-01-15
**用途:** 工作区视图重构实施指导