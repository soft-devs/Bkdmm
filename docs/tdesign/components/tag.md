# Tag 标签

用于标记和分类内容。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDTag(
  text: '标签',
),

TDTag(
  text: '主要标签',
  theme: TDTagTheme.primary,
),

TDTag(
  text: '成功标签',
  theme: TDTagTheme.success,
),

TDTag(
  text: '警告标签',
  theme: TDTagTheme.warning,
),

TDTag(
  text: '危险标签',
  theme: TDTagTheme.danger,
),
```

### 可关闭

```dart
TDTag(
  text: '可关闭标签',
  closable: true,
  onClose: () {
    // 关闭逻辑
  },
),
```

### 可选中

```dart
var selected = false;

TDTag(
  text: '可选标签',
  selectable: true,
  selected: selected,
  onTap: () {
    selected = !selected;
  },
),
```

### 不同尺寸

```dart
TDTag(
  text: '小标签',
  size: TDTagSize.small,
),

TDTag(
  text: '中标签',
  size: TDTagSize.medium,
),

TDTag(
  text: '大标签',
  size: TDTagSize.large,
),
```

### 轮廓样式

```dart
TDTag(
  text: '描边标签',
  variant: TDTagVariant.outline,
),
```

### 带图标

```dart
TDTag(
  text: '带图标',
  icon: TDIcons.tag,
),
```

### 圆角标签

```dart
TDTag(
  text: '圆角标签',
  shape: TDTagShape.round,
),
```

## API

### TDTag Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| text | `String` | - | 标签文字 |
| theme | `TDTagTheme` | `defaultTheme` | 主题色 |
| size | `TDTagSize` | `medium` | 尺寸 |
| variant | `TDTagVariant` | `filled` | 样式变体 |
| shape | `TDTagShape` | `square` | 形状 |
| icon | `IconData?` | - | 图标 |
| closable | `bool` | `false` | 是否可关闭 |
| selectable | `bool` | `false` | 是否可选中 |
| selected | `bool` | `false` | 选中状态 |
| onTap | `VoidCallback?` | - | 点击事件 |
| onClose | `VoidCallback?` | - | 关闭事件 |

### TDTagTheme

| 值 | 说明 |
|----|------|
| `defaultTheme` | 默认 |
| `primary` | 主要 |
| `success` | 成功 |
| `warning` | 警告 |
| `danger` | 危险 |

### TDTagSize

| 值 | 说明 |
|----|------|
| `small` | 小号 |
| `medium` | 中号 |
| `large` | 大号 |

### TDTagVariant

| 值 | 说明 |
|----|------|
| `filled` | 填充样式 |
| `outline` | 描边样式 |

### TDTagShape

| 值 | 说明 |
|----|------|
| `square` | 方形 |
| `round` | 圆角 |
| `mark` | 标记 |