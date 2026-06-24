# Switch 开关

用于在两种状态之间切换。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDSwitch(
  isOn: true,
  onChanged: (value) {
    print('开关状态: $value');
  },
),
```

### 禁用状态

```dart
TDSwitch(
  isOn: true,
  disabled: true,
  onChanged: (value) {},
),
```

### 带标签

```dart
TDSwitch(
  isOn: true,
  label: '消息通知',
  onChanged: (value) {},
),
```

### 自定义颜色

```dart
TDSwitch(
  isOn: true,
  activeColor: Colors.green,
  onChanged: (value) {},
),
```

### 不同尺寸

```dart
TDSwitch(
  isOn: true,
  size: TDSwitchSize.large,
  onChanged: (value) {},
),
TDSwitch(
  isOn: true,
  size: TDSwitchSize.medium,
  onChanged: (value) {},
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| isOn | `bool` | `false` | 是否开启 |
| disabled | `bool` | `false` | 是否禁用 |
| label | `String?` | - | 标签文字 |
| activeColor | `Color?` | - | 打开时的颜色 |
| inactiveColor | `Color?` | - | 关闭时的颜色 |
| size | `TDSwitchSize` | `medium` | 开关尺寸 |
| onChanged | `ValueChanged<bool>?` | - | 切换回调 |