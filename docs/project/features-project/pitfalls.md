# Project Module - Known Pitfalls

## 1. ID Validation in Module Updates

**Issue**: When updating modules, empty or duplicate IDs can cause data corruption.

**Location**: `ProjectNotifier.updateModule()` (lines 461-479)

**Symptom**: Entities or fields with empty IDs cause runtime errors; duplicate IDs cause data merge issues.

**Solution**: The `updateModule` method now includes automatic ID validation and repair:

```dart
void updateModule(String moduleId, Module module) {
  // Validation and auto-fix
  Module validatedModule = module;
  if (!module.validateAllIds()) {
    validatedModule = module.fixAllIds();
  }
  // ... continue with update
}
```

**Best Practice**: Always ensure entities and fields have valid IDs before calling update. Use `Module.validateAllIds()` for pre-validation if needed.

---

## 2. Auto-save Timer Lifecycle

**Issue**: Auto-save timer may continue running after widget disposal if not properly managed.

**Location**: `ProjectNotifier` (lines 668-679)

**Symptom**: Memory leaks, exceptions when trying to save disposed state.

**Solution**: The `dispose()` method cancels the timer:

```dart
@override
void dispose() {
  _stopAutoSaveTimer();
  super.dispose();
}
```

**Best Practice**: When using `ProjectNotifier` in widgets, ensure the provider is properly scoped or use `ref.onDispose()` for cleanup.

---

## 3. File Picker Path Handling on Windows

**Issue**: File paths on Windows contain backslashes which may cause issues with JSON serialization.

**Location**: `CreateProjectDialog._pickSaveLocation()` (lines 220-245)

**Symptom**: Paths stored in JSON may have inconsistent separators; file not found errors.

**Solution**: Always use `File` class from `dart:io` for path operations; the JSON encoder handles escaping correctly.

**Best Practice**: Store paths as-is; use `File.path` for OS-specific operations.

---

## 4. Project Name Validation

**Issue**: Project names with special characters can create invalid file names.

**Location**: `CreateProjectDialog._createProject()` (lines 270-316)

**Symptom**: File creation fails on certain characters (`<>:"/\|?*`).

**Solution**: Validation is performed:

```dart
if (_nameController.text.contains(RegExp(r'[<>:"/\\|?*]'))) {
  setState(() => _error = 'Project name contains invalid characters');
  return;
}
```

**Best Practice**: Also sanitize the name when generating file names:

```dart
final sanitized = projectName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
```

---

## 5. Dirty State After Auto-save

**Issue**: Auto-save doesn't clear the dirty flag, only manual save does.

**Location**: `ProjectNotifier.autoSave()` (lines 352-376)

**Symptom**: Users see "unsaved changes" indicator even after auto-save.

**Reason**: By design - auto-save is a background operation; user should still manually save to confirm.

**Behavior**:
- `saveProject()`: Sets `isDirty = false`
- `autoSave()`: Does NOT change `isDirty`
- Both update `lastSavedAt` / `lastAutoSavedAt` respectively

---

## 6. History Service Not Awaited

**Issue**: History operations are fire-and-forget in some code paths.

**Location**: `OpenProjectDialog._removeRecent()` (lines 311-317)

**Symptom**: UI may show stale history if operation fails silently.

**Current Code**:
```dart
Future<void> _removeRecent(String path) async {
  // This would typically call a service to remove from history
  // For now, just deselect if it was selected
  if (_selectedPath == path) {
    setState(() => _selectedPath = null);
  }
}
```

**Best Practice**: Call `ProjectNotifier.removeFromRecent(path)` to properly update history.

---

## 7. File Extension Handling

**Issue**: Files without `.bkdmm.json` extension may be opened but cause issues.

**Location**: `ProjectFileService.isValidProjectFile()` (lines 216-227)

**Symptom**: File picker allows `.json` files, but validation may reject them.

**Code**:
```dart
Future<bool> isValidProjectFile(String filePath) async {
  if (!filePath.endsWith('.$fileExtension')) {
    return false;
  }
  // ...
}
```

**Note**: `OpenProjectDialog` allows both `.bkdmm.json` and `.json` extensions in the picker, but validation only accepts `.bkdmm.json`.

---

## 8. Backup Creation on Save

**Issue**: Every manual save creates a backup file, potentially filling disk space.

**Location**: `ProjectFileService.saveProjectFile()` (lines 86-115)

**Symptom**: Many `.bak` files accumulate over time.

**Solution**: Auto-save doesn't create backups (`createBackup: false`). Manual save creates backup by default.

**Mitigation**: `cleanupAutoSaveFiles()` method exists but must be called explicitly:

```dart
Future<void> cleanupAutoSaveFiles(String filePath, {int keepCount = 5})
```

---

## 9. Provider Initialization Timing

**Issue**: `projectNotifierProvider` auto-initializes with `notifier.init()`, but async operations may not complete before first use.

**Location**: `project_notifier.dart` (lines 754-762)

**Code**:
```dart
final projectNotifierProvider = StateNotifierProvider<...>((ref) {
  final notifier = ProjectNotifier(...);
  notifier.init(); // Returns Future but not awaited
  return notifier;
});
```

**Symptom**: `recentProjects` may be empty on first render.

**Best Practice**: Watch `isLoading` or handle empty initial state in UI.

---

## 10. Migration Version Comparison

**Issue**: Version strings must be valid semantic versions (x.y.z).

**Location**: `DataMigrationService._compareVersions()` (lines 73-91)

**Symptom**: Invalid version strings default to `0.0.0`, potentially triggering unnecessary migrations.

**Code**:
```dart
int _compareVersions(String v1, String v2) {
  final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  // ...
}
```

**Best Practice**: Always store valid semantic versions. Pre-release versions (e.g., `1.0.0-beta`) are not supported.

---

## 11. TDInput Validation

**Issue**: `TDInput` widget from TDesign doesn't have built-in form validation.

**Location**: `CreateProjectDialog` (lines 94-103, 107-115)

**Symptom**: Form shows as valid even with invalid input.

**Workaround**: Manual validation in submit handler:

```dart
// Manual validation since TDInput doesn't have built-in validator
if (_nameController.text.trim().isEmpty) {
  setState(() => _error = 'Project name is required');
  return;
}
```

**Best Practice**: Always implement custom validation logic when using TDesign form inputs.

---

## 12. Close Project Without Save Prompt

**Issue**: `closeProject()` with `promptSave: true` attempts to save, but user may want a prompt dialog first.

**Location**: `ProjectNotifier.closeProject()` (lines 379-398)

**Current Code**:
```dart
if (promptSave && state.isDirty) {
  // This would typically show a dialog - we'll just save
  await saveProject();
}
```

**Symptom**: No user confirmation before saving.

**Best Practice**: UI should show a confirmation dialog before calling `closeProject()` if dirty.

---

## Summary Table

| Issue | Severity | Auto-fixed | Location |
|-------|----------|------------|----------|
| ID Validation | High | Yes | updateModule() |
| Auto-save Timer | Medium | Yes | dispose() |
| Windows Paths | Low | No | File picker |
| Name Validation | Medium | No | CreateProjectDialog |
| Dirty after Auto-save | Info | N/A | By design |
| History Not Awaited | Low | No | OpenProjectDialog |
| File Extension | Medium | No | Validation |
| Backup Accumulation | Low | No | saveProjectFile() |
| Provider Init Timing | Low | No | Provider definition |
| Version Comparison | Low | No | Migration service |
| TDInput Validation | Medium | No | All dialogs |
| Close Project Prompt | Medium | No | closeProject() |
