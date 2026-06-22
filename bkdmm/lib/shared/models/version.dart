import 'package:json_annotation/json_annotation.dart';

part 'version.g.dart';

/// 版本快照模型
@JsonSerializable()
class VersionSnapshot {
  /// 快照唯一标识
  final String id;

  /// 版本号
  final String version;

  /// 版本描述
  final String? description;

  /// 数据快照 (项目数据)
  final Map<String, dynamic> snapshot;

  /// 创建时间
  final DateTime createdAt;

  /// 创建者
  final String? createdBy;

  VersionSnapshot({
    required this.id,
    required this.version,
    this.description,
    required this.snapshot,
    required this.createdAt,
    this.createdBy,
  });

  factory VersionSnapshot.fromJson(Map<String, dynamic> json) =>
      _$VersionSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$VersionSnapshotToJson(this);
}

/// 变更记录模型
@JsonSerializable()
class ChangeRecord {
  /// 变更唯一标识
  final String id;

  /// 变更类型
  final ChangeType type;

  /// 变更操作
  final ChangeOperation operation;

  /// 变更目标
  final ChangeTarget target;

  /// 变更前数据
  final dynamic before;

  /// 变更后数据
  final dynamic after;

  /// 回滚SQL
  final String? rollbackSQL;

  /// 创建时间
  final DateTime createdAt;

  ChangeRecord({
    required this.id,
    required this.type,
    required this.operation,
    required this.target,
    this.before,
    this.after,
    this.rollbackSQL,
    required this.createdAt,
  });

  factory ChangeRecord.fromJson(Map<String, dynamic> json) =>
      _$ChangeRecordFromJson(json);
  Map<String, dynamic> toJson() => _$ChangeRecordToJson(this);
}

/// 变更类型枚举
enum ChangeType {
  @JsonValue('table')
  table,
  @JsonValue('field')
  field,
  @JsonValue('index')
  indexChange,
  @JsonValue('relation')
  relation,
}

/// 变更操作枚举
enum ChangeOperation {
  @JsonValue('add')
  add,
  @JsonValue('delete')
  delete,
  @JsonValue('update')
  update,
}

/// 变更目标模型
@JsonSerializable()
class ChangeTarget {
  /// 模块ID
  final String moduleId;

  /// 数据表ID
  final String? entityId;

  /// 字段ID
  final String? fieldId;

  /// 索引ID
  final String? indexId;

  ChangeTarget({
    required this.moduleId,
    this.entityId,
    this.fieldId,
    this.indexId,
  });

  factory ChangeTarget.fromJson(Map<String, dynamic> json) =>
      _$ChangeTargetFromJson(json);
  Map<String, dynamic> toJson() => _$ChangeTargetToJson(this);
}