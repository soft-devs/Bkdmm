import 'dart:ui';

/// ER 图交互模式
enum ERInteractionMode {
  /// 预览模式（只读，可平移/缩放，双击打开预览弹窗）
  preview,

  /// 编辑模式（可拖拽节点、创建连线、框选，双击打开编辑弹窗）
  edit,
}

/// ER 图选择模式
enum ERSelectionType {
  /// 单选模式：只能选中一个节点
  single,

  /// 多选模式：可以选中多个节点
  multiple,
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

/// ER 图框选状态
class ERSelectionState {
  /// 是否正在框选
  final bool isSelecting;

  /// 框选起始点
  final Offset startPoint;

  /// 框选当前点
  final Offset currentPoint;

  const ERSelectionState({
    this.isSelecting = false,
    this.startPoint = Offset.zero,
    this.currentPoint = Offset.zero,
  });

  /// 框选矩形区域
  Rect get selectionRect {
    final left = startPoint.dx < currentPoint.dx ? startPoint.dx : currentPoint.dx;
    final top = startPoint.dy < currentPoint.dy ? startPoint.dy : currentPoint.dy;
    final right = startPoint.dx < currentPoint.dx ? currentPoint.dx : startPoint.dx;
    final bottom = startPoint.dy < currentPoint.dy ? currentPoint.dy : startPoint.dy;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  ERSelectionState copyWith({
    bool? isSelecting,
    Offset? startPoint,
    Offset? currentPoint,
  }) {
    return ERSelectionState(
      isSelecting: isSelecting ?? this.isSelecting,
      startPoint: startPoint ?? this.startPoint,
      currentPoint: currentPoint ?? this.currentPoint,
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

  /// 当前选择类型（单选/多选）
  final ERSelectionType selectionType;

  /// 选中的节点 ID 集合
  final Set<String> selectedNodeIds;

  /// 悬停的节点 ID
  final String? hoveredNodeId;

  /// 正在拖动的节点 ID 集合（多选拖动时可能有多个）
  final Set<String> draggingNodeIds;

  /// 视口状态
  final ERViewportState viewport;

  /// 连线状态
  final ERConnectionState connection;

  /// 框选状态
  final ERSelectionState selection;

  const ERDiagramUIState({
    required this.moduleId,
    this.interactionMode = ERInteractionMode.preview,
    this.selectionType = ERSelectionType.single,
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.draggingNodeIds = const {},
    this.viewport = const ERViewportState(),
    this.connection = const ERConnectionState(),
    this.selection = const ERSelectionState(),
  });

  /// 是否是编辑模式
  bool get isEditMode => interactionMode == ERInteractionMode.edit;

  /// 是否是预览模式
  bool get isPreviewMode => interactionMode == ERInteractionMode.preview;

  /// 是否是单选模式
  bool get isSingleSelection => selectionType == ERSelectionType.single;

  /// 是否是多选模式
  bool get isMultipleSelection => selectionType == ERSelectionType.multiple;

  /// 是否正在连线
  bool get isConnecting => connection.isConnecting;

  /// 是否正在拖动节点
  bool get isDragging => draggingNodeIds.isNotEmpty;

  /// 是否正在框选
  bool get isSelecting => selection.isSelecting;

  /// 是否选中了多个节点
  bool get hasMultipleSelected => selectedNodeIds.length > 1;

  /// 创建空状态
  factory ERDiagramUIState.empty(String moduleId) {
    return ERDiagramUIState(moduleId: moduleId);
  }

  ERDiagramUIState copyWith({
    String? moduleId,
    ERInteractionMode? interactionMode,
    ERSelectionType? selectionType,
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    Set<String>? draggingNodeIds,
    ERViewportState? viewport,
    ERConnectionState? connection,
    ERSelectionState? selection,
  }) {
    return ERDiagramUIState(
      moduleId: moduleId ?? this.moduleId,
      interactionMode: interactionMode ?? this.interactionMode,
      selectionType: selectionType ?? this.selectionType,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      draggingNodeIds: draggingNodeIds ?? this.draggingNodeIds,
      viewport: viewport ?? this.viewport,
      connection: connection ?? this.connection,
      selection: selection ?? this.selection,
    );
  }

  @override
  String toString() {
    return 'ERDiagramUIState(moduleId: $moduleId, mode: $interactionMode, selectionType: $selectionType, selected: ${selectedNodeIds.length}, dragging: ${draggingNodeIds.length}, connecting: $isConnecting, selecting: $isSelecting)';
  }
}
