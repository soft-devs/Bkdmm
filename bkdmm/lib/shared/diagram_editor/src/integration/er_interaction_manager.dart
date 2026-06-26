/// ER 图事件处理集成
///
/// 将 ER 图的所有事件处理器集成到一个统一的接口中，
/// 替代原来分散在 er_diagram_canvas.dart 中的事件处理代码。
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../handlers/diagram_event.dart';
import '../handlers/diagram_context.dart';
import '../handlers/diagram_handler.dart';
import '../handlers/handler_registry.dart';
import '../handlers/anchor_click_handler.dart';
import '../handlers/node_drag_handler.dart';
import '../handlers/selection_handler.dart';
import '../handlers/canvas_pan_handler.dart';
import '../spatial/spatial_index.dart';
import '../spatial/simple_index.dart';
import '../commands/diagram_command.dart';
import '../commands/history_controller.dart';

/// 交互模式
enum InteractionMode {
  /// 移动模式 - 仅查看，pan/zoom
  move,

  /// 编辑模式 - 可拖拽节点、创建连线
  edit,

  /// 只读模式 - 不可交互
  readonly,
}

/// ER 图交互状态
///
/// 包含所有交互相关的状态信息
class ERInteractionState {
  /// 当前交互模式
  final InteractionMode mode;

  /// 选中的节点 ID
  final Set<String> selectedNodeIds;

  /// 正在拖动的节点 ID
  final String? draggingNodeId;

  /// 拖动起始位置
  final Offset? dragStartPosition;

  /// 连线源锚点
  final String? connectionSourceAnchorId;

  /// 连线预览终点
  final Offset? connectionPreviewEnd;

  /// 框选矩形
  final Rect? selectionRect;

  /// 悬停节点 ID
  final String? hoveredNodeId;

  const ERInteractionState({
    this.mode = InteractionMode.edit,
    this.selectedNodeIds = const {},
    this.draggingNodeId,
    this.dragStartPosition,
    this.connectionSourceAnchorId,
    this.connectionPreviewEnd,
    this.selectionRect,
    this.hoveredNodeId,
  });

  bool get isIdle =>
      draggingNodeId == null &&
      connectionSourceAnchorId == null &&
      selectionRect == null;

  bool get isDragging => draggingNodeId != null;
  bool get isConnecting => connectionSourceAnchorId != null;
  bool get isSelecting => selectionRect != null;
  bool get isPreviewMode => mode == InteractionMode.move;
  bool get isEditMode => mode == InteractionMode.edit;

  ERInteractionState copyWith({
    InteractionMode? mode,
    Set<String>? selectedNodeIds,
    String? draggingNodeId,
    Offset? dragStartPosition,
    String? connectionSourceAnchorId,
    Offset? connectionPreviewEnd,
    Rect? selectionRect,
    String? hoveredNodeId,
    bool clearDragging = false,
    bool clearConnection = false,
    bool clearSelection = false,
    bool clearHovered = false,
  }) {
    return ERInteractionState(
      mode: mode ?? this.mode,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      draggingNodeId: clearDragging ? null : (draggingNodeId ?? this.draggingNodeId),
      dragStartPosition: clearDragging ? null : (dragStartPosition ?? this.dragStartPosition),
      connectionSourceAnchorId: clearConnection ? null : (connectionSourceAnchorId ?? this.connectionSourceAnchorId),
      connectionPreviewEnd: clearConnection ? null : (connectionPreviewEnd ?? this.connectionPreviewEnd),
      selectionRect: clearSelection ? null : (selectionRect ?? this.selectionRect),
      hoveredNodeId: clearHovered ? null : (hoveredNodeId ?? this.hoveredNodeId),
    );
  }
}

/// ER 图交互管理器
///
/// 统一管理 ER 图的所有交互逻辑，包括：
/// - 事件分发
/// - 状态管理
/// - 命令执行
class ERInteractionManager {
  /// 处理器注册表
  final HandlerRegistry _registry;

  /// 空间索引
  final DiagramSpatialIndex _spatialIndex;

  /// 历史控制器
  final HistoryController _historyController;

  /// 变换控制器
  final TransformationController transformController;

  /// 当前交互状态
  ERInteractionState _state = const ERInteractionState();

  /// 节点位置缓存（用于多选拖动）
  Map<String, Offset> _nodeStartPositions = {};

  ERInteractionManager({
    required this.transformController,
    DiagramSpatialIndex? spatialIndex,
    HistoryController? historyController,
  })  : _registry = HandlerRegistry(),
        _spatialIndex = spatialIndex ?? DiagramSpatialIndex(),
        _historyController = historyController ?? HistoryController() {
    _registerHandlers();
  }

  void _registerHandlers() {
    _registry.registerAll([
      AnchorClickHandler(priority: 10),
      ConnectionHandler(priority: 30),
      NodeDragHandler(priority: 20),
      SelectionHandler(priority: 50),
      CanvasPanHandler(priority: 100),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问
  // ═══════════════════════════════════════════════════════════════════

  ERInteractionState get state => _state;
  HandlerRegistry get registry => _registry;
  DiagramSpatialIndex get spatialIndex => _spatialIndex;
  HistoryController get historyController => _historyController;

  // ═══════════════════════════════════════════════════════════════════
  // 模式切换
  // ═══════════════════════════════════════════════════════════════════

  void enterEditMode() {
    _state = _state.copyWith(mode: InteractionMode.edit);
  }

  void enterPreviewMode() {
    _state = _state.copyWith(mode: InteractionMode.move);
  }

  void toggleMode() {
    if (_state.isEditMode) {
      enterPreviewMode();
    } else {
      enterEditMode();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  Offset toScene(Offset local) {
    final matrix = transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, local);
  }

  Offset toScreen(Offset scene) {
    return MatrixUtils.transformPoint(transformController.value, scene);
  }

  double get zoom => transformController.value.getMaxScaleOnAxis();

  // ═══════════════════════════════════════════════════════════════════
  // 空间索引更新
  // ═══════════════════════════════════════════════════════════════════

  void updateNodeInIndex(String nodeId, Rect bounds) {
    _spatialIndex.nodeIndex.insert(BoundedItem(
      id: nodeId,
      bounds: bounds,
    ));
  }

  void updateAnchorInIndex(String anchorId, Rect bounds, {required String nodeId, required dynamic anchor}) {
    _spatialIndex.anchorIndex.insert(BoundedItem(
      id: anchorId,
      bounds: bounds,
      data: {'nodeId': nodeId, 'anchor': anchor},
    ));
  }

  void clearIndex() {
    _spatialIndex.clear();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 事件处理
  // ═══════════════════════════════════════════════════════════════════

  /// 处理指针按下事件
  void onPointerDown(PointerDownEvent event, DiagramContext context) {
    if (event.buttons == kSecondaryMouseButton) {
      // 右键：在编辑模式下开始平移
      if (_state.isEditMode) {
        _startPan(event.localPosition);
      }
      return;
    }

    if (event.buttons == kPrimaryMouseButton) {
      final scenePos = toScene(event.localPosition);
      final hitResult = _spatialIndex.hitTest(scenePos);

      if (_state.isEditMode) {
        if (hitResult.isOnAnchor) {
          _handleAnchorClick(hitResult, event);
        } else if (hitResult.isOnNode) {
          _handleNodeClick(hitResult, event);
        } else {
          _startBoxSelection(event.localPosition);
        }
      } else if (_state.isPreviewMode) {
        // 预览模式：平移由 InteractiveViewer 处理
      }
    }
  }

  /// 处理指针移动事件
  void onPointerMove(PointerMoveEvent event, DiagramContext context) {
    if (_isPanning) {
      _updatePan(event.localPosition);
      return;
    }

    if (_state.isDragging) {
      _updateNodeDrag(event);
    } else if (_state.isSelecting) {
      _updateBoxSelection(event.localPosition);
    } else if (_state.isConnecting) {
      _updateConnectionPreview(event.localPosition);
    }

    // 更新悬停状态
    final scenePos = toScene(event.localPosition);
    final hitResult = _spatialIndex.hitTest(scenePos);
    _state = _state.copyWith(hoveredNodeId: hitResult.nodeId);
  }

  /// 处理指针释放事件
  void onPointerUp(PointerUpEvent event, DiagramContext context) {
    if (_isPanning) {
      _endPan();
      return;
    }

    if (_state.isDragging) {
      _endNodeDrag();
    } else if (_state.isSelecting) {
      _endBoxSelection();
    } else if (_state.isConnecting) {
      final scenePos = toScene(event.localPosition);
      final hitResult = _spatialIndex.hitTest(scenePos);
      if (hitResult.isOnAnchor && hitResult.nodeId != null) {
        _completeConnection(hitResult.nodeId!);
      } else {
        _cancelConnection();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 节点选择
  // ═══════════════════════════════════════════════════════════════════

  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (addToSelection) {
      final newSelection = Set<String>.from(_state.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
      _state = _state.copyWith(selectedNodeIds: newSelection);
    } else {
      _state = _state.copyWith(selectedNodeIds: {nodeId});
    }
  }

  void selectNodes(Set<String> nodeIds) {
    _state = _state.copyWith(selectedNodeIds: nodeIds);
  }

  void clearSelection() {
    _state = _state.copyWith(selectedNodeIds: const {});
  }

  // ═══════════════════════════════════════════════════════════════════
  // 私有方法 - 节点拖动
  // ═══════════════════════════════════════════════════════════════════

  void _handleNodeClick(SpatialHitTestResult hitResult, PointerDownEvent event) {
    final nodeId = hitResult.nodeId;
    if (nodeId == null) return;

    // 选择节点
    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlLeft);
    selectNode(nodeId, addToSelection: isCtrlPressed);

    // 开始拖动
    _state = _state.copyWith(
      draggingNodeId: nodeId,
      dragStartPosition: event.localPosition,
    );

    // 记录所有选中节点的起始位置
    _nodeStartPositions = {};
    // 注意：实际的节点位置需要从外部获取
  }

  void _updateNodeDrag(PointerMoveEvent event) {
    // 拖动更新由外部回调处理
  }

  void _endNodeDrag() {
    _state = _state.copyWith(
      draggingNodeId: null,
      dragStartPosition: null,
      clearDragging: true,
    );
    _nodeStartPositions = {};
  }

  // ═══════════════════════════════════════════════════════════════════
  // 私有方法 - 锚点/连线
  // ═══════════════════════════════════════════════════════════════════

  void _handleAnchorClick(SpatialHitTestResult hitResult, PointerDownEvent event) {
    _state = _state.copyWith(
      connectionSourceAnchorId: hitResult.nodeId,
      connectionPreviewEnd: event.localPosition,
    );
  }

  void _updateConnectionPreview(Offset position) {
    _state = _state.copyWith(connectionPreviewEnd: position);
  }

  void _completeConnection(String targetNodeId) {
    // 连线创建由外部回调处理
    _cancelConnection();
  }

  void _cancelConnection() {
    _state = _state.copyWith(
      connectionSourceAnchorId: null,
      connectionPreviewEnd: null,
      clearConnection: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 私有方法 - 框选
  // ═══════════════════════════════════════════════════════════════════

  void _startBoxSelection(Offset position) {
    _state = _state.copyWith(
      selectionRect: Rect.fromLTWH(position.dx, position.dy, 0, 0),
    );
  }

  void _updateBoxSelection(Offset position) {
    if (_state.selectionRect == null) return;

    final start = _state.selectionRect!.topLeft;
    final rect = Rect.fromPoints(start, position);
    _state = _state.copyWith(selectionRect: rect);
  }

  void _endBoxSelection() {
    if (_state.selectionRect == null) {
      _state = _state.copyWith(clearSelection: true);
      return;
    }

    // 将屏幕坐标的框选矩形转换为场景坐标
    final screenRect = _state.selectionRect!;
    final topLeft = toScene(screenRect.topLeft);
    final bottomRight = toScene(screenRect.bottomRight);
    final sceneRect = Rect.fromPoints(topLeft, bottomRight);

    // 查询场景坐标中的节点
    final nodeIds = _spatialIndex.queryNodesInRect(sceneRect);
    _state = _state.copyWith(
      selectedNodeIds: nodeIds.toSet(),
      selectionRect: null,
      clearSelection: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 私有方法 - 平移
  // ═══════════════════════════════════════════════════════════════════

  bool _isPanning = false;
  Offset _panStart = Offset.zero;
  Matrix4 _panStartTransform = Matrix4.identity();

  void _startPan(Offset position) {
    _isPanning = true;
    _panStart = position;
    _panStartTransform = transformController.value.clone();
  }

  void _updatePan(Offset position) {
    if (!_isPanning) return;

    final delta = position - _panStart;
    final newMatrix = _panStartTransform.clone()..translate(delta.dx, delta.dy);
    transformController.value = newMatrix;
  }

  void _endPan() {
    _isPanning = false;
  }

  // ═══════════════════════════════════════════════════════════════════
  // 命令执行
  // ═══════════════════════════════════════════════════════════════════

  void executeCommand(DiagramCommand command) {
    _historyController.execute(command);
  }

  void undo() {
    _historyController.undo();
  }

  void redo() {
    _historyController.redo();
  }

  bool get canUndo => _historyController.canUndo;
  bool get canRedo => _historyController.canRedo;

  // ═══════════════════════════════════════════════════════════════════
  // 光标
  // ═══════════════════════════════════════════════════════════════════

  MouseCursor getCursor() {
    if (_isPanning) return SystemMouseCursors.grab;
    if (_state.isDragging) return SystemMouseCursors.grabbing;
    if (_state.hoveredNodeId != null) return SystemMouseCursors.grab;
    if (_state.isConnecting) return SystemMouseCursors.click;

    return SystemMouseCursors.basic;
  }

  // ═══════════════════════════════════════════════════════════════════
  // 重置
  // ═══════════════════════════════════════════════════════════════════

  void reset() {
    _state = const ERInteractionState();
    _registry.resetAll();
    _nodeStartPositions = {};
    _isPanning = false;
  }
}