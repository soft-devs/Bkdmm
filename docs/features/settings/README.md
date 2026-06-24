# features/settings - 设置页面

应用设置和项目配置管理。

## 概述

该模块管理应用全局设置和项目级别配置。

## 文件结构

```
features/settings/
├── settings.dart              # 模块导出
└── views/
    └── settings_view.dart     # 设置视图
```

## 设置类型

### 应用设置 (全局)

| 设置 | 类型 | 说明 |
|------|------|------|
| 主题模式 | ThemeMode | 浅色/深色/跟随系统 |
| 强调色 | Color? | 自定义主题强调色 |
| 语言 | String | 界面语言 (zh-CN/en-US) |
| 默认项目路径 | String? | 新建项目的默认保存位置 |
| 自动保存 | bool | 是否开启自动保存 |
| 自动保存间隔 | int | 自动保存间隔 (秒) |

### 项目配置 (项目级别)

| 配置 | 类型 | 说明 |
|------|------|------|
| 默认字段 | List<String> | 新建表时的默认字段 |
| 默认字段类型 | String | 默认字段的数据类型 |
| 默认数据库 | String? | 默认目标数据库 |

## SettingsView

设置视图。

### 布局

```
┌─────────────────────────────────────────────────────────────┐
│ 设置                                                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ 外观                                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 主题模式    │ [浅色 ▼]                                   │ │
│ │ 强调色      │ [🔵 蓝色 ▼]                                 │ │
│ │ 语言        │ [简体中文 ▼]                                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ 项目                                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 默认保存路径 │ [选择...]                                  │ │
│ │ 自动保存     │ [✓] 开启                                   │ │
│ │ 保存间隔     │ [60] 秒                                    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ 关于                                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 版本: 1.0.0                                             │ │
│ │ 许可证: MIT                                             │ │
│ │ GitHub: github.com/xxx/bkdmm                            │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 功能

- **主题切换** - 浅色/深色/跟随系统
- **强调色选择** - 预设颜色或自定义
- **语言切换** - 中文/英文
- **默认路径设置** - 设置项目默认保存位置
- **自动保存配置** - 开启/关闭，设置间隔
- **关于信息** - 版本信息、许可证

## SettingsProvider

设置状态管理。

### 状态类

```dart
class Settings {
  final ThemeMode themeMode;
  final Color? accentColor;
  final String language;
  final String? defaultProjectPath;
  final bool autoSave;
  final int autoSaveInterval;

  // 便捷方法
  ThemeMode get themeModeEnum;
  int? get accentColorValue;
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `loadSettings()` | 加载设置 |
| `setThemeMode(ThemeMode mode)` | 设置主题模式 |
| `setAccentColor(Color? color)` | 设置强调色 |
| `setLanguage(String lang)` | 设置语言 |
| `setDefaultProjectPath(String? path)` | 设置默认路径 |
| `setAutoSave(bool enabled)` | 设置自动保存 |
| `setAutoSaveInterval(int seconds)` | 设置保存间隔 |

## 主题配置

主题使用 `AppTheme` 类定义：

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(...);
  static ThemeData get darkTheme => ThemeData(...);
}
```

### 强调色预设

| 颜色 | 值 |
|------|------|
| 蓝色 | #1976D2 |
| 绿色 | #388E3C |
| 紫色 | #7B1FA2 |
| 橙色 | #F57C00 |
| 红色 | #D32F2F |

## 设置持久化

设置存储在 Hive 中：

```dart
// 保存设置
await StorageService.put('settings', settings.toJson());

// 加载设置
final json = StorageService.get<Map>('settings');
final settings = Settings.fromJson(json ?? {});
```

## 注意事项

1. **主题生效** - 修改主题后立即生效，无需重启
2. **语言切换** - 需要重启应用才能完全生效
3. **设置同步** - 设置修改后自动保存
4. **默认值** - 首次使用时使用默认设置
5. **项目配置** - 项目级别配置随项目文件保存