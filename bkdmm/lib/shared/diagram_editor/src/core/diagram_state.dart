import 'dart:ui';
import 'diagram_node.dart';
import 'diagram_edge.dart';

/// 图表状态
///
/// 存储图表的所有状态信息，包括节点、边、视口等
class DiagramState {
  /// 图表 ID
  final String diagramId;

  /// 图表类型
  final String diagramType;

  /// 所有节点
  final Map<String, DiagramNode> nodes;

  /// 所有边
  final Map<String, DiagramEdge> edges;

  /// 节点状态
  final Map<String, NodeState> nodeStates;

  /// 边状态
  final Map<String, EdgeState> edgeStates;

  /// 视口状态
  final ViewportState viewport;

  /// 交互状态
  final InteractionState interaction;

  /// 选择状态
  final SelectionState selection;

  const DiagramState({
    required this.diagramId,
    required this.diagramType,
    this.nodes = const {},
    this.edges = const {},
    this.nodeStates = const {},
    this.edgeStates = const {},
    this.viewport = const ViewportState(),
    this.interaction = const InteractionState(),
    this.selection = const SelectionState(),
  });

  /// 获取节点
  DiagramNode? getNode(String id) => nodes[id];

  /// 获取边
  DiagramEdge? getEdge(String id) => edges[id];

  /// 获取节点状态
  NodeState getNodeState(String nodeId) {
    return nodeStates[nodeId] ?? const NodeState();
  }

  /// 获取边状态
  EdgeState getEdgeState(String edgeId) {
    return edgeStates[edgeId] ?? const EdgeState();
  }

  /// 获取选中节点
  List<DiagramNode> getSelectedNodes() {
    return nodes.values
        .where((n) => getNodeState(n.id).isSelected)
        .toList();
  }

  /// 获取选中边
  List<DiagramEdge> getSelectedEdges() {
    return edges.values
        .where((e) => getEdgeState(e.id).isSelected)
        .toList();
  }

  /// 获取连接到指定节点的边
  List<DiagramEdge> getEdgesForNode(String nodeId) {
    return edges.values.where((e) =>
      e.sourceNodeId == nodeId || e.targetNodeId == nodeId
    ).toList();
  }

  /// 获取锚点
  AnchorPoint? getAnchor(String anchorId) {
    // 解析 anchorId: nodeId:anchorKey
    final parts = anchorId.split(':');
    if (parts.length < 2) return null;

    final nodeId = parts.first;
    final node = nodes[nodeId];
    if (node == null) return null;

    // 查找匹配的锚点
    for (final anchor in node.getAnchors()) {
      if (anchor.id == anchorId) {
        return anchor;
      }
    }
    return null;
  }

  /// 计算内容边界
  Rect calculateContentBounds({double padding = 50.0}) {
    if (nodes.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes.values) {
      final rect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );
      minX = minX < rect.left ? minX : rect.left;
      minY = minY < rect.top ? minY : rect.top;
      maxX = maxX > rect.right ? maxX : rect.right;
      maxY = maxY > rect.bottom ? maxY : rect.bottom;
    }

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// 复制并修改
  DiagramState copyWith({
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
    return DiagramState(
      diagramId: diagramId ?? this.diagramId,
      diagramType: diagramType ?? this.diagramType,
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

/// 视口状态
class ViewportState {
  /// 缩放比例
  final double zoom;

  /// 平移偏移
  final Offset panOffset;

  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  const ViewportState({
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
  });

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return Offset(
      scene.dx * zoom + panOffset.dx,
      scene.dy * zoom + panOffset.dy,
    );
  }

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset screen) {
    return Offset(
      (screen.dx - panOffset.dx) / zoom,
      (screen.dy - panOffset.dy) / zoom,
    );
  }

  /// 缩放到指定比例（以指定点为中心）
  ViewportState zoomTo(double newZoom, Offset center) {
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);
    final factor = clampedZoom / zoom;

    return ViewportState(
      zoom: clampedZoom,
      panOffset: Offset(
        center.dx - (center.dx - panOffset.dx) * factor,
        center.dy - (center.dy - panOffset.dy) * factor,
      ),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 平移
  ViewportState pan(Offset delta) {
    return ViewportState(
      zoom: zoom,
      panOffset: panOffset + delta,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 适应内容到视口
  ViewportState fitContent(Rect contentBounds, Size viewportSize, {double padding = 50.0}) {
    if (contentBounds == Rect.zero) {
      return const ViewportState();
    }

    final contentWidth = contentBounds.width + padding * 2;
    final contentHeight = contentBounds.height + padding * 2;

    final scaleX = viewportSize.width / contentWidth;
    final scaleY = viewportSize.height / contentHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(minZoom, maxZoom);

    final offsetX = (viewportSize.width - contentWidth * scale) / 2 -
        contentBounds.left * scale + padding * scale;
    final offsetY = (viewportSize.height - contentHeight * scale) / 2 -
        contentBounds.top * scale + padding * scale;

    return ViewportState(
      zoom: scale,
      panOffset: Offset(offsetX, offsetY),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  ViewportState copyWith({
    double? zoom,
    Offset? panOffset,
    double? minZoom,
    double? maxZoom,
  }) {
    return ViewportState(
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }
}

/// 交互状态
class InteractionState {
  /// 当前交互模式
  final InteractionMode mode;

  /// 当前交互类型
  final InteractionType type;

  /// 是否正在拖拽
  final bool isDragging;

  /// 是否正在连线
  final bool isConnecting;

  /// 正在拖拽的节点 ID
  final String? draggedNodeId;

  /// 连线的源锚点 ID
  final String? connectionSourceAnchorId;

  /// 连线预览的目标位置
  final Offset? connectionPreviewEnd;

  const InteractionState({
    this.mode = InteractionMode.edit,
    this.type = InteractionType.none,
    this.isDragging = false,
    this.isConnecting = false,
    this.draggedNodeId,
    this.connectionSourceAnchorId,
    this.connectionPreviewEnd,
  });

  bool get isIdle => type == InteractionType.none;
  bool get isPanning => type == InteractionType.pan;
  bool get isNodeDrag => type == InteractionType.nodeDrag;
  bool get isEdgeCreate => type == InteractionType.edgeCreate;

  InteractionState copyWith({
    InteractionMode? mode,
    InteractionType? type,
    bool? isDragging,
    bool? isConnecting,
    String? draggedNodeId,
    String? connectionSourceAnchorId,
    Offset? connectionPreviewEnd,
  }) {
    return InteractionState(
      mode: mode ?? this.mode,
      type: type ?? this.type,
      isDragging: isDragging ?? this.isDragging,
      isConnecting: isConnecting ?? this.isConnecting,
      draggedNodeId: draggedNodeId ?? this.draggedNodeId,
      connectionSourceAnchorId: connectionSourceAnchorId ?? this.connectionSourceAnchorId,
      connectionPreviewEnd: connectionPreviewEnd ?? this.connectionPreviewEnd,
    );
  }
}

/// 交互模式
enum InteractionMode {
  /// 移动模式 - 仅查看，pan/zoom
  move,

  /// 编辑模式 - 可拖拽节点、创建连线
  edit,

  /// 只读模式 - 不可交互
  readonly,
}

/// 交互类型
enum InteractionType {
  /// 无交互
  none,

  /// 平移画布
  pan,

  /// 拖拽节点
  nodeDrag,

  /// 创建边
  edgeCreate,

  /// 框选
  boxSelect,
}

/// 选择状态
class SelectionState {
  /// 选中的节点 ID
  final Set<String> selectedNodeIds;

  /// 选中的边 ID
  final Set<String> selectedEdgeIds;

  /// 悬停的节点 ID
  final String? hoveredNodeId;

  /// 悬停的边 ID
  final String? hoveredEdgeId;

  /// 框选矩形（屏幕坐标）
  final Rect? boxSelectRect;

  const SelectionState({
    this.selectedNodeIds = const {},
    this.selectedEdgeIds = const {},
    this.hoveredNodeId,
    this.hoveredEdgeId,
    this.boxSelectRect,
  });

  bool get hasSelection =>
      selectedNodeIds.isNotEmpty || selectedEdgeIds.isNotEmpty;

  bool get hasMultiSelection =>
      selectedNodeIds.length > 1 || selectedEdgeIds.length > 1;

  bool isNodeSelected(String nodeId) => selectedNodeIds.contains(nodeId);
  bool isEdgeSelected(String edgeId) => selectedEdgeIds.contains(edgeId);

  SelectionState copyWith({
    Set<String>? selectedNodeIds,
    Set<String>? selectedEdgeIds,
    String? hoveredNodeId,
    String? hoveredEdgeId,
    Rect? boxSelectRect,
  }) {
    return SelectionState(
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      selectedEdgeIds: selectedEdgeIds ?? this.selectedEdgeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      hoveredEdgeId: hoveredEdgeId ?? this.hoveredEdgeId,
      boxSelectRect: boxSelectRect ?? this.boxSelectRect,
    );
  }
}