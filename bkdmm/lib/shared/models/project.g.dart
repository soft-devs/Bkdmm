// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => Module.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dataTypeDomains: DataTypeDomains.fromJson(
          json['dataTypeDomains'] as Map<String, dynamic>),
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      versionHistory: (json['versionHistory'] as List<dynamic>?)
          ?.map((e) => VersionSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'modules': instance.modules,
      'dataTypeDomains': instance.dataTypeDomains,
      'profile': instance.profile,
      'versionHistory': instance.versionHistory,
    };

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      defaultFields: (json['defaultFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      defaultFieldsType: json['defaultFieldsType'] as String? ?? '1',
      defaultDatabase: json['defaultDatabase'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'defaultFields': instance.defaultFields,
      'defaultFieldsType': instance.defaultFieldsType,
      'defaultDatabase': instance.defaultDatabase,
      'settings': instance.settings,
    };
