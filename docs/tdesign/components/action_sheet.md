# Action Sheet 动作面板

从底部弹出的动作选择面板。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDActionSheet.show(
  context,
  title: '请选择操作',
  actions: [
    TDActionSheetItem(text: '操作一', onTap: () {}),
    TDActionSheetItem(text: '操作二', onTap: () {}),
    TDActionSheetItem(text: '操作三', onTap: () {}),
  ],
);
```

### 带取消按钮

```dart
TDActionSheet.show(
  context,
  title: '请选择操作',
  actions: [
    TDActionSheetItem(text: '操作一', onTap: () {}),
    TDActionSheetItem(text: '操作二', onTap: () {}),
  ],
  showCancel: true,
  cancelText: '取消',
);
```

### 危险操作

```dart
TDActionSheet.show(
  context,
  title: '请选择操作',
  actions: [
    TDActionSheetItem(text: '普通操作', onTap: () {}),
    TDActionSheetItem(text: '危险操作', danger: true, onTap: () {}),
  ],
);
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| context | `BuildContext` | - | 上下文 |
| title | `String?` | - | 标题 |
| actions | `List<TDActionSheetItem>` | - | 操作项列表 |
| showCancel | `bool` | `true` | 是否显示取消 |
| cancelText | `String` | `'取消'` | 取消文字 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/actionsheet)