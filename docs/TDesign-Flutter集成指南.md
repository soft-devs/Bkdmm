# TDesign Flutter 组件库集成指南

> 适用于 Bkdmm 项目的 TDesign Flutter 组件库集成文档

---

## 一、TDesign Flutter 简介

### 1.1 概述

TDesign 是腾讯开源的企业级设计体系，提供了一致、高效、易用的 UI 组件。

| 属性 | 详情 |
|------|------|
| **来源** | 腾讯 TDesign 团队 |
| **设计体系** | 企业级设计语言 |
| **组件数量** | 50+ 组件 |
| **许可证** | MIT 开源 |
| **维护状态** | 活跃维护 |

### 1.2 核心特性

- ✅ **企业级设计** - 经过腾讯内部大规模验证
- ✅ **一致性** - 统一的设计语言和交互规范
- ✅ **国际化** - 支持多语言
- ✅ **主题定制** - 灵活的主题配置
- ✅ **无障碍** - 符合 WCAG 标准

### 1.3 为什么选择 TDesign

| 对比项 | TDesign | Material 3 | Ant Design |
|--------|---------|------------|------------|
| 企业风格 | ✅ 专业 | ⚠️ Google 风格 | ✅ 企业风格 |
| 中文支持 | ✅ 原生 | ⚠️ 需配置 | ✅ 原生 |
| 组件丰富度 | ✅ 50+ | ✅ 内置 | ⚠️ Flutter 版较少 |
| 学习曲线 | ✅ 低 | ⚠️ 中 | ⚠️ 中 |
| 定制性 | ✅ 高 | ✅ 高 | ⚠️ 中 |

---

## 二、安装与配置

### 2.1 添加依赖

```yaml
# pubspec.yaml
dependencies:
  # TDesign Flutter
  tdesign_flutter: ^0.1.4
```

### 2.2 安装命令

```bash
flutter pub add tdesign_flutter
```

### 2.3 初始化配置

```dart
// main.dart
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TDTheme(
      data: TDThemeData.defaultData(),
      child: MaterialApp(
        title: 'Bkdmm',
        theme: ThemeData(
          useMaterial3: true,
          // 与 TDesign 主题融合
          colorScheme: ColorScheme.fromSeed(
            seedColor: TDTheme.of(context).brandColor,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
```

### 2.4 主题配置

```dart
// 自定义主题
class AppTheme {
  static TDThemeData get lightTheme => TDThemeData.defaultData().copyWith(
    // 品牌色
    brandColor: const Color(0xFF0052D9),

    // 功能色
    successColor: const Color(0xFF2BA471),
    warningColor: const Color(0xFFE37318),
    errorColor: const Color(0xFFD54941),
    linkColor: const Color(0xFF0052D9),

    // 背景色
    bgColor: const Color(0xFFFFFFFF),
    bgColorContainer: const Color(0xFFF3F3F3),

    // 文字色
    textColorPrimary: const Color(0xFF000000),
    textColorSecondary: const Color(0xFF666D72),
    textColorDisabled: const Color(0xFFBBBEBF),
    textColorPlaceholder: const Color(0xFFBBBEBF),
  );

  static TDThemeData get darkTheme => TDThemeData.defaultData().copyWith(
    brandColor: const Color(0xFF4582E6),
    bgColor: const Color(0xFF1D1D1D),
    bgColorContainer: const Color(0xFF2C2C2C),
    textColorPrimary: const Color(0xFFFFFFFF),
    textColorSecondary: const Color(0xFFBFBFBF),
  );
}
```

---

## 三、组件清单

### 3.1 基础组件

| 组件 | TDesign Widget | 用途 |
|------|---------------|------|
| **按钮** | `TDButton` | 主要操作、次要操作、危险操作 |
| **图标** | `TDIcon` | 图标显示 |
| **链接** | `TDLink` | 文本链接 |
| **分割线** | `TDDivider` | 内容分割 |

### 3.2 表单组件

| 组件 | TDesign Widget | 用途 |
|------|---------------|------|
| **输入框** | `TDInput` | 文本输入、搜索框 |
| **文本域** | `TDTextarea` | 多行文本输入 |
| **选择器** | `TDPicker` | 单选、多选、级联选择 |
| **开关** | `TDSwitch` | 开关切换 |
| **复选框** | `TDCheckbox` | 多选 |
| **单选框** | `TDRadio` | 单选 |
| **滑块** | `TDSlider` | 数值调节 |
| **评分** | `TDRate` | 星级评分 |
| **上传** | `TDUpload` | 文件上传 |

### 3.3 数据展示组件

| 组件 | TDesign Widget | 用途 |
|------|---------------|------|
| **表格** | `TDTable` | 数据表格 |
| **标签** | `TDTag` | 标签标记 |
| **徽标** | `TDBadge` | 状态标记 |
| **头像** | `TDAvatar` | 用户头像 |
| **卡片** | `TDCard` | 卡片容器 |
| **描述列表** | `TDDescription` | 键值对展示 |
| **进度条** | `TDProgress` | 进度展示 |
| **空状态** | `TDEmpty` | 空数据提示 |
| **折叠面板** | `TDCollapse` | 内容折叠 |

### 3.4 导航组件

| 组件 | TDesign Widget | 用途 |
|------|---------------|------|
| **导航栏** | `TDNavBar` | 页面顶部导航 |
| **标签页** | `TDTabBar` | 内容切换 |
| **侧边导航** | `TDSideBar` | 侧边菜单 |
| **分段器** | `TDSegmentedControl` | 分段选择 |
| **步骤条** | `TDSteps` | 步骤指引 |
| **菜单** | `TDMenu` | 下拉菜单 |

### 3.5 反馈组件

| 组件 | TDesign Widget | 用途 |
|------|---------------|------|
| **对话框** | `TDDialog` | 模态对话框 |
| **消息提示** | `TDMessage` | 轻量提示 |
| **通知** | `TDNotice` | 全局通知 |
| **弹出层** | `TDPopup` | 底部弹出 |
| **加载** | `TDLoading` | 加载状态 |
| **抽屉** | `TDDrawer` | 侧边抽屉 |
| **气泡确认框** | `TDPopconfirm` | 确认气泡 |

---

## 四、核心组件使用示例

### 4.1 按钮 TDButton

```dart
// 主要按钮
TDButton(
  text: '创建实体',
  theme: TDButtonTheme.primary,
  size: TDButtonSize.large,
  icon: TDIcons.add,
  onTap: () => _createEntity(),
),

// 次要按钮
TDButton(
  text: '取消',
  theme: TDButtonTheme.defaultTheme,
  onTap: () => Navigator.pop(context),
),

// 危险按钮
TDButton(
  text: '删除',
  theme: TDButtonTheme.danger,
  icon: TDIcons.delete,
  onTap: () => _deleteEntity(),
),

// 图标按钮
TDButton(
  theme: TDButtonTheme.primary,
  icon: TDIcons.settings,
  size: TDButtonSize.small,
  onTap: () => _openSettings(),
),
```

### 4.2 输入框 TDInput

```dart
// 基础输入框
TDInput(
  hintText: '请输入表名',
  leftLabel: '表名',
  controller: _nameController,
  onChanged: (value) => _validateName(value),
),

// 搜索输入框
TDInput(
  hintText: '搜索表',
  leftIcon: TDIcons.search,
  backgroundColor: Colors.grey.shade100,
  onChanged: (value) => _search(value),
),

// 带清除按钮
TDInput(
  hintText: '请输入字段名',
  controller: _controller,
  clearBtn: true,
  onClear: () => _controller.clear(),
),

// 多行输入
TDTextarea(
  hintText: '请输入描述',
  maxLength: 200,
  maxLines: 4,
),
```

### 4.3 选择器 TDPicker

```dart
// 单选选择器
TDPicker(
  title: '数据类型',
  data: ['VARCHAR', 'INT', 'BIGINT', 'DATE', 'DATETIME'],
  selectedIndex: _selectedIndex,
  onConfirm: (index) {
    setState(() => _selectedIndex = index);
  },
),

// 多选选择器
TDMultiPicker(
  title: '选择字段',
  data: _fields,
  selectedIndexes: _selectedIndexes,
  onConfirm: (indexes) {
    setState(() => _selectedIndexes = indexes);
  },
),

// 级联选择器
TDCascadePicker(
  title: '选择数据库',
  data: _cascadeData,
  onConfirm: (values) {
    print('Selected: $values');
  },
),
```

### 4.4 对话框 TDDialog

```dart
// 确认对话框
showDialog(
  context: context,
  builder: (context) => TDDialog(
    title: '确认删除',
    content: '删除后数据将无法恢复，确定要删除吗？',
    actions: [
      TDDialogAction(
        text: '取消',
        action: () => Navigator.pop(context),
      ),
      TDDialogAction(
        text: '删除',
        theme: TDButtonTheme.danger,
        action: () {
          _delete();
          Navigator.pop(context);
        },
      ),
    ],
  ),
);

// 表单对话框
showDialog(
  context: context,
  builder: (context) => TDDialog(
    title: '新建实体',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TDInput(
          hintText: '表名',
          leftLabel: '表名',
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        TDInput(
          hintText: '中文名',
          leftLabel: '中文名',
          controller: _chnNameController,
        ),
      ],
    ),
    actions: [
      TDDialogAction(
        text: '取消',
        action: () => Navigator.pop(context),
      ),
      TDDialogAction(
        text: '确定',
        theme: TDButtonTheme.primary,
        action: () {
          _createEntity();
          Navigator.pop(context);
        },
      ),
    ],
  ),
);
```

### 4.5 消息提示 TDMessage

```dart
// 成功消息
TDMessage.showSuccess(context, message: '保存成功');

// 错误消息
TDMessage.showError(context, message: '操作失败，请重试');

// 警告消息
TDMessage.showWarning(context, message: '该操作可能导致数据丢失');

// 加载消息
TDMessage.showLoading(context, message: '正在保存...');

// 关闭消息
TDMessage.hide(context);
```

### 4.6 标签 TDTag

```dart
// 基础标签
TDTag(
  text: 'VARCHAR',
  theme: TDTagTheme.primary,
  size: TDTagSize.small,
),

// 可关闭标签
TDTag(
  text: '筛选条件',
  closable: true,
  onClose: () => _removeFilter(),
),

// 多彩标签
TDTag(
  text: '主键',
  theme: TDTagTheme.warning,
  icon: TDIcons.lock,
),
```

### 4.7 卡片 TDCard

```dart
// 基础卡片
TDCard(
  title: '用户表',
  subtitle: 'sys_user',
  actions: [
    TDButton(
      text: '编辑',
      theme: TDButtonTheme.defaultTheme,
      size: TDButtonSize.small,
    ),
  ],
  child: Column(
    children: [
      _buildFieldRow('id', 'BIGINT', pk: true),
      _buildFieldRow('name', 'VARCHAR(50)'),
      _buildFieldRow('email', 'VARCHAR(100)'),
    ],
  ),
),

// 无标题卡片
TDCard(
  child: TDTable(
    columns: _columns,
    data: _data,
  ),
),
```

### 4.8 表格 TDTable

```dart
TDTable(
  columns: [
    TDTableColumn(
      title: '字段名',
      key: 'name',
      width: 120,
    ),
    TDTableColumn(
      title: '类型',
      key: 'type',
      width: 100,
    ),
    TDTableColumn(
      title: '是否主键',
      key: 'isPk',
      width: 80,
      render: (value) => value ? TDTag(text: 'PK', theme: TDTagTheme.warning) : null,
    ),
  ],
  data: [
    {'name': 'id', 'type': 'BIGINT', 'isPk': true},
    {'name': 'name', 'type': 'VARCHAR(50)', 'isPk': false},
  ],
  onRowClick: (row) => _editField(row),
),
```

### 4.9 导航栏 TDNavBar

```dart
TDNavBar(
  title: 'ER 图编辑器',
  leftBarItems: [
    TDNavBarItem(
      icon: TDIcons.chevron_left,
      action: () => Navigator.pop(context),
    ),
  ],
  rightBarItems: [
    TDNavBarItem(
      icon: TDIcons.settings,
      action: () => _openSettings(),
    ),
    TDNavBarItem(
      icon: TDIcons.more,
      action: () => _showMoreOptions(),
    ),
  ],
),
```

### 4.10 标签页 TDTabBar

```dart
TDTabBar(
  tabs: [
    TDTab(text: '基本信息'),
    TDTab(text: '字段列表'),
    TDTab(text: '索引'),
    TDTab(text: '关系'),
  ],
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() => _currentIndex = index);
  },
),
```

---

## 五、与现有架构集成

### 5.1 与 InteractiveViewer + GraphView 集成

```dart
// ER 图编辑器主组件
class ERDiagramEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TDesign 导航栏
      appBar: TDNavBar(
        title: 'ER 图编辑器',
        rightBarItems: [
          TDNavBarItem(
            icon: TDIcons.save,
            action: () => _save(),
          ),
        ],
      ),

      body: Stack(
        children: [
          // InteractiveViewer 包裹 GraphView
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: GraphView(
              graph: _graph,
              algorithm: SugiyamaAlgorithm(_config),
              builder: (node) => _buildERNode(node), // 使用 TDesign 组件
            ),
          ),

          // TDesign 工具栏
          Positioned(
            top: 16,
            right: 16,
            child: _buildToolbar(),
          ),
        ],
      ),

      // TDesign 浮动按钮
      floatingActionButton: TDButton(
        text: '新建实体',
        theme: TDButtonTheme.primary,
        icon: TDIcons.add,
        onTap: () => _createEntity(),
      ),
    );
  }

  // 使用 TDesign 组件构建节点
  Widget _buildERNode(Node node) {
    final entity = node.key!.value as Entity;
    return TDCard(
      title: entity.title,
      subtitle: entity.chnname,
      size: TDCardSize.small,
      child: Column(
        children: entity.fields.map((f) => _buildFieldRow(f)).toList(),
      ),
    );
  }

  Widget _buildFieldRow(Field field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 主键标记
          if (field.pk)
            TDTag(text: 'PK', theme: TDTagTheme.warning, size: TDTagSize.small),
          const SizedBox(width: 8),
          // 字段名
          Expanded(
            child: TDText(
              field.name,
              fontWeight: field.pk ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          // 类型标签
          TDTag(
            text: field.type,
            theme: TDTagTheme.defaultTheme,
            size: TDTagSize.small,
          ),
        ],
      ),
    );
  }

  // TDesign 工具栏
  Widget _buildToolbar() {
    return TDCard(
      size: TDCardSize.small,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TDButton(
            icon: TDIcons.zoom_in,
            theme: TDButtonTheme.defaultTheme,
            size: TDButtonSize.small,
            onTap: () => _zoomIn(),
          ),
          TDButton(
            icon: TDIcons.zoom_out,
            theme: TDButtonTheme.defaultTheme,
            size: TDButtonSize.small,
            onTap: () => _zoomOut(),
          ),
          TDButton(
            icon: TDIcons.autofit_width,
            theme: TDButtonTheme.defaultTheme,
            size: TDButtonSize.small,
            onTap: () => _fitToScreen(),
          ),
        ],
      ),
    );
  }
}
```

### 5.2 替换现有 Material 组件

| 现有组件 | 替换为 TDesign | 说明 |
|---------|---------------|------|
| `ElevatedButton` | `TDButton` | 统一按钮风格 |
| `TextButton` | `TDButton(theme: default)` | 次要按钮 |
| `TextField` | `TDInput` | 统一输入框 |
| `AlertDialog` | `TDDialog` | 统一对话框 |
| `SnackBar` | `TDMessage` | 统一消息提示 |
| `Card` | `TDCard` | 统一卡片 |
| `Chip` | `TDTag` | 统一标签 |
| `AppBar` | `TDNavBar` | 统一导航栏 |
| `BottomNavigationBar` | `TDTabBar` | 统一底部导航 |

---

## 六、最佳实践

### 6.1 主题切换

```dart
class ThemeProvider extends StateNotifier<ThemeMode> {
  ThemeProvider() : super(ThemeMode.light);

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

// 在应用中使用
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return TDTheme(
      data: themeMode == ThemeMode.light
        ? AppTheme.lightTheme
        : AppTheme.darkTheme,
      child: MaterialApp(
        themeMode: themeMode,
        // ...
      ),
    );
  }
}
```

### 6.2 响应式布局

```dart
// 使用 TDLayout 实现响应式
TDLayout(
  mobile: _buildMobileLayout(),
  tablet: _buildTabletLayout(),
  desktop: _buildDesktopLayout(),
),
```

### 6.3 国际化

```dart
// 配置国际化
MaterialApp(
  localizationsDelegates: [
    TDLocalizations.delegate,
    // 其他 delegate...
  ],
  supportedLocales: [
    const Locale('zh', 'CN'),
    const Locale('en', 'US'),
  ],
),
```

---

## 七、注意事项

### 7.1 兼容性

- ✅ Flutter SDK >= 3.0.0
- ✅ 支持 iOS、Android、Web、Windows、macOS、Linux
- ⚠️ 部分组件在桌面端可能需要额外配置

### 7.2 性能优化

```dart
// 使用 const 构造函数
const TDButton(text: '确定'),

// 使用 TDBuilder 按需更新
TDBuilder(
  builder: (context) {
    // 只在需要时更新
    return TDText(_count.toString());
  },
),

// 大列表使用 TDListView
TDListView(
  itemCount: 1000,
  itemBuilder: (context, index) => TDCell(title: 'Item $index'),
),
```

### 7.3 与 GraphView 兼容性

- ✅ TDesign 组件可直接用作 GraphView 的节点 Widget
- ✅ InteractiveViewer 与 TDesign 无冲突
- ⚠️ 避免在节点内部使用滚动组件（可能导致手势冲突）

---

## 八、参考资源

| 资源 | 链接 |
|------|------|
| TDesign Flutter pub.dev | https://pub.dev/packages/tdesign_flutter |
| TDesign Flutter GitHub | https://github.com/Tencent/tdesign-flutter |
| TDesign 设计规范 | https://tdesign.tencent.com/ |
| TDesign 组件演示 | https://tdesign.tencent.com/flutter/components/button |

---

## 九、迁移清单

- [ ] 添加 tdesign_flutter 依赖
- [ ] 配置 TDTheme 主题
- [ ] 替换按钮组件（TDButton）
- [ ] 替换输入框组件（TDInput）
- [ ] 替换对话框组件（TDDialog）
- [ ] 替换导航栏组件（TDNavBar）
- [ ] 替换消息提示（TDMessage）
- [ ] 替换标签组件（TDTag）
- [ ] 替换卡片组件（TDCard）
- [ ] 更新主题配置支持深色模式
- [ ] 测试与 GraphView + InteractiveViewer 的兼容性

---

> **总结**: TDesign Flutter 提供了完整的企业级 UI 组件，与现有的 InteractiveViewer + GraphView 架构完美兼容。通过统一的设计语言，可以显著提升 Bkdmm 项目的用户体验和开发效率。