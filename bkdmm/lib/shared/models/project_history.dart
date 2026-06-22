import 'package:json_annotation/json_annotation.dart';

part 'project_history.g.dart';

/// 项目历史记录模型
@JsonSerializable()
class ProjectHistory {
  /// 项目文件路径
  final String path;

  /// 项目名称
  final String name;

  /// 最后打开时间
  final DateTime lastOpenedAt;

  /// 缩略图 Base64
  final String? thumbnail;

  ProjectHistory({
    required this.path,
    required this.name,
    required this.lastOpenedAt,
    this.thumbnail,
  });

  factory ProjectHistory.fromJson(Map<String, dynamic> json) =>
      _$ProjectHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectHistoryToJson(this);

  ProjectHistory copyWith({
    String? path,
    String? name,
    DateTime? lastOpenedAt,
    String? thumbnail,
  }) {
    return ProjectHistory(
      path: path ?? this.path,
      name: name ?? this.name,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}