import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';
import '../../utils/id_generator.dart';

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

  /// 验证所有Entity的ID唯一性
  bool validateEntityIds() {
    final ids = entities.map((e) => e.id).toSet();
    return ids.length == entities.length && !ids.contains('');
  }

  /// 验证模块内所有ID（包括Entity、Field、Index）
  bool validateAllIds() {
    if (!validateEntityIds()) return false;
    for (final entity in entities) {
      if (!entity.validateAllIds()) return false;
    }
    return true;
  }

  /// 检查是否有空ID
  bool hasEmptyIds() {
    if (entities.any((e) => e.id.isEmpty)) return true;
    for (final entity in entities) {
      if (entity.hasEmptyFieldIds() || entity.hasEmptyIndexIds()) return true;
    }
    return false;
  }

  /// 修复所有空ID和重复ID
  Module fixAllIds() {
    final seenEntityIds = <String>{};
    final fixedEntities = <Entity>[];

    for (final entity in entities) {
      // 修复entity ID
      String entityId = entity.id;
      if (entityId.isEmpty || seenEntityIds.contains(entityId)) {
        entityId = IdGenerator.generate();
      }
      seenEntityIds.add(entityId);

      // 修复字段ID
      final seenFieldIds = <String>{};
      final fixedFields = <Field>[];
      for (final field in entity.fields) {
        String fieldId = field.id;
        if (fieldId.isEmpty || seenFieldIds.contains(fieldId)) {
          fieldId = IdGenerator.generate();
        }
        seenFieldIds.add(fieldId);
        fixedFields.add(field.copyWith(id: fieldId));
      }

      // 修复索引ID
      final seenIndexIds = <String>{};
      final fixedIndexes = <Index>[];
      for (final index in entity.indexes) {
        String indexId = index.id;
        if (indexId.isEmpty || seenIndexIds.contains(indexId)) {
          indexId = IdGenerator.generate();
        }
        seenIndexIds.add(indexId);
        fixedIndexes.add(index.copyWith(id: indexId));
      }

      fixedEntities.add(entity.copyWith(
        id: entityId,
        fields: fixedFields,
        indexes: fixedIndexes,
      ));
    }

    return copyWith(entities: fixedEntities);
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
  /// 源节点 (表名:序号)
  final String source;

  /// 目标节点 (表名:序号)
  final String target;

  /// 源字段名 (可选，用于字段级连线)
  final String? sourceField;

  /// 目标字段名 (可选，用于字段级连线)
  final String? targetField;

  /// 关系标签
  final String? label;

  /// 关系类型: 1:1, 1:N, N:1, N:M
  final String? relationType;

  GraphEdge({
    required this.source,
    required this.target,
    this.sourceField,
    this.targetField,
    this.label,
    this.relationType,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) =>
      _$GraphEdgeFromJson(json);
  Map<String, dynamic> toJson() => _$GraphEdgeToJson(this);

  GraphEdge copyWith({
    String? source,
    String? target,
    String? sourceField,
    String? targetField,
    String? label,
    String? relationType,
  }) {
    return GraphEdge(
      source: source ?? this.source,
      target: target ?? this.target,
      sourceField: sourceField ?? this.sourceField,
      targetField: targetField ?? this.targetField,
      label: label ?? this.label,
      relationType: relationType ?? this.relationType,
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
