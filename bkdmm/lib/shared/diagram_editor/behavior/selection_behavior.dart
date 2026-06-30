/// 框选行为
///
/// 处理框选和节点选择交互。
/// 优先级：40-49（选择/框选范围）
library;

import 'dart:ui';
import 'package:flutter/material.dart' show Matrix4, MatrixUtils;
import 'behavior_registry.dart';

/// 框选行为状态
class SelectionBehaviorState {
  /// 框选起始位置（屏幕坐标）
  final Offset? startPosition;

  /// 当前框选位置（屏幕坐标）
  final Offset? currentPosition;

  /// 是否正在框选
  final bool isSelecting;

  /// 是否为添加模式（Ctrl 按下）
  final bool isAddMode;

  const SelectionBehaviorState({
    this.startPosition,
    this.currentPosition,
    this.isSelecting = false,
    this.isAddMode = false,
  });

  /// 初始状态
  static const initial = SelectionBehaviorState();

  /// 计算框选矩形
  Rect? calculateSelectionRect() {
    if (startPosition == null || currentPosition == null || !isSelecting) {
      return null;
    }

    final left = startPosition!.dx < currentPosition!.dx
        ? startPosition!.dx
        : currentPosition!.dx;
    final top = startPosition!.dy < currentPosition!.dy
        ? startPosition!.dy
        : currentPosition!.dy;
    final right = startPosition!.dx > currentPosition!.dx
        ? startPosition!.dx
        : currentPosition!.dx;
    final bottom = startPosition!.dy > currentPosition!.dy
        ? startPosition!.dy
        : currentPosition!.dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 复制并修改
  SelectionBehaviorState copyWith({
    Offset? startPosition,
    Offset? currentPosition,
    bool? isSelecting,
    bool? isAddMode,
    bool clearPosition = false,
  }) {
    return SelectionBehaviorState(
      startPosition: clearPosition ? null : (startPosition ?? this.startPosition),
      currentPosition: clearPosition ? null : (currentPosition ?? this.currentPosition),
      isSelecting: isSelecting ?? this.isSelecting,
      isAddMode: isAddMode ?? this.isAddMode,
    );
  }
}

/// 框选行为
///
/// 处理以下操作：
/// 1. 点击空白区域清空选择
/// 2. 拖动创建框选区域
/// 3. 框选完成后选中框内的所有节点
///
/// ## 使用示例
///
/// ```dart
/// final behavior = SelectionBehavior(
///   priority: BehaviorPriority.selectionMin,
///   minSelectionSize: 10.0,
/// );
///
/// registry.register(behavior);
/// ```
class SelectionBehavior extends Behavior {
  /// 框选状态
  SelectionBehaviorState _state = SelectionBehaviorState.initial;

  /// 最小框选尺寸（像素）
  final double minSelectionSize;

  /// 回调：选择节点
  final void Function(Set<String> nodeIds, bool addToSelection)? onSelectionComplete;

  /// 回调：更新框选区域
  final void Function(Rect? selectionRect)? onSelectionRectUpdate;

  /// 回调：清空选择
  final VoidCallback? onClearSelection;

  SelectionBehavior({
    super.priority = BehaviorPriority.selectionMin,
    this.minSelectionSize = 10.0,
    this.onSelectionComplete,
    this.onSelectionRectUpdate,
    this.onClearSelection,
  }) : super(id: 'selection', name: 'Selection Behavior');

  /// 获取当前状态
  SelectionBehaviorState get state => _state;

  /// 是否正在框选
  bool get isSelecting => _state.isSelecting;

  /// 获取当前框选矩形
  Rect? get selectionRect => _state.calculateSelectionRect();

  /// 开始框选
  ///
  /// [startPosition] - 起始位置（屏幕坐标）
  /// [isAddMode] - 是否为添加模式（Ctrl 按下）
  void startSelection(Offset startPosition, {bool isAddMode = false}) {
    _state = SelectionBehaviorState(
      startPosition: startPosition,
      currentPosition: startPosition,
      isSelecting: true,
      isAddMode: isAddMode,
    );

    // 通知框选区域更新
    onSelectionRectUpdate?.call(selectionRect);

    // 如果不是添加模式，清空当前选择
    if (!isAddMode) {
      onClearSelection?.call();
    }
  }

  /// 更新框选位置
  ///
  /// [currentPosition] - 当前位置（屏幕坐标）
  void updateSelection(Offset currentPosition) {
    if (!_state.isSelecting) return;

    _state = _state.copyWith(currentPosition: currentPosition);
    onSelectionRectUpdate?.call(selectionRect);
  }

  /// 完成框选
  ///
  /// [nodesInRect] - 框选区域内的节点 ID 集合
  void completeSelection(Set<String> nodesInRect) {
    if (!_state.isSelecting) return;

    final rect = selectionRect;

    // 检查框选区域是否足够大
    if (rect != null &&
        rect.width >= minSelectionSize &&
        rect.height >= minSelectionSize) {
      // 框选有效，选中框内的节点
      onSelectionComplete?.call(nodesInRect, _state.isAddMode);
    } else {
      // 框选区域太小，视为点击清空选择
      if (!_state.isAddMode) {
        onClearSelection?.call();
      }
    }

    // 重置状态
    _state = SelectionBehaviorState.initial;
    onSelectionRectUpdate?.call(null);
  }

  /// 取消框选
  void cancelSelection() {
    _state = SelectionBehaviorState.initial;
    onSelectionRectUpdate?.call(null);
  }

  @override
  void reset() {
    cancelSelection();
  }

  @override
  String toString() =>
      'SelectionBehavior(priority=$priority, selecting=$isSelecting)';
}

/// 框选行为配置
class SelectionBehaviorConfig {
  /// 最小框选尺寸（像素）
  final double minSelectionSize;

  /// 是否启用框选
  final bool enabled;

  /// 框选框颜色
  final Color? selectionBoxColor;

  /// 框选框边框宽度
  final double? selectionBoxStrokeWidth;

  const SelectionBehaviorConfig({
    this.minSelectionSize = 10.0,
    this.enabled = true,
    this.selectionBoxColor,
    this.selectionBoxStrokeWidth,
  });

  /// 默认配置
  static const defaultConfig = SelectionBehaviorConfig();

  /// 复制并修改
  SelectionBehaviorConfig copyWith({
    double? minSelectionSize,
    bool? enabled,
    Color? selectionBoxColor,
    double? selectionBoxStrokeWidth,
  }) {
    return SelectionBehaviorConfig(
      minSelectionSize: minSelectionSize ?? this.minSelectionSize,
      enabled: enabled ?? this.enabled,
      selectionBoxColor: selectionBoxColor ?? this.selectionBoxColor,
      selectionBoxStrokeWidth:
          selectionBoxStrokeWidth ?? this.selectionBoxStrokeWidth,
    );
  }
}

/// 框选工具类
///
/// 提供框选相关的辅助方法
class SelectionUtils {
  SelectionUtils._();

  /// 计算场景坐标下的框选矩形
  ///
  /// [screenRect] - 屏幕坐标下的框选矩形
  /// [transform] - 变换矩阵
  static Rect screenToSceneRect(Rect screenRect, Matrix4 transform) {
    final inverse = Matrix4.tryInvert(transform);
    if (inverse == null) return screenRect;

    final topLeft = MatrixUtils.transformPoint(inverse, screenRect.topLeft);
    final topRight = MatrixUtils.transformPoint(inverse, screenRect.topRight);
    final bottomLeft =
        MatrixUtils.transformPoint(inverse, screenRect.bottomLeft);
    final bottomRight =
        MatrixUtils.transformPoint(inverse, screenRect.bottomRight);

    final minX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx]
        .reduce((a, b) => a < b ? a : b);
    final maxX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx]
        .reduce((a, b) => a > b ? a : b);
    final minY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy]
        .reduce((a, b) => a < b ? a : b);
    final maxY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy]
        .reduce((a, b) => a > b ? a : b);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 判断节点是否在框选区域内
  ///
  /// [nodeBounds] - 节点边界（场景坐标）
  /// [selectionRect] - 框选矩形（场景坐标）
  /// [partialSelect] - 是否允许部分选择（默认 false，需要完全包含）
  static bool isNodeInSelection(
    Rect nodeBounds,
    Rect selectionRect, {
    bool partialSelect = false,
  }) {
    if (partialSelect) {
      // 部分相交即可
      return nodeBounds.overlaps(selectionRect);
    } else {
      // 完全包含
      return selectionRect.contains(nodeBounds.topLeft) &&
          selectionRect.contains(nodeBounds.topRight) &&
          selectionRect.contains(nodeBounds.bottomLeft) &&
          selectionRect.contains(nodeBounds.bottomRight);
    }
  }

  /// 过滤框选区域内的节点
  ///
  /// [nodes] - 节点映射（ID -> 边界）
  /// [selectionRect] - 框选矩形（场景坐标）
  /// [partialSelect] - 是否允许部分选择
  static Set<String> filterNodesInSelection(
    Map<String, Rect> nodes,
    Rect selectionRect, {
    bool partialSelect = false,
  }) {
    return nodes.entries
        .where((entry) =>
            isNodeInSelection(entry.value, selectionRect, partialSelect: partialSelect))
        .map((entry) => entry.key)
        .toSet();
  }
}
