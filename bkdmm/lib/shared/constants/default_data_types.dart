import '../models/data_type.dart';

/// Database codes for type mapping
class DatabaseCodes {
  static const String mysql = 'MYSQL';
  static const String postgresql = 'POSTGRESQL';
  static const String oracle = 'ORACLE';
  static const String sqlServer = 'SQLSERVER';
  static const String sqlite = 'SQLITE';

  static const List<String> all = [
    mysql,
    postgresql,
    oracle,
    sqlServer,
    sqlite,
  ];

  static String getDisplayName(String code) {
    switch (code) {
      case mysql:
        return 'MySQL';
      case postgresql:
        return 'PostgreSQL';
      case oracle:
        return 'Oracle';
      case sqlServer:
        return 'SQL Server';
      case sqlite:
        return 'SQLite';
      default:
        return code;
    }
  }
}

/// Default data types for Bkdmm
class DefaultDataTypes {
  /// Get all default data types
  static List<DataType> getAll() {
    return [
      DataType(
        id: '1',
        name: 'IdOrKey',
        chnname: '标识键',
        remark: 'Unique identifier or key field',
        apply: {
          DatabaseCodes.mysql: 'VARCHAR(32)',
          DatabaseCodes.postgresql: 'VARCHAR(32)',
          DatabaseCodes.oracle: 'VARCHAR2(32)',
          DatabaseCodes.sqlServer: 'NVARCHAR(32)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
      DataType(
        id: '2',
        name: 'Name',
        chnname: '名称',
        remark: 'Name field, typically up to 128 characters',
        apply: {
          DatabaseCodes.mysql: 'VARCHAR(128)',
          DatabaseCodes.postgresql: 'VARCHAR(128)',
          DatabaseCodes.oracle: 'VARCHAR2(128)',
          DatabaseCodes.sqlServer: 'NVARCHAR(128)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
      DataType(
        id: '3',
        name: 'Intro',
        chnname: '简介',
        remark: 'Introduction or brief description, up to 512 characters',
        apply: {
          DatabaseCodes.mysql: 'VARCHAR(512)',
          DatabaseCodes.postgresql: 'VARCHAR(512)',
          DatabaseCodes.oracle: 'VARCHAR2(512)',
          DatabaseCodes.sqlServer: 'NVARCHAR(512)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
      DataType(
        id: '4',
        name: 'LongText',
        chnname: '长文本',
        remark: 'Long text content, unlimited length',
        apply: {
          DatabaseCodes.mysql: 'TEXT',
          DatabaseCodes.postgresql: 'TEXT',
          DatabaseCodes.oracle: 'CLOB',
          DatabaseCodes.sqlServer: 'NVARCHAR(MAX)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
      DataType(
        id: '5',
        name: 'Integer',
        chnname: '整数',
        remark: 'Integer number, 32-bit',
        apply: {
          DatabaseCodes.mysql: 'INT',
          DatabaseCodes.postgresql: 'INTEGER',
          DatabaseCodes.oracle: 'NUMBER(10)',
          DatabaseCodes.sqlServer: 'INT',
          DatabaseCodes.sqlite: 'INTEGER',
        },
        java: 'Integer',
      ),
      DataType(
        id: '6',
        name: 'Long',
        chnname: '长整数',
        remark: 'Long integer, 64-bit',
        apply: {
          DatabaseCodes.mysql: 'BIGINT',
          DatabaseCodes.postgresql: 'BIGINT',
          DatabaseCodes.oracle: 'NUMBER(19)',
          DatabaseCodes.sqlServer: 'BIGINT',
          DatabaseCodes.sqlite: 'INTEGER',
        },
        java: 'Long',
      ),
      DataType(
        id: '7',
        name: 'Money',
        chnname: '金额',
        remark: 'Monetary value with high precision',
        apply: {
          DatabaseCodes.mysql: 'DECIMAL(32,8)',
          DatabaseCodes.postgresql: 'DECIMAL(32,8)',
          DatabaseCodes.oracle: 'NUMBER(32,8)',
          DatabaseCodes.sqlServer: 'DECIMAL(32,8)',
          DatabaseCodes.sqlite: 'REAL',
        },
        java: 'BigDecimal',
      ),
      DataType(
        id: '8',
        name: 'DateTime',
        chnname: '日期时间',
        remark: 'Date and time',
        apply: {
          DatabaseCodes.mysql: 'DATETIME',
          DatabaseCodes.postgresql: 'TIMESTAMP',
          DatabaseCodes.oracle: 'DATE',
          DatabaseCodes.sqlServer: 'DATETIME',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'LocalDateTime',
      ),
      DataType(
        id: '9',
        name: 'YesNo',
        chnname: '是否',
        remark: 'Boolean flag (Y/N)',
        apply: {
          DatabaseCodes.mysql: 'VARCHAR(1)',
          DatabaseCodes.postgresql: 'VARCHAR(1)',
          DatabaseCodes.oracle: 'VARCHAR2(1)',
          DatabaseCodes.sqlServer: 'NVARCHAR(1)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
      DataType(
        id: '10',
        name: 'Dict',
        chnname: '字典',
        remark: 'Dictionary reference code',
        apply: {
          DatabaseCodes.mysql: 'VARCHAR(32)',
          DatabaseCodes.postgresql: 'VARCHAR(32)',
          DatabaseCodes.oracle: 'VARCHAR2(32)',
          DatabaseCodes.sqlServer: 'NVARCHAR(32)',
          DatabaseCodes.sqlite: 'TEXT',
        },
        java: 'String',
      ),
    ];
  }

  /// Get default data type by ID
  static DataType? getById(String id) {
    return getAll().where((dt) => dt.id == id).firstOrNull;
  }

  /// Get default data type by name
  static DataType? getByName(String name) {
    return getAll().where((dt) => dt.name == name).firstOrNull;
  }

  /// Check if a data type ID is a default type
  static bool isDefaultType(String id) {
    return int.tryParse(id) != null && int.parse(id) >= 1 && int.parse(id) <= 10;
  }

  /// Create DataTypeDomains with default types
  static DataTypeDomains createDefaultDomains() {
    return DataTypeDomains(
      datatype: getAll(),
      database: [],
    );
  }
}