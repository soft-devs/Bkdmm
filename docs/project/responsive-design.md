# 响应式设计方案

## 概述

本方案为 Bkdmm 项目提供统一的响应式布局解决方案，适用于 Flutter 桌面应用 (Windows/macOS/Linux)。

**设计依据**：
- Material Design 3 断点规范
- Flutter 官方 flutter_adaptive_scaffold 包
- Flutter 官方 adaptive_breakpoints 包

## 断点系统

基于 Material Design 3 规范，与 flutter_adaptive_scaffold 保持一致：

| 断点 | 宽度范围 | 典型设备 | 网格列数 | 边距 | 间距 |
|------|---------|---------|---------|------|------|
| `compact` | 0-600dp | 手机竖屏 | 4 | 16px | 16px |
| `medium` | 600-840dp | 平板竖屏、手机横屏 | 8 | 24px | 24px |
| `mediumLarge` | 840-1200dp | 平板横屏 | 12 | 24px | 24px |
| `large` | 1200-1600dp | 桌面显示器 | 12 | 24px | 24px |
| `extraLarge` | 1600dp+ | 大型显示器 | 12 | 24px | 24px |

### 与官方实现对比

**flutter_adaptive_scaffold 断点定义**：
```dart
// 来源: flutter_adaptive_scaffold-0.3.3+1/lib/src/breakpoints.dart
Breakpoint.small:   0-600dp
Breakpoint.medium:  600-840dp
Breakpoint.mediumLarge: 840-1200dp
Breakpoint.large:   1200-1600dp
Breakpoint.extraLarge: 1600dp+
```

**本方案断点定义**：
```dart
// 与官方保持一致
ScreenBreakpoint.compact:     0-600dp
ScreenBreakpoint.medium:      600-840dp
ScreenBreakpoint.mediumLarge: 840-1200dp
ScreenBreakpoint.large:       1200-1600dp
ScreenBreakpoint.extraLarge:  1600dp+
```

## 对话框尺寸预设

基于 Material Design 3 规范和桌面应用最佳实践设计：

| 预设 | 基础宽度 | 基础高度 | 屏幕占比 | 最大倍数 | 适用场景 |
|------|---------|---------|---------|---------|---------|
| `small` | 320px | 自适应 | 85% | 1.3× | 简单确认、选择 |
| `medium` | 480px | 自适应 | 85% | 1.3× | 表单录入、编辑 |
| `large` | 600px | 自适应 | 80% | 1.3× | 复杂表单、多步骤 |
| `extraLarge` | 720px | 自适应 | 75% | 1.25× | 设置面板、多栏 |
| `form` | 520px | 自适应 | 85% | 1.3× | 数据录入表单 |
| `settings` | 720px | 480px | 75% | 1.25× | 设置面板 |
| `project` | 640px | 420px | 80% | 1.3× | 创建/打开项目 |

## 尺寸计算公式

```
dialogWidth = (screenWidth × screenRatio).clamp(baseWidth, baseWidth × maxScale)
```

参数说明：
- `screenWidth`: 当前屏幕宽度
- `screenRatio`: 屏幕占比系数
- `baseWidth`: 基础宽度
- `maxScale`: 最大放大倍数

## 使用方法

### 1. 基本使用

```dart
import '../../../shared/utils/responsive_utils.dart';

// 获取对话框宽度
final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);

// 获取对话框尺寸 (宽+高)
final dialogSize = ResponsiveUtils.getDialogSize(context, DialogSizePreset.project);

// 获取表单字段间距 (统一 16px)
final spacing = ResponsiveUtils.getFormFieldSpacing(context);
```

### 2. 在对话框中使用

```dart
@override
Widget build(BuildContext context) {
  final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);
  final formSpacing = ResponsiveUtils.getFormFieldSpacing(context);

  return TDAlertDialog(
    title: '创建模块',
    contentWidget: SizedBox(
      width: dialogWidth,
      child: Column(
        children: [
          TDInput(...),
          SizedBox(height: formSpacing),
          TDInput(...),
        ],
      ),
    ),
  );
}
```

### 3. 断点判断

```dart
// 获取当前断点
final breakpoint = ResponsiveUtils.getBreakpoint(context);

// 判断断点类型
if (ResponsiveUtils.isCompact(context)) {
  // 紧凑布局: < 600dp
} else if (ResponsiveUtils.isMedium(context)) {
  // 中等布局: 600-840dp
} else if (ResponsiveUtils.isMediumLargeOrLarger(context)) {
  // 中大及以上布局: >= 840dp
} else if (ResponsiveUtils.isLargeOrLarger(context)) {
  // 大及以上布局: >= 1200dp
}
```

### 4. 使用 Widget 包装

```dart
// 仅设置宽度
ResponsiveDialogWidth(
  preset: DialogSizePreset.form,
  child: YourFormContent(),
)

// 设置宽度和高度
ResponsiveDialogSize(
  preset: DialogSizePreset.settings,
  child: YourSettingsContent(),
)
```

### 5. 自定义参数

```dart
// 覆盖基础宽度
final width = ResponsiveUtils.getDialogWidth(
  context,
  DialogSizePreset.form,
  customBaseWidth: 600,
);

// 覆盖屏幕占比
final width = ResponsiveUtils.getDialogWidth(
  context,
  DialogSizePreset.form,
  customScreenRatio: 0.9,  // 占屏幕 90%
);
```

### 6. 网格布局

```dart
// 获取网格列数
final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);

// 获取网格最大宽度
final maxWidth = ResponsiveUtils.getGridMaxWidth(context);
```

## 迁移指南

### 从旧代码迁移

**旧代码:**
```dart
final screenWidth = MediaQuery.of(context).size.width;
const double baseWidth = 500.0;
final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);
```

**新代码:**
```dart
final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);
```

## 文件位置

- 工具类: `lib/shared/utils/responsive_utils.dart`

## 参考资料

### Flutter 官方包

1. **flutter_adaptive_scaffold**
   - 来源: Flutter 官方
   - 路径: `C:\Users\admin\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn\flutter_adaptive_scaffold-0.3.3+1\`
   - 主要特点:
     - 完整的断点系统 (Breakpoints 类)
     - 平台区分 (desktop/mobile)
     - 自动布局切换 (SlotLayout)
     - 动画过渡支持

2. **adaptive_breakpoints**
   - 来源: Flutter 官方
   - 路径: `C:\Users\admin\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn\adaptive_breakpoints-0.1.7\`
   - 主要特点:
     - 纯断点定义
     - 完整的断点系统表 (13个细分断点)
     - AdaptiveWindowType 设备分类

### Material Design 3 规范

- 官方文档: https://m3.material.io/foundations/layout/understand-layout/breakpoints
- 断点定义:
  - Compact: < 600dp
  - Medium: 600-840dp
  - Expanded: 840-1200dp
  - Large: 1200-1600dp
  - Extra Large: > 1600dp

## 最佳实践

1. **统一使用预设**: 优先使用 `DialogSizePreset` 预设，避免硬编码尺寸
2. **表单间距统一**: 使用 `getFormFieldSpacing()` 获取统一的 16px 间距
3. **响应式测试**: 在不同窗口尺寸下测试对话框显示效果
4. **最小窗口限制**: 桌面应用应设置最小窗口尺寸 (800×600)
5. **断点判断优先级**: 使用 `isLargeOrLarger()` 而非精确匹配断点