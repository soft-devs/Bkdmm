# Settings API Reference

## Views

### SettingsView

Main settings screen with tabbed interface for Global and Project settings.

**File**: `lib/features/settings/views/settings_view.dart`

```dart
class SettingsView extends ConsumerStatefulWidget
```

#### Constructor

```dart
const SettingsView({super.key})
```

#### Features

- Two tabs: Global Settings and Project Settings
- Uses `TabController` with `SingleTickerProviderStateMixin`
- Integrates with `hasProjectSettingsProvider` to determine project availability

#### Dependencies

| Provider | Usage |
|----------|-------|
| `hasProjectSettingsProvider` | Check if project is loaded |

#### Structure

```
AppScaffold
├── TabBar (Global Settings | Project Settings)
└── TabBarView
    ├── GlobalSettingsView
    └── ProjectSettingsView
```

---

### GlobalSettingsView

Global application settings view with categorized sections.

**File**: `lib/features/settings/views/global_settings_view.dart`

```dart
class GlobalSettingsView extends ConsumerWidget
```

#### Constructor

```dart
const GlobalSettingsView({super.key})
```

#### Sections

| Section | Settings |
|---------|----------|
| Appearance | Language, Theme Mode, Accent Color, Font Size |
| Editor | Default Database Type, Auto-save Interval, Show Line Numbers |
| Default Fields (Global) | REVISION, CREATED_BY, CREATED_TIME, UPDATED_BY, UPDATED_TIME |
| Data Types | Manage Data Types (placeholder) |
| Reset | Reset to Defaults |

#### Dependencies

| Provider | Usage |
|----------|-------|
| `settingsProvider` | Read/write global settings |
| `appLocaleProvider` | Read/update locale |

#### Dialog Methods

| Method | Dialog | Callback |
|--------|--------|----------|
| `_showLanguageDialog()` | `TDAlertDialog` | `appLocaleProvider.notifier.setLocale()` |
| `_showThemeModeDialog()` | `ThemeModeDialog` | `settingsProvider.notifier.setThemeMode()` |
| `_showAccentColorDialog()` | `AccentColorDialog` | `settingsProvider.notifier.setAccentColor()` |
| `_showFontSizeDialog()` | `FontSizeDialog` | `settingsProvider.notifier.setEditorFontSize()` |
| `_showDatabaseTypeDialog()` | `DatabaseTypeDialog` | `settingsProvider.notifier.setDefaultDatabase()` |
| `_showAutoSaveDialog()` | `AutoSaveDialog` | `settingsProvider.notifier.setAutoSaveInterval()` |

---

### ProjectSettingsView

Project-specific settings view with inheritance support.

**File**: `lib/features/settings/views/project_settings_view.dart`

```dart
class ProjectSettingsView extends ConsumerStatefulWidget
```

#### Constructor

```dart
const ProjectSettingsView({
  super.key,
  required this.hasProject,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `hasProject` | `bool` | Whether a project is currently loaded |

#### Sections

| Section | Settings |
|---------|----------|
| Default Database | Inherit from Global toggle, Default Database Type |
| Default Fields | Inherit from Global toggle, Field toggles |
| Reset | Reset to Inherit All |

#### Dependencies

| Provider | Usage |
|----------|-------|
| `projectSettingsProvider` | Read/write project settings |
| `settingsProvider` | Read global settings (for inheritance display) |
| `currentProjectProvider` | Load project settings on init |

#### Key Methods

| Method | Description |
|--------|-------------|
| `_loadProjectSettings()` | Load settings from current project |
| `_buildFieldToggle()` | Build field toggle with global indicator |
| `_showProjectDatabaseTypeDialog()` | Show database selection dialog |
| `_showProjectResetConfirmation()` | Show reset confirmation dialog |

---

### SettingsDialog

Dialog variant with tree navigation and panel-based layout.

**File**: `lib/features/settings/views/settings_dialog.dart`

```dart
class SettingsDialog extends ConsumerStatefulWidget
```

#### Constructor

```dart
const SettingsDialog({super.key})
```

#### Features

- Left panel: Tree navigation with Global Settings and Project Settings nodes
- Right panel: Content panel based on selected node
- Responsive dialog size via `ResponsiveUtils.getDialogSize()`

#### Navigation Nodes

| Node ID | Label | Icon | Children |
|---------|-------|------|----------|
| `global` | Global Settings | `TDIcons.internet` | None |
| `project` | Project Settings | `TDIcons.folder` | default_fields, default_database |

#### Internal Components

- `_ProjectSettingsPanel`: Wrapper that delegates to `DefaultFieldsPanel` or `DefaultDatabasePanel`

---

## Widgets

### SettingsSection

Container widget for grouped settings items.

**File**: `lib/features/settings/widgets/settings_section.dart`

```dart
class SettingsSection extends StatelessWidget
```

#### Constructor

```dart
const SettingsSection({
  super.key,
  required this.title,
  required this.icon,
  this.description,
  required this.children,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String` | Section title |
| `icon` | `IconData` | Section icon |
| `description` | `String?` | Optional description text |
| `children` | `List<Widget>` | Child setting widgets |

#### Styling

- Container with `bgColorContainer` background
- Rounded corners with `radiusLarge`
- Border using `componentStrokeColor`
- Divider between header and children

---

### SettingsTile

Clickable settings item with leading icon and trailing widget.

**File**: `lib/features/settings/widgets/settings_tile.dart`

```dart
class SettingsTile extends StatelessWidget
```

#### Constructor

```dart
const SettingsTile({
  super.key,
  required this.title,
  required this.subtitle,
  required this.leading,
  this.trailing,
  this.onTap,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String` | Setting title |
| `subtitle` | `String` | Setting description/value |
| `leading` | `Widget` | Leading widget (typically icon) |
| `trailing` | `Widget?` | Optional trailing widget |
| `onTap` | `VoidCallback?` | Tap callback |

#### Styling

- `InkWell` for tap feedback
- Horizontal padding: 16, vertical padding: 12
- Title: `fontBodyMedium`, fontWeight 500
- Subtitle: `fontBodySmall`, `textColorSecondary`

---

### SettingsSwitchTile

Settings item with toggle switch.

**File**: `lib/features/settings/widgets/settings_switch_tile.dart`

```dart
class SettingsSwitchTile extends StatelessWidget
```

#### Constructor

```dart
const SettingsSwitchTile({
  super.key,
  required this.title,
  required this.subtitle,
  required this.value,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String` | Setting title |
| `subtitle` | `String` | Setting description |
| `value` | `bool` | Current switch value |
| `onChanged` | `ValueChanged<bool>` | Value change callback |

#### Styling

- Left padding: 40 (aligns with other tiles' leading icons)
- Uses `TDSwitch` with `TDSwitchSize.medium`
- `onChanged` callback returns `false` to let internal state update

---

### ColorDot

Circular color indicator widget.

**File**: `lib/features/settings/widgets/color_dot.dart`

```dart
class ColorDot extends StatelessWidget
```

#### Constructor

```dart
const ColorDot({
  super.key,
  required this.color,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `color` | `Color` | The color to display |

#### Styling

- Size: 20x20
- Shape: Circle
- Border: `componentBorderColor`

---

## Dialogs

### ThemeModeDialog

Theme mode selection dialog.

**File**: `lib/features/settings/dialogs/theme_mode_dialog.dart`

```dart
class ThemeModeDialog extends StatelessWidget
```

#### Constructor

```dart
const ThemeModeDialog({
  super.key,
  required this.currentValue,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `currentValue` | `String` | Current theme mode ('system', 'light', 'dark') |
| `onChanged` | `ValueChanged<String>` | Selection callback |

#### Options

| ID | Title | Subtitle | Icon |
|----|-------|----------|------|
| `system` | System | Follow system settings | `TDIcons.brightness` |
| `light` | Light | Always use light theme | `TDIcons.sun_rising` |
| `dark` | Dark | Always use dark theme | `TDIcons.moon` |

---

### AccentColorDialog

Accent color picker dialog with preset colors.

**File**: `lib/features/settings/dialogs/accent_color_dialog.dart`

```dart
class AccentColorDialog extends StatelessWidget
```

#### Constructor

```dart
const AccentColorDialog({
  super.key,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `onChanged` | `ValueChanged<Color>` | Color selection callback |

#### Preset Colors

| Color | Value | Name |
|-------|-------|------|
| TDesign Brand Blue | `0xFF0052D9` | Primary |
| TDesign Hover Blue | `0xFF366EF4` | Hover |
| TDesign Lighter Blue | `0xFF618DFF` | Light |
| TDesign Success Green | `0xFF2BA471` | Success |
| TDesign Normal Green | `0xFF008858` | Success Normal |
| TDesign Warning Orange | `0xFFE37318` | Warning |
| TDesign Error Red | `0xFFD54941` | Error |
| TDesign Error Normal | `0xAD352F` | Error Normal |

---

### FontSizeDialog

Font size selection dialog with slider.

**File**: `lib/features/settings/dialogs/font_size_dialog.dart`

```dart
class FontSizeDialog extends StatefulWidget
```

#### Constructor

```dart
const FontSizeDialog({
  super.key,
  required this.currentValue,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `currentValue` | `double` | Current font size |
| `onChanged` | `ValueChanged<double>` | Size selection callback |

#### Range

- Min: 10 pt
- Max: 24 pt
- Divisions: 14
- Shows live preview with "Sample Text"

---

### DatabaseTypeDialog

Database type selection dialog.

**File**: `lib/features/settings/dialogs/database_type_dialog.dart`

```dart
class DatabaseTypeDialog extends StatelessWidget
```

#### Constructor

```dart
const DatabaseTypeDialog({
  super.key,
  required this.currentValue,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `currentValue` | `String?` | Current database type (nullable) |
| `onChanged` | `ValueChanged<String?>` | Selection callback |

#### Options

- "Not Set" (clears selection)
- Database types from `AppConstants.supportedDatabases`

---

### AutoSaveDialog

Auto-save interval selection dialog.

**File**: `lib/features/settings/dialogs/auto_save_dialog.dart`

```dart
class AutoSaveDialog extends StatelessWidget
```

#### Constructor

```dart
const AutoSaveDialog({
  super.key,
  required this.currentValue,
  required this.onChanged,
})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `currentValue` | `int` | Current interval in seconds |
| `onChanged` | `ValueChanged<int>` | Selection callback |

#### Intervals

| Seconds | Label |
|---------|-------|
| 0 | Disabled |
| 30 | 30 seconds |
| 60 | 1 minute |
| 120 | 2 minutes |
| 300 | 5 minutes |

---

## Panels

### GlobalSettingsPanel

Panel variant of global settings for dialog layout.

**File**: `lib/features/settings/panels/global_settings_panel.dart`

```dart
class GlobalSettingsPanel extends ConsumerWidget
```

#### Constructor

```dart
const GlobalSettingsPanel({super.key})
```

Same sections and functionality as `GlobalSettingsView` but optimized for dialog/panel layout.

---

### DefaultFieldsPanel

Project default fields settings panel.

**File**: `lib/features/settings/panels/default_fields_panel.dart`

```dart
class DefaultFieldsPanel extends ConsumerWidget
```

#### Constructor

```dart
const DefaultFieldsPanel({super.key})
```

#### Features

- Inheritance toggle with `TDSwitch`
- Shows field toggles only when not inheriting
- Displays "Global" badge when using global value

#### Internal Methods

| Method | Description |
|--------|-------------|
| `_buildFieldSwitch()` | Build field toggle with global indicator |

---

### DefaultDatabasePanel

Project default database settings panel.

**File**: `lib/features/settings/panels/default_database_panel.dart`

```dart
class DefaultDatabasePanel extends ConsumerWidget
```

#### Constructor

```dart
const DefaultDatabasePanel({super.key})
```

#### Features

- Inheritance toggle with `TDSwitch`
- Shows database selection only when not inheriting
- Falls back to global setting if project setting is null