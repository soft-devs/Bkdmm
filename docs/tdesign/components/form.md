# Form 表单

用于收集和验证用户输入的数据。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础表单

```dart
TDForm(
  cells: [
    TDCell(
      title: '用户名',
      noteWidget: TDInput(
        hintText: '请输入用户名',
      ),
    ),
    TDCell(
      title: '密码',
      noteWidget: TDInput(
        hintText: '请输入密码',
        obscureText: true,
      ),
    ),
  ],
),
```

### 表单验证

```dart
TDForm(
  onSubmit: (value) {
    // 提交表单
    print('表单数据: $value');
  },
  cells: [
    TDCell(
      title: '手机号',
      required: true,
      noteWidget: TDInput(
        hintText: '请输入手机号',
        keyboardType: TextInputType.phone,
      ),
    ),
    TDCell(
      title: '邮箱',
      required: true,
      noteWidget: TDInput(
        hintText: '请输入邮箱',
        keyboardType: TextInputType.emailAddress,
      ),
    ),
  ],
),
```

### 登录表单

```dart
TDForm(
  cells: [
    TDCell(
      leftIcon: TDIcons.user,
      noteWidget: TDInput(
        hintText: '请输入用户名',
      ),
    ),
    TDCell(
      leftIcon: TDIcons.lock_on,
      noteWidget: TDInput(
        hintText: '请输入密码',
        obscureText: true,
      ),
    ),
  ],
  submitWidget: TDButton(
    text: '登录',
    isBlock: true,
    onTap: () {},
  ),
),
```

## API

### TDForm Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| cells | `List<Widget>` | - | 表单项列表 |
| onSubmit | `ValueChanged<Map<String, dynamic>>?` | - | 提交回调 |
| submitWidget | `Widget?` | - | 自定义提交按钮 |

## 更多内容

请参考 [Cell 单元格](./cell.md) 和 [Input 输入框](./input.md) 文档。完整示例请查看 [官方 GitHub 示例](https://github.com/Tencent/tdesign-flutter/tree/develop/tdesign-component/example/lib/page)。