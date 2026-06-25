# Project Module - Data Models

## Core Models

### Project

**Location**: `lib/shared/models/project.dart`

Primary project model containing all project data.

```dart
class Project {
  final String id;                              // Unique identifier (UUID)
  final String name;                            // Project name
  final String? description;                    // Optional description
  final String version;                         // File format version (default: '1.0.0')
  final DateTime createdAt;                     // Creation timestamp
  final DateTime updatedAt;                     // Last update timestamp
  final List<Module> modules;                   // List of modules
  final DataTypeDomains dataTypeDomains;        // Data type definitions
  final Profile profile;                        // Project settings
  final List<VersionSnapshot>? versionHistory;  // Version history (optional)
}
```

**JSON Structure**:
```json
{
  "id": "uuid-string",
  "name": "Project Name",
  "description": "Optional description",
  "version": "1.0.0",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "modules": [],
  "dataTypeDomains": {
    "datatype": [...],
    "database": []
  },
  "profile": {
    "defaultFields": [],
    "defaultFieldsType": "1",
    "defaultDatabase": null,
    "settings": {}
  },
  "versionHistory": []
}
```

### Profile

Project configuration embedded in Project.

```dart
class Profile {
  final List<String> defaultFields;        // Default field names for new entities
  final String defaultFieldsType;          // Default field type ID
  final String? defaultDatabase;           // Default database type
  final Map<String, dynamic>? settings;    // Additional settings
}
```

### ProjectHistory

**Location**: `lib/shared/models/project_history.dart`

Recent project record for history management.

```dart
class ProjectHistory {
  final String path;            // File path
  final String name;            // Display name
  final DateTime lastOpenedAt;  // Last open timestamp
  final String? thumbnail;      // Base64 thumbnail (optional)
}
```

**JSON Structure**:
```json
{
  "path": "/path/to/project.bkdmm.json",
  "name": "My Project",
  "lastOpenedAt": "2024-01-01T00:00:00.000Z",
  "thumbnail": null
}
```

## State Models

### ProjectState

**Location**: `lib/features/project/providers/project_notifier.dart`

Reactive state for current project session.

```dart
class ProjectState {
  final Project? project;                  // Current project or null
  final String? projectPath;               // File path
  final bool isDirty;                      // Has unsaved changes
  final bool isLoading;                    // Operation in progress
  final String? error;                     // Error message
  final DateTime? lastSavedAt;             // Last save time
  final DateTime? lastAutoSavedAt;         // Last auto-save time
  final ProjectStatistics? statistics;     // Aggregated stats
  final List<ProjectHistory> recentProjects; // History list

  // Computed
  bool get hasProject;      // project != null
  bool get canSave;         // hasProject && hasValidPath && isDirty
  bool get canSaveAs;       // hasProject
  bool get hasValidPath;    // projectPath != null && !isEmpty
}
```

### ProjectStatistics

Runtime statistics about project content.

```dart
class ProjectStatistics {
  final int moduleCount;    // Number of modules
  final int entityCount;    // Total entities across modules
  final int fieldCount;     // Total fields across entities
  final int relationCount;  // Total relations (edges)

  bool get isEmpty;         // All counts are 0
  bool get hasContent;      // !isEmpty
}
```

## Result Types

### ProjectOperationResult

Result of project CRUD operations.

```dart
class ProjectOperationResult {
  final bool success;       // Operation succeeded
  final bool cancelled;     // User cancelled
  final Project? project;   // Resulting project
  final String? path;       // File path
  final String? error;      // Error message if failed

  // Factory constructors
  factory ProjectOperationResult.success({required Project project, required String path});
  factory ProjectOperationResult.error(String error);
  factory ProjectOperationResult.cancelled();
}
```

### ProjectCreateResult

Result of `ProjectFileService.createNewProject()`.

```dart
class ProjectCreateResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;
}
```

### ProjectReadResult

Result of `ProjectFileService.readProjectFile()`.

```dart
class ProjectReadResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;
}
```

### ProjectSaveResult

Result of `ProjectFileService.saveProjectFile()` and `saveProjectAs()`.

```dart
class ProjectSaveResult {
  final bool success;
  final Project? project;    // Updated project with new timestamps
  final String? filePath;
  final String? error;
}
```

### ProjectValidationResult

Result of `ProjectFileService.validateProjectFile()`.

```dart
class ProjectValidationResult {
  final bool isValid;
  final List<String> errors;    // Blocking issues
  final List<String> warnings;  // Non-blocking issues

  bool get hasWarnings;
  bool get hasErrors;
}
```

### ProjectFileInfo

File metadata from `ProjectFileService.getFileInfo()`.

```dart
class ProjectFileInfo {
  final String path;
  final String name;           // Project name from file
  final int size;              // File size in bytes
  final DateTime modifiedTime; // File modification time
  final int moduleCount;       // Number of modules
  final int entityCount;       // Total entities

  String get formattedSize;    // "X B", "X KB", "X MB"
}
```

## Migration Models

### DataMigration

Abstract base for version migrations.

```dart
abstract class DataMigration {
  String get fromVersion;     // Source version
  String get toVersion;       // Target version
  String get description;     // Human-readable description

  Map<String, dynamic> migrate(Map<String, dynamic> data);
}
```

### MigrationResult

Detailed migration result.

```dart
class MigrationResult {
  final bool success;
  final String? error;
  final String fromVersion;
  final String toVersion;
  final List<String> appliedMigrations;  // Migration descriptions
  final Map<String, dynamic> data;       // Migrated data
}
```

### VersionIncrement

Enum for version increment types.

```dart
enum VersionIncrement {
  patch,   // x.y.z -> x.y.(z+1)
  minor,   // x.y.z -> x.(y+1).0
  major,   // x.y.z -> (x+1).0.0
}
```

## Dialog Result Types

### CreateProjectResult

Result from `CreateProjectDialog`.

```dart
class CreateProjectResult {
  final String name;           // Project name
  final String? description;   // Optional description
  final String filePath;       // Selected file path
}
```

## File Constants

### ProjectFileService

```dart
static const String currentFileVersion = '1.0.0';
static const String fileExtension = 'bkdmm.json';
```

### DataMigrationService

```dart
static const String currentVersion = '1.0.0';
```

### Auto-save

```dart
static const int defaultAutoSaveInterval = 30000; // 30 seconds
```

## Default Data Types

New projects are created with 10 default data types:

| ID | Name | Chinese Name | MySQL Type |
|----|------|--------------|------------|
| 1 | IdOrKey | Identifier Key | VARCHAR(32) |
| 2 | Name | Name | VARCHAR(128) |
| 3 | Intro | Introduction | VARCHAR(512) |
| 4 | LongText | Long Text | TEXT |
| 5 | Integer | Integer | INT |
| 6 | Long | Long Integer | BIGINT |
| 7 | Money | Money | DECIMAL(32,8) |
| 8 | DateTime | Date Time | DATETIME |
| 9 | YesNo | Yes/No | VARCHAR(1) |
| 10 | Dict | Dictionary | VARCHAR(32) |
