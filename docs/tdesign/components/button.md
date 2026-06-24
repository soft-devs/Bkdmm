# Button 按钮

按钮用于触发一个操作，如提交表单、打开对话框等。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 按钮类型

按钮支持多种类型：填充按钮、描边按钮、文字按钮。

```dart
// 主要按钮（默认）
TDButton(
  text: '主要按钮',
  theme: TDButtonTheme.primary,
  onTap: () {},
),

// 次要按钮
TDButton(
  text: '次要按钮',
  theme: TDButtonTheme.defaultTheme,
  onTap: () {},
),

// 描边按钮
TDButton(
  text: '描边按钮',
  theme: TDButtonTheme.outline,
  onTap: () {},
),

// 文字按钮
TDButton(
  text: '文字按钮',
  theme: TDButtonTheme.text,
  onTap: () {},
),

// 危险按钮
TDButton(
  text: '危险按钮',
  theme: TDButtonTheme.danger,
  onTap: () {},
),
```

### 按钮尺寸

按钮支持多种尺寸：大、中（默认）、小。

```dart
// 大号按钮
TDButton(
  text: '大号按钮',
  size: TDButtonSize.large,
  onTap: () {},
),

// 中号按钮（默认）
TDButton(
  text: '中号按钮',
  size: TDButtonSize.medium,
  onTap: () {},
),

// 小号按钮
TDButton(
  text: '小号按钮',
  size: TDButtonSize.small,
  onTap: () {},
),
```

### 按钮形状

```dart
// 方形按钮（默认）
TDButton(
  text: '方形按钮',
  shape: TDButtonShape.square,
  onTap: () {},
),

// 圆角按钮
TDButton(
  text: '圆角按钮',
  shape: TDButtonShape.round,
  onTap: () {},
),

// 圆形按钮
TDButton(
  icon: TDIcons.add,
  shape: TDButtonShape.circle,
  onTap: () {},
),
```

### 禁用状态

```dart
TDButton(
  text: '禁用按钮',
  disabled: true,
  onTap: () {},
),
```

### 加载状态

```dart
TDButton(
  text: '加载中',
  loading: true,
  onTap: () {},
),
```

### 图标按钮

```dart
TDButton(
  text: '图标按钮',
  icon: TDIcons.home,
  onTap: () {},
),

// 纯图标按钮
TDButton(
  icon: TDIcons.search,
  shape: TDButtonShape.circle,
  onTap: () {},
),
```

### 块级按钮

```dart
TDButton(
  text: '块级按钮',
  isBlock: true,
  onTap: () {},
),
```

## API

### Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| text | `String?` | - | 按钮文字 |
| icon | `IconData?` | - | 图标 |
| theme | `TDButtonTheme` | `TDButtonTheme.primary` | 按钮类型 |
| size | `TDButtonSize` | `TDButtonSize.medium` | 按钮尺寸 |
| shape | `TDButtonShape` | `TDButtonShape.square` | 按钮形状 |
| disabled | `bool` | `false` | 是否禁用 |
| loading | `bool` | `false` | 是否加载中 |
| isBlock | `bool` | `false` | 是否为块级按钮 |
| onTap | `VoidCallback?` | - | 点击事件 |

### TDButtonTheme

| 值 | 说明 |
|----|------|
| `primary` | 主要按钮（填充） |
| `defaultTheme` | 次要按钮（浅色填充） |
| `outline` | 描边按钮 |
| `text` | 文字按钮 |
| `danger` | 危险按钮 |

### TDButtonSize

| 值 | 说明 |
|----|------|
| `large` | 大号 |
| `medium` | 中号（默认） |
| `small` | 小号 |

### TDButtonShape

| 值 | 说明 |
|----|------|
| `square` | 方形（默认） |
| `round` | 圆角 |
| `circle` | 圆形 |