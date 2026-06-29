# features/codegen - DDL Code Generation Module

## Overview

The codegen module provides DDL (Data Definition Language) generation for multiple database types. It converts entity definitions into database-specific SQL statements using a template-based approach.

### Supported Databases

| Database | Code | Notes |
|----------|------|-------|
| MySQL | `MYSQL` | Default, supports comments, AUTO_INCREMENT |
| PostgreSQL | `POSTGRESQL` | Uses SERIAL type, separate COMMENT statements |
| Oracle | `ORACLE` | Standard Oracle syntax |
| SQL Server | `SQLSERVER` | Uses IDENTITY for auto-increment |
| SQLite | `SQLITE` | Limited ALTER TABLE support |

### Template System

Uses `mustache_template` package for rendering. Available template variables:

**Entity Variables:**
- `{{tableName}}` / `{{entity.title}}` - Table name
- `{{tableComment}}` / `{{entity.chnname}}` - Chinese name
- `{{#fields}}...{{/fields}}` - Iterate fields
- `{{#indexes}}...{{/indexes}}` - Iterate indexes
- `{{#primaryKeys}}...{{/primaryKeys}}` - Primary key fields

**Field Variables (inside `{{#fields}}`):**
- `{{name}}` - Field name
- `{{typeDB}}` - Database-specific type
- `{{pk}}` - Is primary key (boolean)
- `{{notNull}}` - Is not null (boolean)
- `{{autoIncrement}}` - Is auto increment (boolean)
- `{{defaultValue}}` - Default value
- `{{remark}}` - Field comment
- `{{camelName}}` - camelCase name
- `{{pascalName}}` - PascalCase name
- `{{snakeName}}` - snake_case name

---

## File Structure

```
bkdmm/lib/features/codegen/
├── codegen.dart                    # Module exports
├── providers/
│   └── codegen_provider.dart       # State management (Riverpod)
├── services/
│   ├── codegen_service.dart        # DDL generation logic
│   └── template_service.dart       # Mustache template rendering
└── views/
    └── codegen_view.dart           # UI for DDL preview/export
```

---

## API Index

### Services

#### `CodegenService`

Main service for DDL generation.

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getDefaultDatabases()` | - | `List<DatabaseTemplate>` | Get all supported database templates |
| `generateCreateTable()` | `Entity`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate CREATE TABLE DDL |
| `generateDropTable()` | `Entity`, `databaseCode`, `dbTemplate?` | `String` | Generate DROP TABLE DDL |
| `generateAlterTableAddColumn()` | `Entity`, `Field`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate ALTER TABLE ADD COLUMN |
| `generateAlterTableModifyColumn()` | `Entity`, `Field`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate ALTER TABLE MODIFY COLUMN |
| `generateAlterTableDropColumn()` | `Entity`, `fieldName`, `databaseCode`, `dbTemplate?` | `String` | Generate ALTER TABLE DROP COLUMN |
| `generateCreateIndex()` | `Entity`, `Index`, `databaseCode`, `dbTemplate?` | `String` | Generate CREATE INDEX DDL |
| `generateDropIndex()` | `Entity`, `Index`, `databaseCode`, `dbTemplate?` | `String` | Generate DROP INDEX DDL |
| `generateAllDdl()` | `Entity`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate complete DDL (drop + create + indexes) |
| `generateModuleDdl()` | `Module`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate DDL for all entities in module |
| `generateProjectDdl()` | `Project`, `databaseCode`, `dataTypes`, `dbTemplate?` | `String` | Generate DDL for entire project |

#### `TemplateService`

Mustache template rendering service.

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `render()` | `template`, `Map<String, dynamic>` | `String` | Render mustache template with data |
| `buildEntityData()` | `Entity`, `databaseCode`, `dataTypes`, `dbTemplate?` | `Map<String, dynamic>` | Build template data for entity |

---

### Providers

#### `codegenProvider`

```dart
final codegenProvider = StateNotifierProvider<CodegenNotifier, CodegenState>
```

Main state provider for code generation.

**State (`CodegenState`):**
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `selectedDatabase` | `String` | `'MYSQL'` | Selected database code |
| `generatedDdl` | `String` | `''` | Generated DDL output |
| `isGenerating` | `bool` | `false` | Generation in progress |
| `selectedEntity` | `Entity?` | `null` | Selected entity for preview |
| `selectedModule` | `Module?` | `null` | Selected module for preview |
| `generateProject` | `bool` | `false` | Generate for entire project |
| `ddlType` | `DdlType` | `createTable` | DDL generation type |
| `error` | `String?` | `null` | Error message |

**Notifier Methods (`CodegenNotifier`):**
| Method | Description |
|--------|-------------|
| `selectDatabase(String code)` | Select target database |
| `selectEntity(Entity entity)` | Select entity for preview |
| `selectModule(Module module)` | Select module for preview |
| `selectProject()` | Select entire project |
| `clearSelection()` | Clear current selection |
| `setDdlType(DdlType type)` | Set DDL generation type |
| `refresh()` | Regenerate DDL |

#### Derived Providers

```dart
// Available database templates
final availableDatabasesProvider = Provider<List<DatabaseTemplate>>

// Current database template
final currentDatabaseTemplateProvider = Provider<DatabaseTemplate?>

// Codegen service instance
final codegenServiceProvider = Provider<CodegenService>
```

---

### Enums

#### `DdlType`

```dart
enum DdlType {
  createTable,           // CREATE TABLE
  dropTable,             // DROP TABLE
  alterTableAddColumn,   // ALTER TABLE ADD COLUMN
  alterTableDropColumn,  // ALTER TABLE DROP COLUMN
  alterTableModifyColumn,// ALTER TABLE MODIFY COLUMN
  createIndex,           // CREATE INDEX
  dropIndex,             // DROP INDEX
}
```

#### `DatabaseType`

```dart
enum DatabaseType {
  mysql('MYSQL', 'MySQL'),
  postgresql('POSTGRESQL', 'PostgreSQL'),
  oracle('ORACLE', 'Oracle'),
  sqlserver('SQLSERVER', 'SQL Server'),
  sqlite('SQLITE', 'SQLite');
}
```

---

### Views

#### `CodegenView`

DDL preview and export UI.

**Constructor:**
```dart
const CodegenView({
  super.key,
  Entity? initialEntity,   // Pre-selected entity
  Module? initialModule,   // Pre-selected module
})
```

**Features:**
- Database selector dropdown
- Entity/module/project tree selection
- DDL type selector
- Syntax-highlighted SQL preview
- Copy to clipboard
- Download as .sql file

---

## Usage Examples

### Generate DDL for Single Entity

```dart
// Using provider
final notifier = ref.read(codegenProvider.notifier);
notifier.selectEntity(entity);
final state = ref.read(codegenProvider);
print(state.generatedDdl);

// Using service directly
final service = CodegenService();
final ddl = service.generateCreateTable(
  entity,
  databaseCode: 'MYSQL',
  dataTypes: dataTypes,
);
```

### Generate DDL for Module

```dart
final service = CodegenService();
final ddl = service.generateModuleDdl(
  module,
  databaseCode: 'POSTGRESQL',
  dataTypes: dataTypes,
);
```

### Generate DDL for Entire Project

```dart
final service = CodegenService();
final ddl = service.generateProjectDdl(
  project,
  databaseCode: 'MYSQL',
  dataTypes: dataTypes,
);
```

### Custom Template Rendering

```dart
final templateService = TemplateService();
final data = templateService.buildEntityData(
  entity,
  databaseCode: 'MYSQL',
  dataTypes: dataTypes,
);
final customDdl = templateService.render(customTemplate, data);
```

---

## Dependencies

- `flutter_riverpod` - State management
- `mustache_template` - Template rendering
- `tdesign_flutter` - UI components
- `shared/models` - Entity, Module, Project, DataType models
- `shared/providers` - currentProjectProvider, dataTypeProvider
