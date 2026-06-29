# Picker 选择器

用于从一个列表中选择一个值。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
final result = await TDPicker.show(
  context,
  title: '请选择',
  options: ['选项A', '选项B', '选项C', '选项D'],
);
if (result != null) {
  print('选择了: $result');
}
```

### 多列选择

```dart
final result = await TDPicker.show(
  context,
  title: '请选择',
  options: [
    TDPickerItem(
      label: '省份',
      options: ['北京', '上海', '广东'],
    ),
    TDPickerItem(
      label: '城市',
      options: ['海淀', '朝阳', '西城'],
    ),
  ],
  multiColumn: true,
);
```

### 级联选择

```dart
final result = await TDPicker.show(
  context,
  title: '请选择地区',
  options: [
    CascaderOption(
      label: '北京',
      children: [
        CascaderOption(label: '海淀区'),
        CascaderOption(label: '朝阳区'),
      ],
    ),
    CascaderOption(
      label: '上海',
      children: [
        CascaderOption(label: '浦东新区'),
        CascaderOption(label: '黄浦区'),
      ],
    ),
  ],
  cascader: true,
);
```

### 默认值

```dart
final result = await TDPicker.show(
  context,
  title: '请选择',
  options: ['选项A', '选项B', '选项C', '选项D'],
  defaultValue: '选项B',
);
```

## API

### Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| context | `BuildContext` | - | 上下文 |
| title | `String?` | - | 标题 |
| options | `List` | - | 选项列表 |
| defaultValue | `String?` | - | 默认值 |
| multiColumn | `bool` | `false` | 是否多列选择 |
| cascader | `bool` | `false` | 是否级联选择 |
| confirmText | `String` | `'确定'` | 确认按钮文字 |
| cancelText | `String` | `'取消'` | 取消按钮文字 |

### TDPickerItem

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| label | `String` | - | 列标签 |
| options | `List<String>` | - | 选项列表 |