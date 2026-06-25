/// 选择处理器
///
/// 处理框选和节点选择事件。
/// 优先级：50（中等优先级，在锚点和节点之后）
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';
import 'diagram_handler.dart';

/// 选择处理器
///
/// 处理以下操作：
/// 1. 点击空白区域清空选择
/// 2. 拖动创建框选区域
/// 3. 框选完成后选中框内的所有节点
class SelectionHandler extends DiagramEventHandler {
  /// 框选起始位置（屏幕坐标）
  Offset? _selectionStart;

  /// 当前框选位置
  Offset? _selectionCurrent;

  /// 是否正在框选
  bool _isSelecting = false;

  /// 最小框选尺寸（像素）
  final double minSelectionSize;

  SelectionHandler({
    super.priority = 50,
    super.name = 'SelectionHandler',
    this.minSelectionSize = 10.0,
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // 只在编辑模式下处理
    if (!context.isEditMode) return false;

    // 指针按下：在空白区域时开始框选
    if (event is DiagramPointerDownEvent) {
      return event.isLeftButton && context.isOnCanvas;
    }

    // 指针移动：正在框选时更新
    if (event is DiagramPointerMoveEvent) {
      return _isSelecting && event.isLeftButton;
    }

    // 指针释放：完成框选
    if (event is DiagramPointerUpEvent) {
      return _isSelecting;
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
    // 在空白区域按下，开始框选
    _selectionStart = event.localPosition;
    _selectionCurrent = event.localPosition;
    _isSelecting = true;

    // 如果未按下 Ctrl，清空当前选择
    if (!event.isCtrlPressed) {
      updateState(HandlerUpdate.clearSelection());
    }

    // 开始框选
    updateState(HandlerUpdate.startBoxSelection(event.localPosition));

    return true;
  }

  /// 处理指针移动
  bool _handlePointerMove(
    DiagramPointerMoveEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isSelecting) return false;

    _selectionCurrent = event.localPosition;

    // 更新框选区域
    updateState(HandlerUpdate.updateBoxSelection(event.localPosition));

    return true;
  }

  /// 处理指针释放
  bool _handlePointerUp(
    DiagramPointerUpEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) {
    if (!_isSelecting) return false;

    // 计算框选区域
    final rect = _calculateSelectionRect();

    // 如果框选区域太小，视为点击清空选择
    if (rect.width < minSelectionSize && rect.height < minSelectionSize) {
      updateState(HandlerUpdate.clearSelection());
    } else {
      // 完成框选，选中框内的节点
      updateState(HandlerUpdate.completeBoxSelection());
    }

    // 重置状态
    _isSelecting = false;
    _selectionStart = null;
    _selectionCurrent = null;

    return true;
  }

  /// 计算框选矩形
  Rect _calculateSelectionRect() {
    if (_selectionStart == null || _selectionCurrent == null) {
      return Rect.zero;
    }

    final left = _selectionStart!.dx < _selectionCurrent!.dx
        ? _selectionStart!.dx
        : _selectionCurrent!.dx;
    final top = _selectionStart!.dy < _selectionCurrent!.dy
        ? _selectionStart!.dy
        : _selectionCurrent!.dy;
    final right = _selectionStart!.dx > _selectionCurrent!.dx
        ? _selectionStart!.dx
        : _selectionCurrent!.dx;
    final bottom = _selectionStart!.dy > _selectionCurrent!.dy
        ? _selectionStart!.dy
        : _selectionCurrent!.dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 获取当前框选矩形
  Rect? get selectionRect {
    if (!_isSelecting) return null;
    return _calculateSelectionRect();
  }

  @override
  void reset() {
    _isSelecting = false;
    _selectionStart = null;
    _selectionCurrent = null;
  }

  /// 是否正在框选
  bool get isSelecting => _isSelecting;
}