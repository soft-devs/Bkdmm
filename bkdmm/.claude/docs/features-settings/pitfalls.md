# Settings Module - Known Pitfalls

This document lists known issues and pitfalls when working with the settings module.

## 1. TDSwitch onChanged Callback Return Value

**Issue**: TDSwitch requires returning `false` from `onChanged` callback to allow internal state update.

**Location**: `widgets/settings_switch_tile.dart`, panels

**Problem**: If you don't return `false`, the switch animation may not work correctly.

```dart
// WRONG
TDSwitch(
  isOn: value,
  onChanged: (newValue) {
    onChanged(newValue);
  },
);

// CORRECT
TDSwitch(
  isOn: value,
  onChanged: (newValue) {
    onChanged(newValue);
    return false;  // Required!
  },
);
```

---

## 2. Project Settings Must Be Loaded Explicitly

**Issue**: `projectSettingsProvider` is initialized as `null`. Must call `loadFromProject()` when project opens.

**Location**: `views/settings_dialog.dart`, `views/project_settings_view.dart`

**Problem**: Project settings panel shows "No project loaded" if not loaded.

```dart
// In initState or when project changes
WidgetsBinding.instance.addPostFrameCallback((_) {
  final project = ref.read(currentProjectProvider);
  ref.read(projectSettingsProvider.notifier).loadFromProject(project);
});
```

**Note**: `SettingsDialog` handles this automatically, but if using `ProjectSettingsView` standalone, you must load manually.

---

## 3. Null-Safe Project Settings Field Values

**Issue**: Project settings field values (`defaultFieldsRevision`, etc.) are nullable (`bool?`). Null means "use global value".

**Location**: All project settings related code

**Problem**: Direct null check may give wrong result. Always resolve using global fallback.

```dart
// WRONG: Direct value check
if (projectSettings.defaultFieldsRevision) { ... }  // May throw on null

// CORRECT: Resolve with global fallback
final displayValue = projectSettings.defaultFieldsRevision ?? globalSettings.defaultFieldsRevision;
```

**Better**: Use the effective providers instead:

```dart
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
if (effectiveFields.revision) { ... }  // Always resolves correctly
```

---

## 4. Accent Color Storage Format

**Issue**: Accent color is stored as `int?` (32-bit ARGB), but dialogs accept/use `Color` objects.

**Location**: `settings_provider.dart`, `accent_color_dialog.dart`

**Conversion**:

```dart
// Setting (Color -> int)
ref.read(settingsProvider.notifier).setAccentColor(color);
// internally: state.copyWith(accentColor: color.toARGB32());

// Reading (int -> Color)
Color? color = settings.accentColorValue;  // Use computed property
```

---

## 5. TDCell Style Configuration

**Issue**: `TDCellStyle` must be created with `context` parameter and modified via property assignment.

**Location**: `dialogs/theme_mode_dialog.dart`, `dialogs/database_type_dialog.dart`, `dialogs/auto_save_dialog.dart`

```dart
// CORRECT pattern
final cellStyle = TDCellStyle(context: context);
if (isSelected) {
  cellStyle.leftIconColor = tdTheme.brandNormalColor;
  cellStyle.rightIconColor = tdTheme.brandNormalColor;
}
return TDCell(
  style: cellStyle,
  leftIcon: TDIcons.data_base,
  ...
);
```

---

## 6. Dialog Responsive Width Calculation

**Issue**: Dialog width must be calculated based on screen size with clamping.

**Location**: All dialogs

**Pattern**:

```dart
final screenWidth = MediaQuery.of(context).size.width;
const baseWidth = 280.0;
final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);
```

**Why**: TDesign dialogs don't auto-resize, so manual calculation is needed for different screen sizes.

---

## 7. Settings Dialog Tree Navigation State

**Issue**: `_selectedNode` and `_selectedSubNode` are local state in `_SettingsDialogState`. Not persisted.

**Location**: `views/settings_dialog.dart`

**Behavior**:
- Default selection: 'global' (Global Settings)
- When clicking 'project', `_selectedSubNode` auto-sets to 'default_fields'
- Sub-node selection resets to null when switching to 'global'

---

## 8. SettingsSection Description Margin

**Issue**: `TDDivider` margin changes based on whether description is present.

**Location**: `widgets/settings_section.dart`

```dart
TDDivider(
  margin: EdgeInsets.symmetric(
    horizontal: 16,
    vertical: description != null ? 8 : 0,
  ),
);
```

---

## 9. TDAlertDialog ContentWidget Usage

**Issue**: When using `contentWidget`, the `content` string parameter should be empty.

**Location**: All dialogs

```dart
TDAlertDialog(
  title: 'Theme Mode',
  content: '',  // Empty when using contentWidget
  contentWidget: Column(...),
  ...
);
```

---

## 10. Font Size Dialog Slider Divisions

**Issue**: TDSlider divisions must match the range for discrete steps.

**Location**: `dialogs/font_size_dialog.dart`

```dart
TDSlider(
  value: _value,
  sliderThemeData: TDSliderThemeData(
    min: 10,
    max: 24,
    divisions: 14,  // (24 - 10) = 14 steps
  ),
  onChanged: (value) => setState(() => _value = value),
);
```

---

## 11. Auto-save Interval Options

**Issue**: Predefined intervals only, not arbitrary values.

**Location**: `dialogs/auto_save_dialog.dart`

```dart
static const List<int> _intervals = [0, 30, 60, 120, 300];
// 0 = Disabled, 30s, 1min, 2min, 5min
```

---

## 12. Project Settings Save Triggers Full Project Update

**Issue**: Changing project settings triggers `projectNotifier.updateProject()` which updates the entire project.

**Location**: `project_settings_provider.dart`, `_saveToProject()`

**Implication**: Every project settings change updates `updatedAt` timestamp. May trigger unnecessary project file writes.

---

## 13. EffectiveDefaultFields.generateDefaultFieldTemplates() Return Type

**Issue**: Returns `List<Map<String, dynamic>>`, not typed Field objects.

**Location**: `project_settings_provider.dart`

**Usage**: The returned maps are meant to be merged into entity field definitions, not used directly as Field instances.

---

## 14. SettingsProvider Initialization Timing

**Issue**: Settings are loaded asynchronously in `SettingsNotifier` constructor. Initial state may be default until loaded.

**Location**: `settings_provider.dart`

**Pattern**:
```dart
SettingsNotifier(this._storageService) : super(const SettingsState()) {
  _loadSettings();  // Async load, state updates after
}
```

**Mitigation**: Use `ref.watch(settingsProvider)` which will update when loading completes.

---

## 15. hasProjectSettingsProvider vs currentProjectProvider

**Issue**: These are related but different.

- `currentProjectProvider`: Returns the current `Project?` object
- `hasProjectSettingsProvider`: Returns `bool` based on `projectSettingsProvider != null`

**Location**: `project_settings_provider.dart`

**Note**: `hasProjectSettingsProvider` only returns true after `loadFromProject()` is called with a valid project.

---

## 16. Database Type "Not Set" Option

**Issue**: Database type can be explicitly set to `null` (meaning "not set").

**Location**: `dialogs/database_type_dialog.dart`

```dart
// First option in list is "Not Set" (null)
if (index == 0) {
  return TDCell(
    title: 'Not Set',
    description: 'No default database',
    onClick: (_) {
      onChanged(null);  // Explicit null
      Navigator.pop(context);
    },
  );
}
```

**This differs from**: Having no value (which would be `defaultDatabase` field being `null` due to never being set).