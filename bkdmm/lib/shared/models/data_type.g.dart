// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataTypeDomains _$DataTypeDomainsFromJson(Map<String, dynamic> json) =>
    DataTypeDomains(
      datatype: (json['datatype'] as List<dynamic>?)
              ?.map((e) => DataType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      database: (json['database'] as List<dynamic>?)
              ?.map((e) => DatabaseTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DataTypeDomainsToJson(DataTypeDomains instance) =>
    <String, dynamic>{
      'datatype': instance.datatype,
      'database': instance.database,
    };

DataType _$DataTypeFromJson(Map<String, dynamic> json) => DataType(
      id: json['id'] as String,
      name: json['name'] as String,
      chnname: json['chnname'] as String,
      remark: json['remark'] as String?,
      apply: (json['apply'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      java: json['java'] as String?,
    );

Map<String, dynamic> _$DataTypeToJson(DataType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'chnname': instance.chnname,
      'remark': instance.remark,
      'apply': instance.apply,
      'java': instance.java,
    };

DatabaseTemplate _$DatabaseTemplateFromJson(Map<String, dynamic> json) =>
    DatabaseTemplate(
      code: json['code'] as String,
      name: json['name'] as String,
      defaultDatabase: json['defaultDatabase'] as bool? ?? false,
      template:
          TemplateConfig.fromJson(json['template'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DatabaseTemplateToJson(DatabaseTemplate instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'defaultDatabase': instance.defaultDatabase,
      'template': instance.template,
    };

TemplateConfig _$TemplateConfigFromJson(Map<String, dynamic> json) =>
    TemplateConfig(
      createTableTemplate: json['createTableTemplate'] as String,
      deleteTableTemplate: json['deleteTableTemplate'] as String,
      rebuildTableTemplate: json['rebuildTableTemplate'] as String,
      createFieldTemplate: json['createFieldTemplate'] as String,
      updateFieldTemplate: json['updateFieldTemplate'] as String,
      deleteFieldTemplate: json['deleteFieldTemplate'] as String,
      createIndexTemplate: json['createIndexTemplate'] as String,
      deleteIndexTemplate: json['deleteIndexTemplate'] as String,
      entityTemplate: json['entityTemplate'] as String?,
      mapperTemplate: json['mapperTemplate'] as String?,
    );

Map<String, dynamic> _$TemplateConfigToJson(TemplateConfig instance) =>
    <String, dynamic>{
      'createTableTemplate': instance.createTableTemplate,
      'deleteTableTemplate': instance.deleteTableTemplate,
      'rebuildTableTemplate': instance.rebuildTableTemplate,
      'createFieldTemplate': instance.createFieldTemplate,
      'updateFieldTemplate': instance.updateFieldTemplate,
      'deleteFieldTemplate': instance.deleteFieldTemplate,
      'createIndexTemplate': instance.createIndexTemplate,
      'deleteIndexTemplate': instance.deleteIndexTemplate,
      'entityTemplate': instance.entityTemplate,
      'mapperTemplate': instance.mapperTemplate,
    };
