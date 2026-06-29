// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectHistory _$ProjectHistoryFromJson(Map<String, dynamic> json) =>
    ProjectHistory(
      path: json['path'] as String,
      name: json['name'] as String,
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
      thumbnail: json['thumbnail'] as String?,
    );

Map<String, dynamic> _$ProjectHistoryToJson(ProjectHistory instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'lastOpenedAt': instance.lastOpenedAt.toIso8601String(),
      'thumbnail': instance.thumbnail,
    };
