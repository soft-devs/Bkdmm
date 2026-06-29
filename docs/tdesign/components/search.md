# Search 搜索框

用于搜索内容。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDSearch(
  hintText: '请输入搜索关键词',
  onChange: (value) {
    print('搜索内容: $value');
  },
  onSubmit: (value) {
    print('提交搜索: $value');
  },
),
```

### 带取消按钮

```dart
TDSearch(
  hintText: '请输入搜索关键词',
  cancelText: '取消',
  onSubmit: (value) {
    print('搜索: $value');
  },
),
```

### 带搜索按钮

```dart
TDSearch(
  hintText: '请输入搜索关键词',
  actionText: '搜索',
  onSubmit: (value) {
    print('搜索: $value');
  },
),
```

### 不同形状

```dart
TDSearch(
  hintText: '圆角搜索框',
  shape: TDSearchShape.round,
),

TDSearch(
  hintText: '方形搜索框',
  shape: TDSearchShape.square,
),
```

### 不同主题

```dart
TDSearch(
  hintText: '浅色主题',
  theme: TDSearchTheme.light,
),

TDSearch(
  hintText: '深色主题',
  theme: TDSearchTheme.dark,
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| hintText | `String?` | - | 占位文字 |
| cancelText | `String?` | - | 取消按钮文字 |
| actionText | `String?` | - | 搜索按钮文字 |
| shape | `TDSearchShape` | `square` | 形状 |
| theme | `TDSearchTheme` | `light` | 主题 |
| onChange | `ValueChanged<String>?` | - | 输入变化回调 |
| onSubmit | `ValueChanged<String>?` | - | 提交回调 |
| onCancel | `VoidCallback?` | - | 取消回调 |