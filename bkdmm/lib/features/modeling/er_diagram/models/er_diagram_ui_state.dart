import 'dart:ui';

/// ER 图交互模式
enum ERInteractionMode {
  /// 移动模式（仅查看，可平移/缩放）
  move,

  /// 编辑模式（可拖拽节点、创建连线）
  edit,
}

/// ER 图视口状态
class ERViewportState {
  final double zoom;
  final Offset pan;

  const ERViewportState({
    this.zoom = 1.0,
    this.pan = Offset.zero,
  });

  ERViewportState copyWith({
    double? zoom,
    Offset? pan,
  }) {
    return ERViewportState(
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }
}

/// ER 图连线状态
class ERConnectionState {
  /// 是否正在连线
  final bool isConnecting;

  /// 连线源锚点（字段锚点）
  final ERFieldAnchor? sourceAnchor;

  /// 连线预览终点
  final Offset previewEnd;

  const ERConnectionState({
    this.isConnecting = false,
    this.sourceAnchor,
    this.previewEnd = Offset.zero,
  });

  ERConnectionState copyWith({
    bool? isConnecting,
    ERFieldAnchor? sourceAnchor,
    Offset? previewEnd,
  }) {
    return ERConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      sourceAnchor: sourceAnchor ?? this.sourceAnchor,
      previewEnd: previewEnd ?? this.previewEnd,
    );
  }
}

/// ER 图字段锚点
class ERFieldAnchor {
  /// 所属节点ID（实体ID）
  final String nodeId;

  /// 字段索引
  final int fieldIndex;

  /// 锚点方向
  final ERAnchorDirection direction;

  /// 锚点位置（绝对坐标）
  final Offset position;

  const ERFieldAnchor({
    required this.nodeId,
    required this.fieldIndex,
    required this.direction,
    required this.position,
  });

  /// 锚点唯一标识
  String get id => '$nodeId:field:$fieldIndex:${direction.name}';
}

/// 锚点方向
enum ERAnchorDirection {
  left,   // 出边连接点
  right,  // 入边连接点
}

/// ER 图 UI 状态
///
/// 只存储 UI 相关状态，不存储业务数据。
/// 业务数据（实体、节点位置、关系）从 Project 实时读取。
class ERDiagramUIState {
  /// 模块 ID
  final String moduleId;

  /// 当前交互模式
  final ERInteractionMode interactionMode;

  /// 选中的节点 ID 集合
  final Set<String> selectedNodeIds;

  /// 悬停的节点 ID
  final String? hoveredNodeId;

  /// 正在拖动的节点 ID
  final String? draggingNodeId;

  /// 视口状态
  final ERViewportState viewport;

  /// 连线状态
  final ERConnectionState connection;

  const ERDiagramUIState({
    required this.moduleId,
    this.interactionMode = ERInteractionMode.move,
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.draggingNodeId,
    this.viewport = const ERViewportState(),
    this.connection = const ERConnectionState(),
  });

  /// 是否是编辑模式
  bool get isEditMode => interactionMode == ERInteractionMode.edit;

  /// 是否是移动模式
  bool get isMoveMode => interactionMode == ERInteractionMode.move;

  /// 是否正在连线
  bool get isConnecting => connection.isConnecting;

  /// 是否正在拖动节点
  bool get isDragging => draggingNodeId != null;

  /// 创建空状态
  factory ERDiagramUIState.empty(String moduleId) {
    return ERDiagramUIState(moduleId: moduleId);
  }

  ERDiagramUIState copyWith({
    String? moduleId,
    ERInteractionMode? interactionMode,
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    String? draggingNodeId,
    ERViewportState? viewport,
    ERConnectionState? connection,
  }) {
    return ERDiagramUIState(
      moduleId: moduleId ?? this.moduleId,
      interactionMode: interactionMode ?? this.interactionMode,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      draggingNodeId: draggingNodeId ?? this.draggingNodeId,
      viewport: viewport ?? this.viewport,
      connection: connection ?? this.connection,
    );
  }

  @override
  String toString() {
    return 'ERDiagramUIState(moduleId: $moduleId, mode: $interactionMode, selected: ${selectedNodeIds.length}, connecting: $isConnecting)';
  }
}
