import 'package:json_annotation/json_annotation.dart';

import 'data_type.dart';
import 'module.dart';
import 'version.dart';

part 'project.g.dart';

/// 项目模型
@JsonSerializable()
class Project {
  /// 项目唯一标识
  final String id;

  /// 项目名称
  final String name;

  /// 项目描述
  final String? description;

  /// 项目版本
  final String version;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 模块列表
  final List<Module> modules;

  /// 数据类型配置
  final DataTypeDomains dataTypeDomains;

  /// 项目配置
  final Profile profile;

  /// 版本历史
  final List<VersionSnapshot>? versionHistory;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.version = '1.0.0',
    required this.createdAt,
    required this.updatedAt,
    this.modules = const [],
    required this.dataTypeDomains,
    required this.profile,
    this.versionHistory,
  });

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Module>? modules,
    DataTypeDomains? dataTypeDomains,
    Profile? profile,
    List<VersionSnapshot>? versionHistory,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modules: modules ?? this.modules,
      dataTypeDomains: dataTypeDomains ?? this.dataTypeDomains,
      profile: profile ?? this.profile,
      versionHistory: versionHistory ?? this.versionHistory,
    );
  }
}

/// 项目配置
@JsonSerializable()
class Profile {
  /// 默认字段列表
  final List<String> defaultFields;

  /// 默认字段类型
  final String defaultFieldsType;

  /// 默认数据库
  final String? defaultDatabase;

  /// 其他设置
  final Map<String, dynamic>? settings;

  Profile({
    this.defaultFields = const [],
    this.defaultFieldsType = '1',
    this.defaultDatabase,
    this.settings,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    List<String>? defaultFields,
    String? defaultFieldsType,
    String? defaultDatabase,
    Map<String, dynamic>? settings,
  }) {
    return Profile(
      defaultFields: defaultFields ?? this.defaultFields,
      defaultFieldsType: defaultFieldsType ?? this.defaultFieldsType,
      defaultDatabase: defaultDatabase ?? this.defaultDatabase,
      settings: settings ?? this.settings,
    );
  }
}
