# Data Model Reference

## Core Models

### DataType

Defined in: `lib/shared/models/data_type.dart`

```dart
@JsonSerializable()
class DataType {
  /// Unique identifier for the type
  final String id;

  /// Type code (English name, e.g., "IdOrKey", "Name")
  final String name;

  /// Chinese display name
  final String chnname;

  /// Optional description/remark
  final String? remark;

  /// Database type mappings: {databaseCode: databaseType}
  final Map<String, String> apply;

  /// Optional Java type for code generation
  final String? java;
}
```

### DataTypeDomains

Container for project-wide data type configuration:

```dart
@JsonSerializable()
class DataTypeDomains {
  /// List of data types (default + custom)
  final List<DataType> datatype;

  /// Database templates for code generation
  final List<DatabaseTemplate> database;
}
```

### DatabaseTemplate

Configuration for each supported database:

```dart
@JsonSerializable()
class DatabaseTemplate {
  /// Database code (MYSQL, POSTGRESQL, ORACLE, SQLSERVER, SQLITE)
  final String code;

  /// Display name
  final String name;

  /// Whether this is the default database
  final bool defaultDatabase;

  /// SQL templates for DDL generation
  final TemplateConfig template;
}
```

### TemplateConfig

SQL templates for DDL operations:

```dart
@JsonSerializable()
class TemplateConfig {
  final String createTableTemplate;
  final String deleteTableTemplate;
  final String rebuildTableTemplate;
  final String createFieldTemplate;
  final String updateFieldTemplate;
  final String deleteFieldTemplate;
  final String createIndexTemplate;
  final String deleteIndexTemplate;
  final String? entityTemplate;  // Java entity class template
  final String? mapperTemplate;   // MyBatis mapper template
}
```

## State Model

### DataTypeState

Riverpod state class for data type management:

```dart
class DataTypeState {
  /// All data types (default + custom)
  final List<DataType> dataTypes;

  /// Available database templates
  final List<DatabaseTemplate> databaseTemplates;

  /// Whether there are unsaved modifications
  final bool isDirty;

  /// Currently selected type for editing
  final DataType? selectedDataType;

  /// Error message if any
  final String? error;

  // Computed getters:
  List<DataType> get defaultTypes;   // IDs 1-10
  List<DataType> get customTypes;    // IDs not 1-10

  // Methods:
  DataType? getById(String id);
  DataType? getByName(String name);
  bool nameExists(String name, {String? excludeId});
  Map<String, List<String>> findTypeUsage(String typeId, List<Module> modules);
}
```

## Database Codes

Defined in: `lib/shared/constants/default_data_types.dart`

```dart
class DatabaseCodes {
  static const String mysql = 'MYSQL';
  static const String postgresql = 'POSTGRESQL';
  static const String oracle = 'ORACLE';
  static const String sqlServer = 'SQLSERVER';
  static const String sqlite = 'SQLITE';

  static const List<String> all = [...];

  static String getDisplayName(String code);
}
```

## JSON Serialization

All models use `json_annotation` for serialization:

```dart
// Serialization
final json = dataType.toJson();
final domainsJson = dataTypeDomains.toJson();

// Deserialization
final dataType = DataType.fromJson(json);
final domains = DataTypeDomains.fromJson(domainsJson);
```

## Default Data Types

Default data types are identified by numeric IDs 1-10:

```dart
class DefaultDataTypes {
  static List<DataType> getAll();
  static DataType? getById(String id);
  static DataType? getByName(String name);
  static bool isDefaultType(String id);
  static DataTypeDomains createDefaultDomains();
}
```

## Entity Field Type Reference

Entity fields reference data types in two ways:

1. **By ID**: `field.type = "1"` (references DataType.id)
2. **By Name**: `field.type = "IdOrKey"` (references DataType.name)

The `findTypeUsage` method handles both cases when checking usage.