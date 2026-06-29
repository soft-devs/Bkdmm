// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionSnapshot _$VersionSnapshotFromJson(Map<String, dynamic> json) =>
    VersionSnapshot(
      id: json['id'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
      snapshot: json['snapshot'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$VersionSnapshotToJson(VersionSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'description': instance.description,
      'snapshot': instance.snapshot,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
    };

ChangeRecord _$ChangeRecordFromJson(Map<String, dynamic> json) => ChangeRecord(
      id: json['id'] as String,
      type: $enumDecode(_$ChangeTypeEnumMap, json['type']),
      operation: $enumDecode(_$ChangeOperationEnumMap, json['operation']),
      target: ChangeTarget.fromJson(json['target'] as Map<String, dynamic>),
      before: json['before'],
      after: json['after'],
      rollbackSQL: json['rollbackSQL'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChangeRecordToJson(ChangeRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ChangeTypeEnumMap[instance.type]!,
      'operation': _$ChangeOperationEnumMap[instance.operation]!,
      'target': instance.target,
      'before': instance.before,
      'after': instance.after,
      'rollbackSQL': instance.rollbackSQL,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ChangeTypeEnumMap = {
  ChangeType.table: 'table',
  ChangeType.field: 'field',
  ChangeType.indexChange: 'index',
  ChangeType.relation: 'relation',
};

const _$ChangeOperationEnumMap = {
  ChangeOperation.add: 'add',
  ChangeOperation.delete: 'delete',
  ChangeOperation.update: 'update',
};

ChangeTarget _$ChangeTargetFromJson(Map<String, dynamic> json) => ChangeTarget(
      moduleId: json['moduleId'] as String,
      entityId: json['entityId'] as String?,
      fieldId: json['fieldId'] as String?,
      indexId: json['indexId'] as String?,
    );

Map<String, dynamic> _$ChangeTargetToJson(ChangeTarget instance) =>
    <String, dynamic>{
      'moduleId': instance.moduleId,
      'entityId': instance.entityId,
      'fieldId': instance.fieldId,
      'indexId': instance.indexId,
    };
