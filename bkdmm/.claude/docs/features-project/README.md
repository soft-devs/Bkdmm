# Project Module

## Overview

The `project` module manages project lifecycle operations including creation, opening, saving, and history management. It serves as the entry point for all project-related functionality in the Bkdmm application.

## Directory Structure

```
lib/features/project/
├── project.dart                    # Module entry point (exports)
├── providers/
│   └── project_notifier.dart       # State management (Riverpod)
├── services/
│   ├── project_file_service.dart   # File I/O operations
│   └── data_migration.dart         # Version migration system
├── views/
│   ├── create_project_dialog.dart  # New project dialog
│   └── open_project_dialog.dart    # Open project dialog
└── widgets/
    ├── recent_project_tile.dart    # Recent project list item
    ├── quick_open_button.dart      # Quick open action button
    ├── project_file_picker.dart    # File picker wrapper
    ├── recent_projects_list.dart   # Recent projects list view
    └── widgets.dart                # Widget exports
```

## Public API

### Providers (Riverpod)

| Provider | Type | Description |
|----------|------|-------------|
| `projectNotifierProvider` | `StateNotifierProvider<ProjectNotifier, ProjectState>` | Main project state notifier |
| `projectProvider` | Alias | Backward compatible alias for `projectNotifierProvider` |
| `currentProjectProvider` | `Provider<Project?>` | Currently loaded project |
| `isProjectDirtyProvider` | `Provider<bool>` | Has unsaved changes |
| `isProjectLoadingProvider` | `Provider<bool>` | Loading/saving in progress |
| `projectErrorProvider` | `Provider<String?>` | Current error message |
| `projectStatisticsProvider` | `Provider<ProjectStatistics?>` | Project stats |
| `recentProjectsProvider` | `Provider<List<ProjectHistory>>` | Recent project list |
| `projectPathProvider` | `Provider<String?>` | Current project file path |
| `canSaveProjectProvider` | `Provider<bool>` | Can save (dirty + has path) |
| `canSaveProjectAsProvider` | `Provider<bool>` | Can save as (has project) |

### Main Classes

#### `ProjectNotifier`

Primary state management class. Key methods:

```dart
// Lifecycle
Future<void> init()                                    // Initialize, load history, start auto-save
Future<ProjectOperationResult> createProject(...)      // Create new project
Future<ProjectOperationResult> openProject(String?)    // Open existing project
Future<ProjectOperationResult> saveProject(...)        // Save current project
Future<ProjectOperationResult> saveProjectAs(String?)  // Save to new path
Future<bool> closeProject({bool promptSave})           // Close current project
Future<bool> autoSave()                                // Auto-save if dirty

// Module operations
void addModule(Module module)
void removeModule(String moduleId)
void updateModule(String moduleId, Module module)
Module createNewModule({required String name, ...})

// Project updates
void updateProject(Project project)
void updateName(String name)
void updateDescription(String? description)

// History
Future<void> refreshRecentProjects()
Future<void> removeFromRecent(String path)
Future<void> clearRecentProjects()

// Auto-save configuration
void setAutoSaveEnabled(bool enabled)
void setAutoSaveInterval(int milliseconds)
```

#### `ProjectState`

Immutable state class with properties:

- `project`: Current `Project` model or null
- `projectPath`: File path of current project
- `isDirty`: Has unsaved changes
- `isLoading`: Operation in progress
- `error`: Error message if any
- `lastSavedAt`: Last manual save time
- `lastAutoSavedAt`: Last auto-save time
- `statistics`: `ProjectStatistics` (module/entity/field/relation counts)
- `recentProjects`: List of `ProjectHistory`

Computed properties: `hasProject`, `canSave`, `canSaveAs`, `hasValidPath`

#### `ProjectFileService`

File operations service:

```dart
Future<ProjectCreateResult> createNewProject({...})
Future<ProjectReadResult> readProjectFile(String filePath)
Future<ProjectSaveResult> saveProjectFile(Project, String, {bool createBackup})
Future<ProjectSaveResult> saveProjectAs(Project, String)
Future<ProjectValidationResult> validateProjectFile(String)
Future<bool> isValidProjectFile(String)
Future<ProjectFileInfo?> getFileInfo(String)
Future<String?> createAutoSave(String)
Future<void> cleanupAutoSaveFiles(String, {int keepCount})
```

#### `DataMigrationService`

Version migration system:

```dart
void registerMigration(DataMigration)
Map<String, dynamic> migrateToCurrent(Map<String, dynamic> data)
Map<String, dynamic> migrate(Map<String, dynamic> data, {String? fromVersion})
bool needsMigration(Map<String, dynamic> data)
List<DataMigration> getRequiredMigrations(String fromVersion)
```

### Dialogs

#### `CreateProjectDialog`

```dart
// Static show method
static Future<CreateProjectResult?> show(
  BuildContext context, {
  String? defaultName,
  String? defaultPath,
})

// Returns CreateProjectResult with:
// - name: String
// - description: String?
// - filePath: String
```

#### `OpenProjectDialog`

```dart
// Static show method
static Future<String?> show(
  BuildContext context, {
  List<ProjectHistory>? recentProjects,
})

// Returns selected file path or null
```

## Core Features

### 1. Project Creation

- User enters project name and optional description
- File picker for save location (`.bkdmm.json` extension)
- Quick location buttons (Documents, Desktop)
- Validates project name for invalid characters
- Creates project with default data types and empty modules

### 2. Project Opening

- Browse for `.bkdmm.json` files
- Recent projects list with validation
- File validation before opening:
  - Extension check
  - File existence
  - JSON structure validation
- Automatic history update

### 3. Project Saving

- Manual save with optional backup creation
- Save As for new file path
- Auto-save every 30 seconds (configurable)
- Dirty tracking for unsaved changes
- Backup cleanup (keeps last 5 auto-saves)

### 4. History Management

- Recent projects stored via `HistoryService`
- Tracks: path, name, last opened time, optional thumbnail
- Remove individual or clear all history
- Automatic refresh after open/create operations

### 5. Data Migration

- Version-based migration system
- Current version: `1.0.0`
- Built-in migration: `MigrationV090ToV100`
- Migration validates and fixes:
  - Missing required fields
  - Empty IDs
  - Timestamp additions
  - Default data types

## Dependencies

- **Riverpod**: State management
- **file_picker**: File system dialogs
- **tdesign_flutter**: UI components
- **shared/models**: Project, Module, ProjectHistory, etc.
- **shared/services**: FileService, HistoryService
- **utils/id_generator**: UUID generation

## Usage Examples

### Create a new project

```dart
final result = await ref.read(projectNotifierProvider.notifier).createProject(
  name: 'My Project',
  description: 'Project description',
  filePath: '/path/to/project.bkdmm.json',
);

if (result.success) {
  print('Created: ${result.path}');
}
```

### Open existing project

```dart
final result = await ref.read(projectNotifierProvider.notifier).openProject(
  '/path/to/project.bkdmm.json',
);
```

### Watch project state

```dart
final project = ref.watch(currentProjectProvider);
final isDirty = ref.watch(isProjectDirtyProvider);
final stats = ref.watch(projectStatisticsProvider);
```

### Show create dialog

```dart
final result = await CreateProjectDialog.show(context);
if (result != null) {
  await ref.read(projectNotifierProvider.notifier).createProject(
    name: result.name,
    description: result.description,
    filePath: result.filePath,
  );
}
```
