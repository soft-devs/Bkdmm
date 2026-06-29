# Codegen Module - Data Structures

## Core Models (from shared/models)

### Entity

Represents a database table.

```dart
class Entity {
  final String id;              // Unique identifier
  final String title;           // Table name (English code)
  final String chnname;         // Table Chinese name
  final String? remark;         // Table remark/comment
  final List<Field> fields;     // Column definitions
  final List<Index> indexes;    // Index definitions
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed
  List<Field> get primaryKeys;  // Fields where pk == true
}
```

### Field

Represents a table column.

```dart
class Field {
  final String id;              // Unique identifier
  final String name;            // Column name
  final String type;            // Abstract data type code
  final String chnname;         // Column Chinese name
  final String? remark;         // Column remark/comment
  final bool pk;                // Is primary key
  final bool notNull;           // Is NOT NULL
  final bool autoIncrement;     // Is auto increment
  final String? defaultValue;   // Default value
  final int? length;            // Type length (e.g., VARCHAR(255))
  final int? decimal;           // Decimal places (e.g., DECIMAL(10,2))
}
```

### Index

Represents a table index.

```dart
class Index {
  final String id;              // Unique identifier
  final String name;            // Index name
  final List<String> fieldIds;  // Referenced field IDs
  final IndexType type;         // Index type
  final String? remark;         // Index remark

  // Method to resolve field names from IDs
  List<String> getFieldNames(List<Field> fields);
}

enum IndexType {
  normal,    // Regular index
  unique,    // Unique index
  fulltext,  // Full-text index (MySQL specific)
}
```

### Module

Represents a logical grouping of entities.

```dart
class Module {
  final String id;
  final String name;            // Module code
  final String chnname;         // Module Chinese name
  final List<Entity> entities;  // Tables in this module
}
```

### Project

Root model containing all modules.

```dart
class Project {
  final String id;
  final String name;
  final String? remark;
  final List<Module> modules;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

## Database Configuration Models

### DatabaseTemplate

Configuration for a specific database type.

```dart
class DatabaseTemplate {
  final String code;            // Database code (MYSQL, POSTGRESQL, etc.)
  final String name;            // Display name
  final bool defaultDatabase;   // Is the default selection
  final TemplateConfig template;// DDL templates for this database
}
```

### TemplateConfig

DDL templates for a database.

```dart
class TemplateConfig {
  final String createTableTemplate;    // CREATE TABLE statement template
  final String deleteTableTemplate;    // DROP TABLE statement template
  final String rebuildTableTemplate;   // Rebuild table template
  final String createFieldTemplate;    // ALTER TABLE ADD COLUMN template
  final String updateFieldTemplate;    // ALTER TABLE MODIFY COLUMN template
  final String deleteFieldTemplate;    // ALTER TABLE DROP COLUMN template
  final String createIndexTemplate;    // CREATE INDEX template
  final String deleteIndexTemplate;    // DROP INDEX template
  final String? entityTemplate;        // Entity class template (optional)
  final String? mapperTemplate;        // Mapper template (optional)
}
```

### DataType

Data type mapping configuration.

```dart
class DataType {
  final String id;              // Unique identifier
  final String name;            // Type code (e.g., "String", "Integer")
  final String chnname;         // Chinese name
  final String? remark;         // Remark
  final Map<String, String> apply; // Database type mapping
  // Example: {"MYSQL": "VARCHAR", "ORACLE": "NVARCHAR2"}

  // Method to get database-specific type
  String? getDatabaseType(String databaseCode);
}
```

### DataTypeDomains

Container for all data type configurations.

```dart
class DataTypeDomains {
  final List<DataType> datatype;    // All data types
  final List<DatabaseTemplate> database; // All database templates
}
```

## Codegen Module State

### CodegenState

UI state for the codegen feature.

```dart
class CodegenState {
  final String selectedDatabase;  // Current database code
  final String generatedDdl;      // Generated DDL output
  final bool isGenerating;        // Generation in progress flag
  final Entity? selectedEntity;   // Selected entity for single preview
  final Module? selectedModule;   // Selected module for batch preview
  final bool generateProject;     // Generate for entire project
  final DdlType ddlType;          // DDL operation type
  final String? error;            // Error message if generation failed

  // Computed properties
  bool get hasOutput => generatedDdl.isNotEmpty;
  bool get hasEntity => selectedEntity != null;
  bool get hasModule => selectedModule != null;
}
```

### DdlType Enum

DDL operation types.

```dart
enum DdlType {
  createTable,             // CREATE TABLE
  dropTable,               // DROP TABLE
  alterTableAddColumn,     // ALTER TABLE ADD COLUMN
  alterTableDropColumn,    // ALTER TABLE DROP COLUMN
  alterTableModifyColumn,  // ALTER TABLE MODIFY COLUMN
  createIndex,             // CREATE INDEX
  dropIndex,               // DROP INDEX
}
```

### DatabaseType Enum

Supported database types (internal use).

```dart
enum DatabaseType {
  mysql('MYSQL', 'MySQL'),
  postgresql('POSTGRESQL', 'PostgreSQL'),
  oracle('ORACLE', 'Oracle'),
  sqlserver('SQLSERVER', 'SQL Server'),
  sqlite('SQLITE', 'SQLite');

  final String code;
  final String displayName;
}
```

## Template Data Structure

Data passed to Mustache templates during rendering:

```dart
{
  'entity': {
    'title': 'user_table',
    'chnname': 'User Table',
    'remark': 'Stores user information',
  },
  'tableName': 'user_table',
  'tableComment': 'User Table',
  'fields': [
    {
      'id': 'field-001',
      'name': 'id',
      'type': 'Integer',
      'typeDB': 'INT',
      'chnname': 'ID',
      'remark': 'Primary key',
      'pk': true,
      'notNull': true,
      'autoIncrement': true,
      'defaultValue': null,
      'hasDefaultValue': false,
      'length': null,
      'decimal': null,
      'camelName': 'id',
      'pascalName': 'Id',
      'snakeName': 'id',
    },
    // ... more fields
  ],
  'primaryKeys': ['id'],
  'hasPrimaryKey': true,
  'primaryKeyFields': 'id',
  'indexes': [
    {
      'name': 'idx_username',
      'fields': 'username',
      'isUnique': true,
      'isFulltext': false,
      'isNormal': false,
    },
  ],
  'hasIndexes': true,
  'databaseCode': 'MYSQL',
}
```

## Field Name Conversions

TemplateService provides automatic name conversion for fields:

| Input        | camelName   | pascalName | snakeName     |
|--------------|-------------|------------|---------------|
| `user_name`  | `userName`  | `UserName` | `user_name`   |
| `UserName`   | `userName`  | `UserName` | `User_Name`   |
| `userId`     | `userId`    | `UserId`   | `user_Id`     |

These conversions are useful for generating code beyond DDL (e.g., entity classes, DTOs).
