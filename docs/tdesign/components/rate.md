# Rate 评分

用于对事物进行评分。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
var rate = 3.0;

TDRate(
  value: rate,
  onRatingChange: (value) {
    setState(() {
      rate = value;
    });
  },
),
```

### 半星评分

```dart
TDRate(
  value: 3.5,
  half: true,
  onRatingChange: (value) {},
),
```

### 自定义数量

```dart
TDRate(
  value: 3.0,
  count: 5,
  onRatingChange: (value) {},
),
```

### 自定义图标

```dart
TDRate(
  value: 3.0,
  icon: TDIcons.heart,
  onRatingChange: (value) {},
),
```

### 禁用状态

```dart
TDRate(
  value: 4.0,
  disabled: true,
  onRatingChange: (value) {},
),
```

### 只读状态

```dart
TDRate(
  value: 4.5,
  readonly: true,
  onRatingChange: (value) {},
),
```

### 带文字

```dart
TDRate(
  value: 4.0,
  showText: true,
  texts: ['很差', '差', '一般', '好', '很好'],
  onRatingChange: (value) {},
),
```

### 大尺寸

```dart
TDRate(
  value: 3.0,
  size: 36.0,
  onRatingChange: (value) {},
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| value | `double` | `0` | 当前分值 |
| count | `int` | `5` | 评分总数 |
| half | `bool` | `false` | 是否支持半星 |
| size | `double` | `24` | 图标大小 |
| icon | `IconData?` | - | 自定义图标 |
| disabled | `bool` | `false` | 是否禁用 |
| readonly | `bool` | `false` | 是否只读 |
| showText | `bool` | `false` | 是否显示提示文字 |
| texts | `List<String>?` | - | 提示文字列表 |
| onRatingChange | `ValueChanged<double>?` | - | 评分变化回调 |