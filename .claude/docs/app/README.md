# app - 应用配置层

## 概述

应用入口和主题配置，是整个应用的启动点。

## 文件清单

| 文件 | 描述 |
|------|------|
| main.dart | 应用入口函数 |
| app.dart | 主应用Widget，集成主题、国际化、路由 |
| app_theme.dart | 主题配置（亮色/暗色主题） |

## main.dart

应用启动入口，初始化服务并运行应用。

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  await LoggingService.init(config: LoggingConfig.development());

  // 初始化存储服务
  await StorageService.init();

  runApp(ProviderScope(child: BkdmmApp()));
}
```

## BkdmmApp

主应用Widget，配置：
- 主题模式（亮色/暗色/跟随系统）
- 强调色
- 国际化（zh/en）
- TDesign 主题

```dart
class BkdmmApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localeState = ref.watch(appLocaleProvider);

    return TDTheme(
      data: _buildTDThemeData(settings.accentColor),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeModeEnum,
        locale: localeState.locale,
        home: HomeView(),
      ),
    );
  }
}
```

## AppTheme

主题配置类，定义亮色和暗色主题。

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(...);
  static ThemeData get darkTheme => ThemeData(...);
}
```

## 启动流程

```
main()
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── LoggingService.init()
  ├── StorageService.init()
  └── runApp(ProviderScope(child: BkdmmApp()))
        └── MaterialApp
              ├── theme: AppTheme.lightTheme
              ├── darkTheme: AppTheme.darkTheme
              ├── locale: appLocaleProvider
              └── home: HomeView
```
