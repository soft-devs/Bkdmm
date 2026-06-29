# Settings Module - Data Model

This document describes the data structures used by the settings module.

## SettingsState (Global Settings)

Location: `lib/shared/providers/settings_provider.dart`

Represents application-wide settings persisted to local storage.

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `themeMode` | `String` | `'system'` | Theme mode: `'system'`, `'light'`, `'dark'` |
| `locale` | `String` | `'zh'` | Language code: `'zh'`, `'en'` |
| `showWelcomePage` | `bool` | `true` | Whether to show welcome page on startup |
| `defaultDatabase` | `String?` | `null` | Default database type for new projects |
| `autoSaveInterval` | `int` | `60` | Auto-save interval in seconds (0 = disabled) |
| `enableAutoBackup` | `bool` | `true` | Enable automatic backups |
| `backupRetentionCount` | `int` | `10` | Number of backups to keep |
| `editorFontSize` | `double` | `14.0` | Code editor font size |
| `enableCodeCompletion` | `bool` | `true` | Enable code auto-completion |
| `showLineNumbers` | `bool` | `true` | Show line numbers in code preview |
| `accentColor` | `int?` | `null` | Accent color as 32-bit ARGB integer |
| `defaultFieldsRevision` | `bool` | `true` | Add REVISION field to new tables |
| `defaultFieldsCreatedBy` | `bool` | `true` | Add CREATED_BY field to new tables |
| `defaultFieldsCreatedTime` | `bool` | `true` | Add CREATED_TIME field to new tables |
| `defaultFieldsUpdatedBy` | `bool` | `true` | Add UPDATED_BY field to new tables |
| `defaultFieldsUpdatedTime` | `bool` | `true` | Add UPDATED_TIME field to new tables |

### Computed Properties

```dart
// Get ThemeMode enum
ThemeMode themeModeEnum;  // Converts string to ThemeMode enum

// Get accent color as Color object
Color? accentColorValue;  // Returns Color? from int?
```

### Serialization

```dart
// From JSON
final settings = SettingsState.fromJson(jsonMap);

// To JSON
final json = settings.toJson();
```

### Storage Key

Settings are stored under the key `'app_settings'` in the StorageService.

---

## ProjectSettingsState

Location: `lib/shared/providers/project_settings_provider.dart`

Represents project-specific settings that can override global settings. Stored in `project.profile.settings`.

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `projectId` | `String` | required | ID of the project these settings belong to |
| `inheritDefaultFields` | `bool` | `true` | Inherit default fields from global settings |
| `inheritDefaultDatabase` | `bool` | `true` | Inherit default database from global settings |
| `defaultFieldsRevision` | `bool?` | `null` | Project-specific REVISION field setting |
| `defaultFieldsCreatedBy` | `bool?` | `null` | Project-specific CREATED_BY field setting |
| `defaultFieldsCreatedTime` | `bool?` | `null` | Project-specific CREATED_TIME field setting |
| `defaultFieldsUpdatedBy` | `bool?` | `null` | Project-specific UPDATED_BY field setting |
| `defaultFieldsUpdatedTime` | `bool?` | `null` | Project-specific UPDATED_TIME field setting |
| `defaultDatabase` | `String?` | `null` | Project-specific default database |
| `customSettings` | `Map<String, dynamic>?` | `null` | Extension point for custom settings |

### Inheritance Model

Project settings use a **tri-state** model for field values:

1. **Inheriting** (`inheritDefaultFields = true`): Use global settings
2. **Overriding with null** (inherit = false, value = null): Use global value as fallback
3. **Overriding with value** (inherit = false, value = set): Use project-specific value

### Factory Methods

```dart
// Create from project profile settings map
final settings = ProjectSettingsState.fromProfile(projectId, profileSettings);
```

### Serialization

```dart
// Convert to storage map (for saving to profile.settings)
final storageMap = settings.toStorageMap();
```

---

## EffectiveDefaultFields

Location: `lib/shared/providers/project_settings_provider.dart`

Resolved default fields configuration that accounts for project/global inheritance.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `revision` | `bool` | Effective REVISION field setting |
| `createdBy` | `bool` | Effective CREATED_BY field setting |
| `createdTime` | `bool` | Effective CREATED_TIME field setting |
| `updatedBy` | `bool` | Effective UPDATED_BY field setting |
| `updatedTime` | `bool` | Effective UPDATED_TIME field setting |
| `source` | `String` | Source of values: `'global'` or `'project'` |

### Methods

```dart
// Generate field templates for new entity
List<Map<String, dynamic>> templates = effectiveFields.generateDefaultFieldTemplates();
```

Each template contains:
- `name`: Field name (e.g., 'REVISION')
- `chnname`: Chinese name (e.g., '乐观锁')
- `type`: Data type (e.g., 'Integer')
- `pk`: Primary key flag (always false)
- `notNull`: Not null flag (always true)
- `autoIncrement`: Auto increment flag (always false)
- `remark`: Description

### Provider Access

```dart
// Get resolved effective settings
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
final effectiveDb = ref.watch(effectiveDefaultDatabaseProvider);
```

---

## Default Field Templates

When `generateDefaultFieldTemplates()` is called, the following field definitions are generated:

### REVISION
```dart
{
  'name': 'REVISION',
  'chnname': '乐观锁',
  'type': 'Integer',
  'pk': false,
  'notNull': true,
  'autoIncrement': false,
  'remark': 'Optimistic lock version',
}
```

### CREATED_BY
```dart
{
  'name': 'CREATED_BY',
  'chnname': '创建人',
  'type': 'IdOrKey',
  'pk': false,
  'notNull': true,
  'autoIncrement': false,
  'remark': 'Creator ID',
}
```

### CREATED_TIME
```dart
{
  'name': 'CREATED_TIME',
  'chnname': '创建时间',
  'type': 'DateTime',
  'pk': false,
  'notNull': true,
  'autoIncrement': false,
  'remark': 'Creation timestamp',
}
```

### UPDATED_BY
```dart
{
  'name': 'UPDATED_BY',
  'chnname': '更新人',
  'type': 'IdOrKey',
  'pk': false,
  'notNull': true,
  'autoIncrement': false,
  'remark': 'Updater ID',
}
```

### UPDATED_TIME
```dart
{
  'name': 'UPDATED_TIME',
  'chnname': '更新时间',
  'type': 'DateTime',
  'pk': false,
  'notNull': true,
  'autoIncrement': false,
  'remark': 'Update timestamp',
}
```

---

## Notifier Methods

### SettingsNotifier

| Method | Parameters | Description |
|--------|------------|-------------|
| `setThemeMode` | `String mode` | Set theme mode |
| `setLocale` | `String locale` | Set language |
| `setShowWelcomePage` | `bool show` | Toggle welcome page |
| `setDefaultDatabase` | `String? database` | Set default database |
| `setAutoSaveInterval` | `int interval` | Set auto-save seconds |
| `setEnableAutoBackup` | `bool enable` | Toggle auto backup |
| `setBackupRetentionCount` | `int count` | Set backup count |
| `setEditorFontSize` | `double size` | Set font size |
| `setEnableCodeCompletion` | `bool enable` | Toggle code completion |
| `setShowLineNumbers` | `bool show` | Toggle line numbers |
| `setAccentColor` | `Color color` | Set accent color |
| `setDefaultFieldsRevision` | `bool value` | Set REVISION default |
| `setDefaultFieldsCreatedBy` | `bool value` | Set CREATED_BY default |
| `setDefaultFieldsCreatedTime` | `bool value` | Set CREATED_TIME default |
| `setDefaultFieldsUpdatedBy` | `bool value` | Set UPDATED_BY default |
| `setDefaultFieldsUpdatedTime` | `bool value` | Set UPDATED_TIME default |
| `resetToDefaults` | - | Reset all to defaults |
| `updateSettings` | `SettingsState newSettings` | Batch update |

### ProjectSettingsNotifier

| Method | Parameters | Description |
|--------|------------|-------------|
| `loadFromProject` | `Project? project` | Load from project profile |
| `clear` | - | Clear settings (project closed) |
| `setInheritDefaultFields` | `bool inherit` | Toggle field inheritance |
| `setInheritDefaultDatabase` | `bool inherit` | Toggle database inheritance |
| `setDefaultFieldsRevision` | `bool? value` | Set project REVISION |
| `setDefaultFieldsCreatedBy` | `bool? value` | Set project CREATED_BY |
| `setDefaultFieldsCreatedTime` | `bool? value` | Set project CREATED_TIME |
| `setDefaultFieldsUpdatedBy` | `bool? value` | Set project UPDATED_BY |
| `setDefaultFieldsUpdatedTime` | `bool? value` | Set project UPDATED_TIME |
| `setDefaultDatabase` | `String? value` | Set project database |
| `resetToDefaults` | - | Reset to inherit all |
