# Navbar 导航栏

用于页面顶部的导航栏。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDNavbar(
  title: '页面标题',
),
```

### 带返回按钮

```dart
TDNavbar(
  title: '页面标题',
  leftBarItems: [
    TDNavBarItem(
      icon: TDIcons.chevron_left,
      onTap: () {
        Navigator.of(context).pop();
      },
    ),
  ],
),
```

### 带右侧操作

```dart
TDNavbar(
  title: '页面标题',
  rightBarItems: [
    TDNavBarItem(
      icon: TDIcons.more,
      onTap: () {
        // 更多操作
      },
    ),
  ],
),
```

### 带左侧菜单

```dart
TDNavbar(
  title: '页面标题',
  leftBarItems: [
    TDNavBarItem(
      icon: TDIcons.home,
      onTap: () {},
    ),
    TDNavBarItem(
      icon: TDIcons.menu,
      onTap: () {},
    ),
  ],
),
```

### 自定义标题

```dart
TDNavbar(
  centerWidget: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TDText('自定义标题'),
      Icon(TDIcons.edit),
    ],
  ),
),
```

### 透明背景

```dart
TDNavbar(
  title: '透明导航栏',
  backgroundColor: Colors.transparent,
),
```

### 带副标题

```dart
TDNavbar(
  title: '标题',
  subTitle: '副标题',
),
```

## API

### TDNavbar Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| title | `String?` | - | 标题 |
| subTitle | `String?` | - | 副标题 |
| centerWidget | `Widget?` | - | 自定义中间组件 |
| leftBarItems | `List<TDNavBarItem>?` | - | 左侧按钮列表 |
| rightBarItems | `List<TDNavBarItem>?` | - | 右侧按钮列表 |
| backgroundColor | `Color?` | - | 背景色 |
| titleFont | `Font?` | - | 标题字体 |

### TDNavBarItem

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| icon | `IconData?` | - | 图标 |
| text | `String?` | - | 文字 |
| onTap | `VoidCallback?` | - | 点击事件 |