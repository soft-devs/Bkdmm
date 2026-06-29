# Dialog 对话框

用于显示重要信息或需要用户确认的操作。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDDialog.show(
  context,
  title: '对话框标题',
  content: '对话框内容',
  onConfirm: () {
    Navigator.of(context).pop();
  },
);
```

### 确认对话框

```dart
TDDialog.show(
  context,
  title: '确认操作',
  content: '确定要执行此操作吗？',
  confirmText: '确定',
  cancelText: '取消',
  onConfirm: () {
    // 确认操作
    Navigator.of(context).pop();
  },
  onCancel: () {
    Navigator.of(context).pop();
  },
);
```

### 提示对话框

```dart
TDDialog.show(
  context,
  title: '提示',
  content: '这是一条提示信息',
  confirmText: '知道了',
  onConfirm: () {
    Navigator.of(context).pop();
  },
);
```

### 输入对话框

```dart
final result = await TDDialog.showInputDialog(
  context,
  title: '请输入内容',
  placeholder: '请输入...',
);
if (result != null) {
  print('输入内容: $result');
}
```

### 确认弹窗

```dart
final confirmed = await TDDialog.showConfirmDialog(
  context,
  title: '确认删除',
  content: '删除后数据将无法恢复，确定要删除吗？',
  confirmText: '删除',
  cancelText: '取消',
);
if (confirmed == true) {
  // 执行删除操作
}
```

### 自定义内容

```dart
showDialog(
  context: context,
  builder: (context) => TDDialog(
    title: '自定义内容',
    contentWidget: Column(
      children: [
        TDInput(
          hintText: '输入框',
        ),
        TDInput(
          hintText: '输入框',
        ),
      ],
    ),
    onConfirm: () {
      Navigator.of(context).pop();
    },
  ),
);
```

### 垂直布局按钮

```dart
TDDialog.show(
  context,
  title: '提示',
  content: '请选择操作',
  actions: [
    TDDialogAction(
      text: '操作一',
      onTap: () {},
    ),
    TDDialogAction(
      text: '操作二',
      onTap: () {},
    ),
    TDDialogAction(
      text: '操作三',
      onTap: () {},
    ),
  ],
  buttonLayout: TDDialogButtonLayout.vertical,
);
```

## API

### TDDialog.show() Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| title | `String?` | - | 标题 |
| content | `String?` | - | 内容 |
| contentWidget | `Widget?` | - | 自定义内容组件 |
| confirmText | `String?` | `'确定'` | 确认按钮文字 |
| cancelText | `String?` | `'取消'` | 取消按钮文字 |
| showCancel | `bool` | `true` | 是否显示取消按钮 |
| barrierDismissible | `bool` | `true` | 点击遮罩是否关闭 |
| onConfirm | `VoidCallback?` | - | 确认回调 |
| onCancel | `VoidCallback?` | - | 取消回调 |
| actions | `List<TDDialogAction>?` | - | 自定义操作按钮 |
| buttonLayout | `TDDialogButtonLayout` | `horizontal` | 按钮布局方式 |

### TDDialog Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| title | `String?` | - | 标题 |
| content | `String?` | - | 内容文字 |
| contentWidget | `Widget?` | - | 自定义内容组件 |
| actions | `List<TDDialogAction>?` | - | 操作按钮列表 |
| closeOnConfirm | `bool` | `true` | 确认后是否关闭 |
| buttonLayout | `TDDialogButtonLayout` | `horizontal` | 按钮布局 |

### TDDialogAction

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| text | `String` | - | 按钮文字 |
| theme | `TDButtonTheme?` | - | 按钮主题 |
| onTap | `VoidCallback?` | - | 点击回调 |

### TDDialogButtonLayout

| 值 | 说明 |
|----|------|
| `horizontal` | 水平排列（默认） |
| `vertical` | 垂直排列 |