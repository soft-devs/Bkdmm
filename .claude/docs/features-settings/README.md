# Settings Module

## Overview

The Settings module provides a comprehensive settings management system for the Bkdmm application, supporting both global application settings and project-specific settings with inheritance capability.

## Module Structure

```
lib/features/settings/
├── settings.dart              # Barrel file (exports SettingsView, SettingsDialog)
├── views/
│   ├── settings_view.dart     # Main tabbed settings view
│   ├── global_settings_view.dart  # Global settings tab content
│   ├── project_settings_view.dart # Project settings tab content
│   └── settings_dialog.dart   # Dialog version with tree navigation
├── widgets/
│   ├── widgets.dart           # Widgets barrel file
│   ├── settings_section.dart  # Section container widget
│   ├── settings_tile.dart     # Clickable settings item widget
│   ├── settings_switch_tile.dart  # Toggle switch settings widget
│   └── color_dot.dart         # Color indicator widget
├── dialogs/
│   ├── dialogs.dart           # Dialogs barrel file
│   ├── theme_mode_dialog.dart # Theme selection dialog
│   ├── accent_color_dialog.dart   # Color picker dialog
│   ├── font_size_dialog.dart  # Font size slider dialog
│   ├── database_type_dialog.dart  # Database selection dialog
│   ├── auto_save_dialog.dart  # Auto-save interval dialog
├── panels/
│   ├── panels.dart            # Panels barrel file
│   ├── global_settings_panel.dart   # Global settings panel for dialog
│   ├── default_fields_panel.dart    # Project default fields panel
│   └── default_database_panel.dart  # Project default database panel
```

## Key Components

### Views

| Component | Description |
|-----------|-------------|
| `SettingsView` | Main settings screen with tabbed interface (Global/Project) |
| `GlobalSettingsView` | Global settings tab with appearance, editor, and default fields sections |
| `ProjectSettingsView` | Project-specific settings with inheritance toggles |
| `SettingsDialog` | Dialog variant with tree navigation and panel-based layout |

### Widgets

| Component | Description |
|-----------|-------------|
| `SettingsSection` | Grouped settings container with title, icon, and optional description |
| `SettingsTile` | Clickable setting item with title, subtitle, leading icon, optional trailing |
| `SettingsSwitchTile` | Toggle switch setting with boolean value |
| `ColorDot` | Circular color indicator widget |

### Dialogs

| Component | Description |
|-----------|-------------|
| `ThemeModeDialog` | Theme mode selection (system/light/dark) |
| `AccentColorDialog` | Accent color picker with preset colors |
| `FontSizeDialog` | Font size slider (10-24 pt) |
| `DatabaseTypeDialog` | Database type selection from supported databases |
| `AutoSaveDialog` | Auto-save interval selection (disabled/30s/1m/2m/5m) |

### Panels

| Component | Description |
|-----------|-------------|
| `GlobalSettingsPanel` | Global settings content for dialog layout |
| `DefaultFieldsPanel` | Project default fields with inheritance toggle |
| `DefaultDatabasePanel` | Project default database with inheritance toggle |

## Features

### Global Settings
- **Appearance**: Theme mode, accent color, font size, language
- **Editor**: Auto-save interval, line numbers, code completion
- **Default Fields**: REVISION, CREATED_BY, CREATED_TIME, UPDATED_BY, UPDATED_TIME
- **Default Database**: Database type selection
- **Reset**: Restore all settings to defaults

### Project Settings
- **Inheritance System**: Project settings can inherit from global defaults
- **Default Fields Override**: Customize default fields per project
- **Default Database Override**: Customize default database per project
- **Reset**: Reset project settings to inherit from global

## State Management

Settings are managed via Riverpod providers:

| Provider | Description |
|----------|-------------|
| `settingsProvider` | Global application settings state |
| `projectSettingsProvider` | Project-specific settings state |
| `effectiveDefaultFieldsProvider` | Resolved default fields (project/global inheritance) |
| `effectiveDefaultDatabaseProvider` | Resolved default database (project/global inheritance) |
| `hasProjectSettingsProvider` | Boolean indicating if project is loaded |

## Persistence

- **Global Settings**: Persisted via `StorageService` with key `app_settings`
- **Project Settings**: Stored in `Project.profile.settings` map

## UI Patterns

- **TDesign Components**: Uses TDesign Flutter for consistent styling
- **Section-based Layout**: Settings grouped by category
- **Dialog Selection**: Settings values selected via modal dialogs
- **Responsive Dialogs**: Dialog sizes adapt via `ResponsiveUtils`
- **Inheritance Toggle**: Switch to enable/disable global inheritance

## File Count

Total: 20 Dart files
- Views: 4 files
- Widgets: 5 files
- Dialogs: 6 files
- Panels: 4 files
- Barrel files: 1 file

## Usage Examples

```dart
// Update theme mode
ref.read(settingsProvider.notifier).setThemeMode('dark');

// Update project default database
ref.read(projectSettingsProvider.notifier).setDefaultDatabase('MYSQL');

// Get effective settings (resolves inheritance)
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
final effectiveDatabase = ref.watch(effectiveDefaultDatabaseProvider);

// Check if project is loaded for settings
final hasProject = ref.watch(hasProjectSettingsProvider);
```