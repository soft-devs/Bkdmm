# Date Time Picker 日期时间选择器

用于选择日期或时间。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 日期选择

```dart
final result = await TDDateTimePicker.showDatePicker(
  context,
  title: '选择日期',
);
if (result != null) {
  print('选择的日期: $result');
}
```

### 时间选择

```dart
final result = await TDDateTimePicker.showTimePicker(
  context,
  title: '选择时间',
);
if (result != null) {
  print('选择的时间: $result');
}
```

### 日期时间选择

```dart
final result = await TDDateTimePicker.showDateTimePicker(
  context,
  title: '选择日期时间',
);
if (result != null) {
  print('选择的日期时间: $result');
}
```

### 年选择

```dart
final result = await TDDateTimePicker.showYearPicker(
  context,
  title: '选择年份',
);
if (result != null) {
  print('选择的年份: $result');
}
```

### 月份选择

```dart
final result = await TDDateTimePicker.showMonthPicker(
  context,
  title: '选择月份',
);
if (result != null) {
  print('选择的月份: $result');
}
```

### 默认值

```dart
final result = await TDDateTimePicker.showDatePicker(
  context,
  title: '选择日期',
  initialDate: DateTime.now(),
);
```

### 限制日期范围

```dart
final result = await TDDateTimePicker.showDatePicker(
  context,
  title: '选择日期',
  initialDate: DateTime.now(),
  minDate: DateTime(2024, 1, 1),
  maxDate: DateTime(2025, 12, 31),
);
```

## API

### 静态方法

| 方法 | 说明 |
|-----|------|
| `showDatePicker()` | 显示日期选择器 |
| `showTimePicker()` | 显示时间选择器 |
| `showDateTimePicker()` | 显示日期时间选择器 |
| `showYearPicker()` | 显示年份选择器 |
| `showMonthPicker()` | 显示月份选择器 |

### Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| context | `BuildContext` | - | 上下文 |
| title | `String?` | - | 标题 |
| initialDate | `DateTime?` | - | 初始日期 |
| minDate | `DateTime?` | - | 最小日期 |
| maxDate | `DateTime?` | - | 最大日期 |
| format | `String?` | - | 日期格式 |