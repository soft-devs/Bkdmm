// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entity _$EntityFromJson(Map<String, dynamic> json) => Entity(
      id: json['id'] as String,
      title: json['title'] as String,
      chnname: json['chnname'] as String,
      remark: json['remark'] as String?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => Field.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      indexes: (json['indexes'] as List<dynamic>?)
              ?.map((e) => Index.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EntityToJson(Entity instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'chnname': instance.chnname,
      'remark': instance.remark,
      'fields': instance.fields,
      'indexes': instance.indexes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      chnname: json['chnname'] as String,
      remark: json['remark'] as String?,
      pk: json['pk'] as bool? ?? false,
      notNull: json['notNull'] as bool? ?? false,
      autoIncrement: json['autoIncrement'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      length: (json['length'] as num?)?.toInt(),
      decimal: (json['decimal'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'chnname': instance.chnname,
      'remark': instance.remark,
      'pk': instance.pk,
      'notNull': instance.notNull,
      'autoIncrement': instance.autoIncrement,
      'defaultValue': instance.defaultValue,
      'length': instance.length,
      'decimal': instance.decimal,
    };

Index _$IndexFromJson(Map<String, dynamic> json) => Index(
      id: json['id'] as String,
      name: json['name'] as String,
      fieldIds:
          (json['fieldIds'] as List<dynamic>).map((e) => e as String).toList(),
      type: $enumDecodeNullable(_$IndexTypeEnumMap, json['type']) ??
          IndexType.normal,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$IndexToJson(Index instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fieldIds': instance.fieldIds,
      'type': _$IndexTypeEnumMap[instance.type]!,
      'remark': instance.remark,
    };

const _$IndexTypeEnumMap = {
  IndexType.normal: 'NORMAL',
  IndexType.unique: 'UNIQUE',
  IndexType.fulltext: 'FULLTEXT',
};
