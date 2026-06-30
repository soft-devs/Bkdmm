import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/constants/default_data_types.dart';
import 'package:bkdmm/utils/id_generator.dart';

/// Data type management state
class DataTypeState {
  /// All data types (default + custom)
  final List<DataType> dataTypes;

  /// Database templates available
  final List<DatabaseTemplate> databaseTemplates;

  /// Whether data types have been modified
  final bool isDirty;

  /// Selected data type for editing
  final DataType? selectedDataType;

  /// Error message
  final String? error;

  const DataTypeState({
    this.dataTypes = const [],
    this.databaseTemplates = const [],
    this.isDirty = false,
    this.selectedDataType,
    this.error,
  });

  /// Get default data types (IDs 1-10)
  List<DataType> get defaultTypes {
    return dataTypes.where((dt) => DefaultDataTypes.isDefaultType(dt.id)).toList();
  }

  /// Get custom data types (IDs not 1-10)
  List<DataType> get customTypes {
    return dataTypes.where((dt) => !DefaultDataTypes.isDefaultType(dt.id)).toList();
  }

  /// Get data type by ID
  DataType? getById(String id) {
    return dataTypes.where((dt) => dt.id == id).firstOrNull;
  }

  /// Get data type by name
  DataType? getByName(String name) {
    return dataTypes.where((dt) => dt.name == name).firstOrNull;
  }

  /// Check if a data type name already exists
  bool nameExists(String name, {String? excludeId}) {
    return dataTypes.any((dt) =>
        dt.name.toLowerCase() == name.toLowerCase() && dt.id != excludeId);
  }

  /// Check if a data type is used in any field
  Map<String, List<String>> findTypeUsage(String typeId, List<Module> modules) {
    final usage = <String, List<String>>{};

    for (final module in modules) {
      for (final entity in module.entities) {
        final fieldsWithType = entity.fields
            .where((f) => f.type == typeId || f.type == getById(typeId)?.name)
            .map((f) => f.name)
            .toList();

        if (fieldsWithType.isNotEmpty) {
          usage['${module.name}.${entity.title}'] = fieldsWithType;
        }
      }
    }

    return usage;
  }

  DataTypeState copyWith({
    List<DataType>? dataTypes,
    List<DatabaseTemplate>? databaseTemplates,
    bool? isDirty,
    DataType? selectedDataType,
    bool clearSelectedDataType = false,
    String? error,
    bool clearError = false,
  }) {
    return DataTypeState(
      dataTypes: dataTypes ?? this.dataTypes,
      databaseTemplates: databaseTemplates ?? this.databaseTemplates,
      isDirty: isDirty ?? this.isDirty,
      selectedDataType:
          clearSelectedDataType ? null : (selectedDataType ?? this.selectedDataType),
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const DataTypeState empty = DataTypeState();
}

/// Notifier for data type management
class DataTypeNotifier extends StateNotifier<DataTypeState> {
  /// Reference to parent provider for getting modules
  final Ref ref;

  DataTypeNotifier(this.ref) : super(DataTypeState.empty);

  /// Initialize with data types from project
  void initialize(DataTypeDomains domains) {
    state = DataTypeState(
      dataTypes: domains.datatype,
      databaseTemplates: domains.database,
      isDirty: false,
    );
  }

  /// Reset to empty state
  void reset() {
    state = DataTypeState.empty;
  }

  /// Add a new data type
  bool addDataType(DataType dataType) {
    // Check if name already exists
    if (state.nameExists(dataType.name)) {
      state = state.copyWith(error: 'Data type name "${dataType.name}" already exists');
      return false;
    }

    final newDataTypes = [...state.dataTypes, dataType];
    state = state.copyWith(
      dataTypes: newDataTypes,
      isDirty: true,
      clearError: true,
    );
    return true;
  }

  /// Update an existing data type
  bool updateDataType(String id, DataType updated) {
    // Check if name already exists (excluding current)
    if (state.nameExists(updated.name, excludeId: id)) {
      state = state.copyWith(error: 'Data type name "${updated.name}" already exists');
      return false;
    }

    final newDataTypes = state.dataTypes.map((dt) {
      return dt.id == id ? updated : dt;
    }).toList();

    state = state.copyWith(
      dataTypes: newDataTypes,
      isDirty: true,
      clearError: true,
    );
    return true;
  }

  /// Delete a data type
  /// Returns map of usage if type is in use, null if deleted successfully
  Map<String, List<String>>? deleteDataType(String id, List<Module> modules) {
    // Check if it's a default type
    if (DefaultDataTypes.isDefaultType(id)) {
      state = state.copyWith(error: 'Cannot delete default data types');
      return {};
    }

    // Check for usage
    final usage = state.findTypeUsage(id, modules);
    if (usage.isNotEmpty) {
      return usage;
    }

    // Delete the type
    final newDataTypes = state.dataTypes.where((dt) => dt.id != id).toList();
    state = state.copyWith(
      dataTypes: newDataTypes,
      isDirty: true,
      clearError: true,
    );
    return null;
  }

  /// Force delete a data type (ignoring usage)
  void forceDeleteDataType(String id) {
    final newDataTypes = state.dataTypes.where((dt) => dt.id != id).toList();
    state = state.copyWith(
      dataTypes: newDataTypes,
      isDirty: true,
      clearError: true,
    );
  }

  /// Restore default data types
  void restoreDefaults() {
    // Keep custom types, restore defaults
    final customTypes = state.customTypes;
    final defaultTypes = DefaultDataTypes.getAll();

    state = state.copyWith(
      dataTypes: [...defaultTypes, ...customTypes],
      isDirty: true,
      clearError: true,
    );
  }

  /// Restore a single default data type
  void restoreDefaultType(String id) {
    final defaultType = DefaultDataTypes.getById(id);
    if (defaultType == null) return;

    // Check if exists, update it, otherwise add
    final exists = state.dataTypes.any((dt) => dt.id == id);
    List<DataType> newDataTypes;

    if (exists) {
      newDataTypes = state.dataTypes.map((dt) {
        return dt.id == id ? defaultType : dt;
      }).toList();
    } else {
      newDataTypes = [...state.dataTypes, defaultType];
    }

    state = state.copyWith(
      dataTypes: newDataTypes,
      isDirty: true,
      clearError: true,
    );
  }

  /// Set selected data type
  void selectDataType(DataType? dataType) {
    state = state.copyWith(selectedDataType: dataType);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Mark as clean (no unsaved changes)
  void markClean() {
    state = state.copyWith(isDirty: false);
  }

  /// Get updated DataTypeDomains
  DataTypeDomains toDataTypeDomains() {
    return DataTypeDomains(
      datatype: state.dataTypes,
      database: state.databaseTemplates,
    );
  }

  /// Create a new data type with generated ID
  DataType createNewDataType({
    required String name,
    required String chnname,
    String? remark,
    Map<String, String>? apply,
    String? java,
  }) {
    return DataType(
      id: IdGenerator.generate(),
      name: name,
      chnname: chnname,
      remark: remark,
      apply: apply ?? {},
      java: java,
    );
  }

  /// Duplicate a data type
  bool duplicateDataType(String id) {
    final original = state.getById(id);
    if (original == null) {
      state = state.copyWith(error: 'Data type not found');
      return false;
    }

    // Generate unique name
    String newName = '${original.name}_copy';
    int counter = 1;
    while (state.nameExists(newName)) {
      newName = '${original.name}_copy$counter';
      counter++;
    }

    final duplicate = DataType(
      id: IdGenerator.generate(),
      name: newName,
      chnname: '${original.chnname} (副本)',
      remark: original.remark,
      apply: Map.from(original.apply),
      java: original.java,
    );

    return addDataType(duplicate);
  }
}

/// Provider for data type management
final dataTypeNotifierProvider =
    StateNotifierProvider<DataTypeNotifier, DataTypeState>((ref) {
  return DataTypeNotifier(ref);
});

/// Convenience provider for data types list
final dataTypesProvider = Provider<List<DataType>>((ref) {
  return ref.watch(dataTypeNotifierProvider).dataTypes;
});

/// Convenience provider for default data types
final defaultDataTypesProvider = Provider<List<DataType>>((ref) {
  return ref.watch(dataTypeNotifierProvider).defaultTypes;
});

/// Convenience provider for custom data types
final customDataTypesProvider = Provider<List<DataType>>((ref) {
  return ref.watch(dataTypeNotifierProvider).customTypes;
});

/// Convenience provider for checking if data types are dirty
final isDataTypeDirtyProvider = Provider<bool>((ref) {
  return ref.watch(dataTypeNotifierProvider).isDirty;
});

/// Convenience provider for selected data type
final selectedDataTypeProvider = Provider<DataType?>((ref) {
  return ref.watch(dataTypeNotifierProvider).selectedDataType;
});
