# Settings Module

Module overview, structure, and public API for the `features/settings` module.

## Module Overview

The settings module manages global and project-specific application settings. It provides:

- **Global Settings**: Theme mode, accent color, font size, auto-save, default fields, default database type
- **Project Settings**: Project-specific overrides with inheritance support from global settings
- **Dialog-based UI**: Tree navigation with left panel tree and right panel content area

The module follows the project's TDesign Flutter UI standards and integrates with Riverpod state management.

## Directory Structure

```
lib/features/settings/
  settings.dart                 # Barrel file, exports SettingsView and SettingsDialog
  views/
    settings_view.dart          # Full-page settings view with tabs (legacy, may be deprecated)
    settings_dialog.dart        # Main dialog-based settings UI with tree navigation
    global_settings_view.dart   # Global settings list view (used in settings_view.dart)
    project_settings_view.dart  # Project settings list view with inheritance support
  widgets/
    widgets.dart                # Widget barrel file
    settings_section.dart       # Section container widget with title and icon
    settings_tile.dart          # Clickable setting row with title/subtitle/leading/trailing
    settings_switch_tile.dart   # Toggle setting row with TDSwitch
    color_dot.dart              # Small circular color indicator widget
  dialogs/
    dialogs.dart                # Dialog barrel file
    theme_mode_dialog.dart      # Theme mode selection (system/light/dark)
    accent_color_dialog.dart    # Accent color picker grid
    font_size_dialog.dart       # Font size slider dialog
    database_type_dialog.dart   # Database type selection list
    auto_save_dialog.dart       # Auto-save interval selection
  panels/
    panels.dart                 # Panel barrel file
    global_settings_panel.dart  # Global settings content panel (used in settings_dialog.dart)
    default_fields_panel.dart   # Project default fields panel with inheritance toggle
    default_database_panel.dart # Project default database panel with inheritance toggle
```

## Public API

### Entry Points

Import via barrel file:
```dart
import 'package:bkdmm/features/settings/settings.dart';
```

Exports:
- `SettingsView` - Full-page settings view (two tabs: Global/Project)
- `SettingsDialog` - Dialog-based settings with tree navigation

### Views

#### SettingsDialog (Recommended)

```dart
// Show settings dialog
showDialog(
  context: context,
  builder: (context) => const SettingsDialog(),
);
```

Dialog structure:
- Left panel: Tree navigation (Global Settings / Project Settings)
- Right panel: Content based on selected node
- Responsive dialog size (600-900 width, 400-600 height)

#### SettingsView

```dart
// Navigate to settings page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SettingsView()),
);
```

### Widgets

```dart
// Section container
SettingsSection(
  title: 'Appearance',
  icon: TDIcons.palette,
  description: 'Optional description',
  children: [...],
);

// Clickable setting row
SettingsTile(
  title: 'Theme Mode',
  subtitle: 'System',
  leading: Icon(TDIcons.brightness),
  trailing: Icon(TDIcons.chevron_right), // optional
  onTap: () => ...,
);

// Toggle setting row
SettingsSwitchTile(
  title: 'Show Line Numbers',
  subtitle: 'In code preview',
  value: true,
  onChanged: (v) => ...,
);

// Color indicator
ColorDot(color: Colors.blue);
```

### Dialogs

All dialogs are `TDAlertDialog` based with TDesign styling:

```dart
ThemeModeDialog(currentValue: 'system', onChanged: (mode) => ...);
AccentColorDialog(onChanged: (color) => ...);
FontSizeDialog(currentValue: 14.0, onChanged: (size) => ...);
DatabaseTypeDialog(currentValue: 'MySQL', onChanged: (db) => ...);
AutoSaveDialog(currentValue: 60, onChanged: (seconds) => ...);
```

### Panels

Used internally by `SettingsDialog`:

```dart
GlobalSettingsPanel();         // Global settings content
DefaultFieldsPanel();          // Project default fields
DefaultDatabasePanel();        // Project default database
```

## Provider Dependencies

The module depends on providers from `shared/providers/providers.dart`:

| Provider | Purpose |
|----------|---------|
| `settingsProvider` | Global settings state (SettingsState) |
| `projectSettingsProvider` | Project settings state (ProjectSettingsState?) |
| `hasProjectSettingsProvider` | Boolean, true if project is open |
| `currentProjectProvider` | Current project for loading settings |
| `effectiveDefaultFieldsProvider` | Resolved default fields (project/global) |
| `effectiveDefaultDatabaseProvider` | Resolved default database (project/global) |

## Usage Pattern

### Accessing Settings

```dart
// Watch settings
final settings = ref.watch(settingsProvider);
final themeMode = settings.themeMode; // 'system', 'light', 'dark'

// Modify settings
ref.read(settingsProvider.notifier).setThemeMode('dark');
ref.read(settingsProvider.notifier).setAccentColor(Colors.blue);
```

### Project Settings with Inheritance

```dart
// Check project settings availability
final hasProject = ref.watch(hasProjectSettingsProvider);

// Load project settings (called automatically by SettingsDialog)
ref.read(projectSettingsProvider.notifier).loadFromProject(project);

// Get effective settings (resolves inheritance)
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
final effectiveDb = ref.watch(effectiveDefaultDatabaseProvider);
```