/// 画布平移处理器
///
/// 处理画布的平移（拖动移动视图）事件。
/// 优先级：100（最低，作为最后的 fallback）
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';
import 'diagram_handler.dart';

/// 画布平移处理器
///
/// 处理画布的平移操作：
/// - 预览模式：左键拖动平移画布
/// - 编辑模式：右键拖动平移画布
class CanvasPanHandler extends DiagramEventHandler {
  /// 是否正在平移
  bool _isPanning = false;

  /// 平移起始位置（屏幕坐标）
  Offset? _panStartPosition;

  /// 平移起始时的变换矩阵
  Matrix4? _panStartTransform;

  CanvasPanHandler({
    super.priority = 100,
    super.name = 'CanvasPanHandler',
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 预览模式：左键平移
    if (context.isPreviewMode) {
      if (event is DiagramPointerDownEvent) {
        return event.isLeftButton;
      }
      if (event is DiagramPointerMoveEvent) {
        return _isPanning && event.isLeftButton;
      }
      if (event is DiagramPointerUpEvent) {
        return _isPanning;
      }
    }

    // 编辑模式：右键平移
    if (context.isEditMode) {
      if (event is DiagramPointerDownEvent) {
        return event.isRightButton;
      }
      if (event is DiagramPointerMoveEvent) {
        return _isPanning && event.isRightButton;
      }
      if (event is DiagramPointerUpEvent) {
        return _isPanning;
      }
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
    _isPanning = true;
    _panStartPosition = event.localPosition;
    _panStartTransform = context.transform.clone();

    return true;
  }

  /// 处理指针移动
  bool _handlePointerMove(
    DiagramPointerMoveEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isPanning || _panStartPosition == null) return false;

    // 计算平移增量
    final delta = event.localPosition - _panStartPosition!;

    // 更新平移
    updateState(HandlerUpdate.panCanvas(delta));

    return true;
  }

  /// 处理指针释放
  bool _handlePointerUp(
    DiagramPointerUpEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isPanning) return false;

    // 重置状态
    _isPanning = false;
    _panStartPosition = null;
    _panStartTransform = null;

    return true;
  }

  @override
  MouseCursor? getCursor(DiagramContext context) {
    if (context.isPreviewMode) {
      return SystemMouseCursors.grab;
    }
    if (context.isEditMode && _isPanning) {
      return SystemMouseCursors.grabbing;
    }
    return null;
  }

  @override
  void reset() {
    _isPanning = false;
    _panStartPosition = null;
    _panStartTransform = null;
  }

  /// 是否正在平移
  bool get isPanning => _isPanning;
}

/// 悬停处理器
///
/// 处理鼠标悬停事件，更新悬停状态。
/// 优先级：200（非常低，仅用于状态更新）
class HoverHandler extends DiagramEventHandler {
  /// 当前悬停的节点 ID
  String? _hoveredNodeId;

  HoverHandler({
    super.priority = 200,
    super.name = 'HoverHandler',
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 只处理悬停事件
    return event is DiagramHoverEvent;
  }

  @override
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    if (event is! DiagramHoverEvent) return false;

    // 检查悬停位置
    final scenePos = context.toScene(event.localPosition);

    // 更新悬停状态
    if (context.isOnNode) {
      final nodeId = context.hitNodeId;
      if (nodeId != _hoveredNodeId) {
        _hoveredNodeId = nodeId;
        updateState(HandlerUpdate.setHoveredNode(nodeId));
      }
    } else if (_hoveredNodeId != null) {
      // 离开节点，清除悬停
      _hoveredNodeId = null;
      updateState(HandlerUpdate.setHoveredNode(null));
    }

    // 悬停事件不需要阻止其他处理器
    return false;
  }

  @override
  void reset() {
    _hoveredNodeId = null;
  }

  /// 当前悬停的节点 ID
  String? get hoveredNodeId => _hoveredNodeId;
}