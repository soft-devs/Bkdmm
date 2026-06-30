# shared/theme - TDesign主题适配

## 概述

TDesign Flutter 组件库的主题适配和扩展。

## 文件

| 文件 | 描述 |
|------|------|
| td_theme.dart | TDesign 主题配置 |

## 功能

- 主题色适配
- TDesign 组件主题定制
- 品牌色配置

## 使用方法

```dart
// 应用 TDesign 主题
TDTheme(
  data: TDThemeData.defaultData(),
  child: MaterialApp(...),
)

// 自定义品牌色
final themeData = TDThemeData.fromJson('custom', '''
{
  "customTheme": {
    "color": {
      "brandNormalColor": "#1890ff"
    }
  }
}
''');
```