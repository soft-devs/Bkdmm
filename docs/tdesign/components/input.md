# Input 输入框

用于输入文本信息。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDInput(
  hintText: '请输入文字',
  onChanged: (value) {
    print('输入内容: $value');
  },
),
```

### 带标签

```dart
TDInput(
  leftLabel: '标签',
  hintText: '请输入文字',
  onChanged: (value) {},
),
```

### 带图标

```dart
TDInput(
  leftIcon: TDIcons.user,
  hintText: '请输入用户名',
  onChanged: (value) {},
),

TDInput(
  leftIcon: TDIcons.lock_on,
  rightIcon: TDIcons.browse_off,
  hintText: '请输入密码',
  onChanged: (value) {},
),
```

### 清除按钮

```dart
TDInput(
  hintText: '可清除的输入框',
  clearable: true,
  onChanged: (value) {},
),
```

### 密码输入框

```dart
TDInput(
  hintText: '请输入密码',
  obscureText: true,
  onChanged: (value) {},
),
```

### 禁用状态

```dart
TDInput(
  hintText: '禁用状态',
  disabled: true,
),
```

### 只读状态

```dart
TDInput(
  hintText: '只读状态',
  readOnly: true,
),
```

### 限制字数

```dart
TDInput(
  hintText: '最多输入20个字',
  maxLength: 20,
  onChanged: (value) {},
),
```

### 多行输入

```dart
TDInput(
  hintText: '多行输入',
  maxLines: 4,
  onChanged: (value) {},
),
```

### 带后缀

```dart
TDInput(
  hintText: '请输入验证码',
  rightWidget: TDButton(
    text: '获取验证码',
    size: TDButtonSize.small,
    theme: TDButtonTheme.primary,
    onTap: () {},
  ),
),
```

### 数字输入

```dart
TDInput(
  hintText: '请输入数字',
  keyboardType: TextInputType.number,
  onChanged: (value) {},
),
```

## API

### Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| hintText | `String?` | - | 占位文字 |
| leftLabel | `String?` | - | 左侧标签 |
| leftIcon | `IconData?` | - | 左侧图标 |
| rightIcon | `IconData?` | - | 右侧图标 |
| rightWidget | `Widget?` | - | 右侧自定义组件 |
| clearable | `bool` | `false` | 是否可清除 |
| obscureText | `bool` | `false` | 是否密码模式 |
| disabled | `bool` | `false` | 是否禁用 |
| readOnly | `bool` | `false` | 是否只读 |
| maxLength | `int?` | - | 最大输入长度 |
| maxLines | `int` | `1` | 最大行数 |
| keyboardType | `TextInputType?` | - | 键盘类型 |
| controller | `TextEditingController?` | - | 文本控制器 |
| onChanged | `ValueChanged<String>?` | - | 输入变化回调 |
| onSubmitted | `ValueChanged<String>?` | - | 提交回调 |

### Events

| 事件 | 参数 | 说明 |
|-----|------|------|
| onChanged | `String` | 输入内容变化时触发 |
| onSubmitted | `String` | 提交时触发 |
| onEditingComplete | - | 编辑完成时触发 |
| onTap | - | 点击输入框时触发 |