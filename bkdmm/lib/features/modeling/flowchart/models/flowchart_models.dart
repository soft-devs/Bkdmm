import 'package:flutter/material.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';

/// 流程图节点类型
enum FlowNodeType {
  /// 开始/结束（椭圆）
  terminal,

  /// 流程（矩形）
  process,

  /// 判断（菱形）
  decision,

  /// 输入/输出（平行四边形）
  inputOutput,

  /// 预定义流程（双边矩形）
  predefinedProcess,

  /// 连接点（圆形）
  connector,

  /// 数据（波形）
  data,

  /// 文档（波形底部）
  document,
}

/// 流程图节点数据
class FlowNodeData {
  /// 节点类型
  final FlowNodeType type;

  /// 节点标题
  final String title;

  /// 节点描述
  final String? description;

  /// 节点ID
  final String id;

  /// 子流程ID（用于预定义流程）
  final String? subProcessId;

  const FlowNodeData({
    required this.type,
    required this.title,
    required this.id,
    this.description,
    this.subProcessId,
  });

  FlowNodeData copyWith({
    FlowNodeType? type,
    String? title,
    String? id,
    String? description,
    String? subProcessId,
  }) {
    return FlowNodeData(
      type: type ?? this.type,
      title: title ?? this.title,
      id: id ?? this.id,
      description: description ?? this.description,
      subProcessId: subProcessId ?? this.subProcessId,
    );
  }
}

/// 流程图节点实现
class FlowNode implements DiagramNode {
  /// 节点数据
  final FlowNodeData data;

  /// 节点位置
  Offset _position;

  /// 节点状态
  final NodeState state;

  FlowNode({
    required this.data,
    required Offset position,
    this.state = const NodeState(),
  }) : _position = position;

  @override
  String get id => data.id;

  @override
  String get type => 'flow_${data.type.name}';

  @override
  String get title => data.title;

  @override
  Offset get position => _position;

  @override
  set position(Offset value) {
    _position = value;
  }

  @override
  Size get size => _calculateSize();

  Size _calculateSize() {
    // 不同类型节点有不同的默认尺寸
    switch (data.type) {
      case FlowNodeType.terminal:
        return const Size(120, 60);
      case FlowNodeType.process:
        return const Size(160, 80);
      case FlowNodeType.decision:
        return const Size(100, 100); // 菱形
      case FlowNodeType.inputOutput:
        return const Size(140, 70);
      case FlowNodeType.predefinedProcess:
        return const Size(160, 80);
      case FlowNodeType.connector:
        return const Size(40, 40); // 圆形
      case FlowNodeType.data:
        return const Size(140, 70);
      case FlowNodeType.document:
        return const Size(140, 80);
    }
  }

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => true;

  @override
  bool get isConnectable => true;

  @override
  dynamic getData() => data;

  @override
  List<AnchorPoint> getAnchors() {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final anchors = <AnchorPoint>[];

    // 流程图节点有固定的输入输出端口
    // 输入端口（顶部）
    anchors.add(AnchorPoint(
      node: this,
      id: '$id:input',
      position: Offset(rect.center.dx, rect.top),
      type: AnchorType.port,
      direction: AnchorDirection.top,
      data: {'portType': 'input'},
    ));

    // 输出端口（底部）
    anchors.add(AnchorPoint(
      node: this,
      id: '$id:output',
      position: Offset(rect.center.dx, rect.bottom),
      type: AnchorType.port,
      direction: AnchorDirection.bottom,
      data: {'portType': 'output'},
    ));

    // 判断节点额外添加左右端口
    if (data.type == FlowNodeType.decision) {
      // Yes 分支（右侧）
      anchors.add(AnchorPoint(
        node: this,
        id: '$id:yes',
        position: Offset(rect.right, rect.center.dy),
        type: AnchorType.port,
        direction: AnchorDirection.right,
        data: {'portType': 'yes'},
      ));

      // No 分支（左侧）
      anchors.add(AnchorPoint(
        node: this,
        id: '$id:no',
        position: Offset(rect.left, rect.center.dy),
        type: AnchorType.port,
        direction: AnchorDirection.left,
        data: {'portType': 'no'},
      ));
    }

    return anchors;
  }

  @override
  AnchorPoint? getAnchor(String direction) {
    final anchors = getAnchors();
    for (final anchor in anchors) {
      if (anchor.id.contains(direction)) {
        return anchor;
      }
    }
    return null;
  }

  FlowNode copyWith({
    FlowNodeData? data,
    Offset? position,
    NodeState? state,
  }) {
    return FlowNode(
      data: data ?? this.data,
      position: position ?? this.position,
      state: state ?? this.state,
    );
  }
}

/// 流程图边类型
enum FlowEdgeType {
  /// 普通流程线
  sequence,

  /// 条件分支（Yes）
  conditionYes,

  /// 条件分支（No）
  conditionNo,

  /// 循环返回
  loopBack,

  /// 并行分支
  parallel,
}

/// 流程图边数据
class FlowEdgeData {
  /// 源节点ID
  final String sourceId;

  /// 目标节点ID
  final String targetId;

  /// 边类型
  final FlowEdgeType type;

  /// 标签（如 "Yes", "No"）
  final String? label;

  /// 边ID
  final String id;

  const FlowEdgeData({
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.id,
    this.label,
  });

  FlowEdgeData copyWith({
    String? sourceId,
    String? targetId,
    FlowEdgeType? type,
    String? id,
    String? label,
  }) {
    return FlowEdgeData(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      id: id ?? this.id,
      label: label ?? this.label,
    );
  }
}

/// 流程图边实现
class FlowEdge implements DiagramEdge {
  /// 边数据
  final FlowEdgeData data;

  /// 边状态
  final EdgeState state;

  FlowEdge({
    required this.data,
    this.state = const EdgeState(),
  });

  @override
  String get id => data.id;

  @override
  String get sourceAnchorId => '${data.sourceId}:output';

  @override
  String get targetAnchorId => '${data.targetId}:input';

  @override
  String get sourceNodeId => data.sourceId;

  @override
  String get targetNodeId => data.targetId;

  @override
  String get type => 'flow_edge';

  @override
  String? get label => data.label;

  @override
  bool get isSelectable => true;

  @override
  dynamic getData() => data;

  @override
  EdgeStyle getStyle() {
    Color color;
    switch (data.type) {
      case FlowEdgeType.conditionYes:
        color = Colors.green.shade500;
        break;
      case FlowEdgeType.conditionNo:
        color = Colors.red.shade500;
        break;
      case FlowEdgeType.loopBack:
        color = Colors.orange.shade500;
        break;
      default:
        color = Colors.grey.shade600;
    }

    return EdgeStyle(
      color: color,
      width: 2.0,
      shape: EdgeShape.orthogonal, // 流程图使用正交线
      showArrow: true,
    );
  }

  @override
  EdgeMarker? getSourceMarker() => null;

  @override
  EdgeMarker? getTargetMarker() => EdgeMarker.arrow();

  FlowEdge copyWith({
    FlowEdgeData? data,
    EdgeState? state,
  }) {
    return FlowEdge(
      data: data ?? this.data,
      state: state ?? this.state,
    );
  }
}

/// 流程图状态
class FlowDiagramState extends DiagramState {
  FlowDiagramState({
    required String diagramId,
    required Map<String, DiagramNode> nodes,
    required Map<String, DiagramEdge> edges,
    Map<String, NodeState>? nodeStates,
    Map<String, EdgeState>? edgeStates,
    ViewportState? viewport,
    InteractionState? interaction,
    SelectionState? selection,
  }) : super(
          diagramId: diagramId,
          diagramType: 'flow_diagram',
          nodes: nodes,
          edges: edges,
          nodeStates: nodeStates ?? const {},
          edgeStates: edgeStates ?? const {},
          viewport: viewport ?? const ViewportState(),
          interaction: interaction ?? const InteractionState(),
          selection: selection ?? const SelectionState(),
        );

  /// 获取流程节点
  FlowNode? getFlowNode(String id) {
    final node = nodes[id];
    return node is FlowNode ? node : null;
  }

  /// 获取流程边
  FlowEdge? getFlowEdge(String id) {
    final edge = edges[id];
    return edge is FlowEdge ? edge : null;
  }

  /// 创建示例流程图
  static FlowDiagramState createSample() {
    final nodes = <String, DiagramNode>{};

    // 创建示例节点
    nodes['start'] = FlowNode(
      data: const FlowNodeData(id: 'start', type: FlowNodeType.terminal, title: '开始'),
      position: const Offset(200, 50),
    );

    nodes['process1'] = FlowNode(
      data: const FlowNodeData(id: 'process1', type: FlowNodeType.process, title: '处理数据'),
      position: const Offset(200, 150),
    );

    nodes['decision1'] = FlowNode(
      data: const FlowNodeData(id: 'decision1', type: FlowNodeType.decision, title: '是否有效?'),
      position: const Offset(200, 280),
    );

    nodes['process2'] = FlowNode(
      data: const FlowNodeData(id: 'process2', type: FlowNodeType.process, title: '保存数据'),
      position: const Offset(200, 420),
    );

    nodes['process3'] = FlowNode(
      data: const FlowNodeData(id: 'process3', type: FlowNodeType.process, title: '记录错误'),
      position: const Offset(350, 280),
    );

    nodes['end'] = FlowNode(
      data: const FlowNodeData(id: 'end', type: FlowNodeType.terminal, title: '结束'),
      position: const Offset(200, 520),
    );

    // 创建边
    final edges = <String, DiagramEdge>{};

    edges['e1'] = FlowEdge(data: const FlowEdgeData(id: 'e1', sourceId: 'start', targetId: 'process1', type: FlowEdgeType.sequence));
    edges['e2'] = FlowEdge(data: const FlowEdgeData(id: 'e2', sourceId: 'process1', targetId: 'decision1', type: FlowEdgeType.sequence));
    edges['e3'] = FlowEdge(data: const FlowEdgeData(id: 'e3', sourceId: 'decision1', targetId: 'process2', type: FlowEdgeType.conditionYes, label: 'Yes'));
    edges['e4'] = FlowEdge(data: const FlowEdgeData(id: 'e4', sourceId: 'decision1', targetId: 'process3', type: FlowEdgeType.conditionNo, label: 'No'));
    edges['e5'] = FlowEdge(data: const FlowEdgeData(id: 'e5', sourceId: 'process2', targetId: 'end', type: FlowEdgeType.sequence));
    edges['e6'] = FlowEdge(data: const FlowEdgeData(id: 'e6', sourceId: 'process3', targetId: 'end', type: FlowEdgeType.sequence));

    return FlowDiagramState(
      diagramId: 'sample_flow',
      nodes: nodes,
      edges: edges,
    );
  }

  @override
  FlowDiagramState copyWith({
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
    return FlowDiagramState(
      diagramId: diagramId ?? this.diagramId,
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