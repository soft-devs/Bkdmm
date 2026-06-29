# Known Pitfalls

This document documents known issues, edge cases, and pitfalls in the workspace module.

## Tab Management

### Tab ID Collision

**Issue**: Tab IDs are generated based on content (e.g., `entity_{entityId}`). If the same entity is opened from different contexts, the existing tab is focused rather than creating a new one.

**Impact**: This is actually intentional behavior, but can be confusing if you expect multiple tabs for the same entity.

**Workaround**: If you need multiple tabs for the same entity (e.g., different views), use unique IDs via `createTab()` method.

### Tab State Persistence Failure

**Issue**: Tab state persistence uses `StorageService.getSetting()` which may fail silently if storage is not initialized.

**Code Location**: `tab_provider.dart` line 226-235

```dart
Future<void> _loadTabs() async {
  try {
    final saved = StorageService().getSetting<String>(_storageKey);
    // ...
  } catch (_) {
    // Ignore errors loading tabs - tabs are lost on error
  }
}
```

**Impact**: If storage fails, users lose their tab state on app restart.

**Mitigation**: The try-catch prevents crashes, but consider adding logging for debugging.

### Tab Close with No Active Tab

**Issue**: Calling `closeTab()` when `activeTabId` is null is a no-op, but calling `closeOtherTabs()` when `activeTabId` is null also does nothing.

**Code Location**: `tab_provider.dart` line 350-358

```dart
void closeOtherTabs() {
  if (state.activeTabId == null) return;  // Silent no-op
  // ...
}
```

**Impact**: UI should disable "Close Others" button when no tab is active.

### Tab Reorder Edge Cases

**Issue**: `reorderTabs()` has bounds checking but the `newIndex` calculation for Flutter's reorder behavior can be confusing.

**Code Location**: `tab_provider.dart` line 414-424

```dart
void reorderTabs(int oldIndex, int newIndex) {
  // ...
  newTabs.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, item);
}
```

**Impact**: When dragging an item forward, Flutter's `newIndex` is one greater than the target position. The code handles this correctly, but it's a common source of bugs when modifying.

## Layout Management

### View Width Clamping

**Issue**: View widths are clamped to fixed ranges (200-400px for left/right, 100-400px for bottom).

**Code Location**: `layout_provider.dart` lines 49, 72, 103

```dart
void setLeftViewWidth(double width) {
  state = state.copyWith(leftViewWidth: width.clamp(200.0, 400.0));
}
```

**Impact**: Users cannot make views smaller than 200px or larger than 400px. This may be too restrictive for some use cases.

**Workaround**: Modify the clamp values in `LayoutNotifier` if different limits are needed.

### View Visibility Logic

**Issue**: `isLeftViewVisible()` checks both `activeLeftView == viewId` AND visibility map, but the visibility map is rarely used correctly.

**Code Location**: `layout_state.dart` line 58-60

```dart
bool isLeftViewVisible(String viewId) {
  return activeLeftView == viewId && (leftViewVisibility[viewId] ?? false);
}
```

**Impact**: A view is only visible if it's both active AND marked visible in the map. However, `showLeftView()` sets both, so this works in practice. The dual condition may cause confusion.

### Layout State Not Persisted

**Issue**: Unlike tab state, layout state (view sizes, visibility) is NOT persisted between sessions.

**Impact**: Users lose their custom layout on app restart.

**Workaround**: Add persistence similar to `TabNotifier._saveTabs()` if needed.

## Module Tree

### Selection State on Module Change

**Issue**: When project modules change (add/delete), the selection state may become invalid.

**Code Location**: `module_tree.dart` line 42-58

```dart
void didUpdateWidget(ModuleTree oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.project.modules != widget.project.modules) {
    if (_selectedModuleId == null ||
        !widget.project.modules.any((m) => m.id == _selectedModuleId)) {
      _selectedModuleId = widget.project.modules.first.id;
    }
    // ...
  }
}
```

**Impact**: If all modules are deleted, accessing `widget.project.modules.first` will throw.

**Mitigation**: Add empty check before accessing `.first`.

### Entity Selection Not Cleared on Module Select

**Issue**: When selecting a module, `_selectedEntityId` is set to null, but the tab for the previously selected entity remains open.

**Code Location**: `module_tree.dart` line 72-77

```dart
void _selectModule(Module module) {
  setState(() {
    _selectedModuleId = module.id;
    _selectedEntityId = null;  // Cleared locally
  });
  ref.read(tabProvider.notifier).openModule(module);  // Opens module tab
  // Entity tab remains open
}
```

**Impact**: Visual inconsistency - tree shows module selected, but entity tab may still be active.

### Expanded State Not Persisted

**Issue**: The `_expandedModules` set is local state, not persisted.

**Impact**: Module expansion state is lost on widget rebuild or app restart.

## Workspace View

### Entity Lookup by ID

**Issue**: Entity lookup iterates through all modules to find the entity.

**Code Location**: `workspace_view.dart` line 213-222

```dart
Entity? entity;
String? moduleId;
for (final module in project.modules) {
  if (module.id == tab.moduleId) {
    moduleId = module.id;
    final found = module.entities.where((e) => e.id == tab.entityId);
    if (found.isNotEmpty) {
      entity = found.first;
    }
    break;
  }
}
```

**Impact**: O(n*m) lookup where n = modules, m = entities per module. For large projects, this could be slow.

**Workaround**: Consider building an entity index in the project model.

### Tab Content Switching

**Issue**: When switching between tabs, the entire content area is rebuilt. For complex views like ER diagrams, this can cause flicker.

**Code Location**: `workspace_view.dart` line 154-174

**Impact**: Potential performance issue with many tabs or complex views.

**Workaround**: Consider using `AutomaticKeepAliveClientMixin` for tab content widgets.

### Closing Flag Race Condition

**Issue**: `_isClosing` flag is set but never cleared in the current implementation.

**Code Location**: `workspace_view.dart` line 52

```dart
bool _isClosing = false;
```

**Impact**: If set to true, the workspace will show a loading indicator indefinitely.

**Mitigation**: This appears to be dead code from a previous implementation. Consider removing.

## Keyboard Shortcuts

### Alt Key Detection

**Issue**: Alt key detection uses `RawKeyboard.instance.keysPressed` which can be unreliable on some platforms.

**Code Location**: `workspace_shortcuts.dart` line 23-29

```dart
final rawKeys = RawKeyboard.instance.keysPressed;
final isAltPressed = rawKeys.any((key) =>
    key == LogicalKeyboardKey.altLeft ||
    key == LogicalKeyboardKey.altRight);
```

**Impact**: Shortcuts may not work reliably on all platforms or with certain keyboard layouts.

### Shortcut Conflict

**Issue**: Alt+D (datatype) may conflict with browser shortcuts in web builds.

**Impact**: Shortcut may be intercepted by browser before reaching the app.

**Workaround**: Consider using Ctrl+Alt combinations for web builds.

## Dialogs

### Dialog Context After Async

**Issue**: Dialogs use `Navigator.pop(context)` after async operations without checking `mounted`.

**Code Location**: `module_dialogs.dart` line 66-67

```dart
action: () {
  // ...
  Navigator.pop(context);  // No mounted check
  // ...
}
```

**Impact**: Potential crash if widget is disposed while dialog is open.

**Mitigation**: Add `mounted` check or use `Navigator.of(context, rootNavigator: true)`.

### Input Validation Timing

**Issue**: Input validation only happens on submit, not during typing.

**Code Location**: `module_dialogs.dart` line 63-66

```dart
if (nameController.text.trim().isEmpty) {
  TDToast.showText('Please enter module name', context: context);
  return;
}
```

**Impact**: Users only see validation errors after clicking submit.

**Workaround**: Add `onChanged` handlers to validate in real-time.

## General Recommendations

1. **Add error boundaries**: Wrap major sections in error boundaries to prevent cascading failures.

2. **Add logging**: Replace silent `catch (_) {}` blocks with proper logging.

3. **Consider memoization**: Cache computed values like entity counts in status bar.

4. **Test edge cases**: Empty projects, no tabs, all views hidden, etc.

5. **Platform testing**: Test keyboard shortcuts on all target platforms.
