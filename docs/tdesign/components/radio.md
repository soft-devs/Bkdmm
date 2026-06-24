# Radio 单选框

用于在多个选项中选择一个。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
var selectedValue = 'A';

TDRadio(
  label: '选项A',
  value: 'A',
  groupValue: selectedValue,
  onChange: (value) {
    selectedValue = value;
  },
),

TDRadio(
  label: '选项B',
  value: 'B',
  groupValue: selectedValue,
  onChange: (value) {
    selectedValue = value;
  },
),
```

### 单选框组

```dart
var selected = '';

TDRadioGroup(
  options: [
    TDRadioOption(label: '选项A', value: 'A'),
    TDRadioOption(label: '选项B', value: 'B'),
    TDRadioOption(label: '选项C', value: 'C'),
  ],
  selectedValue: selected,
  onChange: (value) {
    selected = value;
  },
),
```

### 禁用状态

```dart
TDRadio(
  label: '禁用选项',
  value: 'A',
  groupValue: 'A',
  disabled: true,
  onChange: (value) {},
),
```

### 按钮样式

```dart
TDRadioGroup(
  theme: TDRadioTheme.button,
  options: [
    TDRadioOption(label: '选项A', value: 'A'),
    TDRadioOption(label: '选项B', value: 'B'),
    TDRadioOption(label: '选项C', value: 'C'),
  ],
  selectedValue: selected,
  onChange: (value) {},
),
```

## API

### TDRadio Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| label | `String?` | - | 标签文字 |
| value | `String` | - | 选项值 |
| groupValue | `String` | - | 当前选中的值 |
| disabled | `bool` | `false` | 是否禁用 |
| contentRight | `bool` | `true` | 标签是否在右侧 |
| onChange | `ValueChanged<String>?` | - | 变化回调 |

### TDRadioGroup Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| options | `List<TDRadioOption>` | - | 选项列表 |
| selectedValue | `String` | - | 当前选中值 |
| theme | `TDRadioTheme` | `radio` | 样式主题 |
| onChange | `ValueChanged<String>?` | - | 变化回调 |

### TDRadioOption

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| label | `String` | - | 选项标签 |
| value | `String` | - | 选项值 |
| disabled | `bool` | `false` | 是否禁用 |