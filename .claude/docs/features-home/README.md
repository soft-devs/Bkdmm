# Home Feature Module

## Overview

The Home module provides the main entry point for the Bkdmm application, displaying project history and quick actions. It serves as the dashboard view where users can create new projects, open existing ones, and access their recent work.

## Architecture

```
lib/features/home/
├── views/
│   └── home_view.dart          # Main home screen
└── widgets/
    ├── history_list_tile.dart  # Project history list items
    └── quick_action_card.dart  # Quick action buttons
```

## Components

### Views

#### `HomeView`

The main home screen that displays:
- Welcome section with app branding
- Quick actions (New Project, Open Project, Import)
- Recent projects list with history management

| Property | Type | Description |
|----------|------|-------------|
| `key` | `Key?` | Widget key |

**State Management:**
- Watches `historyNotifierProvider` for project history
- Watches `projectProvider` for project state and loading status

**Key Methods:**
| Method | Description |
|--------|-------------|
| `_showCreateProjectDialog()` | Opens dialog to create a new project |
| `_showOpenProjectDialog()` | Opens dialog to select an existing project |
| `_openProjectAtPath(String path)` | Opens a project from a file path |
| `_openFromHistory(ProjectHistory history)` | Opens a project from history |
| `_deleteHistory(String path)` | Removes a project from recent history |
| `_showAllHistory(List<ProjectHistory> historyList)` | Shows dialog with all recent projects |

**Navigation:**
- Settings view via settings button
- Workspace view after opening/creating a project

---

### Widgets

#### `HistoryListTile`

A list tile widget for displaying project history items with leading icon, title, subtitle, timestamp, and optional trailing action menu.

| Property | Type | Description |
|----------|------|-------------|
| `history` | `ProjectHistory` | The project history item to display |
| `onTap` | `VoidCallback` | Callback when the tile is tapped |
| `onDelete` | `VoidCallback` | Callback when delete is requested |
| `onFavorite` | `VoidCallback?` | Callback when favorite is toggled |
| `onDuplicate` | `VoidCallback?` | Callback when duplicate is requested |
| `isFavorite` | `bool` | Whether this item is marked as favorite (default: `false`) |
| `trailing` | `Widget?` | Optional custom trailing widget |

**Menu Actions:**
- Open - Opens the project
- Add to Favorites / Remove from Favorites - Toggles favorite status
- Duplicate - Duplicates the project (if `onDuplicate` provided)
- Remove from List - Deletes from history

---

#### `HistoryListTileSimple`

A simplified history list tile for basic use cases without a popup menu.

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String` | The title of the history item |
| `timestamp` | `DateTime` | When the item was last modified |
| `subtitle` | `String?` | Optional subtitle |
| `icon` | `IconData` | The icon to display (default: `TDIcons.file`) |
| `onTap` | `VoidCallback?` | Callback when tapped |
| `onDelete` | `VoidCallback?` | Callback when delete is requested |

**Timestamp Formatting:**
- "Modified X minutes ago" for < 1 hour
- "Modified X hours ago" for < 24 hours
- "Modified X days ago" for < 7 days
- "Modified on MM/DD/YYYY" otherwise

---

#### `QuickActionCard`

A clickable card widget with hover effects, displaying an icon, label, and description. Used for quick actions like creating or opening projects.

| Property | Type | Description |
|----------|------|-------------|
| `icon` | `IconData` | Icon to display |
| `label` | `String` | Main label text |
| `description` | `String` | Description text |
| `tdTheme` | `TDThemeData` | TDesign theme data |
| `onTap` | `VoidCallback?` | Callback when tapped (null disables interaction) |

**Behavior:**
- Hover effect with slight scale animation (1.0 -> 1.02)
- Cursor changes to click when `onTap` is provided
- Background color changes on hover

---

## Dependencies

### External Packages
- `flutter_riverpod` - State management
- `tdesign_flutter` - UI components and theming
- `intl` - Date formatting

### Internal Dependencies
- `core/i18n/i18n.dart` - Internationalization (`l10n` extension)
- `shared/providers/providers.dart` - `historyNotifierProvider`, `projectProvider`
- `shared/models/models.dart` - `ProjectHistory` model
- `shared/widgets/app_scaffold.dart` - App scaffold wrapper
- `shared/widgets/td_popup_menu.dart` - TDesign popup menu wrapper
- `features/project/views/create_project_dialog.dart` - Project creation dialog
- `features/project/views/open_project_dialog.dart` - Project selection dialog
- `features/settings/views/settings_view.dart` - Settings screen
- `features/workspace/views/workspace_view.dart` - Main workspace

---

## Usage Examples

### Displaying Home View

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const HomeView(),
  ),
);
```

### Using HistoryListTile

```dart
HistoryListTile(
  history: projectHistory,
  onTap: () => openProject(projectHistory.path),
  onDelete: () => removeFromHistory(projectHistory.path),
  onFavorite: () => toggleFavorite(projectHistory),
)
```

### Using QuickActionCard

```dart
QuickActionCard(
  icon: TDIcons.add,
  label: 'New Project',
  description: 'Create a new database project',
  tdTheme: TDTheme.of(context),
  onTap: () => showCreateDialog(),
)
```

---

## Responsive Design

The `HomeView` implements responsive layouts:

| Breakpoint | Max Width | Layout |
|------------|-----------|--------|
| > 1200px | 1200px | Centered content |
| 800-1200px | 900px | Centered content |
| < 800px | Full width | Edge-to-edge |

Quick actions switch from horizontal Row to Wrap layout below 400px width.
