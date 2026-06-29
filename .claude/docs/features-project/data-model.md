# Project Module Data Models

## Overview

This document describes the data models used in the Project module. Most core models are defined in `shared/models/` and referenced here.

---

## ProjectState

**File:** `providers/project_notifier.dart`

Primary state container for the project module.

```dart
class ProjectState {
  final Project? project;           // Current project data
  final String? projectPath;        // File path on disk
  final bool isDirty;               // Unsaved changes flag
  final bool isLoading;             // Loading/saving in progress
  final String? error;              // Error message if any
  final DateTime? lastSavedAt;      // Last manual save time
  final DateTime? lastAutoSavedAt;  // Last auto-save time
  final ProjectStatistics? statistics;  // Computed statistics
  final List<ProjectHistory> recentProjects;  // History list
}
```

### State Transitions

```
[empty] --> [loading] --> [loaded]
    ^                        |
    |                        v
    +---- [saving] <---------+
              |
              v
           [saved]
```

### Computed Properties

| Property | Logic |
|----------|-------|
| `hasProject` | `project != null` |
| `canSave` | `project != null && projectPath != null && isDirty` |
| `canSaveAs` | `project != null` |
| `hasValidPath` | `projectPath != null && projectPath!.isNotEmpty` |

---

## ProjectOperationResult

**File:** `providers/project_notifier.dart`

Result wrapper for all project operations.

```dart
class ProjectOperationResult {
  final bool success;      // Operation succeeded
  final bool cancelled;    // User cancelled (no error)
  final Project? project;  // Result project (on success)
  final String? path;      // File path (on success)
  final String? error;     // Error message (on failure)
}
```

### Factory Constructors

| Factory | success | cancelled | Meaning |
|---------|---------|-----------|---------|
| `.success(project, path)` | true | false | Operation completed |
| `.error(message)` | false | false | Operation failed |
| `.cancelled()` | false | true | User cancelled |

### Usage Pattern

```dart
final result = await notifier.openProject(path);
if (result.success) {
  print('Opened: ${result.project!.name}');
} else if (result.cancelled) {
  print('User cancelled');
} else {
  print('Error: ${result.error}');
}
```

---

## ProjectStatistics

**File:** `providers/project_notifier.dart`

Aggregated statistics about project content.

```dart
class ProjectStatistics {
  final int moduleCount;    // Number of modules
  final int entityCount;    // Total entities across modules
  final int fieldCount;     // Total fields across entities
  final int relationCount;  // Total relations (edges)
}
```

### Calculation

```dart
ProjectStatistics _calculateStatistics(Project project) {
  int entityCount = 0;
  int fieldCount = 0;
  int relationCount = 0;

  for (final module in project.modules) {
    entityCount += module.entities.length;
    for (final entity in module.entities) {
      fieldCount += entity.fields.length;
    }
    relationCount += module.graphCanvas.edges.length;
  }

  return ProjectStatistics(
    moduleCount: project.modules.length,
    entityCount: entityCount,
    fieldCount: fieldCount,
    relationCount: relationCount,
  );
}
```

---

## ProjectCreateResult / ProjectReadResult / ProjectSaveResult

**File:** `services/project_file_service.dart`

Operation-specific result types from ProjectFileService.

```dart
class ProjectCreateResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;
}

class ProjectReadResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;
}

class ProjectSaveResult {
  final bool success;
  final Project? project;      // Updated project with new timestamps
  final String? filePath;
  final String? error;
}
```

---

## ProjectValidationResult

**File:** `services/project_file_service.dart`

Result of project file validation.

```dart
class ProjectValidationResult {
  final bool isValid;          // No errors
  final List<String> errors;   // Blocking issues
  final List<String> warnings; // Non-blocking issues

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
```

### Validation Rules

| Check | Level | Condition |
|-------|-------|-----------|
| File exists | Error | `!await fileExists(path)` |
| Project ID | Error | `project.id.isEmpty` |
| Project name | Error | `project.name.isEmpty` |
| Module name empty | Error | `module.name.isEmpty` |
| Entity title empty | Error | `entity.title.isEmpty` |
| Field name empty | Error | `field.name.isEmpty` |
| Duplicate module name | Warning | `moduleNames.contains(name)` |
| Duplicate entity title | Warning | `entityTitles.contains(title)` |
| Duplicate field name | Warning | `fieldNames.contains(name)` |

---

## ProjectFileInfo

**File:** `services/project_file_service.dart`

Metadata about a project file.

```dart
class ProjectFileInfo {
  final String path;           // Full file path
  final String name;           // Project name
  final int size;              // File size in bytes
  final DateTime modifiedTime; // Last modified time
  final int moduleCount;       // Number of modules
  final int entityCount;       // Total entities

  String get formattedSize;    // Human-readable size
}
```

### Formatted Size Examples
- 512 bytes -> "512 B"
- 2048 bytes -> "2.0 KB"
- 1572864 bytes -> "1.5 MB"

---

## CreateProjectResult

**File:** `views/create_project_dialog.dart`

Result from CreateProjectDialog.

```dart
class CreateProjectResult {
  final String name;           // Project name
  final String? description;   // Optional description
  final String filePath;       // Save location
}
```

---

## MigrationResult

**File:** `services/data_migration.dart`

Result of a migration operation.

```dart
class MigrationResult {
  final bool success;
  final String? error;
  final String fromVersion;
  final String toVersion;
  final List<String> appliedMigrations;
  final Map<String, dynamic> data;
}
```

---

## DataMigration (Abstract)

**File:** `services/data_migration.dart`

Base class for version migrations.

```dart
abstract class DataMigration {
  String get fromVersion;    // Source version
  String get toVersion;      // Target version
  String get description;    // Human-readable description

  Map<String, dynamic> migrate(Map<String, dynamic> data);
}
```

### Implementing a Migration

```dart
class MyMigration extends DataMigration {
  @override
  String get fromVersion => '1.0.0';

  @override
  String get toVersion => '1.1.0';

  @override
  String get description => 'Adds new feature X';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);
    // Transform data...
    migrated['version'] = toVersion;
    return migrated;
  }
}
```

---

## Related External Models

These models are defined in `shared/models/` but heavily used in the Project module:

### Project
Core data model representing a complete database design project.

### Module
A logical grouping of entities within a project.

### Entity
A database table/entity definition.

### ProjectHistory
Record of a recently opened project.

```dart
class ProjectHistory {
  final String path;           // File path
  final String name;           // Project name
  final DateTime lastOpenedAt; // Last access time
}
```

### DataType
Data type definition for field types.

### GraphNode / GraphEdge
ER diagram positioning data.

---

## Version Increment Enum

**File:** `services/data_migration.dart`

```dart
enum VersionIncrement {
  patch,   // 1.0.0 -> 1.0.1
  minor,   // 1.0.0 -> 1.1.0
  major,   // 1.0.0 -> 2.0.0
}
```

Used by `DataVersionUtils.incrementVersion()`.