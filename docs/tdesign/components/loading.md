# Loading 加载

用于页面或区块的加载状态。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDLoading(
  size: TDLoadingSize.medium,
),
```

### 加载文字

```dart
TDLoading(
  text: '加载中...',
  size: TDLoadingSize.medium,
),
```

### 不同尺寸

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    TDLoading(size: TDLoadingSize.small),
    TDLoading(size: TDLoadingSize.medium),
    TDLoading(size: TDLoadingSize.large),
  ],
),
```

### 全屏加载

```dart
TDLoading.show(context, text: '加载中...');

// 关闭加载
TDLoading.dismiss();
```

### 加载遮罩

```dart
TDLoading.show(
  context,
  text: '加载中...',
  mask: true,
);
```

### 自定义颜色

```dart
TDLoading(
  color: TDTheme.of(context).brandNormalColor,
),
```

### 纵向布局

```dart
TDLoading(
  text: '加载中...',
  layout: TDLoadingLayout.vertical,
),
```

## API

### TDLoading Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| size | `TDLoadingSize` | `medium` | 加载尺寸 |
| text | `String?` | - | 加载文字 |
| color | `Color?` | - | 颜色 |
| layout | `TDLoadingLayout` | `horizontal` | 布局方向 |

### TDLoadingSize

| 值 | 说明 |
|----|------|
| `small` | 小号 |
| `medium` | 中号（默认） |
| `large` | 大号 |

### TDLoadingLayout

| 值 | 说明 |
|----|------|
| `horizontal` | 水平布局（默认） |
| `vertical` | 垂直布局 |

### 静态方法

| 方法 | 说明 |
|-----|------|
| `TDLoading.show()` | 显示全屏加载 |
| `TDLoading.dismiss()` | 关闭加载 |