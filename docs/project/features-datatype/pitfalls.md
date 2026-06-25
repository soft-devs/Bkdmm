# Known Pitfalls

## 1. Default Type Protection

**Issue**: Default data types (IDs 1-10) cannot be deleted.

**Behavior**: The `deleteDataType` method checks if the type is a default type and returns an empty map with an error message.

```dart
if (DefaultDataTypes.isDefaultType(id)) {
  state = state.copyWith(error: 'Cannot delete default data types');
  return {};
}
```

**Solution**: If you need to remove a default type from a project, consider hiding it in the UI instead of deleting.

## 2. Name Uniqueness

**Issue**: Data type names must be unique (case-insensitive).

**Behavior**: Adding or updating a type with an existing name will fail silently (returns `false`).

```dart
// This check is case-insensitive
bool nameExists(String name, {String? excludeId}) {
  return dataTypes.any((dt) =>
      dt.name.toLowerCase() == name.toLowerCase() && dt.id != excludeId);
}
```

**Solution**: Always check the return value of `addDataType` and `updateDataType`, and handle `state.error` appropriately.

## 3. Type In Use Check

**Issue**: Deleting a type that is in use returns a usage map instead of deleting.

**Behavior**: `deleteDataType` returns a `Map<String, List<String>>` where keys are "ModuleName.EntityName" and values are field names.

```dart
final usage = ref.read(dataTypeNotifierProvider.notifier)
    .deleteDataType(typeId, modules);

if (usage != null && usage.isNotEmpty) {
  // Type is in use - show warning dialog
} else if (usage == null) {
  // Successfully deleted
}
```

**Solution**: Always handle the usage map case by showing a confirmation dialog and optionally calling `forceDeleteDataType`.

## 4. Project Sync Required

**Issue**: Changes to data types are not automatically persisted to the project.

**Behavior**: The `DataTypeNotifier` manages its own state, but project updates require explicit sync.

```dart
// After any data type change:
void _updateProject() {
  final domains = ref.read(dataTypeNotifierProvider.notifier).toDataTypeDomains();
  final updated = project.copyWith(
    dataTypeDomains: domains,
    updatedAt: DateTime.now(),
  );
  ref.read(projectProvider.notifier).updateProject(updated);
}
```

**Solution**: Always call `_updateProject()` after successful CRUD operations. Dialog functions receive an `onUpdate` callback for this purpose.

## 5. ID Generation for Custom Types

**Issue**: Custom types require unique string IDs, but the system doesn't enforce a specific format.

**Behavior**: `createNewDataType` uses `IdGenerator.generate()` for new types.

```dart
DataType createNewDataType({...}) {
  return DataType(
    id: IdGenerator.generate(),  // Generates a unique string ID
    ...
  );
}
```

**Pitfall**: If you manually create DataType objects without using `createNewDataType`, ensure IDs are unique and not in the 1-10 range (reserved for defaults).

## 6. Default Type Name Edit Lock

**Issue**: Default types have read-only names in the edit dialog.

**Behavior**: The `DataTypeEditDialog` sets `readOnly: _isDefaultType` for the name field.

```dart
TDInput(
  controller: _nameController,
  leftLabel: 'Type Name (English)',
  readOnly: _isDefaultType,  // Default types can't rename
  ...
)
```

**Reason**: Default types are referenced by name in many places. Changing names could break existing entity fields.

## 7. Dual Type Reference (ID vs Name)

**Issue**: Entity fields can reference types by either ID or name.

**Behavior**: The `findTypeUsage` method checks both:

```dart
final fieldsWithType = entity.fields
    .where((f) => f.type == typeId || f.type == getById(typeId)?.name)
    ...
```

**Pitfall**: When renaming a custom type, existing fields using the old name won't be updated automatically. They may become orphaned.

## 8. Database Mappings Display

**Issue**: Not all databases may have mappings defined for a type.

**Behavior**: The `DataTypeMappings` widget shows "-" for unmapped databases.

```dart
Text(
  dbType ?? '-',  // Shows dash if no mapping
  ...
)
```

**Solution**: When creating custom types, provide mappings for all supported databases to avoid confusion.

## 9. State Reset on Project Change

**Issue**: The DataTypeNotifier doesn't automatically reset when switching projects.

**Behavior**: You must explicitly call `initialize()` with the new project's data types.

```dart
void _initializeFromProject() {
  final project = ref.read(currentProjectProvider);
  if (project != null) {
    ref.read(dataTypeNotifierProvider.notifier).initialize(project.dataTypeDomains);
  }
}
```

**Solution**: Listen to project changes and re-initialize the data types accordingly.

## 10. isDirty Flag Management

**Issue**: The `isDirty` flag must be manually cleared after saving.

**Behavior**: Changes set `isDirty = true`, but it stays true until explicitly cleared.

```dart
void markClean() {
  state = state.copyWith(isDirty: false);
}
```

**Solution**: Call `markClean()` after successfully persisting changes (e.g., after project save).

## Best Practices

1. **Always use dialog functions**: They handle validation and project sync
2. **Check return values**: CRUD methods return boolean success indicators
3. **Handle usage warnings**: Provide user feedback when types are in use
4. **Use convenience providers**: Prefer `dataTypesProvider` over accessing state directly
5. **Test with both ID and name references**: Ensure field type references work both ways
