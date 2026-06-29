# Settings Module Pitfalls

## Common Issues and Gotchas

---

## 1. Project Settings Null State

### Issue

`projectSettingsProvider` returns `null` when no project is loaded.

### Pitfall

```dart
// WRONG - Will throw null check error
final projectSettings = ref.watch(projectSettingsProvider);
print(projectSettings.inheritDefaultFields); // Runtime error!
```

### Solution

```dart
// CORRECT - Check for null first
final projectSettings = ref.watch(projectSettingsProvider);
if (projectSettings != null) {
  print(projectSettings.inheritDefaultFields);
}

// Or use hasProjectSettingsProvider
final hasProject = ref.watch(hasProjectSettingsProvider);
if (hasProject) {
  final projectSettings = ref.watch(projectSettingsProvider);
  // Safe to access
}
```

---

## 2. Effective vs Direct Settings Access

### Issue

Direct access to project settings may not reflect the actual effective value due to inheritance.

### Pitfall

```dart
// WRONG - Ignores inheritance logic
final projectSettings = ref.watch(projectSettingsProvider);
final database = projectSettings?.defaultDatabase; // May be null due to inheritance
```

### Solution

```dart
// CORRECT - Use effective providers
final effectiveDatabase = ref.watch(effectiveDefaultDatabaseProvider);
final effectiveFields = ref.watch(effectiveDefaultFieldsProvider);
```

---

## 3. Project Settings Must Be Loaded

### Issue

Project settings are not automatically loaded when opening settings view.

### Pitfall

```dart
// WRONG - Settings not loaded yet
class ProjectSettingsView extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    // projectSettingsProvider is null here!
  }
}
```

### Solution

```dart
// CORRECT - Load in initState with post-frame callback
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final project = ref.read(currentProjectProvider);
    ref.read(projectSettingsProvider.notifier).loadFromProject(project);
  });
}
```

---

## 4. TDSwitch onChanged Return Value

### Issue

`TDSwitch.onChanged` expects a boolean return value to control internal state.

### Pitfall

```dart
// WRONG - Missing return statement
TDSwitch(
  isOn: value,
  onChanged: (newValue) {
    onChanged(newValue);
    // Missing return - switch may not update properly
  },
)
```

### Solution

```dart
// CORRECT - Return false to let internal state update
TDSwitch(
  isOn: value,
  onChanged: (newValue) {
    onChanged(newValue);
    return false;
  },
)
```

---

## 5. Settings Async Operations

### Issue

Settings methods are async but UI updates synchronously via Riverpod state.

### Pitfall

```dart
// WRONG - Not awaiting may cause issues
void _updateTheme(String mode) {
  ref.read(settingsProvider.notifier).setThemeMode(mode);
  // May not be persisted yet if app closes
}
```

### Solution

```dart
// CORRECT - Await for critical operations
Future<void> _updateTheme(String mode) async {
  await ref.read(settingsProvider.notifier).setThemeMode(mode);
  // Now persisted
}
```

---

## 6. Reset Settings Data Loss

### Issue

Resetting settings to defaults is irreversible and loses all user preferences.

### Pitfall

```dart
// WRONG - No confirmation
ref.read(settingsProvider.notifier).resetToDefaults();
```

### Solution

```dart
// CORRECT - Show confirmation dialog first
void _showResetConfirmation(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: l10n.resetSettings,
      content: l10n.resetSettingsConfirm,
      leftBtn: TDDialogButtonOptions(
        title: l10n.cancel,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: l10n.reset,
        theme: TDButtonTheme.danger,
        action: () {
          ref.read(settingsProvider.notifier).resetToDefaults();
          Navigator.pop(context);
        },
      ),
    ),
  );
}
```

---

## 7. Nullable vs Non-Nullable Default Fields

### Issue

Project settings use nullable booleans (`bool?`) while global settings use non-nullable (`bool`).

### Pitfall

```dart
// WRONG - Type mismatch
final globalValue = settings.defaultFieldsRevision; // bool
final projectValue = projectSettings.defaultFieldsRevision; // bool?

// Direct comparison fails when project is null
if (projectSettings.defaultFieldsRevision == settings.defaultFieldsRevision) {
  // Logic error - null != false/true
}
```

### Solution

```dart
// CORRECT - Handle nullability
final displayValue = projectSettings?.defaultFieldsRevision ?? settings.defaultFieldsRevision;

// Or check inheritance flag
if (projectSettings.inheritDefaultFields) {
  // Use global value
} else {
  // Use project value (may still be null, fallback to global)
}
```

---

## 8. Accent Color Storage Format

### Issue

Accent color is stored as `int` (ARGB32) but UI works with `Color` objects.

### Pitfall

```dart
// WRONG - Using Color directly
settings.accentColor; // This is int?, not Color?
```

### Solution

```dart
// CORRECT - Use the computed property
final color = settings.accentColorValue; // Color? - properly converted

// Or convert manually
final color = settings.accentColor != null ? Color(settings.accentColor!) : null;
```

---

## 9. TabController Lifecycle

### Issue

`TabController` must be disposed to prevent memory leaks.

### Pitfall

```dart
// WRONG - Missing dispose
class _SettingsViewState extends ConsumerState<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  // Missing dispose!
}
```

### Solution

```dart
// CORRECT - Dispose in dispose()
@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}
```

---

## 10. Theme Mode String vs Enum

### Issue

Settings stores theme mode as string ('system', 'light', 'dark') but Flutter uses `ThemeMode` enum.

### Pitfall

```dart
// WRONG - String comparison with enum
if (settings.themeMode == ThemeMode.dark) {
  // Type mismatch - String != ThemeMode
}
```

### Solution

```dart
// CORRECT - Use the computed property
final themeMode = settings.themeModeEnum; // Returns ThemeMode enum

// Or convert manually
ThemeMode getThemeMode(String mode) {
  switch (mode) {
    case 'light': return ThemeMode.light;
    case 'dark': return ThemeMode.dark;
    default: return ThemeMode.system;
  }
}
```

---

## 11. Project Settings Persistence

### Issue

Project settings are stored in `Project.profile.settings`, not in a separate storage.

### Pitfall

```dart
// WRONG - Assuming separate storage
// Project settings are NOT persisted via StorageService
```

### Solution

```dart
// CORRECT - Understand the storage model
// Global settings: StorageService (app_settings key)
// Project settings: Project.profile.settings map

// Project settings are saved via ProjectNotifier
projectNotifier.updateProject(updatedProject);
```

---

## 12. Color Comparison in AccentColorDialog

### Issue

Comparing colors can fail due to different color spaces or representations.

### Pitfall

```dart
// WRONG - Direct comparison may fail
final isSelected = color == tdTheme.brandNormalColor;
```

### Solution

```dart
// CORRECT - Use toARGB32 for comparison
final isSelected = color.toARGB32 == tdTheme.brandNormalColor.toARGB32;
```

---

## 13. Dialog Context vs Widget Context

### Issue

Using wrong context for Navigator.pop() in dialogs.

### Pitfall

```dart
// WRONG - Using outer context
showDialog(
  context: context,
  builder: (context) => TDAlertDialog(
    action: () => Navigator.pop(context), // Which context?
  ),
);
```

### Solution

```dart
// CORRECT - Use builder's context
showDialog(
  context: context,
  builder: (dialogContext) => TDAlertDialog(
    action: () => Navigator.pop(dialogContext),
  ),
);

// Or use the outer context explicitly
showDialog(
  context: context,
  builder: (ctx) => TDAlertDialog(
    action: () => Navigator.pop(ctx),
  ),
);
```

---

## 14. Font Size Divisions

### Issue

Font size slider divisions don't match all possible font sizes in range.

### Pitfall

```dart
// Font size range: 10-24 (15 possible values)
// Divisions: 14 (creates 15 snap points)
// This works correctly, but if changed:
TDSliderThemeData(min: 10, max: 24, divisions: 10) // Wrong!
```

### Solution

```dart
// CORRECT - Ensure divisions match desired snap points
// For range 10-24 with integer steps: divisions = 14 (24-10)
TDSliderThemeData(min: 10, max: 24, divisions: 14)
```

---

## 15. Hardcoded Strings (Missing i18n)

### Issue

Some strings in ProjectSettingsView are hardcoded in English.

### Pitfall

```dart
// WRONG - Hardcoded string
TDText('No Project Open')
TDText('Inherit from Global')
```

### Note

The current implementation has some hardcoded strings that should be internationalized:

```dart
// In ProjectSettingsView
'No Project Open'
'Open a project to configure project-specific settings'
'Default Database'
'Inherit from Global'
'Use global default database setting'
// ... etc
```

### Solution

Add corresponding entries to ARB files and use `context.l10n`:

```dart
// CORRECT - Use i18n
TDText(l10n.noProjectOpen)
TDText(l10n.inheritFromGlobal)
```

---

## Summary Checklist

- [ ] Always check `projectSettingsProvider` for null before access
- [ ] Use effective providers for resolved inheritance values
- [ ] Load project settings with `loadFromProject()` in `initState()`
- [ ] Return `false` from `TDSwitch.onChanged`
- [ ] Await async settings operations for critical paths
- [ ] Show confirmation before reset operations
- [ ] Handle nullable project settings values with fallbacks
- [ ] Use `accentColorValue` instead of raw `accentColor`
- [ ] Dispose `TabController` in widget dispose
- [ ] Use `themeModeEnum` for Flutter `ThemeMode` compatibility
- [ ] Understand global vs project storage locations
- [ ] Use `toARGB32` for color comparisons
- [ ] Use correct context in dialog callbacks
- [ ] Verify slider divisions match intended snap points
- [ ] Internationalize all user-facing strings