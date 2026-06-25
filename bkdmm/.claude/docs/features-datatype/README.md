# DataType Module

## Overview

The DataType module provides data type management functionality for the Bkdmm application. It enables users to manage custom data types and their mappings to various database systems. This is essential for database design and code generation features.

## Module Structure

```
lib/features/datatype/
├── datatype.dart                    # Module entry point (exports)
├── providers/
│   └── datatype_provider.dart       # State management (Riverpod)
├── views/
│   ├── datatype_view.dart           # Main data type list view
│   └── datatype_edit_dialog.dart    # Add/Edit dialog
├── dialogs/
│   └── datatype_dialogs.dart        # Dialog functions (add, edit, delete, restore)
├── widgets/
│   └── datatype_type_card.dart      # DataType card widget with mappings display
└── utils/
    └── datatype_utils.dart          # Utility functions (icon mapping)
```

## Dependencies

- **flutter_riverpod**: State management
- **tdesign_flutter**: UI component library
- **shared/models**: DataType, DataTypeDomains, DatabaseTemplate models
- **shared/constants/default_data_types**: Default data type definitions
- **shared/providers**: currentProjectProvider, projectProvider

## Public API

### Main Entry Point

```dart
import 'package:bkdmm/features/datatype/datatype.dart';
```

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `dataTypeNotifierProvider` | `StateNotifierProvider<DataTypeNotifier, DataTypeState>` | Main state notifier |
| `dataTypesProvider` | `Provider<List<DataType>>` | All data types list |
| `defaultDataTypesProvider` | `Provider<List<DataType>>` | Default types (IDs 1-10) |
| `customDataTypesProvider` | `Provider<List<DataType>>` | Custom types (non-default) |
| `isDataTypeDirtyProvider` | `Provider<bool>` | Has unsaved changes |
| `selectedDataTypeProvider` | `Provider<DataType?>` | Currently selected type |

### Views

| Widget | Description |
|--------|-------------|
| `DataTypeView` | Main view for data type management |
| `DataTypeEditDialog` | Dialog for adding/editing data types |

### Dialog Functions

```dart
// Show add data type dialog
void showAddDataTypeDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate)

// Show edit data type dialog
void showEditDataTypeDialog(BuildContext context, WidgetRef ref, DataType type, VoidCallback onUpdate)

// Show delete confirmation dialog
void showDeleteDataTypeDialog(BuildContext context, WidgetRef ref, DataType type, List<Module> modules, VoidCallback onUpdate)

// Show restore defaults dialog
void showRestoreDefaultsDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate)
```

### Notifier Methods (DataTypeNotifier)

```dart
// Initialize with project data
void initialize(DataTypeDomains domains)

// Reset to empty state
void reset()

// CRUD operations
bool addDataType(DataType dataType)
bool updateDataType(String id, DataType updated)
Map<String, List<String>>? deleteDataType(String id, List<Module> modules)
void forceDeleteDataType(String id)

// Duplicate a type
bool duplicateDataType(String id)

// Restore defaults
void restoreDefaults()
void restoreDefaultType(String id)

// State management
void selectDataType(DataType? dataType)
void clearError()
void markClean()

// Utility
DataType createNewDataType({...})
DataTypeDomains toDataTypeDomains()
```

## Core Features

### 1. Data Type Management

- **View Types**: Display all data types with search and filter capabilities
- **Default vs Custom**: Separate display of default (IDs 1-10) and custom types
- **CRUD Operations**: Add, edit, duplicate, and delete custom types
- **Name Validation**: Prevents duplicate type names

### 2. Database Type Mapping

Each DataType contains mappings for multiple databases:
- MySQL
- PostgreSQL
- Oracle
- SQL Server
- SQLite

Plus optional Java type mapping for code generation.

### 3. Usage Tracking

Before deletion, the system checks if a data type is used in any entity fields across all modules and warns the user.

### 4. Default Types Restoration

Users can restore all default types to their original values without affecting custom types.

## Default Data Types (IDs 1-10)

| ID | Name | Chinese Name | MySQL Type | Java Type |
|----|------|--------------|------------|-----------|
| 1 | IdOrKey | 标识键 | VARCHAR(32) | String |
| 2 | Name | 名称 | VARCHAR(128) | String |
| 3 | Intro | 简介 | VARCHAR(512) | String |
| 4 | LongText | 长文本 | TEXT | String |
| 5 | Integer | 整数 | INT | Integer |
| 6 | Long | 长整数 | BIGINT | Long |
| 7 | Money | 金额 | DECIMAL(32,8) | BigDecimal |
| 8 | DateTime | 日期时间 | DATETIME | LocalDateTime |
| 9 | YesNo | 是否 | VARCHAR(1) | String |
| 10 | Dict | 字典 | VARCHAR(32) | String |

## Integration with Project

The DataType module integrates with the project through:

1. **Initialization**: Loads data types from `project.dataTypeDomains`
2. **Updates**: Changes are persisted via `projectProvider.updateProject()`
3. **Entity Fields**: Field types reference DataType by ID or name

## Usage Example

```dart
// In a consumer widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all data types
    final types = ref.watch(dataTypesProvider);

    // Check for unsaved changes
    final isDirty = ref.watch(isDataTypeDirtyProvider);

    // Get notifier for mutations
    final notifier = ref.read(dataTypeNotifierProvider.notifier);

    return DataTypeView();
  }
}
```
