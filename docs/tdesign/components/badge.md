# Badge 徽标

用于标记位置的小图标或数字，常用于角标。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDBadge(
  count: 5,
  child: Icon(TDIcons.message),
),
```

### 小红点

```dart
TDBadge(
  dot: true,
  child: Icon(TDIcons.message),
),
```

### 最大值

```dart
TDBadge(
  count: 100,
  maxCount: 99,
  child: Icon(TDIcons.message),
),
```

### 不同主题

```dart
TDBadge(
  count: 5,
  theme: TDBadgeTheme.danger,
  child: Icon(TDIcons.message),
),
```

### 独立使用

```dart
TDBadge(
  count: 5,
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| count | `int?` | - | 计数值 |
| dot | `bool` | `false` | 是否显示为红点 |
| maxCount | `int` | `99` | 最大显示数 |
| theme | `TDBadgeTheme` | `danger` | 主题色 |
| child | `Widget?` | - | 子组件 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/badge)