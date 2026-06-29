# Codegen Module - DDL Code Generation

## Overview

The `codegen` module provides DDL (Data Definition Language) generation and preview functionality for database schemas. It supports multiple database types and offers both single entity and batch generation capabilities.

## Directory Structure

```
lib/features/codegen/
├── codegen.dart              # Module exports
├── providers/
│   └── codegen_provider.dart # State management (Riverpod)
├── services/
│   ├── codegen_service.dart  # DDL generation core logic
│   └── template_service.dart # Mustache template rendering
└── views/
    └── codegen_view.dart     # UI for DDL preview and export
```

## Supported Databases

| Database  | Code        | Features                                    |
|-----------|-------------|---------------------------------------------|
| MySQL     | `MYSQL`     | Full support, default database              |
| PostgreSQL| `POSTGRESQL`| Full support, standard syntax               |
| Oracle    | `ORACLE`    | Full support, Oracle-specific syntax        |
| SQL Server| `SQLSERVER` | Full support, IDENTITY for auto-increment   |
| SQLite    | `SQLITE`    | Limited ALTER TABLE support (see pitfalls)  |

## Public API

### Providers

```dart
// Main state provider
final codegenProvider = StateNotifierProvider<CodegenNotifier, CodegenState>

// Available databases list
final availableDatabasesProvider = Provider<List<DatabaseTemplate>>

// Current database template
final currentDatabaseTemplateProvider = Provider<DatabaseTemplate?>
```

### CodegenState

```dart
class CodegenState {
  String selectedDatabase;      // Current database code (default: 'MYSQL')
  String generatedDdl;          // Generated DDL output
  bool isGenerating;            // Generation in progress
  Entity? selectedEntity;       // Selected entity for preview
  Module? selectedModule;       // Selected module for preview
  bool generateProject;         // Generate for entire project
  DdlType ddlType;              // DDL generation type
  String? error;                // Error message if any

  // Computed properties
  bool get hasOutput;           // Has generated DDL
  bool get hasEntity;           // Has selected entity
  bool get hasModule;           // Has selected module
}
```

### CodegenNotifier Methods

```dart
// Selection methods
void selectDatabase(String databaseCode)
void selectEntity(Entity entity)
void selectModule(Module module)
void selectProject()
void clearSelection()

// Configuration
void setDdlType(DdlType type)

// Generation
String generateEntityDdl(Entity entity)
String generateModuleDdl(Module module)
String generateProjectDdl()

// Refresh
void refresh()
```

### CodegenService Methods

```dart
class CodegenService {
  // Get available database templates
  List<DatabaseTemplate> getDefaultDatabases()

  // Single DDL generation
  String generateCreateTable(Entity entity, {...})
  String generateDropTable(Entity entity, {...})
  String generateAlterTableAddColumn(Entity entity, Field field, {...})
  String generateAlterTableDropColumn(Entity entity, String fieldName, {...})
  String generateAlterTableModifyColumn(Entity entity, Field field, {...})
  String generateCreateIndex(Entity entity, Index index, {...})
  String generateDropIndex(Entity entity, Index index, {...})

  // Batch generation
  String generateAllDdl(Entity entity, {...})
  String generateModuleDdl(Module module, {...})
  String generateProjectDdl(Project project, {...})
}
```

## Core Features

### 1. DDL Type Selection

The module supports multiple DDL operation types via `DdlType` enum:

| Type                      | Description                    |
|---------------------------|--------------------------------|
| `createTable`             | CREATE TABLE statements        |
| `dropTable`               | DROP TABLE statements          |
| `createIndex`             | CREATE INDEX statements        |
| `dropIndex`               | DROP INDEX statements          |
| `alterTableAddColumn`     | ALTER TABLE ADD COLUMN         |
| `alterTableDropColumn`    | ALTER TABLE DROP COLUMN        |
| `alterTableModifyColumn`  | ALTER TABLE MODIFY COLUMN      |

### 2. Template-Based Generation

DDL generation uses Mustache templates. Each database has its own template configuration:

```dart
class TemplateConfig {
  String createTableTemplate;
  String deleteTableTemplate;
  String rebuildTableTemplate;
  String createFieldTemplate;
  String updateFieldTemplate;
  String deleteFieldTemplate;
  String createIndexTemplate;
  String deleteIndexTemplate;
}
```

### 3. Template Variables

Available variables for CREATE TABLE template:

```
{{tableName}}        - Table name (entity.title)
{{tableComment}}     - Table comment (entity.chnname)
{{#fields}}...{{/fields}} - Field iteration block
  {{name}}           - Field name
  {{typeDB}}         - Database-specific type
  {{chnname}}        - Field Chinese name
  {{remark}}         - Field remark/comment
  {{pk}}             - Is primary key (boolean)
  {{notNull}}        - Is NOT NULL (boolean)
  {{autoIncrement}}  - Is auto increment (boolean)
  {{defaultValue}}   - Default value
  {{hasDefaultValue}}- Has default value (boolean)
  {{length}}         - Field length
  {{decimal}}        - Decimal places
```

### 4. CodegenView Widget

The main UI component provides:

- Database selector dropdown
- DDL type selector
- Entity/Module/Project tree selection
- SQL syntax highlighting
- Copy to clipboard
- Download as .sql file (placeholder)
- Export all functionality

## Usage Examples

### Generate DDL for Single Entity

```dart
// Via provider
final ddl = ref.read(codegenProvider.notifier).generateEntityDdl(entity);

// Via service directly
final service = CodegenService();
final ddl = service.generateCreateTable(
  entity,
  databaseCode: 'MYSQL',
  dataTypes: dataTypes,
  dbTemplate: dbTemplate,
);
```

### Generate DDL for Entire Project

```dart
ref.read(codegenProvider.notifier).selectProject();
final ddl = ref.read(codegenProvider).generatedDdl;
```

### Switch Database Type

```dart
ref.read(codegenProvider.notifier).selectDatabase('POSTGRESQL');
```

## Dependencies

- `flutter_riverpod` - State management
- `mustache_template` - Template rendering
- `tdesign_flutter` - UI components
- `shared/models` - Entity, Module, Project, DataType models
- `shared/providers` - currentProjectProvider, dataTypeProvider
