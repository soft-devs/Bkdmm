# Settings Data Model

## Overview

The settings module uses two primary state classes managed by Riverpod StateNotifier providers:

1. **SettingsState** - Global application settings
2. **ProjectSettingsState** - Project-specific settings with inheritance

---

## SettingsState

Global application settings persisted via `StorageService`.

**File**: `lib/shared/providers/settings_provider.dart`

```dart
class SettingsState {
  final String themeMode;
  final String locale;
  final bool showWelcomePage;
  final String? defaultDatabase;
  final int autoSaveInterval;
  final bool enableAutoBackup;
  final int backupRetentionCount;
  final double editorFontSize;
  final bool enableCodeCompletion;
  final bool showLineNumbers;
  final int? accentColor;
  final bool defaultFieldsRevision;
  final bool defaultFieldsCreatedBy;
  final bool defaultFieldsCreatedTime;
  final bool defaultFieldsUpdatedBy;
  final bool defaultFieldsUpdatedTime;
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `themeMode` | `String` | `'system'` | Theme mode: 'system', 'light', 'dark' |
| `locale` | `String` | `'zh'` | Language code: 'zh', 'en' |
| `showWelcomePage` | `bool` | `true` | Show welcome page on startup |
| `defaultDatabase` | `String?` | `null` | Default database type (nullable) |
| `autoSaveInterval` | `int` | `60` | Auto-save interval in seconds (0 = disabled) |
| `enableAutoBackup` | `bool` | `true` | Enable automatic backup |
| `backupRetentionCount` | `int` | `10` | Number of backups to retain |
| `editorFontSize` | `double` | `14.0` | Editor font size in points |
| `enableCodeCompletion` | `bool` | `true` | Enable code completion |
| `showLineNumbers` | `bool` | `true` | Show line numbers in code preview |
| `accentColor` | `int?` | `null` | Accent color as ARGB32 integer |
| `defaultFieldsRevision` | `bool` | `true` | Add REVISION field by default |
| `defaultFieldsCreatedBy` | `bool` | `true` | Add CREATED_BY field by default |
| `defaultFieldsCreatedTime` | `bool` | `true` | Add CREATED_TIME field by default |
| `defaultFieldsUpdatedBy` | `bool` | `true` | Add UPDATED_BY field by default |
| `defaultFieldsUpdatedTime` | `bool` | `true` | Add UPDATED_TIME field by default |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `themeModeEnum` | `ThemeMode` | Converts `themeMode` string to Flutter `ThemeMode` enum |
| `accentColorValue` | `Color?` | Converts `accentColor` integer to `Color` object |

### Serialization

```dart
// From JSON
factory SettingsState.fromJson(Map<String, dynamic> json)

// To JSON
Map<String, dynamic> toJson()
```

### Copy With

```dart
SettingsState copyWith({
  String? themeMode,
  String? locale,
  bool? showWelcomePage,
  String? defaultDatabase,
  int? autoSaveInterval,
  bool? enableAutoBackup,
  int? backupRetentionCount,
  double? editorFontSize,
  bool? enableCodeCompletion,
  bool? showLineNumbers,
  int? accentColor,
  bool? defaultFieldsRevision,
  bool? defaultFieldsCreatedBy,
  bool? defaultFieldsCreatedTime,
  bool? defaultFieldsUpdatedBy,
  bool? defaultFieldsUpdatedTime,
})
```

---

## SettingsNotifier

State manager for global settings.

**File**: `lib/shared/providers/settings_provider.dart`

```dart
class SettingsNotifier extends StateNotifier<SettingsState>
```

### Storage Key

```dart
static const String _settingsKey = 'app_settings';
```

### Key Methods

| Method | Parameter | Description |
|--------|-----------|-------------|
| `setThemeMode()` | `String mode` | Set theme mode |
| `setLocale()` | `String locale` | Set language |
| `setShowWelcomePage()` | `bool show` | Toggle welcome page |
| `setDefaultDatabase()` | `String? database` | Set default database |
| `setAutoSaveInterval()` | `int interval` | Set auto-save interval |
| `setEnableAutoBackup()` | `bool enable` | Toggle auto backup |
| `setBackupRetentionCount()` | `int count` | Set backup retention |
| `setEditorFontSize()` | `double size` | Set font size |
| `setEnableCodeCompletion()` | `bool enable` | Toggle code completion |
| `setShowLineNumbers()` | `bool show` | Toggle line numbers |
| `setAccentColor()` | `Color color` | Set accent color |
| `setDefaultFieldsRevision()` | `bool value` | Toggle REVISION field |
| `setDefaultFieldsCreatedBy()` | `bool value` | Toggle CREATED_BY field |
| `setDefaultFieldsCreatedTime()` | `bool value` | Toggle CREATED_TIME field |
| `setDefaultFieldsUpdatedBy()` | `bool value` | Toggle UPDATED_BY field |
| `setDefaultFieldsUpdatedTime()` | `bool value` | Toggle UPDATED_TIME field |
| `resetToDefaults()` | - | Reset all to defaults |
| `updateSettings()` | `SettingsState newSettings` | Batch update |

---

## ProjectSettingsState

Project-specific settings with inheritance support.

**File**: `lib/shared/providers/project_settings_provider.dart`

```dart
class ProjectSettingsState {
  final String projectId;
  final bool inheritDefaultFields;
  final bool inheritDefaultDatabase;
  final bool? defaultFieldsRevision;
  final bool? defaultFieldsCreatedBy;
  final bool? defaultFieldsCreatedTime;
  final bool? defaultFieldsUpdatedBy;
  final bool? defaultFieldsUpdatedTime;
  final String? defaultDatabase;
  final Map<String, dynamic>? customSettings;
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `projectId` | `String` | Required | Project ID these settings belong to |
| `inheritDefaultFields` | `bool` | `true` | Inherit default fields from global |
| `inheritDefaultDatabase` | `bool` | `true` | Inherit default database from global |
| `defaultFieldsRevision` | `bool?` | `null` | Project-specific REVISION field setting |
| `defaultFieldsCreatedBy` | `bool?` | `null` | Project-specific CREATED_BY field setting |
| `defaultFieldsCreatedTime` | `bool?` | `null` | Project-specific CREATED_TIME field setting |
| `defaultFieldsUpdatedBy` | `bool?` | `null` | Project-specific UPDATED_BY field setting |
| `defaultFieldsUpdatedTime` | `bool?` | `null` | Project-specific UPDATED_TIME field setting |
| `defaultDatabase` | `String?` | `null` | Project-specific default database |
| `customSettings` | `Map<String, dynamic>?` | `null` | Custom settings from profile |

### Inheritance Logic

- When `inheritDefaultFields` is `true`, use global settings for default fields
- When `inheritDefaultDatabase` is `true`, use global settings for default database
- Project-specific values are nullable (`bool?`, `String?`)
  - `null` means "use global/inherited value"
  - Non-null means "use project-specific value"

### Factory Methods

```dart
// Create from Project's Profile settings
factory ProjectSettingsState.fromProfile(
  String projectId,
  Map<String, dynamic>? profileSettings
)
```

### Serialization

```dart
// Convert to storage map (stored in profile.settings)
Map<String, dynamic> toStorageMap()
```

---

## ProjectSettingsNotifier

State manager for project settings.

**File**: `lib/shared/providers/project_settings_provider.dart`

```dart
class ProjectSettingsNotifier extends StateNotifier<ProjectSettingsState?>
```

### Key Methods

| Method | Parameter | Description |
|--------|-----------|-------------|
| `loadFromProject()` | `Project? project` | Load settings from project profile |
| `clear()` | - | Clear settings (project closed) |
| `setInheritDefaultFields()` | `bool inherit` | Toggle default fields inheritance |
| `setInheritDefaultDatabase()` | `bool inherit` | Toggle default database inheritance |
| `setDefaultFieldsRevision()` | `bool? value` | Set REVISION field setting |
| `setDefaultFieldsCreatedBy()` | `bool? value` | Set CREATED_BY field setting |
| `setDefaultFieldsCreatedTime()` | `bool? value` | Set CREATED_TIME field setting |
| `setDefaultFieldsUpdatedBy()` | `bool? value` | Set UPDATED_BY field setting |
| `setDefaultFieldsUpdatedTime()` | `bool? value` | Set UPDATED_TIME field setting |
| `setDefaultDatabase()` | `String? value` | Set default database |
| `resetToDefaults()` | - | Reset to inherit all from global |

### Persistence

Settings are saved to `Project.profile.settings` via `projectNotifierProvider`.

---

## EffectiveDefaultFields

Resolved default fields settings with inheritance.

**File**: `lib/shared/providers/project_settings_provider.dart`

```dart
class EffectiveDefaultFields {
  final bool revision;
  final bool createdBy;
  final bool createdTime;
  final bool updatedBy;
  final bool updatedTime;
  final String source; // 'global' or 'project'
}
```

### Resolution Logic

1. If no project or project inherits from global -> use global settings
2. If project has custom settings -> use project values (fallback to global for nulls)

### Methods

```dart
// Generate default field templates for new entity
List<Map<String, dynamic>> generateDefaultFieldTemplates()
```

Returns a list of field definition maps for enabled default fields.

---

## Providers

### Primary Providers

| Provider | Type | Description |
|----------|------|-------------|
| `settingsProvider` | `StateNotifierProvider<SettingsNotifier, SettingsState>` | Global settings |
| `projectSettingsProvider` | `StateNotifierProvider<ProjectSettingsNotifier, ProjectSettingsState?>` | Project settings |

### Convenience Providers (Global)

| Provider | Type | Description |
|----------|------|-------------|
| `themeModeProvider` | `Provider<String>` | Current theme mode |
| `localeProvider` | `Provider<String>` | Current locale |
| `showWelcomePageProvider` | `Provider<bool>` | Show welcome page |
| `defaultDatabaseProvider` | `Provider<String?>` | Default database |
| `autoSaveIntervalProvider` | `Provider<int>` | Auto-save interval |
| `enableAutoBackupProvider` | `Provider<bool>` | Auto backup enabled |
| `backupRetentionCountProvider` | `Provider<int>` | Backup retention count |
| `editorFontSizeProvider` | `Provider<double>` | Font size |
| `enableCodeCompletionProvider` | `Provider<bool>` | Code completion enabled |
| `showLineNumbersProvider` | `Provider<bool>` | Line numbers visible |
| `accentColorProvider` | `Provider<Color?>` | Accent color |

### Effective Providers (Resolved)

| Provider | Type | Description |
|----------|------|-------------|
| `effectiveDefaultFieldsProvider` | `Provider<EffectiveDefaultFields>` | Resolved default fields |
| `effectiveDefaultDatabaseProvider` | `Provider<String?>` | Resolved default database |
| `hasProjectSettingsProvider` | `Provider<bool>` | Project is loaded |

---

## Data Flow

```
User Action (UI)
    ↓
SettingsNotifier/ProjectSettingsNotifier (State Update)
    ↓
┌─────────────────────────────────────────────────────┐
│ Global: StorageService.saveSetting('app_settings') │
│ Project: ProjectNotifier.updateProject(profile)     │
└─────────────────────────────────────────────────────┘
    ↓
State Persistence
    ↓
Provider Rebuild (Riverpod)
    ↓
UI Update
```

---

## Usage Examples

### Reading Settings

```dart
// Global settings
final settings = ref.watch(settingsProvider);
final themeMode = ref.watch(themeModeProvider);
final fontSize = ref.watch(editorFontSizeProvider);

// Project settings
final projectSettings = ref.watch(projectSettingsProvider);
final hasProject = ref.watch(hasProjectSettingsProvider);

// Effective (resolved) settings
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
final effectiveDatabase = ref.watch(effectiveDefaultDatabaseProvider);
```

### Writing Settings

```dart
// Global settings
await ref.read(settingsProvider.notifier).setThemeMode('dark');
await ref.read(settingsProvider.notifier).setEditorFontSize(16.0);
await ref.read(settingsProvider.notifier).setAutoSaveInterval(120);

// Project settings
await ref.read(projectSettingsProvider.notifier).setInheritDefaultFields(false);
await ref.read(projectSettingsProvider.notifier).setDefaultDatabase('MYSQL');
await ref.read(projectSettingsProvider.notifier).resetToDefaults();
```

### Generating Default Fields

```dart
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
final fieldTemplates = effectiveFields.generateDefaultFieldTemplates();

// Returns list of field definitions:
// [
//   {'name': 'REVISION', 'type': 'Integer', ...},
//   {'name': 'CREATED_BY', 'type': 'IdOrKey', ...},
//   ...
// ]
```