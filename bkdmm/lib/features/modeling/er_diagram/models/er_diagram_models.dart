import 'dart:ui';
import '../../../../shared/models/models.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';

/// ER 图节点实现
///
/// 包装 Entity 数据，提供 DiagramNode 接口
class ERNode implements DiagramNode {
  /// 底层实体数据
  final Entity entity;

  /// 图节点数据（位置等）
  final GraphNode graphNode;

  /// 节点状态
  final NodeState state;

  ERNode({
    required this.entity,
    required this.graphNode,
    this.state = const NodeState(),
  });

  @override
  String get id => graphNode.title;

  @override
  String get type => 'er_table';

  @override
  String get title => entity.title;

  @override
  Offset get position => Offset(graphNode.x, graphNode.y);

  @override
  set position(Offset value) {
    // 通过 copyWith 创建新实例
  }

  @override
  Size get size => _calculateSize();

  Size _calculateSize() {
    const headerHeight = 40.0;
    const fieldRowHeight = 28.0;
    const padding = 12.0;
    const defaultWidth = 200.0;
    const minHeight = 80.0;

    final fieldCount = entity.fields.length;
    final height = headerHeight + (fieldCount * fieldRowHeight) + padding;
    return Size(defaultWidth, height < minHeight ? minHeight : height);
  }

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => true;

  @override
  bool get isConnectable => true;

  @override
  dynamic getData() => entity;

  @override
  List<AnchorPoint> getAnchors() {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final anchors = <AnchorPoint>[];

    // 字段级锚点
    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final rowY = rect.top + 40.0 + (i * 28.0) + 28.0 / 2;

      // 左锚点（出边）
      anchors.add(AnchorPoint.fieldAnchor(
        node: this,
        fieldIndex: i,
        direction: AnchorDirection.left,
        position: Offset(rect.left - 8, rowY),
        fieldData: field,
      ));

      // 右锚点（入边）
      anchors.add(AnchorPoint.fieldAnchor(
        node: this,
        fieldIndex: i,
        direction: AnchorDirection.right,
        position: Offset(rect.right + 8, rowY),
        fieldData: field,
      ));
    }

    return anchors;
  }

  @override
  AnchorPoint? getAnchor(String direction) {
    final anchors = getAnchors();
    for (final anchor in anchors) {
      if (anchor.direction.name == direction) {
        return anchor;
      }
    }
    return null;
  }

  /// 获取指定字段的锚点
  AnchorPoint? getFieldAnchor(int fieldIndex, AnchorDirection direction) {
    final anchors = getAnchors();
    for (final anchor in anchors) {
      if (anchor.type == AnchorType.field) {
        final data = anchor.data as Map;
        if (data['fieldIndex'] == fieldIndex && anchor.direction == direction) {
          return anchor;
        }
      }
    }
    return null;
  }

  /// 复制并修改
  ERNode copyWith({
    Entity? entity,
    GraphNode? graphNode,
    NodeState? state,
  }) {
    return ERNode(
      entity: entity ?? this.entity,
      graphNode: graphNode ?? this.graphNode,
      state: state ?? this.state,
    );
  }
}

/// ER 图边实现
///
/// 表示实体之间的关系
class ERRelationEdge implements DiagramEdge {
  /// 底层图边数据
  final GraphEdge graphEdge;

  /// 边状态
  final EdgeState state;

  ERRelationEdge({
    required this.graphEdge,
    this.state = const EdgeState(),
  });

  @override
  String get id => '${graphEdge.source}:${graphEdge.target}';

  @override
  String get type => 'er_relation';

  @override
  String get sourceAnchorId => graphEdge.sourceField != null
      ? '${graphEdge.source}:field:${graphEdge.sourceField}:left'
      : '${graphEdge.source}:right';

  @override
  String get targetAnchorId => graphEdge.targetField != null
      ? '${graphEdge.target}:field:${graphEdge.targetField}:right'
      : '${graphEdge.target}:left';

  @override
  String? get label => graphEdge.label;

  @override
  String get sourceNodeId => graphEdge.source;

  @override
  String get targetNodeId => graphEdge.target;

  @override
  bool get isSelectable => true;

  @override
  dynamic getData() => graphEdge;

  @override
  EdgeStyle getStyle() {
    return const EdgeStyle(
      color: Color(0xFF666666),
      width: 2.0,
      shape: EdgeShape.straight,
    );
  }

  @override
  EdgeMarker? getSourceMarker() {
    final relationType = graphEdge.relationType;
    if (relationType == null) return null;

    final parts = relationType.split(':');
    if (parts.isEmpty) return null;

    final sourceMarker = parts[0];
    if (sourceMarker == '1') {
      return EdgeMarker.one();
    } else if (sourceMarker == 'N') {
      return EdgeMarker.many();
    } else if (sourceMarker == 'M') {
      return EdgeMarker.multiple();
    }
    return null;
  }

  @override
  EdgeMarker? getTargetMarker() {
    final relationType = graphEdge.relationType;
    if (relationType == null) return null;

    final parts = relationType.split(':');
    if (parts.length < 2) return null;

    final targetMarker = parts[1];
    if (targetMarker == '1') {
      return EdgeMarker.one();
    } else if (targetMarker == 'N') {
      return EdgeMarker.many();
    } else if (targetMarker == 'M') {
      return EdgeMarker.multiple();
    }
    return null;
  }

  /// 复制并修改
  ERRelationEdge copyWith({
    GraphEdge? graphEdge,
    EdgeState? state,
  }) {
    return ERRelationEdge(
      graphEdge: graphEdge ?? this.graphEdge,
      state: state ?? this.state,
    );
  }
}

/// ER 图状态扩展
class ERDiagramState extends DiagramState {
  /// 模块 ID
  final String moduleId;

  ERDiagramState({
    required this.moduleId,
    required Map<String, DiagramNode> nodes,
    required Map<String, DiagramEdge> edges,
    Map<String, NodeState>? nodeStates,
    Map<String, EdgeState>? edgeStates,
    ViewportState? viewport,
    InteractionState? interaction,
    SelectionState? selection,
  }) : super(
          diagramId: moduleId,
          diagramType: 'er_diagram',
          nodes: nodes,
          edges: edges,
          nodeStates: nodeStates ?? const {},
          edgeStates: edgeStates ?? const {},
          viewport: viewport ?? const ViewportState(),
          interaction: interaction ?? const InteractionState(),
          selection: selection ?? const SelectionState(),
        );

  /// 从模块创建
  factory ERDiagramState.fromModule(Module module) {
    // 创建实体映射
    final entityMap = <String, Entity>{};
    for (final entity in module.entities) {
      entityMap[entity.title] = entity;
    }

    // 创建节点映射
    final nodes = <String, DiagramNode>{};
    for (final graphNode in module.graphCanvas.nodes) {
      final entityTitle = graphNode.title.split(':').first;
      final entity = entityMap[entityTitle];
      if (entity != null) {
        nodes[graphNode.title] = ERNode(
          entity: entity,
          graphNode: graphNode,
        );
      }
    }

    // 创建边映射
    final edges = <String, DiagramEdge>{};
    for (final graphEdge in module.graphCanvas.edges) {
      final edgeId = '${graphEdge.source}:${graphEdge.target}';
      edges[edgeId] = ERRelationEdge(graphEdge: graphEdge);
    }

    return ERDiagramState(
      moduleId: module.id,
      nodes: nodes,
      edges: edges,
    );
  }

  /// 获取 ER 节点
  ERNode? getERNode(String id) {
    final node = nodes[id];
    return node is ERNode ? node : null;
  }

  /// 获取 ER 边
  ERRelationEdge? getERRelation(String id) {
    final edge = edges[id];
    return edge is ERRelationEdge ? edge : null;
  }

  @override
  ERDiagramState copyWith({
    String? diagramId,
    String? diagramType,
    Map<String, DiagramNode>? nodes,
    Map<String, DiagramEdge>? edges,
    Map<String, NodeState>? nodeStates,
    Map<String, EdgeState>? edgeStates,
    ViewportState? viewport,
    InteractionState? interaction,
    SelectionState? selection,
  }) {
    return ERDiagramState(
      moduleId: diagramId ?? moduleId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      nodeStates: nodeStates ?? this.nodeStates,
      edgeStates: edgeStates ?? this.edgeStates,
      viewport: viewport ?? this.viewport,
      interaction: interaction ?? this.interaction,
      selection: selection ?? this.selection,
    );
  }
}