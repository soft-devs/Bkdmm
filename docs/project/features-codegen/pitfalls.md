# Codegen Module - Known Pitfalls

## 1. SQLite ALTER TABLE Limitations

**Problem:** SQLite has limited support for ALTER TABLE operations.

```dart
// codegen_service.dart - SQLite template configuration
updateFieldTemplate:
    '-- SQLite does not support MODIFY COLUMN. Recreate table required.',
deleteFieldTemplate:
    '-- SQLite does not support DROP COLUMN. Recreate table required.',
```

**Impact:**
- `alterTableModifyColumn` generates a comment instead of executable SQL
- `alterTableDropColumn` generates a comment instead of executable SQL

**Workaround:** For SQLite, the recommended approach is:
1. Create a new table with the desired schema
2. Copy data from the old table
3. Drop the old table
4. Rename the new table

**Code Location:** `codegen_service.dart:519-537`

---

## 2. Index DROP Syntax Differences

**Problem:** Different databases use different syntax for DROP INDEX.

```dart
// MySQL
DROP INDEX `indexName` ON `tableName`;

// PostgreSQL / SQLite
DROP INDEX indexName;
```

**Solution:** The service handles this internally:

```dart
// codegen_service.dart:194-196
if (databaseCode == 'SQLITE' || databaseCode == 'POSTGRESQL') {
  template = 'DROP INDEX {{indexName}};';
}
```

---

## 3. MySQL FULLTEXT Index Handling

**Problem:** MySQL FULLTEXT index requires special syntax.

```dart
// Standard index
CREATE INDEX idx_name ON table(column);

// FULLTEXT index
CREATE FULLTEXT INDEX idx_name ON table(column);
```

**Solution:** Post-processing in `generateCreateIndex`:

```dart
// codegen_service.dart:176-178
if (index.type == IndexType.fulltext && databaseCode == 'MYSQL') {
  result = result.replaceFirst('CREATE ', 'CREATE FULLTEXT ');
}
```

**Note:** FULLTEXT is MySQL-specific. Other databases may use different full-text search mechanisms.

---

## 4. Auto-Increment Syntax Variations

**Problem:** Each database has different auto-increment syntax.

| Database   | Syntax                    |
|------------|---------------------------|
| MySQL      | `AUTO_INCREMENT`          |
| PostgreSQL | `SERIAL` or `IDENTITY`    |
| Oracle     | `IDENTITY` (12c+)         |
| SQL Server | `IDENTITY(1,1)`           |
| SQLite     | `AUTOINCREMENT`           |

**Solution:** Template-based approach handles this:

```dart
// MySQL template
{{#autoIncrement}} AUTO_INCREMENT{{/autoIncrement}}

// SQL Server template
{{#autoIncrement}} IDENTITY(1,1){{/autoIncrement}}

// SQLite template
{{#autoIncrement}} AUTOINCREMENT{{/autoIncrement}}
```

---

## 5. Template Mustache Boolean Sections

**Problem:** Mustache boolean sections work differently for null vs false.

```dart
// In template
{{#pk}} PRIMARY KEY{{/pk}}

// This renders if pk is true, doesn't render if pk is false or null
```

**Gotcha:** Ensure boolean fields are properly initialized:

```dart
// Good - explicit false
Field({ ..., this.pk = false });

// Bad - null can cause issues
Field({ ..., this.pk }); // pk could be null
```

---

## 6. Data Type Resolution Fallback

**Problem:** If a data type is not found in the DataType list, the system falls back to constructing the type from field properties.

```dart
// codegen_service.dart:338-354
final dataType = dataTypes.firstWhere(
  (dt) => dt.name.toLowerCase() == field.type.toLowerCase(),
  orElse: () => DataType(
    id: 'custom',
    name: field.type,
    chnname: field.type,
    apply: {},
  ),
);
```

**Impact:**
- Unknown types will use the raw field.type value
- Type length/decimal will be appended: `VARCHAR(255)`, `DECIMAL(10,2)`
- No database-specific mapping will be applied

**Recommendation:** Ensure all data types used in entities are defined in the DataType configuration.

---

## 7. Case Sensitivity in Type Matching

**Problem:** Type matching is case-insensitive, but the original case is preserved.

```dart
// codegen_service.dart:339
(dt) => dt.name.toLowerCase() == field.type.toLowerCase()
```

**Impact:**
- `String`, `STRING`, `string` all match the "String" data type
- The output uses the database mapping, not the input case

---

## 8. Oracle Identifier Length Limits

**Problem:** Oracle has a 30-character limit for identifiers (prior to 12c R2).

**Current State:** The codegen module does not validate or truncate identifier lengths.

**Recommendation:** Add validation for Oracle target:
- Table names <= 30 characters
- Column names <= 30 characters
- Index names <= 30 characters

---

## 9. Index Field Resolution

**Problem:** Index uses `fieldIds` (references) instead of `fieldNames` (values).

```dart
// Index model
final List<String> fieldIds;  // References to Field.id

// Resolution required
List<String> getFieldNames(List<Field> fields) {
  return fieldIds.map((id) {
    final field = fields.where((f) => f.id == id).firstOrNull;
    return field?.name ?? id;  // Falls back to ID if not found
  }).toList();
}
```

**Gotcha:** If a field is deleted but the index still references it, the index generation will use the field ID as the column name.

---

## 10. State Selection Mutually Exclusive

**Problem:** `selectEntity`, `selectModule`, and `selectProject` are mutually exclusive.

```dart
// codegen_provider.dart:106-113
void selectEntity(Entity entity) {
  state = state.copyWith(
    selectedEntity: entity,
    clearModule: true,       // Clears module selection
    generateProject: false,  // Clears project flag
  );
}
```

**Impact:** When selecting an entity, any previous module/project selection is cleared.

---

## 11. No File System Integration

**Problem:** Download functionality is a placeholder.

```dart
// codegen_view.dart:840-844
void _downloadSql() {
  final state = ref.read(codegenProvider);
  final fileName = _getFileName(state);
  TDToast.showText('Ready to download: $fileName', context: context);
}
```

**Current State:** Shows a toast message but does not actually save the file.

**Recommendation:** Integrate with `file_picker` or `file_saver` package for actual file download.

---

## 12. SQL Injection Consideration

**Problem:** The generated DDL directly uses entity/field names without escaping beyond backticks (MySQL) or quotes.

**Current Mitigation:** MySQL templates use backticks:
```dart
CREATE TABLE `{{tableName}}` (
  `{{name}}` {{typeDB}}...
)
```

**Gotcha:** Other databases may require different quoting:
- PostgreSQL: `"tableName"`
- SQL Server: `[tableName]`
- Oracle: `"tableName"` (or no quotes for simple names)

**Recommendation:** Add identifier quoting per database type in the template system.

---

## 13. Generated DDL Not Validated

**Problem:** The generated DDL is not validated against the target database syntax.

**Impact:** Invalid DDL may be generated if:
- Entity names contain special characters
- Data types are incompatible with the target database
- Reserved keywords are used as identifiers

**Recommendation:** Add a DDL validation step or use a SQL parser library.
