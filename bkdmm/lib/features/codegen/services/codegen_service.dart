import '../../../shared/models/models.dart';
import 'template_service.dart';

/// Supported database types
enum DatabaseType {
  mysql('MYSQL', 'MySQL'),
  postgresql('POSTGRESQL', 'PostgreSQL'),
  oracle('ORACLE', 'Oracle'),
  sqlserver('SQLSERVER', 'SQL Server'),
  sqlite('SQLITE', 'SQLite');

  final String code;
  final String displayName;

  const DatabaseType(this.code, this.displayName);
}

/// DDL generation type
enum DdlType {
  createTable,
  dropTable,
  alterTableAddColumn,
  alterTableDropColumn,
  alterTableModifyColumn,
  createIndex,
  dropIndex,
}

/// Code generation service for DDL and code templates
class CodegenService {
  final TemplateService _templateService;

  CodegenService({TemplateService? templateService})
      : _templateService = templateService ?? TemplateService();

  /// Get default database templates
  List<DatabaseTemplate> getDefaultDatabases() {
    return [
      _createMySqlTemplate(),
      _createPostgreSqlTemplate(),
      _createOracleTemplate(),
      _createSqlServerTemplate(),
      _createSqliteTemplate(),
    ];
  }

  /// Generate CREATE TABLE DDL
  String generateCreateTable(
    Entity entity, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.createTableTemplate ??
        _getDefaultCreateTemplate(databaseCode);

    final data = _templateService.buildEntityData(
      entity,
      databaseCode: databaseCode,
      dataTypes: dataTypes,
      dbTemplate: dbTemplate,
    );

    return _templateService.render(template, data);
  }

  /// Generate DROP TABLE DDL
  String generateDropTable(
    Entity entity, {
    required String databaseCode,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.deleteTableTemplate ??
        'DROP TABLE IF EXISTS {{tableName}};';

    final data = {
      'tableName': entity.title,
      'entity': {
        'title': entity.title,
        'chnname': entity.chnname,
      },
    };

    return _templateService.render(template, data);
  }

  /// Generate ALTER TABLE DDL for adding a column
  String generateAlterTableAddColumn(
    Entity entity,
    Field field, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.createFieldTemplate ??
        'ALTER TABLE {{tableName}} ADD COLUMN {{field.name}} {{field.typeDB}};';

    final data = _templateService.buildEntityData(
      entity,
      databaseCode: databaseCode,
      dataTypes: dataTypes,
    );

    // Add field data at root level for simple template access
    data['field'] = _buildFieldData(field, databaseCode, dataTypes);

    return _templateService.render(template, data);
  }

  /// Generate ALTER TABLE DDL for modifying a column
  String generateAlterTableModifyColumn(
    Entity entity,
    Field field, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.updateFieldTemplate ??
        'ALTER TABLE {{tableName}} MODIFY COLUMN {{field.name}} {{field.typeDB}};';

    final data = _templateService.buildEntityData(
      entity,
      databaseCode: databaseCode,
      dataTypes: dataTypes,
    );

    data['field'] = _buildFieldData(field, databaseCode, dataTypes);

    return _templateService.render(template, data);
  }

  /// Generate ALTER TABLE DDL for dropping a column
  String generateAlterTableDropColumn(
    Entity entity,
    String fieldName, {
    required String databaseCode,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.deleteFieldTemplate ??
        'ALTER TABLE {{tableName}} DROP COLUMN {{fieldName}};';

    final data = {
      'tableName': entity.title,
      'fieldName': fieldName,
      'entity': {
        'title': entity.title,
        'chnname': entity.chnname,
      },
    };

    return _templateService.render(template, data);
  }

  /// Generate CREATE INDEX DDL
  String generateCreateIndex(
    Entity entity,
    Index index, {
    required String databaseCode,
    DatabaseTemplate? dbTemplate,
  }) {
    final template = dbTemplate?.template.createIndexTemplate ??
        'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX {{indexName}} ON {{tableName}}({{fields}});';

    final data = {
      'tableName': entity.title,
      'indexName': index.name,
      'fields': index.fields.join(', '),
      'isUnique': index.type == IndexType.unique,
      'isFulltext': index.type == IndexType.fulltext,
      'isNormal': index.type == IndexType.normal,
    };

    var result = _templateService.render(template, data);

    // Handle MySQL FULLTEXT index
    if (index.type == IndexType.fulltext && databaseCode == 'MYSQL') {
      result = result.replaceFirst('CREATE ', 'CREATE FULLTEXT ');
    }

    return result;
  }

  /// Generate DROP INDEX DDL
  String generateDropIndex(
    Entity entity,
    Index index, {
    required String databaseCode,
    DatabaseTemplate? dbTemplate,
  }) {
    var template = dbTemplate?.template.deleteIndexTemplate ??
        'DROP INDEX {{indexName}} ON {{tableName}};';

    // SQLite and PostgreSQL use different syntax
    if (databaseCode == 'SQLITE' || databaseCode == 'POSTGRESQL') {
      template = 'DROP INDEX {{indexName}};';
    }

    final data = {
      'tableName': entity.title,
      'indexName': index.name,
    };

    return _templateService.render(template, data);
  }

  /// Generate all DDL for an entity
  String generateAllDdl(
    Entity entity, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final buffer = StringBuffer();

    // DROP TABLE if exists
    buffer.writeln('-- Drop table if exists');
    buffer.writeln(generateDropTable(
      entity,
      databaseCode: databaseCode,
      dbTemplate: dbTemplate,
    ));
    buffer.writeln();

    // CREATE TABLE
    buffer.writeln('-- Create table: ${entity.chnname}');
    buffer.writeln(generateCreateTable(
      entity,
      databaseCode: databaseCode,
      dataTypes: dataTypes,
      dbTemplate: dbTemplate,
    ));

    // Indexes
    if (entity.indexes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('-- Indexes');

      for (final index in entity.indexes) {
        buffer.writeln(generateCreateIndex(
          entity,
          index,
          databaseCode: databaseCode,
          dbTemplate: dbTemplate,
        ));
      }
    }

    return buffer.toString();
  }

  /// Generate DDL for all entities in a module
  String generateModuleDdl(
    Module module, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('-- ========================================');
    buffer.writeln('-- Module: ${module.chnname} (${module.name})');
    buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('-- ========================================');
    buffer.writeln();

    for (final entity in module.entities) {
      buffer.writeln(generateAllDdl(
        entity,
        databaseCode: databaseCode,
        dataTypes: dataTypes,
        dbTemplate: dbTemplate,
      ));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate DDL for all entities in a project
  String generateProjectDdl(
    Project project, {
    required String databaseCode,
    required List<DataType> dataTypes,
    DatabaseTemplate? dbTemplate,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('-- ========================================');
    buffer.writeln('-- Project: ${project.name}');
    buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('-- Database: $databaseCode');
    buffer.writeln('-- ========================================');
    buffer.writeln();

    for (final module in project.modules) {
      buffer.writeln(generateModuleDdl(
        module,
        databaseCode: databaseCode,
        dataTypes: dataTypes,
        dbTemplate: dbTemplate,
      ));
    }

    return buffer.toString();
  }

  /// Build field data for template
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
      'hasDefaultValue': field.defaultValue != null,
      'length': field.length,
      'decimal': field.decimal,
    };
  }

  /// Get database-specific type
  String _getDatabaseType(
    Field field,
    String databaseCode,
    List<DataType> dataTypes,
  ) {
    final dataType = dataTypes.firstWhere(
      (dt) => dt.name.toLowerCase() == field.type.toLowerCase(),
      orElse: () => DataType(
        id: 'custom',
        name: field.type,
        chnname: field.type,
        apply: {},
      ),
    );

    final dbType = dataType.getDatabaseType(databaseCode);
    if (dbType != null && dbType.isNotEmpty) {
      return dbType;
    }

    return _constructType(field);
  }

  /// Construct type from field properties
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

  /// Get default CREATE TABLE template for a database
  String _getDefaultCreateTemplate(String databaseCode) {
    switch (databaseCode) {
      case 'MYSQL':
        return _mysqlCreateTableTemplate;
      case 'POSTGRESQL':
        return _postgresqlCreateTableTemplate;
      case 'ORACLE':
        return _oracleCreateTableTemplate;
      case 'SQLSERVER':
        return _sqlServerCreateTableTemplate;
      case 'SQLITE':
        return _sqliteCreateTableTemplate;
      default:
        return _mysqlCreateTableTemplate;
    }
  }

  // MySQL template
  static const _mysqlCreateTableTemplate = '''CREATE TABLE `{{tableName}}` (
{{#fields}}
  `{{name}}` {{typeDB}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} AUTO_INCREMENT{{/autoIncrement}}{{#hasDefaultValue}} DEFAULT {{defaultValue}}{{/hasDefaultValue}}{{#remark}} COMMENT '{{remark}}'{{/remark}},
{{/fields}}
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='{{tableComment}}';''';

  // PostgreSQL template
  static const _postgresqlCreateTableTemplate = '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{typeDB}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#hasDefaultValue}} DEFAULT {{defaultValue}}{{/hasDefaultValue}},
{{/fields}}
);
COMMENT ON TABLE {{tableName}} IS '{{tableComment}}';''';

  // Oracle template
  static const _oracleCreateTableTemplate = '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{typeDB}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#hasDefaultValue}} DEFAULT {{defaultValue}}{{/hasDefaultValue}},
{{/fields}}
);
COMMENT ON TABLE {{tableName}} IS '{{tableComment}}';''';

  // SQL Server template
  static const _sqlServerCreateTableTemplate = '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{typeDB}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} IDENTITY(1,1){{/autoIncrement}}{{#hasDefaultValue}} DEFAULT {{defaultValue}}{{/hasDefaultValue}},
{{/fields}}
);
-- Table: {{tableComment}}''';

  // SQLite template
  static const _sqliteCreateTableTemplate = '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{typeDB}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} AUTOINCREMENT{{/autoIncrement}}{{#hasDefaultValue}} DEFAULT {{defaultValue}}{{/hasDefaultValue}},
{{/fields}}
);''';

  /// Create MySQL database template
  DatabaseTemplate _createMySqlTemplate() {
    return DatabaseTemplate(
      code: 'MYSQL',
      name: 'MySQL',
      defaultDatabase: true,
      template: TemplateConfig(
        createTableTemplate: _mysqlCreateTableTemplate,
        deleteTableTemplate: 'DROP TABLE IF EXISTS `{{tableName}}`;',
        rebuildTableTemplate: '',
        createFieldTemplate:
            'ALTER TABLE `{{tableName}}` ADD COLUMN `{{field.name}}` {{field.typeDB}};',
        updateFieldTemplate:
            'ALTER TABLE `{{tableName}}` MODIFY COLUMN `{{field.name}}` {{field.typeDB}};',
        deleteFieldTemplate:
            'ALTER TABLE `{{tableName}}` DROP COLUMN `{{field.name}}`;',
        createIndexTemplate:
            'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX `{{indexName}}` ON `{{tableName}}`({{fields}});',
        deleteIndexTemplate: 'DROP INDEX `{{indexName}}` ON `{{tableName}}`;',
      ),
    );
  }

  /// Create PostgreSQL database template
  DatabaseTemplate _createPostgreSqlTemplate() {
    return DatabaseTemplate(
      code: 'POSTGRESQL',
      name: 'PostgreSQL',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: _postgresqlCreateTableTemplate,
        deleteTableTemplate: 'DROP TABLE IF EXISTS {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate:
            'ALTER TABLE {{tableName}} ADD COLUMN {{field.name}} {{field.typeDB}};',
        updateFieldTemplate:
            'ALTER TABLE {{tableName}} ALTER COLUMN {{field.name}} TYPE {{field.typeDB}};',
        deleteFieldTemplate:
            'ALTER TABLE {{tableName}} DROP COLUMN {{field.name}};',
        createIndexTemplate:
            'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}};',
      ),
    );
  }

  /// Create Oracle database template
  DatabaseTemplate _createOracleTemplate() {
    return DatabaseTemplate(
      code: 'ORACLE',
      name: 'Oracle',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: _oracleCreateTableTemplate,
        deleteTableTemplate: 'DROP TABLE {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate:
            'ALTER TABLE {{tableName}} ADD {{field.name}} {{field.typeDB}};',
        updateFieldTemplate:
            'ALTER TABLE {{tableName}} MODIFY {{field.name}} {{field.typeDB}};',
        deleteFieldTemplate:
            'ALTER TABLE {{tableName}} DROP COLUMN {{field.name}};',
        createIndexTemplate:
            'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}};',
      ),
    );
  }

  /// Create SQL Server database template
  DatabaseTemplate _createSqlServerTemplate() {
    return DatabaseTemplate(
      code: 'SQLSERVER',
      name: 'SQL Server',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: _sqlServerCreateTableTemplate,
        deleteTableTemplate: 'DROP TABLE {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate:
            'ALTER TABLE {{tableName}} ADD {{field.name}} {{field.typeDB}};',
        updateFieldTemplate:
            'ALTER TABLE {{tableName}} ALTER COLUMN {{field.name}} {{field.typeDB}};',
        deleteFieldTemplate:
            'ALTER TABLE {{tableName}} DROP COLUMN {{field.name}};',
        createIndexTemplate:
            'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}} ON {{tableName}};',
      ),
    );
  }

  /// Create SQLite database template
  DatabaseTemplate _createSqliteTemplate() {
    return DatabaseTemplate(
      code: 'SQLITE',
      name: 'SQLite',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: _sqliteCreateTableTemplate,
        deleteTableTemplate: 'DROP TABLE IF EXISTS {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate:
            'ALTER TABLE {{tableName}} ADD COLUMN {{field.name}} {{field.typeDB}};',
        updateFieldTemplate:
            '-- SQLite does not support MODIFY COLUMN. Recreate table required.',
        deleteFieldTemplate:
            '-- SQLite does not support DROP COLUMN. Recreate table required.',
        createIndexTemplate:
            'CREATE {{#isUnique}}UNIQUE{{/isUnique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}};',
      ),
    );
  }
}