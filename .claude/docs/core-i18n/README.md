# core/i18n - 国际化支持

## 概述

应用国际化支持，当前支持中文(zh)和英文(en)。

## 依赖

- `flutter_localizations` - Flutter 国际化框架
- `intl` - 国际化工具库

## 模块清单

| 文件 | 描述 |
|------|------|
| i18n.dart | 导出入口 |
| locale_provider.dart | 语言状态管理 |
| app_localizations_ext.dart | 扩展方法 |
| td_resource_delegate.dart | TDesign 国际化适配 |

## 支持语言

- `zh` - 中文（默认）
- `en` - English

## 使用方法

```dart
// 获取翻译
final label = AppLocalizations.of(context)!.appName;

// 切换语言
ref.read(appLocaleProvider.notifier).setLocale('en');
```

## 语言切换

```dart
// 获取当前语言
final locale = ref.watch(appLocaleProvider);

// 设置语言
await ref.read(appLocaleProvider.notifier).setLocale('zh');
```

## TDesign 国际化

TDesign 组件通过 `AppTDResourceDelegate` 适配国际化。

```dart
TDTheme.setResourceBuilder(
  (context) => AppTDResourceDelegate(context),
  needAlwaysBuild: true,
);
```