import 'package:mustache_template/mustache_template.dart';
import '../../../shared/models/models.dart';

/// Template service for rendering DDL and code templates using Mustache
class TemplateService {
  /// Render a mustache template with the given data
  String render(String template, Map<String, dynamic> data) {
    final mustache = Template(template, htmlEscapeValues: false);
    return mustache.renderString(data);
  }

  /// Build template data for entity DDL generation
  Map<String, dynamic> buildEntityData(
    Entity entity, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final fields = entity.fields.map((field) {
      return _buildFieldData(field, databaseCode, dataTypes);
    }).toList();

    final primaryKeys = entity.fields.where((f) => f.pk).map((f) => f.name).toList();

    // Build indexes data
    final indexes = entity.indexes.map((index) {
      return {
        'name': index.name,
        'fields': index.getFieldNames(entity.fields).join(', '),
        'isUnique': index.type == IndexType.unique,
        'isFulltext': index.type == IndexType.fulltext,
        'isNormal': index.type == IndexType.normal,
      };
    }).toList();

    return {
      'entity': {
        'title': entity.title,
        'chnname': entity.chnname,
        'remark': entity.remark ?? '',
      },
      'tableName': entity.title,
      'tableComment': entity.chnname,
      'fields': fields,
      'primaryKeys': primaryKeys,
      'hasPrimaryKey': primaryKeys.isNotEmpty,
      'primaryKeyFields': primaryKeys.join(', '),
      'indexes': indexes,
      'hasIndexes': indexes.isNotEmpty,
      'databaseCode': databaseCode,
    };
  }

  /// Build field data for template rendering
  Map<String, dynamic> _buildFieldData(
    Field field,
    String databaseCode,
    List<DataType> dataTypes,
  ) {
    final dbType = _getDatabaseType(field, databaseCode, dataTypes);

    return {
      'id': field.id,
      'name': field.name,
      'type': field.type,
      'typeDB': dbType,
      'chnname': field.chnname,
      'remark': field.remark ?? '',
      'pk': field.pk,
      'notNull': field.notNull,
      'autoIncrement': field.autoIncrement,
      'defaultValue': field.defaultValue,
      'hasDefaultValue': field.defaultValue != null && field.defaultValue!.isNotEmpty,
      'length': field.length,
      'decimal': field.decimal,
      // CamelCase conversions
      'camelName': _toCamelCase(field.name),
      'pascalName': _toPascalCase(field.name),
      'snakeName': _toSnakeCase(field.name),
    };
  }

  /// Get database-specific type for a field
  String _getDatabaseType(
    Field field,
    String databaseCode,
    List<DataType> dataTypes,
  ) {
    // Find matching data type
    final dataType = dataTypes.firstWhere(
      (dt) => dt.name.toLowerCase() == field.type.toLowerCase(),
      orElse: () => DataType(
        id: 'custom',
        name: field.type,
        chnname: field.type,
        apply: {},
      ),
    );

    // Get database-specific type from mapping
    final dbType = dataType.getDatabaseType(databaseCode);
    if (dbType != null && dbType.isNotEmpty) {
      return dbType;
    }

    // Fallback: construct type based on length/decimal
    return _constructType(field);
  }

  /// Construct type from field properties when no mapping exists
  String _constructType(Field field) {
    final baseType = field.type.toUpperCase();

    if (field.length != null) {
      if (field.decimal != null) {
        return '$baseType(${field.length}, ${field.decimal})';
      }
      return '$baseType(${field.length})';
    }

    return baseType;
  }

  /// Convert string to camelCase
  String _toCamelCase(String input) {
    if (input.isEmpty) return input;

    final parts = input.split(RegExp(r'[_\s]+'));
    if (parts.isEmpty) return input;

    final result = StringBuffer(parts.first.toLowerCase());
    for (var i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        result.write(parts[i][0].toUpperCase());
        if (parts[i].length > 1) {
          result.write(parts[i].substring(1).toLowerCase());
        }
      }
    }

    return result.toString();
  }

  /// Convert string to PascalCase
  String _toPascalCase(String input) {
    if (input.isEmpty) return input;

    final parts = input.split(RegExp(r'[_\s]+'));
    final result = StringBuffer();

    for (final part in parts) {
      if (part.isNotEmpty) {
        result.write(part[0].toUpperCase());
        if (part.length > 1) {
          result.write(part.substring(1).toLowerCase());
        }
      }
    }

    return result.toString();
  }

  /// Convert string to snake_case
  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;

    final result = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        if (i > 0) result.write('_');
        result.write(char.toLowerCase());
      } else {
        result.write(char);
      }
    }

    return result.toString();
  }
}