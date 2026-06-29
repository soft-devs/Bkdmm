# Project Module API Reference

## ProjectNotifier

**File:** `providers/project_notifier.dart`

Central state manager for all project operations. Extends `StateNotifier<ProjectState>`.

### Constructor

```dart
ProjectNotifier({
  ProjectFileService? fileService,
})
```

### Initialization

```dart
Future<void> init()  // Load recent projects, start auto-save timer
```

### Project Operations

#### createProject
```dart
Future<ProjectOperationResult> createProject({
  required String name,
  String? description,
  String? filePath,
})
```
Creates a new project file. If `filePath` is null, prompts user with save dialog.

**Returns:** `ProjectOperationResult` with success/error/cancelled status.

#### openProject
```dart
Future<ProjectOperationResult> openProject(String? filePath)
```
Opens an existing project file. If `filePath` is null, prompts user with open dialog.

**Returns:** `ProjectOperationResult` with loaded project.

#### openFromHistory
```dart
Future<ProjectOperationResult> openFromHistory(ProjectHistory history)
```
Opens a project from the history list by path.

#### saveProject
```dart
Future<ProjectOperationResult> saveProject({
  bool createBackup = true,
})
```
Saves the current project to its file path. Creates backup by default.

**Precondition:** `state.canSave` must be true.

#### saveProjectAs
```dart
Future<ProjectOperationResult> saveProjectAs(String? newFilePath)
```
Saves project to a new file path. Prompts for location if `newFilePath` is null.

**Precondition:** `state.canSaveAs` must be true.

#### autoSave
```dart
Future<bool> autoSave()
```
Silently saves without backup if project is dirty. Used by auto-save timer.

**Returns:** `true` if save succeeded.

#### closeProject
```dart
Future<bool> closeProject({
  bool promptSave = true,
})
```
Closes the current project. Saves if there are unsaved changes and `promptSave` is true.

**Returns:** Always returns `true`.

### Project Updates

#### updateProject
```dart
void updateProject(Project project)
```
Replaces the current project and marks state as dirty.

#### updateName / updateDescription
```dart
void updateName(String name)
void updateDescription(String? description)
```
Convenience methods for updating project metadata.

### Module Operations

#### addModule
```dart
void addModule(Module module)
```
Appends a new module to the project.

#### removeModule
```dart
void removeModule(String moduleId)
```
Removes a module by ID.

#### updateModule
```dart
void updateModule(String moduleId, Module module)
```
Updates a specific module. Validates and fixes IDs automatically.

#### createNewModule
```dart
Module createNewModule({
  required String name,
  required String chnname,
  String? description,
})
```
Factory method creating a new Module with generated ID.

### Graph/ER Diagram Operations

#### updateGraphNode
```dart
void updateGraphNode(String moduleId, String entityId, double x, double y)
```
Updates or creates a graph node position for an entity.

#### applyGraphLayout
```dart
void applyGraphLayout(String moduleId, Map<String, Offset> positions)
```
Batch updates multiple node positions (used by auto-layout).

#### addGraphEdge / removeGraphEdge / updateGraphEdge
```dart
void addGraphEdge(String moduleId, GraphEdge edge)
void removeGraphEdge(String moduleId, String sourceId, String targetId)
void updateGraphEdge(String moduleId, String sourceId, String targetId, GraphEdge newEdge)
```
Manage relationship connections between entities.

#### cleanupOrphanedGraphNodes
```dart
void cleanupOrphanedGraphNodes(String moduleId)
```
Removes graph nodes for deleted entities.

#### ensureGraphNodesForEntities
```dart
void ensureGraphNodesForEntities(String moduleId)
```
Creates graph nodes for entities that don't have one yet.

### History Management

#### refreshRecentProjects
```dart
Future<void> refreshRecentProjects()
```
Reloads recent projects list from storage.

#### removeFromRecent
```dart
Future<void> removeFromRecent(String path)
```
Removes a project from the recent list.

#### clearRecentProjects
```dart
Future<void> clearRecentProjects()
```
Clears all recent project history.

### Auto-Save Configuration

#### setAutoSaveEnabled
```dart
void setAutoSaveEnabled(bool enabled)
```
Enable/disable auto-save timer.

#### setAutoSaveInterval
```dart
void setAutoSaveInterval(int milliseconds)
```
Change auto-save interval (default: 30000ms).

### State Helpers

#### clearError
```dart
void clearError()
```
Clears the error message in state.

#### markClean
```dart
void markClean()
```
Marks project as having no unsaved changes.

#### getDefaultDataTypes
```dart
List<DataType> getDefaultDataTypes()
```
Returns default data type definitions for new projects.

---

## ProjectState

**File:** `providers/project_notifier.dart`

Immutable state class containing all project-related data.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `project` | `Project?` | Currently loaded project |
| `projectPath` | `String?` | File path of current project |
| `isDirty` | `bool` | Has unsaved changes |
| `isLoading` | `bool` | Loading/saving in progress |
| `error` | `String?` | Error message |
| `lastSavedAt` | `DateTime?` | Last manual save time |
| `lastAutoSavedAt` | `DateTime?` | Last auto-save time |
| `statistics` | `ProjectStatistics?` | Project statistics |
| `recentProjects` | `List<ProjectHistory>` | Recent projects list |

### Computed Properties

| Property | Description |
|----------|-------------|
| `hasProject` | `project != null` |
| `canSave` | Has project, path, and is dirty |
| `canSaveAs` | Has project |
| `hasValidPath` | Path is not null/empty |

### Factory

```dart
static const empty = ProjectState()
```

---

## ProjectFileService

**File:** `services/project_file_service.dart`

Handles all file I/O operations for project files.

### Constants

```dart
static const String currentFileVersion = '1.0.0'
static const String fileExtension = 'bkdmm.json'
```

### Methods

#### createNewProject
```dart
Future<ProjectCreateResult> createNewProject({
  required String name,
  String? description,
  required String filePath,
})
```
Creates a new project file with default configuration.

#### readProjectFile
```dart
Future<ProjectReadResult> readProjectFile(String filePath)
```
Reads and validates a project file.

#### saveProjectFile
```dart
Future<ProjectSaveResult> saveProjectFile(
  Project project,
  String filePath, {
  bool createBackup = true,
})
```
Saves project to file, optionally creating backup.

#### saveProjectAs
```dart
Future<ProjectSaveResult> saveProjectAs(Project project, String newFilePath)
```
Saves project to a new file path.

#### validateProjectFile
```dart
Future<ProjectValidationResult> validateProjectFile(String filePath)
```
Validates project file structure and content.

#### isValidProjectFile
```dart
Future<bool> isValidProjectFile(String filePath)
```
Quick check if file is a valid project file.

#### getFileInfo
```dart
Future<ProjectFileInfo?> getFileInfo(String filePath)
```
Returns metadata about a project file.

#### createAutoSave
```dart
Future<String?> createAutoSave(String filePath)
```
Creates an auto-save copy with timestamp.

#### cleanupAutoSaveFiles
```dart
Future<void> cleanupAutoSaveFiles(String filePath, {int keepCount = 5})
```
Removes old auto-save files, keeping newest N.

---

## DataMigrationService

**File:** `services/data_migration.dart`

Handles version-to-version data transformations.

### Methods

#### registerMigration
```dart
void registerMigration(DataMigration migration)
```
Registers a migration to be applied.

#### migrateToCurrent
```dart
Map<String, dynamic> migrateToCurrent(Map<String, dynamic> data)
```
Migrates data to the current version.

#### migrate
```dart
Map<String, dynamic> migrate(Map<String, dynamic> data, {String? fromVersion})
```
Migrates data from a specific version.

#### needsMigration
```dart
bool needsMigration(Map<String, dynamic> data)
```
Checks if data needs migration.

#### getRequiredMigrations
```dart
List<DataMigration> getRequiredMigrations(String fromVersion)
```
Gets list of migrations needed for a version.

### DataMigration Abstract Class

```dart
abstract class DataMigration {
  String get fromVersion;
  String get toVersion;
  String get description;
  Map<String, dynamic> migrate(Map<String, dynamic> data);
}
```

### Built-in Migrations

| Migration | From | To | Description |
|-----------|------|-----|-------------|
| MigrationV090ToV100 | 0.9.0 | 1.0.0 | Initial migration, adds missing fields |
| FieldRenameMigration | 1.0.0 | 1.1.0 | Placeholder for field renames |
| DefaultFieldsMigration | 1.1.0 | 1.2.0 | Adds new profile settings |

---

## CreateProjectDialog

**File:** `views/create_project_dialog.dart`

Dialog for creating new projects with form validation.

### Static Show Method

```dart
static Future<CreateProjectResult?> show(
  BuildContext context, {
  String? defaultName,
  String? defaultPath,
})
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `defaultName` | `String?` | Pre-filled project name |
| `defaultPath` | `String?` | Pre-filled save path |
| `onCreate` | `Function(String, String?, String)?` | Callback when created |

### CreateProjectResult

```dart
class CreateProjectResult {
  final String name;
  final String? description;
  final String filePath;
}
```

### Validation Rules
- Project name is required
- Project name cannot contain: `< > : " / \ | ? *`
- File path is required
- File must end with `.bkdmm.json`

---

## OpenProjectDialog

**File:** `views/open_project_dialog.dart`

Dialog for opening existing projects with recent history.

### Static Show Method

```dart
static Future<String?> show(
  BuildContext context, {
  List<ProjectHistory>? recentProjects,
})
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `recentProjects` | `List<ProjectHistory>?` | List of recent projects to display |
| `onProjectSelected` | `Function(String)?` | Callback when project selected |

### Features
- Browse button for file selection
- Recent projects list with validation
- Error display for invalid files
- File existence and format validation

---

## Result Types

### ProjectOperationResult

```dart
class ProjectOperationResult {
  final bool success;
  final bool cancelled;
  final Project? project;
  final String? path;
  final String? error;

  factory ProjectOperationResult.success({required Project project, required String path});
  factory ProjectOperationResult.error(String error);
  factory ProjectOperationResult.cancelled();
}
```

### ProjectCreateResult / ProjectReadResult / ProjectSaveResult

Similar structure with `success`, `project`, `filePath`, `error` fields.

### ProjectValidationResult

```dart
class ProjectValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  bool get hasWarnings;
  bool get hasErrors;
}
```

### ProjectStatistics

```dart
class ProjectStatistics {
  final int moduleCount;
  final int entityCount;
  final int fieldCount;
  final int relationCount;

  bool get isEmpty;
  bool get hasContent;
}
```

### ProjectFileInfo

```dart
class ProjectFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final int moduleCount;
  final int entityCount;

  String get formattedSize;  // "1.2 KB" etc.
}
```