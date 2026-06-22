import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

part 'module.g.dart';

/// 模块模型
@JsonSerializable()
class Module {
  /// 模块唯一标识
  final String id;

  /// 模块代码（英文）
  final String name;

  /// 模块中文名
  final String chnname;

  /// 模块描述
  final String? description;

  /// 数据表列表
  final List<Entity> entities;

  /// 关系图画布
  final GraphCanvas graphCanvas;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  Module({
    required this.id,
    required this.name,
    required this.chnname,
    this.description,
    this.entities = const [],
    required this.graphCanvas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  Module copyWith({
    String? id,
    String? name,
    String? chnname,
    String? description,
    List<Entity>? entities,
    GraphCanvas? graphCanvas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Module(
      id: id ?? this.id,
      name: name ?? this.name,
      chnname: chnname ?? this.chnname,
      description: description ?? this.description,
      entities: entities ?? this.entities,
      graphCanvas: graphCanvas ?? this.graphCanvas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 图画布
@JsonSerializable()
class GraphCanvas {
  /// 节点列表
  final List<GraphNode> nodes;

  /// 连线列表
  final List<GraphEdge> edges;

  /// 视口状态
  final Viewport? viewport;

  GraphCanvas({
    this.nodes = const [],
    this.edges = const [],
    this.viewport,
  });

  factory GraphCanvas.fromJson(Map<String, dynamic> json) =>
      _$GraphCanvasFromJson(json);
  Map<String, dynamic> toJson() => _$GraphCanvasToJson(this);

  GraphCanvas copyWith({
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    Viewport? viewport,
  }) {
    return GraphCanvas(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      viewport: viewport ?? this.viewport,
    );
  }
}

/// 图节点
@JsonSerializable()
class GraphNode {
  /// 格式: 表名:序号
  final String title;

  /// X坐标
  final double x;

  /// Y坐标
  final double y;

  /// 所属模块名
  final String? moduleName;

  GraphNode({
    required this.title,
    required this.x,
    required this.y,
    this.moduleName,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) =>
      _$GraphNodeFromJson(json);
  Map<String, dynamic> toJson() => _$GraphNodeToJson(this);

  GraphNode copyWith({
    String? title,
    double? x,
    double? y,
    String? moduleName,
  }) {
    return GraphNode(
      title: title ?? this.title,
      x: x ?? this.x,
      y: y ?? this.y,
      moduleName: moduleName ?? this.moduleName,
    );
  }
}

/// 图连线
@JsonSerializable()
class GraphEdge {
  /// 源节点
  final String source;

  /// 目标节点
  final String target;

  /// 关系标签
  final String? label;

  GraphEdge({
    required this.source,
    required this.target,
    this.label,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) =>
      _$GraphEdgeFromJson(json);
  Map<String, dynamic> toJson() => _$GraphEdgeToJson(this);

  GraphEdge copyWith({
    String? source,
    String? target,
    String? label,
  }) {
    return GraphEdge(
      source: source ?? this.source,
      target: target ?? this.target,
      label: label ?? this.label,
    );
  }
}

/// 视口状态
@JsonSerializable()
class Viewport {
  /// 缩放比例
  final double scale;

  /// X偏移量
  final double offsetX;

  /// Y偏移量
  final double offsetY;

  Viewport({
    this.scale = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) =>
      _$ViewportFromJson(json);
  Map<String, dynamic> toJson() => _$ViewportToJson(this);

  Viewport copyWith({
    double? scale,
    double? offsetX,
    double? offsetY,
  }) {
    return Viewport(
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}
