/// 节点拖动处理器
///
/// 处理节点的拖动事件，支持单节点和多节点拖动。
/// 优先级：20（在锚点之后，因为节点包含锚点）
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';
import 'diagram_handler.dart';

/// 节点拖动处理器
///
/// 当用户在节点上按下并拖动时，移动节点位置。
/// 支持多选拖动（同时移动多个选中的节点）。
class NodeDragHandler extends DiagramEventHandler {
  /// 拖动阈值（像素），超过此距离才算拖动
  final double dragThreshold;

  /// 是否正在拖动
  bool _isDragging = false;

  /// 拖动起始位置（屏幕坐标）
  Offset? _dragStartPosition;

  /// 当前拖动的节点 ID
  String? _draggedNodeId;

  /// 多选拖动时的起始位置
  Map<String, Offset> _multiDragStartPositions = {};

  /// 是否已经超过拖动阈值
  bool _hasExceededThreshold = false;

  NodeDragHandler({
    super.priority = 20,
    super.name = 'NodeDragHandler',
    this.dragThreshold = 5.0,
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 只在编辑模式下处理
    if (!context.isEditMode) return false;

    // 处理指针按下：检查是否在节点上
    if (event is DiagramPointerDownEvent) {
      return event.isLeftButton && context.isOnNode;
    }

    // 处理指针移动：正在拖动时
    if (event is DiagramPointerMoveEvent) {
      return _isDragging && event.isLeftButton;
    }

    // 处理指针释放：结束拖动
    if (event is DiagramPointerUpEvent) {
      return _isDragging;
    }

    return false;
  }

  @override
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    if (event is DiagramPointerDownEvent) {
      return _handlePointerDown(event, context, updateState);
    }

    if (event is DiagramPointerMoveEvent) {
      return _handlePointerMove(event, context, updateState);
    }

    if (event is DiagramPointerUpEvent) {
      return _handlePointerUp(event, context, updateState);
    }

    return false;
  }

  /// 处理指针按下
  bool _handlePointerDown(
    DiagramPointerDownEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    final nodeId = context.hitNodeId;
    if (nodeId == null) return false;

    _draggedNodeId = nodeId;
    _dragStartPosition = event.localPosition;
    _hasExceededThreshold = false;
    _isDragging = true;

    // 选择节点
    if (event.isCtrlPressed) {
      // Ctrl+点击：切换选择
      updateState(HandlerUpdate.selectNode(nodeId, addToSelection: true));
    } else if (!context.state.selection.selectedNodeIds.contains(nodeId)) {
      // 点击未选中的节点：单选
      updateState(HandlerUpdate.selectNode(nodeId));
    }
    // 如果点击已选中的节点，保持当前选择（用于多选拖动）

    // 开始拖动
    updateState(HandlerUpdate.startDrag(nodeId, event.localPosition));

    return true;
  }

  /// 处理指针移动
  bool _handlePointerMove(
    DiagramPointerMoveEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isDragging || _dragStartPosition == null) return false;

    // 检查是否超过拖动阈值
    final delta = event.localPosition - _dragStartPosition!;
    if (!_hasExceededThreshold) {
      if (delta.distance > dragThreshold) {
        _hasExceededThreshold = true;
      } else {
        // 还未超过阈值，不触发拖动
        return true;
      }
    }

    // 更新拖动位置
    updateState(HandlerUpdate.updateDrag(event.localPosition));

    return true;
  }

  /// 处理指针释放
  bool _handlePointerUp(
    DiagramPointerUpEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isDragging) return false;

    // 结束拖动
    updateState(HandlerUpdate.endDrag());

    // 重置状态
    _isDragging = false;
    _dragStartPosition = null;
    _draggedNodeId = null;
    _multiDragStartPositions = {};
    _hasExceededThreshold = false;

    return true;
  }

  @override
  MouseCursor? getCursor(DiagramContext context) {
    if (context.isOnNode && context.isEditMode) {
      if (_isDragging) {
        return SystemMouseCursors.grabbing;
      }
      return SystemMouseCursors.grab;
    }
    return null;
  }

  @override
  void reset() {
    _isDragging = false;
    _dragStartPosition = null;
    _draggedNodeId = null;
    _multiDragStartPositions = {};
    _hasExceededThreshold = false;
  }

  /// 是否正在拖动
  bool get isDragging => _isDragging;

  /// 当前拖动的节点 ID
  String? get draggedNodeId => _draggedNodeId;
}
