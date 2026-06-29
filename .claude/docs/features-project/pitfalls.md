# Project Module Pitfalls

## State Management

### 1. StateNotifier Singleton Behavior

**Issue:** `ProjectNotifier` is created once per provider scope. The auto-save timer starts in `init()` and runs until disposal.

**Pitfall:** If you create multiple provider scopes (e.g., in tests), each gets its own timer.

**Solution:**
```dart
// In tests, override the provider
final container = ProviderContainer(
  overrides: [
    projectNotifierProvider.overrideWith((ref) => TestProjectNotifier()),
  ],
);
```

### 2. Dirty State Not Reset on Failed Save

**Issue:** If `saveProject()` fails, `isDirty` remains true, but the user might think it's saved.

**Current Behavior:** Error is set in state, but dirty flag unchanged.

**Best Practice:**
```dart
final result = await notifier.saveProject();
if (!result.success) {
  // Show error to user, keep dirty flag
  showError(result.error);
}
```

### 3. Auto-Save Race Condition

**Issue:** Auto-save can trigger while user is actively editing, potentially overwriting in-progress changes.

**Mitigation:** Auto-save only saves if `isDirty` is true. UI should set dirty flag atomically.

**Consideration:** For very large projects, auto-save might block the UI thread during serialization.

---

## File Operations

### 4. File Extension Handling

**Issue:** The file extension is `.bkdmm.json` (double extension). Some file pickers might not handle this correctly.

**Code:**
```dart
// In CreateProjectDialog
if (!finalPath.endsWith('.bkdmm.json')) {
  finalPath = '$finalPath.bkdmm.json';
}
```

**Pitfall:** On Windows, `FilePicker.platform.saveFile()` might return a path without the extension if the user doesn't type it.

**Solution:** Always append the extension if missing.

### 5. Backup File Naming

**Issue:** Backup files are created in the same directory as the original with `.bak` extension.

**Current:**
```dart
await _fileService.createBackup(filePath);  // Creates filePath.bak
```

**Pitfall:** No backup rotation. Multiple saves overwrite the same backup.

**Workaround:** The `createAutoSave()` method creates timestamped backups:
```dart
final autoSavePath = '$filePath.autosave.$timestamp';
```

### 6. Cross-Platform Path Separators

**Issue:** Path separators differ between Windows (`\`) and Unix (`/`).

**Pitfall:** String concatenation for paths can fail cross-platform.

**Solution:** Use `path` package or `File` class:
```dart
import 'package:path/path.dart' as p;
final filePath = p.join(directory, '$name.bkdmm.json');
```

---

## Validation

### 7. Validation Only on Open

**Issue:** `validateProjectFile()` is only called when opening a project, not when saving.

**Risk:** A corrupted in-memory project could be saved without validation.

**Best Practice:** Validate before critical operations:
```dart
final validationResult = await fileService.validateProjectFile(path);
if (!validationResult.isValid) {
  // Block operation
}
```

### 8. Warnings vs Errors

**Issue:** Duplicate names generate warnings, not errors. The project still opens.

**Current Behavior:**
```dart
if (moduleNames.contains(module.name)) {
  warnings.add('Duplicate module name: ${module.name}');
}
```

**Implication:** UI should display warnings to user, but they're easily missed.

---

## Migration

### 9. Migration Chain Order

**Issue:** Migrations must be registered in version order.

**Code:**
```dart
void registerMigration(DataMigration migration) {
  _migrations.add(migration);
  _migrations.sort((a, b) => _compareVersions(a.fromVersion, b.fromVersion));
}
```

**Pitfall:** If you register migrations out of order, they're sorted, but the sort might not match the logical migration path.

**Example:** If you have migrations for 0.9.0->1.0.0 and 1.0.0->1.1.0, but register them in reverse order, the sort fixes it. But if you skip a version (e.g., 0.9.0->1.0.0 and 1.1.0->1.2.0), there's a gap.

### 10. Migration Data Loss

**Issue:** Migrations add missing fields with defaults but don't preserve unknown fields.

**Code:**
```dart
final migrated = Map<String, dynamic>.from(data);
// Only sets known fields
migrated['profile'] = {...};
```

**Risk:** If a future version adds a field and the user downgrades, that field is lost on next save.

**Mitigation:** Keep unknown fields in the map:
```dart
// Don't reassign, just update/add
if (!migrated.containsKey('profile')) {
  migrated['profile'] = {...};
}
```

### 11. Version String Comparison

**Issue:** Version comparison expects semantic versioning (X.Y.Z).

**Code:**
```dart
int _compareVersions(String v1, String v2) {
  final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  // ...
}
```

**Pitfall:** Non-numeric version parts default to 0.
- "1.0.alpha" -> [1, 0, 0]
- "2.0" -> [2, 0, 0]

**Best Practice:** Always use numeric versions: "1.0.0", "1.1.0", etc.

---

## Graph Operations

### 12. Orphaned Graph Nodes

**Issue:** When an entity is deleted, its graph node might remain.

**Solution:** Call `cleanupOrphanedGraphNodes()` after entity deletion:
```dart
void removeModule(String moduleId) {
  // ... remove module
  cleanupOrphanedGraphNodes(moduleId);
}
```

**Current State:** Not automatically called. UI should call it.

### 13. Graph Node Creation for New Entities

**Issue:** New entities don't automatically get graph nodes.

**Solution:** Call `ensureGraphNodesForEntities()` before showing the ER diagram:
```dart
notifier.ensureGraphNodesForEntities(moduleId);
```

**Layout:** New nodes are placed in a grid pattern (4 columns, 250px spacing).

### 14. Edge Source/Target Matching

**Issue:** Edges are identified by `(source, target)` pair, not by ID.

**Code:**
```dart
void removeGraphEdge(String moduleId, String sourceId, String targetId) {
  final edges = m.graphCanvas.edges
      .where((e) => !(e.source == sourceId && e.target == targetId))
      .toList();
}
```

**Pitfall:** If there are multiple edges between the same entities (different relation types), this removes all of them.

**Workaround:** Add a unique ID to `GraphEdge` if multiple edges are needed.

---

## UI Components

### 15. Dialog Responsive Width

**Issue:** Dialog width is calculated based on screen size but might be too narrow on small screens.

**Code:**
```dart
final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.project);
```

**Pitfall:** On very narrow screens, form fields might overflow.

**Solution:** Use `SingleChildScrollView` wrapper (already implemented).

### 16. Recent Project File Existence

**Issue:** Recent projects list shows paths that might no longer exist.

**Current:** Validation happens on click, not on list load.

**Performance Trade-off:** Checking all files on load would be slow for large lists.

**UX Issue:** User sees a project in the list, clicks it, then gets an error.

**Potential Improvement:** Show file existence status with a different icon.

### 17. Form Validation Timing

**Issue:** `CreateProjectDialog` validates on submit, not on field change.

**Code:**
```dart
void _createProject() async {
  if (_nameController.text.trim().isEmpty) {
    setState(() => _error = 'Project name is required');
    return;
  }
  // ...
}
```

**UX Issue:** User doesn't see validation errors until they click Create.

**Improvement:** Add real-time validation with `TDInput` error state.

---

## Memory/Performance

### 18. Auto-Save Timer Never Stops

**Issue:** Auto-save timer runs continuously, even when no project is open.

**Code:**
```dart
void _startAutoSaveTimer() {
  _autoSaveTimer = Timer.periodic(Duration(milliseconds: _autoSaveInterval), (_) => autoSave());
}
```

**Mitigation:** `autoSave()` checks `hasProject` and `isDirty`:
```dart
Future<bool> autoSave() async {
  if (!state.hasProject || !state.hasValidPath || !state.isDirty) {
    return false;
  }
  // ...
}
```

**Optimization:** Stop timer when no project is open:
```dart
void closeProject() {
  // ...
  _stopAutoSaveTimer();
}
```

### 19. Statistics Recalculation

**Issue:** Statistics are recalculated on every `updateProject()` call.

**Code:**
```dart
void updateProject(Project project) {
  final stats = _calculateStatistics(project);  // O(modules * entities * fields)
  // ...
}
```

**Impact:** For large projects (100+ entities), this adds up.

**Potential Optimization:** Cache statistics and recalculate only when structure changes (add/remove module/entity/field), not on property updates.

---

## Error Handling

### 20. Silent Failure in Auto-Save

**Issue:** Auto-save failures are not surfaced to the user.

**Code:**
```dart
Future<bool> autoSave() async {
  try {
    final result = await _fileService.saveProjectFile(...);
    return result.success;
  } catch (_) {
    return false;  // Error swallowed
  }
}
```

**Risk:** User thinks data is saved, but it's not.

**Improvement:** Track consecutive failures and show warning:
```dart
int _autoSaveFailures = 0;
if (!result.success) {
  _autoSaveFailures++;
  if (_autoSaveFailures >= 3) {
    // Show warning to user
  }
}
```

### 21. Error State Persistence

**Issue:** Once an error is set, it persists until manually cleared or a new operation starts.

**Pitfall:** User might see a stale error from a previous operation.

**Current:** Each operation clears error at start:
```dart
state = state.copyWith(isLoading: true, error: null);
```

**Edge Case:** If the operation fails and then user performs a different action (e.g., switches modules), the error might still show.