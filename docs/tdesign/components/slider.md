# Slider 滑块

用于在一定范围内选择一个值。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
var value = 50.0;

TDSlider(
  value: value,
  onChange: (newValue) {
    setState(() {
      value = newValue;
    });
  },
),
```

### 带刻度

```dart
TDSlider(
  value: 50.0,
  min: 0,
  max: 100,
  step: 20,
  showScale: true,
  onChange: (value) {},
),
```

### 范围选择

```dart
var startValue = 20.0;
var endValue = 80.0;

TDSlider(
  isRange: true,
  startValue: startValue,
  endValue: endValue,
  onChange: (value, type) {
    // value 包含 start 和 end
  },
),
```

### 禁用状态

```dart
TDSlider(
  value: 30.0,
  disabled: true,
  onChange: (value) {},
),
```

### 带标签

```dart
TDSlider(
  value: 50.0,
  label: '音量',
  showValue: true,
  onChange: (value) {},
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| value | `double` | `0` | 当前值 |
| min | `double` | `0` | 最小值 |
| max | `double` | `100` | 最大值 |
| step | `double` | `1` | 步长 |
| label | `String?` | - | 标签 |
| showValue | `bool` | `false` | 是否显示当前值 |
| showScale | `bool` | `false` | 是否显示刻度 |
| disabled | `bool` | `false` | 是否禁用 |
| isRange | `bool` | `false` | 是否范围选择 |
| startValue | `double?` | - | 范围选择的起始值 |
| endValue | `double?` | - | 范围选择的结束值 |
| onChange | `Function` | - | 值变化回调 |