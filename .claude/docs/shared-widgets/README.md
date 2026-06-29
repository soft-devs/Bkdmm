# shared/widgets - 通用UI组件

## 概述

提供应用级别的通用UI组件，基于 TDesign Flutter 构建。

## 依赖

- `tdesign_flutter` - TDesign 组件库
- `flutter_riverpod` - 状态管理

## 组件清单

| 组件 | 描述 | 使用场景 |
|------|------|----------|
| AppScaffold | 应用脚手架 | 页面布局基础 |
| LoadingOverlay | 加载遮罩 | 异步操作等待 |
| TDPopupMenu | TDesign弹出菜单 | 下拉菜单 |

## AppScaffold

统一的应用页面脚手架，集成导航栏、侧边栏等。

```dart
AppScaffold(
  title: '页面标题',
  actions: [IconButton(...)],
  body: ContentView(),
)
```

## LoadingOverlay

全屏加载遮罩，阻止用户交互。

```dart
LoadingOverlay.show(context, message: '加载中...');
// 异步操作
await someAsyncOperation();
LoadingOverlay.hide(context);
```

## TDPopupMenu

TDesign 风格的弹出菜单。

```dart
TDPopupMenu(
  items: [
    TDPopupMenuItem(title: '选项1', onTap: () {}),
    TDPopupMenuItem(title: '选项2', onTap: () {}),
  ],
  child: IconButton(...),
)
```