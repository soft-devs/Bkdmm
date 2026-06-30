# API 文档

## SettingsState - 应用设置状态

```dart
class SettingsState {
  final String themeMode;           // 'system', 'light', 'dark'
  final String locale;              // 'zh', 'en'
  final bool showWelcomePage;       // 是否显示欢迎页
  final String? defaultDatabase;    // 默认数据库
  final int autoSaveInterval;       // 自动保存间隔(秒)，0表示禁用
  final bool enableAutoBackup;      // 是否启用自动备份
  final int backupRetentionCount;   // 备份保留数量
  final double editorFontSize;      // 编辑器字体大小
  final bool enableCodeCompletion;  // 是否启用代码补全
  final bool showLineNumbers;       // 是否显示行号
  final int? accentColor;           // 强调色(32位整数)
  final bool defaultFieldsRevision; // 默认字段-乐观锁
  final bool defaultFieldsCreatedBy; // 默认字段-创建人
  final bool defaultFieldsCreatedTime; // 默认字段-创建时间
  final bool defaultFieldsUpdatedBy; // 默认字段-更新人
  final bool defaultFieldsUpdatedTime; // 默认字段-更新时间
}
```

### SettingsState 方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `themeModeEnum` | `ThemeMode` | 获取 ThemeMode 枚举 |
| `accentColorValue` | `Color?` | 获取强调色 Color 对象 |
| `fromJson(json)` | `SettingsState` | 从 JSON 创建实例 |
| `toJson()` | `Map<String, dynamic>` | 转换为 JSON |

### SettingsNotifier 方法

| 方法 | 描述 |
|------|------|
| `setThemeMode(mode)` | 设置主题模式 |
| `setLocale(locale)` | 设置语言 |
| `setShowWelcomePage(show)` | 设置是否显示欢迎页 |
| `setDefaultDatabase(db)` | 设置默认数据库 |
| `setAutoSaveInterval(interval)` | 设置自动保存间隔 |
| `setAccentColor(color)` | 设置强调色 |
| `resetToDefaults()` | 重置所有设置 |
| `updateSettings(newSettings)` | 批量更新设置 |

### 便捷 Provider

```dart
// 以下 Provider 提供便捷访问
final themeModeProvider = Provider<String>;       // 主题模式
final localeProvider = Provider<String>;          // 语言
final showWelcomePageProvider = Provider<bool>;   // 是否显示欢迎页
final defaultDatabaseProvider = Provider<String?>; // 默认数据库
final autoSaveIntervalProvider = Provider<int>;   // 自动保存间隔
final enableAutoBackupProvider = Provider<bool>;  // 是否启用备份
final editorFontSizeProvider = Provider<double>;  // 字体大小
final accentColorProvider = Provider<Color?>;     // 强调色
```

## ProjectSettingsState - 项目设置状态

```dart
class ProjectSettingsState {
  final String projectId;            // 所属项目ID
  final bool inheritDefaultFields;   // 是否继承全局默认字段设置
  final bool inheritDefaultDatabase; // 是否继承全局默认数据库
  final bool? defaultFieldsRevision; // 项目级默认字段(可选)
  final bool? defaultFieldsCreatedBy;
  final bool? defaultFieldsCreatedTime;
  final bool? defaultFieldsUpdatedBy;
  final bool? defaultFieldsUpdatedTime;
  final String? defaultDatabase;     // 项目级默认数据库
  final Map<String, dynamic>? customSettings; // 自定义设置
}
```

### ProjectSettingsNotifier 方法

| 方法 | 描述 |
|------|------|
| `loadFromProject(project)` | 从项目加载设置 |
| `clear()` | 清除设置(关闭项目时) |
| `setInheritDefaultFields(inherit)` | 设置是否继承默认字段 |
| `setInheritDefaultDatabase(inherit)` | 设置是否继承默认数据库 |
| `setDefaultFieldsRevision(value)` | 设置项目级默认字段 |
| `setDefaultDatabase(value)` | 设置项目级默认数据库 |
| `resetToDefaults()` | 重置为继承所有 |

## EffectiveDefaultFields - 有效默认字段

```dart
class EffectiveDefaultFields {
  final bool revision;     // 乐观锁
  final bool createdBy;    // 创建人
  final bool createdTime;  // 创建时间
  final bool updatedBy;    // 更新人
  final bool updatedTime;  // 更新时间
  final String source;     // 'global' 或 'project'
}
```

### EffectiveDefaultFields 方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `generateDefaultFieldTemplates()` | `List<Map<String, dynamic>>` | 生成默认字段模板 |

### 有效值 Provider

```dart
// 解决项目/全局继承关系的 Provider
final effectiveDefaultFieldsProvider = Provider<EffectiveDefaultFields>;
final effectiveDefaultDatabaseProvider = Provider<String?>;
```

## 使用示例

### 监听设置变化

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return Text('Theme: $themeMode');
  }
}
```

### 更新设置

```dart
// 在 ConsumerWidget 或 ConsumerStatefulWidget 中
void updateTheme(WidgetRef ref, String mode) {
  ref.read(settingsProvider.notifier).setThemeMode(mode);
}

// 批量更新
void updateAllSettings(WidgetRef ref) {
  final newSettings = SettingsState(
    themeMode: 'dark',
    locale: 'en',
  );
  ref.read(settingsProvider.notifier).updateSettings(newSettings);
}
```

### 获取有效默认字段

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
  
  // 生成默认字段模板
  final templates = effectiveFields.generateDefaultFieldTemplates();
  
  // 判断来源
  if (effectiveFields.source == 'project') {
    // 使用项目级设置
  } else {
    // 使用全局设置
  }
}
```

### 项目设置继承关系

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final projectSettings = ref.watch(projectSettingsProvider);
  
  if (projectSettings?.inheritDefaultFields) {
    // 使用全局设置
    final globalSettings = ref.watch(settingsProvider);
  } else {
    // 使用项目级设置
    final revision = projectSettings?.defaultFieldsRevision ?? false;
  }
}
```