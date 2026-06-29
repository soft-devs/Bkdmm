# Stepper 步进器

用于数值的步进调整。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
var value = 1;

TDStepper(
  value: value,
  onChange: (newValue) {
    setState(() {
      value = newValue;
    });
  },
),
```

### 设置范围

```dart
TDStepper(
  value: 5,
  min: 1,
  max: 10,
  onChange: (value) {},
),
```

### 设置步长

```dart
TDStepper(
  value: 0,
  step: 2,
  min: 0,
  max: 20,
  onChange: (value) {},
),
```

### 禁用状态

```dart
TDStepper(
  value: 5,
  disabled: true,
  onChange: (value) {},
),
```

### 整数模式

```dart
TDStepper(
  value: 3,
  isInteger: true,
  onChange: (value) {},
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| value | `num` | `0` | 当前值 |
| min | `num` | `int.min` | 最小值 |
| max | `num` | `int.max` | 最大值 |
| step | `num` | `1` | 步长 |
| disabled | `bool` | `false` | 是否禁用 |
| isInteger | `bool` | `false` | 是否只允许整数 |
| onChange | `ValueChanged<num>?` | - | 值变化回调 |