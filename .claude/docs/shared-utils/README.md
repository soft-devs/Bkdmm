# shared/utils - 响应式工具

## 概述

响应式布局工具类，用于适配不同屏幕尺寸。

## 文件

| 文件 | 描述 |
|------|------|
| responsive_utils.dart | 响应式布局工具 |

## ResponsiveUtils

根据屏幕宽度判断设备类型和布局断点。

```dart
// 获取实例
final responsive = ResponsiveUtils(context);

// 判断设备类型
if (responsive.isMobile) {
  // 手机布局
} else if (responsive.isTablet) {
  // 平板布局
} else {
  // 桌面布局
}

// 获取断点
final breakpoint = responsive.breakpoint; // compact, medium, expanded
```

## 断点定义

| 断点 | 宽度范围 | 设备 |
|------|----------|------|
| compact | 0-599px | 手机 |
| medium | 600-839px | 平板竖屏 |
| expanded | 840px+ | 平板横屏/桌面 |

## 使用示例

```dart
Widget build(BuildContext context) {
  final responsive = ResponsiveUtils(context);

  return responsive.isCompact
    ? MobileLayout()
    : DesktopLayout();
}
```