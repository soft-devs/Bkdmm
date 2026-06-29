# Calendar 日历

用于选择日期或展示日程。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDCalendar(
  onSelect: (date) {
    print('选中日期: $date');
  },
),
```

### 日期范围选择

```dart
TDCalendar(
  multiple: true,
  onSelect: (dates) {
    print('选中日期范围: $dates');
  },
),
```

### 固定选择模式

```dart
TDCalendar(
  value: DateTime.now(),
  type: TDCalendarType.single,
  onChange: (date) {},
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| value | `DateTime?` | - | 当前值 |
| type | `TDCalendarType` | `single` | 选择类型 |
| multiple | `bool` | `false` | 是否多选 |
| minDate | `DateTime?` | - | 最小日期 |
| maxDate | `DateTime?` | - | 最大日期 |
| onSelect | `Function?` | - | 选择回调 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/calendar)