# Toast 轻提示

用于轻量级的反馈或提示。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDToast.showText('提示文字', context: context);
```

### 成功提示

```dart
TDToast.showSuccess('操作成功', context: context);
```

### 失败提示

```dart
TDToast.showFail('操作失败', context: context);
```

### 加载提示

```dart
TDToast.showLoading('加载中...', context: context);

// 关闭加载
TDToast.dismiss();
```

### 自定义持续时间

```dart
TDToast.showText(
  '3秒后消失',
  context: context,
  duration: Duration(seconds: 3),
);
```

### 自定义图标

```dart
TDToast.show(
  context: context,
  text: '自定义图标',
  icon: TDIcons.info_circle,
);
```

### 纯文字提示

```dart
TDToast.showText(
  '这是一条纯文字提示',
  context: context,
);
```

### 顶部显示

```dart
TDToast.showText(
  '顶部提示',
  context: context,
  position: TDToastPosition.top,
);
```

### 底部显示

```dart
TDToast.showText(
  '底部提示',
  context: context,
  position: TDToastPosition.bottom,
);
```

## API

### 静态方法

| 方法 | 说明 |
|-----|------|
| `TDToast.showText()` | 显示文字提示 |
| `TDToast.showSuccess()` | 显示成功提示 |
| `TDToast.showFail()` | 显示失败提示 |
| `TDToast.showLoading()` | 显示加载提示 |
| `TDToast.show()` | 显示自定义提示 |
| `TDToast.dismiss()` | 关闭提示 |

### Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| text | `String` | - | 提示文字 |
| context | `BuildContext` | - | 上下文 |
| icon | `IconData?` | - | 图标 |
| duration | `Duration` | `2秒` | 显示时长 |
| position | `TDToastPosition` | `center` | 显示位置 |
| barrierDismissible | `bool` | `true` | 点击遮罩是否关闭 |

### TDToastPosition

| 值 | 说明 |
|----|------|
| `top` | 顶部显示 |
| `center` | 居中显示（默认） |
| `bottom` | 底部显示 |

## 注意事项

1. `showLoading` 需要手动调用 `TDToast.dismiss()` 关闭
2. Toast 显示期间不会阻止用户操作
3. 建议文字不超过 14 个字