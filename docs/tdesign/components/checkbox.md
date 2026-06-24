# Checkbox 复选框

用于在多个选项中选择一个或多个。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
var checked = false;

TDCheckbox(
  label: '选项',
  checked: checked,
  onChange: (value) {
    checked = value;
  },
),
```

### 默认选中

```dart
TDCheckbox(
  label: '默认选中',
  checked: true,
  onChange: (value) {},
),
```

### 禁用状态

```dart
TDCheckbox(
  label: '禁用选项',
  checked: true,
  disabled: true,
  onChange: (value) {},
),
```

### 复选框组

```dart
var selectedValues = <String>[];

TDCheckboxGroup(
  options: [
    TDCheckboxOption(label: '选项A', value: 'A'),
    TDCheckboxOption(label: '选项B', value: 'B'),
    TDCheckboxOption(label: '选项C', value: 'C'),
  ],
  selectedValues: selectedValues,
  onChange: (values) {
    selectedValues = values;
  },
),
```

### 全选

```dart
TDCheckbox(
  label: '全选',
  checkAll: true,
  checked: false,
  onChange: (value) {},
),
```

### 自定义布局

```dart
TDCheckbox(
  label: '右侧标签',
  contentRight: false,
  checked: true,
  onChange: (value) {},
),
```

## API

### TDCheckbox Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| label | `String?` | - | 标签文字 |
| checked | `bool` | `false` | 是否选中 |
| disabled | `bool` | `false` | 是否禁用 |
| checkAll | `bool` | `false` | 是否全选模式 |
| contentRight | `bool` | `true` | 标签是否在右侧 |
| onChange | `ValueChanged<bool>?` | - | 变化回调 |

### TDCheckboxGroup Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| options | `List<TDCheckboxOption>` | - | 选项列表 |
| selectedValues | `List<String>` | `[]` | 已选值列表 |
| disabled | `bool` | `false` | 是否禁用整个组 |
| max | `int?` | - | 最大可选数 |
| onChange | `ValueChanged<List<String>>?` | - | 变化回调 |

### TDCheckboxOption

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| label | `String` | - | 选项标签 |
| value | `String` | - | 选项值 |
| disabled | `bool` | `false` | 是否禁用 |