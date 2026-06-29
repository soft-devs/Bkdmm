# Cell 单元格

用于展示一组列表信息。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDCell(
  title: '单元格标题',
  note: '描述信息',
),
```

### 带图标

```dart
TDCell(
  leftIcon: TDIcons.home,
  title: '带图标',
  note: '描述信息',
),
```

### 可点击

```dart
TDCell(
  title: '点击跳转',
  arrow: true,
  onClick: () {
    // 跳转逻辑
  },
),
```

### 分组

```dart
TDCellGroup(
  cells: [
    TDCell(
      title: '单元格一',
      note: '描述一',
    ),
    TDCell(
      title: '单元格二',
      note: '描述二',
    ),
    TDCell(
      title: '单元格三',
      note: '描述三',
    ),
  ],
),
```

### 带标题分组

```dart
TDCellGroup(
  title: '分组标题',
  cells: [
    TDCell(
      title: '单元格一',
      arrow: true,
    ),
    TDCell(
      title: '单元格二',
      arrow: true,
    ),
  ],
),
```

### 单元格大小

```dart
TDCell(
  title: '大号单元格',
  size: TDCellSize.large,
),

TDCell(
  title: '中等单元格',
  size: TDCellSize.medium,
),
```

### 必填标记

```dart
TDCell(
  title: '必填项',
  required: true,
),
```

### 自定义右侧

```dart
TDCell(
  title: '自定义右侧',
  noteWidget: TDSwitch(
    isOn: true,
    onChanged: (value) {},
  ),
),
```

### 多行描述

```dart
TDCell(
  title: '标题',
  description: '这是一段很长的描述信息，可以换行显示',
),
```

## API

### TDCell Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| title | `String?` | - | 标题 |
| note | `String?` | - | 右侧描述 |
| noteWidget | `Widget?` | - | 右侧自定义组件 |
| description | `String?` | - | 下方描述 |
| leftIcon | `IconData?` | - | 左侧图标 |
| arrow | `bool` | `false` | 是否显示箭头 |
| required | `bool` | `false` | 是否必填 |
| size | `TDCellSize` | `medium` | 单元格大小 |
| onClick | `VoidCallback?` | - | 点击事件 |

### TDCellGroup Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| title | `String?` | - | 分组标题 |
| cells | `List<TDCell>` | - | 单元格列表 |
| bordered | `bool` | `true` | 是否显示边框 |

### TDCellSize

| 值 | 说明 |
|----|------|
| `large` | 大号 |
| `medium` | 中号（默认） |