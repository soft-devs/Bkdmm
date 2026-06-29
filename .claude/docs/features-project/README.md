# Project Module Overview

## Module Location
`bkdmm/lib/features/project/`

## Purpose
The Project module provides comprehensive project management functionality for Bkdmm, including project creation, opening, saving, and history tracking. It serves as the central hub for managing the lifecycle of database design projects.

## Architecture

### Directory Structure
```
project/
  |-- project.dart               # Module entry point (exports)
  |-- providers/
  |   |-- project_notifier.dart  # State management (Riverpod)
  |-- services/
  |   |-- project_file_service.dart  # File I/O operations
  |   |-- data_migration.dart    # Version migration system
  |-- views/
  |   |-- create_project_dialog.dart  # New project dialog
  |   |-- open_project_dialog.dart    # Open project dialog
  |-- widgets/
  |   |-- widgets.dart           # Widget exports
  |   |-- quick_open_button.dart # Quick open action button
  |   |-- recent_project_tile.dart    # Recent project list item
  |   |-- project_file_picker.dart    # File picker component
  |   |-- recent_projects_list.dart   # Recent projects list view
```

## Key Components

### State Management
| Component | Description |
|-----------|-------------|
| ProjectNotifier | Riverpod StateNotifier managing project state |
| ProjectState | Immutable state class containing project data and metadata |
| Convenience Providers | Derived providers for common state access |

### Services
| Service | Description |
|---------|-------------|
| ProjectFileService | Handles file creation, reading, saving, validation |
| DataMigrationService | Version-to-version data transformation system |

### Views/Dialogs
| View | Description |
|------|-------------|
| CreateProjectDialog | Full dialog for creating new projects with form validation |
| OpenProjectDialog | Dialog for opening projects with recent history browsing |

### Widgets
| Widget | Description |
|--------|-------------|
| QuickOpenProjectButton | Simple button triggering file picker |
| RecentProjectTile | Card-style tile for recent project list |
| ProjectFilePicker | Embeddable file path input with browse button |
| RecentProjectsList | ListView of recent projects |

## Dependencies
- `flutter_riverpod` - State management
- `file_picker` - Cross-platform file selection
- `tdesign_flutter` - UI components (TDInput, TDButton, TDAlertDialog)
- `intl` - Date formatting
- Internal: `shared/models`, `shared/services`, `utils/id_generator`

## Main Providers

### projectNotifierProvider
Primary state provider managing all project operations.

| Method | Description |
|--------|-------------|
| `createProject(name, path)` | Create new project |
| `openProject(path)` | Open existing project |
| `saveProject()` | Save current project |
| `saveProjectAs(path)` | Save with new file path |
| `closeProject()` | Close current project |
| `updateProject(project)` | Update project data |
| `addModule(module)` | Add module to project |
| `removeModule(moduleId)` | Remove module |
| `updateModule(moduleId, module)` | Update specific module |

### Derived Providers
| Provider | Description |
|----------|-------------|
| `currentProjectProvider` | Current Project object |
| `isProjectDirtyProvider` | Has unsaved changes |
| `isProjectLoadingProvider` | Loading/saving state |
| `projectErrorProvider` | Error message |
| `projectStatisticsProvider` | Project statistics (module/entity counts) |
| `recentProjectsProvider` | List of recent projects |
| `projectPathProvider` | Current file path |
| `canSaveProjectProvider` | Can save check |
| `canSaveProjectAsProvider` | Can save-as check |

## Usage Example

```dart
// Access project state via provider
final projectState = ref.watch(projectNotifierProvider);
final project = ref.watch(currentProjectProvider);

// Create new project
final notifier = ref.read(projectNotifierProvider.notifier);
final result = await notifier.createProject(
  name: 'My Database',
  filePath: '/path/to/project.bkdmm.json',
);

// Open existing project
final result = await notifier.openProject('/path/to/project.bkdmm.json');

// Save project
if (projectState.canSave) {
  await notifier.saveProject();
}

// Access recent projects
final recent = ref.watch(recentProjectsProvider);
```

## Related Modules
- `shared/models` - Project, Module, Entity data models
- `shared/services` - FileService, HistoryService
- `features/module` - Module editing functionality