# Popup 弹出层

用于从屏幕边缘弹出的面板组件。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 底部弹出

```dart
TDPopup.showBottomSheet(
  context,
  child: Container(
    height: 300,
    child: Center(child: Text('弹出内容')),
  ),
);
```

### 居中弹出

```dart
TDPopup.showCenterDialog(
  context,
  child: Container(
    width: 300,
    height: 200,
    child: Center(child: Text('居中弹出')),
  ),
);
```

### 自定义位置

```dart
TDPopup.show(
  context,
  content: '弹出内容',
  position: TDPopupPosition.top,
);
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| context | `BuildContext` | - | 上下文 |
| content | `Widget` | - | 弹出内容 |
| position | `TDPopupPosition` | `center` | 弹出位置 |
| barrierDismissible | `bool` | `true` | 点击遮罩是否关闭 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/popup)