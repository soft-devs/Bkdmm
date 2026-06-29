# Workspace Module

The workspace module provides the main project editing interface with tab management, module tree, and IDE-style layout.

## Overview

The workspace is the central hub for project editing, following an IDEA-style layout with:

- Top menu bar for file/view operations
- Left icon bar for view toggling
- Left panel for module tree and data types
- Main content area with tab management
- Right panel for properties
- Bottom panel for console/logs/output
- Status bar

```
+-----------------------------------------------------+
| TopMenuBar (File | View | Project Name | Actions)  |
+----+------------------------------------------------+
|Icon| Tab Bar                                        |
|Bar +------------------------------------------------+
|    |                                                |
|Left|         Tab Content Area                       |
|View|                                                |
|----+------------------------------------------------+
|Bott| BottomViewContainer (Console/Log/Output)      |
|View|                                                |
+----+------------------------------------------------+
| StatusBar                                           |
+-----------------------------------------------------+
```

## Directory Structure

```
lib/features/workspace/
+-- workspace.dart              # Module exports
+-- views/
|   +-- workspace_view.dart     # Main workspace view
+-- widgets/
|   +-- module_tree.dart        # Module tree widget
|   +-- module_tree_item.dart   # Individual tree item
|   +-- tab_bar.dart            # Custom tab bar with overflow
|   +-- property_section.dart   # Property panel section
|   +-- property_field.dart     # Property field widget
|   +-- stat_tile.dart          # Statistics tile widget
|   +-- toolbar/
|   |   +-- top_menu_bar.dart   # Top menu bar
|   |   +-- file_menu.dart      # File menu dropdown
|   |   +-- view_menu.dart      # View menu dropdown
|   +-- icon_bar/
|   |   +-- icon_bar.dart       # Left icon bar
|   |   +-- upper_section.dart  # Upper icons (left views)
|   |   +-- lower_section.dart  # Lower icons (bottom views)
|   |   +-- icon_bar_button.dart
|   +-- left_view/
|   |   +-- left_view_container.dart  # Left panel container
|   +-- bottom_view/
|   |   +-- bottom_view_container.dart # Bottom panel container
|   +-- shortcuts/
|       +-- workspace_shortcuts.dart  # Keyboard shortcuts
+-- providers/
|   +-- tab_provider.dart       # Tab state management
|   +-- layout_provider.dart    # Layout state management
+-- models/
|   +-- layout_state.dart       # Layout state model
|   +-- view_config.dart        # View configuration model
+-- constants/
|   +-- view_configs.dart       # View configuration constants
+-- dialogs/
    +-- module_dialogs.dart     # Module/entity dialogs
```

## Public API

### Exports (workspace.dart)

```dart
export 'views/workspace_view.dart';  // WorkspaceView
export 'providers/tab_provider.dart'; // tabProvider, TabState, WorkspaceTab
export 'widgets/module_tree.dart';    // ModuleTree
export 'widgets/tab_bar.dart';        // WorkspaceTabBar
```

### Main Components

#### WorkspaceView

The main workspace widget that orchestrates all sub-components.

```dart
class WorkspaceView extends ConsumerStatefulWidget
```

Usage:
```dart
const WorkspaceView()
```

#### ModuleTree

Displays project modules and entities in a tree structure.

```dart
class ModuleTree extends ConsumerStatefulWidget {
  final Project project;
}
```

#### WorkspaceTabBar

Custom tab bar with close buttons, overflow handling, and context menus.

```dart
class WorkspaceTabBar extends ConsumerStatefulWidget {
  final VoidCallback? onNewTab;
  final VoidCallback? onSettingsTab;
  final bool showScrollButtons;
}
```

### Providers

#### tabProvider

Manages tab state (open/close/activate tabs).

```dart
final tabProvider = StateNotifierProvider<TabNotifier, TabState>

// Key methods:
- openTab(WorkspaceTab tab)
- openEntity(Entity entity, String moduleId)
- openModule(Module module)
- openSettings()
- closeTab(String tabId)
- closeAllTabs()
- closeOtherTabs()
- setActiveTab(String tabId)
- nextTab() / previousTab()
- reorderTabs(int oldIndex, int newIndex)
```

#### layoutProvider

Manages workspace layout state (view visibility, sizes).

```dart
final layoutProvider = StateNotifierProvider<LayoutNotifier, LayoutState>

// Key methods:
- showLeftView(String viewId) / hideLeftView()
- toggleLeftView(String viewId)
- showRightView() / hideRightView()
- showBottomView(String viewId) / hideBottomView()
- setLeftViewWidth(double width)
- setRightViewWidth(double width)
- setBottomViewHeight(double height)
- hideAllViews()
- restoreDefaultLayout()
```

### Derived Providers

```dart
final activeTabProvider = Provider<WorkspaceTab?>  // Current active tab
final tabCountProvider = Provider<int>              // Number of open tabs
```

### Dialogs

Module dialogs for CRUD operations on modules and entities:

```dart
void showAddModuleDialog(BuildContext context, WidgetRef ref, List<Module> modules)
void showAddEntityDialog(BuildContext context, WidgetRef ref, List<Module> modules, {Module? selectedModule})
void showDeleteModuleDialog(BuildContext context, WidgetRef ref, Module module)
void showDeleteEntityDialog(BuildContext context, WidgetRef ref, Entity entity, Module module)
void showRenameModuleDialog(BuildContext context, WidgetRef ref, Module module)
void showRenameEntityDialog(BuildContext context, WidgetRef ref, Entity entity, Module module)
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Alt+1 | Toggle module tree |
| Alt+D | Toggle data type view |
| Alt+P | Toggle properties panel |
| Alt+C | Toggle console |
| Alt+L | Toggle log |
| Alt+O | Toggle output |
| Ctrl+Shift+F12 | Hide all views |
| Shift+Escape | Hide current view |
| Ctrl+E | Close active tab |
| Ctrl+Tab | Next tab |
| Ctrl+Shift+Tab | Previous tab |

## Dependencies

- `flutter_riverpod` - State management
- `tdesign_flutter` - UI components
- `shared/models` - Project, Module, Entity models
- `shared/providers` - projectProvider, projectNotifierProvider
- `shared/services/storage_service` - Persistent tab state
- `features/modeling/entity_editor` - Entity editing
- `features/modeling/er_diagram` - ER diagram display
- `features/datatype` - Data type management
- `features/settings` - Settings view
