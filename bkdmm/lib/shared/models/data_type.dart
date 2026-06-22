import 'package:json_annotation/json_annotation.dart';

part 'data_type.g.dart';

/// 数据类型域配置
@JsonSerializable()
class DataTypeDomains {
  /// 数据类型列表
  final List<DataType> datatype;

  /// 数据库模板列表
  final List<DatabaseTemplate> database;

  DataTypeDomains({
    this.datatype = const [],
    this.database = const [],
  });

  factory DataTypeDomains.fromJson(Map<String, dynamic> json) =>
      _$DataTypeDomainsFromJson(json);
  Map<String, dynamic> toJson() => _$DataTypeDomainsToJson(this);
}

/// 数据类型模型
@JsonSerializable()
class DataType {
  /// 类型唯一标识
  final String id;

  /// 类型代码
  final String name;

  /// 类型中文名
  final String chnname;

  /// 类型备注
  final String? remark;

  /// 各数据库映射 {数据库代码: 类型映射}
  final Map<String, String> apply;

  /// Java类型映射
  final String? java;

  DataType({
    required this.id,
    required this.name,
    required this.chnname,
    this.remark,
    this.apply = const {},
    this.java,
  });

  factory DataType.fromJson(Map<String, dynamic> json) =>
      _$DataTypeFromJson(json);
  Map<String, dynamic> toJson() => _$DataTypeToJson(this);

  /// 获取指定数据库的类型映射
  String? getDatabaseType(String databaseCode) => apply[databaseCode];
}

/// 数据库模板配置
@JsonSerializable()
class DatabaseTemplate {
  /// 数据库代码 (MYSQL/ORACLE/POSTGRESQL/SQLSERVER等)
  final String code;

  /// 数据库名称
  final String name;

  /// 是否为默认数据库
  final bool defaultDatabase;

  /// 模板配置
  final TemplateConfig template;

  DatabaseTemplate({
    required this.code,
    required this.name,
    this.defaultDatabase = false,
    required this.template,
  });

  factory DatabaseTemplate.fromJson(Map<String, dynamic> json) =>
      _$DatabaseTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$DatabaseTemplateToJson(this);
}

/// 模板配置模型
@JsonSerializable()
class TemplateConfig {
  /// 创建表模板
  final String createTableTemplate;

  /// 删除表模板
  final String deleteTableTemplate;

  /// 重建表模板
  final String rebuildTableTemplate;

  /// 创建字段模板
  final String createFieldTemplate;

  /// 更新字段模板
  final String updateFieldTemplate;

  /// 删除字段模板
  final String deleteFieldTemplate;

  /// 创建索引模板
  final String createIndexTemplate;

  /// 删除索引模板
  final String deleteIndexTemplate;

  /// 实体类模板
  final String? entityTemplate;

  /// Mapper模板
  final String? mapperTemplate;

  TemplateConfig({
    required this.createTableTemplate,
    required this.deleteTableTemplate,
    required this.rebuildTableTemplate,
    required this.createFieldTemplate,
    required this.updateFieldTemplate,
    required this.deleteFieldTemplate,
    required this.createIndexTemplate,
    required this.deleteIndexTemplate,
    this.entityTemplate,
    this.mapperTemplate,
  });

  factory TemplateConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateConfigToJson(this);
}