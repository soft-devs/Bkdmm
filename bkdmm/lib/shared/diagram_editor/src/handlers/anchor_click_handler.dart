/// 锚点点击处理器
///
/// 处理锚点的点击事件，用于开始连线操作。
/// 优先级：10（最高，因为锚点是最小的交互区域）
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';
import 'diagram_handler.dart';

/// 锚点点击处理器
///
/// 当用户点击锚点时，开始连线操作。
/// 支持双击检测（可选功能）。
class AnchorClickHandler extends DiagramEventHandler {
  /// 双击时间阈值（毫秒）
  final int doubleTapThresholdMs;

  /// 锚点命中半径（像素）
  final double hitRadius;

  /// 上次点击的锚点 ID
  String? _lastTappedAnchorId;

  /// 上次点击时间
  DateTime? _lastTapTime;

  AnchorClickHandler({
    super.priority = 10,
    super.name = 'AnchorClickHandler',
    this.doubleTapThresholdMs = 300,
    this.hitRadius = 12.0,
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 只处理指针按下事件
    if (event is! DiagramPointerDownEvent) return false;

    // 只处理左键
    if (!event.isLeftButton) return false;

    // 必须在编辑模式
    if (!context.isEditMode) return false;

    // 检查是否点击在锚点上
    return context.isOnAnchor;
  }

  @override
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    if (event is! DiagramPointerDownEvent) return false;

    final anchor = context.hitAnchor;
    if (anchor == null) return false;

    // 检查是否是双击
    final isDoubleTap = _checkDoubleTap(anchor.id);

    if (isDoubleTap) {
      // 双击锚点：触发特殊操作（如快速创建关系）
      updateState(HandlerUpdate.startConnection(
        anchor.id,
        anchor.position,
      ));
      // 清除双击状态
      _lastTappedAnchorId = null;
      _lastTapTime = null;
    } else {
      // 单击锚点：开始连线
      updateState(HandlerUpdate.startConnection(
        anchor.id,
        anchor.position,
      ));

      // 记录点击信息用于双击检测
      _lastTappedAnchorId = anchor.id;
      _lastTapTime = DateTime.now();
    }

    return true;
  }

  /// 检查是否是双击
  bool _checkDoubleTap(String anchorId) {
    if (_lastTappedAnchorId == null || _lastTapTime == null) {
      return false;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastTapTime!).inMilliseconds;

    return _lastTappedAnchorId == anchorId &&
        elapsed < doubleTapThresholdMs;
  }

  @override
  MouseCursor? getCursor(DiagramContext context) {
    if (context.isOnAnchor && context.isEditMode) {
      return SystemMouseCursors.click;
    }
    return null;
  }

  @override
  void reset() {
    _lastTappedAnchorId = null;
    _lastTapTime = null;
  }
}

/// 连线处理器
///
/// 处理连线创建过程中的事件。
/// 优先级：30（在锚点点击和节点拖动之后）
class ConnectionHandler extends DiagramEventHandler {
  /// 当前连线的源锚点
  String? _sourceAnchorId;

  ConnectionHandler({
    super.priority = 30,
    super.name = 'ConnectionHandler',
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 只在编辑模式下处理
    if (!context.isEditMode) return false;

    // 如果正在连线，处理移动和释放事件
    if (_sourceAnchorId != null) {
      return event is DiagramPointerMoveEvent ||
          event is DiagramPointerUpEvent;
    }

    return false;
  }

  @override
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    if (_sourceAnchorId == null) return false;

    if (event is DiagramPointerMoveEvent) {
      // 更新连线预览
      updateState(HandlerUpdate.updateConnectionPreview(event.localPosition));
      return true;
    }

    if (event is DiagramPointerUpEvent) {
      // 完成或取消连线
      if (context.isOnAnchor && context.hitAnchor?.id != _sourceAnchorId) {
        // 完成连线
        updateState(HandlerUpdate.completeConnection(context.hitAnchor!.id));
      } else {
        // 取消连线
        updateState(HandlerUpdate.cancelConnection());
      }

      // 重置状态
      _sourceAnchorId = null;
      return true;
    }

    return false;
  }

  /// 开始连线（由 AnchorClickHandler 调用）
  void startConnection(String anchorId, Offset position) {
    _sourceAnchorId = anchorId;
  }

  /// 获取当前连线状态
  bool get isConnecting => _sourceAnchorId != null;

  /// 获取源锚点 ID
  String? get sourceAnchorId => _sourceAnchorId;

  @override
  MouseCursor? getCursor(DiagramContext context) {
    if (_sourceAnchorId != null) {
      return SystemMouseCursors.click;
    }
    return null;
  }

  @override
  void reset() {
    _sourceAnchorId = null;
  }
}
