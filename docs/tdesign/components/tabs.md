# Tabs 选项卡

用于在不同内容区域之间切换。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDTabs(
  tabs: [
    TDTab(text: '标签一'),
    TDTab(text: '标签二'),
    TDTab(text: '标签三'),
  ],
  children: [
    Center(child: Text('内容一')),
    Center(child: Text('内容二')),
    Center(child: Text('内容三')),
  ],
),
```

### 带徽标

```dart
TDTabs(
  tabs: [
    TDTab(text: '全部'),
    TDTab(text: '未读', badge: TDBadge(count: 5)),
    TDTab(text: '已读'),
  ],
),
```

### 可滑动

```dart
TDTabs(
  tabs: [
    TDTab(text: '标签一'),
    TDTab(text: '标签二'),
    TDTab(text: '标签三'),
    TDTab(text: '标签四'),
    TDTab(text: '标签五'),
  ],
  scrollable: true,
),
```

### 不同位置

```dart
TDTabs(
  tabs: [TDTab(text: '标签一'), TDTab(text: '标签二')],
  tabBarPosition: TDTabBarPosition.top,
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| tabs | `List<TDTab>` | - | 标签列表 |
| children | `List<Widget>?` | - | 对应内容 |
| scrollable | `bool` | `false` | 是否可滑动 |
| tabBarPosition | `TDTabBarPosition` | `top` | 标签栏位置 |
| currentIndex | `int` | `0` | 当前索引 |
| onChange | `ValueChanged<int>?` | - | 切换回调 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/tabs)