# Data Model

This document describes the data structures used in the workspace module.

## Tab Management

### TabType Enum

Defines the types of tabs supported by the workspace.

```dart
enum TabType {
  entity,     // Entity/table editor
  relation,   // Relation view
  settings,   // Settings page
  module,     // Module ER diagram view
  datatype,   // Data type management
}
```

### WorkspaceTab

Represents a single tab in the workspace.

```dart
class WorkspaceTab {
  final String id;           // Unique tab identifier
  final TabType type;        // Tab type
  final String title;        // Display title
  final String? subtitle;    // Optional subtitle (e.g., Chinese name)
  final String? icon;        // Icon identifier string
  final String? moduleId;    // Associated module ID (if applicable)
  final String? entityId;    // Associated entity ID (if applicable)
}
```

#### Factory Constructors

| Factory | Description |
|---------|-------------|
| `forEntity({id, entity, moduleId})` | Creates tab for entity editor |
| `forModule({id, module})` | Creates tab for module view |
| `forRelation({id, moduleId, moduleName})` | Creates tab for relation view |
| `settings({id})` | Creates tab for settings |
| `datatype({id})` | Creates tab for data type management |

#### Tab ID Conventions

Tab IDs follow specific patterns for identification:

- Entity: `entity_{entityId}`
- Module: `module_{moduleId}`
- Relation: `relation_{moduleId}`
- Settings: `settings`
- Datatype: `datatype`

#### Serialization

```dart
Map<String, dynamic> toJson()
factory WorkspaceTab.fromJson(Map<String, dynamic> json)
```

### TabState

Immutable state container for tab management.

```dart
class TabState {
  final List<WorkspaceTab> tabs;      // Open tabs in order
  final String? activeTabId;          // Currently active tab ID
  final int maxVisibleTabs;           // Maximum visible tabs (default: 10)
}
```

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `hasTabs` | `bool` | True if any tabs are open |
| `activeTab` | `WorkspaceTab?` | Currently active tab |
| `activeIndex` | `int` | Index of active tab (-1 if none) |

#### Methods

| Method | Description |
|--------|-------------|
| `hasTab(String id)` | Check if tab exists |
| `getTab(String id)` | Get tab by ID |
| `isEntityOpen(String entityId)` | Check if entity tab is open |
| `isModuleOpen(String moduleId)` | Check if module tab is open |
| `copyWith(...)` | Create modified copy |

#### Default State

```dart
static const TabState empty = TabState()
```

## Layout Management

### ViewPosition Enum

Defines where a view is positioned in the layout.

```dart
enum ViewPosition {
  left,   // Left sidebar
  right,  // Right sidebar
  bottom, // Bottom panel
}
```

### ViewConfig

Configuration for a single view panel.

```dart
class ViewConfig {
  final String id;              // Unique view identifier
  final String title;           // Display title
  final IconData icon;          // Icon data
  final String shortcut;        // Keyboard shortcut
  final ViewPosition position;  // View position
  final bool isDefaultVisible;  // Default visibility
  final double defaultWidth;    // Default width (left/right)
  final double defaultHeight;   // Default height (bottom)
  final int order;              // Sort order
}
```

### LayoutState

Immutable state container for workspace layout.

```dart
class LayoutState {
  // Left view
  final String? activeLeftView;           // Active left view ID
  final Map<String, bool> leftViewVisibility;  // Visibility map
  final double leftViewWidth;             // Width in pixels

  // Right view
  final bool rightViewVisible;            // Visibility
  final double rightViewWidth;            // Width in pixels

  // Bottom view
  final String? activeBottomView;         // Active bottom view ID
  final Map<String, bool> bottomViewVisibility; // Visibility map
  final double bottomViewHeight;          // Height in pixels

  // Icon bar
  final double iconBarWidth;              // Width in pixels (default: 48)

  // View configurations
  final List<ViewConfig> leftViewConfigs;    // Left view definitions
  final List<ViewConfig> bottomViewConfigs;  // Bottom view definitions
}
```

#### Default Dimensions

| Property | Default | Range |
|----------|---------|-------|
| `leftViewWidth` | 260px | 200-400px |
| `rightViewWidth` | 280px | 200-400px |
| `bottomViewHeight` | 200px | 100-400px |
| `iconBarWidth` | 48px | Fixed |

#### Methods

| Method | Description |
|--------|-------------|
| `isLeftViewVisible(viewId)` | Check if left view is visible |
| `isBottomViewVisible(viewId)` | Check if bottom view is visible |
| `hasAnyViewOpen()` | Check if any view panel is open |
| `copyWith(...)` | Create modified copy |

Special `copyWith` flags:

- `clearActiveLeftView: true` - Sets `activeLeftView` to null
- `clearActiveBottomView: true` - Sets `activeBottomView` to null

## Predefined Views

### Left Views

| ID | Title | Shortcut | Default Visible |
|----|-------|----------|-----------------|
| `module_tree` | Module Tree | Alt+1 | Yes |
| `datatype` | Data Types | Alt+D | No |

### Bottom Views

| ID | Title | Shortcut | Default Visible |
|----|-------|----------|-----------------|
| `console` | Console | Alt+C | No |
| `log` | Log | Alt+L | No |
| `output` | Output | Alt+O | No |

## State Persistence

### Tab State Persistence

Tabs are automatically persisted to local storage via `StorageService`.

```dart
// Storage key
static const String _storageKey = 'workspace_tabs';

// Persistence methods in TabNotifier
Future<void> _loadTabs()
Future<void> _saveTabs()
```

The tab state is saved:
- When a new tab is opened
- When a tab is closed
- When tab order changes
- When active tab changes

### Layout State

Layout state is NOT currently persisted between sessions. It initializes with default values on each app start.

## State Flow Diagram

```
User Action
    |
    v
Widget (ConsumerWidget)
    |
    v
Provider (ref.read/watch)
    |
    v
Notifier (StateNotifier)
    |
    v
State (Immutable)
    |
    v
Widget Rebuild
```

### Example: Opening an Entity Tab

```
ModuleTree._selectEntity()
    |
    v
tabProvider.notifier.openEntity(entity, moduleId)
    |
    v
TabNotifier.openEntity()
    |-- Create WorkspaceTab.forEntity()
    |-- Call openTab(tab)
    |       |-- Check if tab exists
    |       |-- If new: add to tabs list
    |       |-- Set as active
    |       |-- _saveTabs()
    |
    v
TabState updated
    |
    v
WorkspaceTabBar rebuilds
WorkspaceView._buildTabContent() rebuilds
```
