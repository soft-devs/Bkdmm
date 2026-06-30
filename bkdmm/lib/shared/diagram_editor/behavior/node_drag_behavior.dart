/// 节点拖拽行为
///
/// 提供可复用的节点拖拽交互行为，支持单节点和多节点拖拽。
/// 可以附加到任何支持 Behavior 协议的组件上。
library;

import 'package:flutter/material.dart';
import 'behavior.dart';

/// 节点拖拽状态
class NodeDragState {
  /// 拖拽的节点 ID
  final String nodeId;

  /// 拖拽起始位置（场景坐标）
  final Offset startPosition;

  /// 拖拽起始时的节点位置
  final Offset nodeStartPosition;

  /// 是否已超过拖拽阈值
  final bool hasExceededThreshold;

  /// 当前拖拽位置（场景坐标）
  final Offset currentPosition;

  /// 是否为多选拖拽
  final bool isMultiDrag;

  /// 多选拖拽时的其他节点 ID
  final Set<String> additionalNodeIds;

  /// 其他节点起始位置
  final Map<String, Offset> additionalNodeStartPositions;

  const NodeDragState({
    required this.nodeId,
    required this.startPosition,
    required this.nodeStartPosition,
    this.hasExceededThreshold = false,
    this.currentPosition = Offset.zero,
    this.isMultiDrag = false,
    this.additionalNodeIds = const {},
    this.additionalNodeStartPositions = const {},
  });

  /// 创建副本
  NodeDragState copyWith({
    String? nodeId,
    Offset? startPosition,
    Offset? nodeStartPosition,
    bool? hasExceededThreshold,
    Offset? currentPosition,
    bool? isMultiDrag,
    Set<String>? additionalNodeIds,
    Map<String, Offset>? additionalNodeStartPositions,
  }) {
    return NodeDragState(
      nodeId: nodeId ?? this.nodeId,
      startPosition: startPosition ?? this.startPosition,
      nodeStartPosition: nodeStartPosition ?? this.nodeStartPosition,
      hasExceededThreshold: hasExceededThreshold ?? this.hasExceededThreshold,
      currentPosition: currentPosition ?? this.currentPosition,
      isMultiDrag: isMultiDrag ?? this.isMultiDrag,
      additionalNodeIds: additionalNodeIds ?? this.additionalNodeIds,
      additionalNodeStartPositions:
          additionalNodeStartPositions ?? this.additionalNodeStartPositions,
    );
  }
}

/// 节点拖拽行为更新类型
enum NodeDragUpdateType {
  /// 选择节点
  selectNode,

  /// 开始拖拽
  startDrag,

  /// 更新拖拽位置
  updateDrag,

  /// 结束拖拽
  endDrag,

  /// 取消拖拽
  cancelDrag,
}

/// 节点拖拽行为更新
class NodeDragUpdate extends BehaviorUpdate {
  /// 更新类型
  final NodeDragUpdateType dragType;

  /// 拖拽的节点 ID
  final String? nodeId;

  /// 当前位置
  final Offset? position;

  /// 增量移动
  final Offset? delta;

  /// 是否添加到选择
  final bool? addToSelection;

  /// 多选拖拽的所有节点 ID
  final Set<String>? allNodeIds;

  NodeDragUpdate({
    required this.dragType,
    this.nodeId,
    this.position,
    this.delta,
    this.addToSelection,
    this.allNodeIds,
  }) : super(type: dragType.name);

  /// 创建选择节点更新
  factory NodeDragUpdate.selectNode(
    String nodeId, {
    bool addToSelection = false,
  }) {
    return NodeDragUpdate(
      dragType: NodeDragUpdateType.selectNode,
      nodeId: nodeId,
      addToSelection: addToSelection,
    );
  }

  /// 创建开始拖拽更新
  factory NodeDragUpdate.startDrag(String nodeId, Offset startPosition) {
    return NodeDragUpdate(
      dragType: NodeDragUpdateType.startDrag,
      nodeId: nodeId,
      position: startPosition,
    );
  }

  /// 创建更新拖拽更新
  factory NodeDragUpdate.updateDrag(Offset position, Offset delta) {
    return NodeDragUpdate(
      dragType: NodeDragUpdateType.updateDrag,
      position: position,
      delta: delta,
    );
  }

  /// 创建结束拖拽更新
  factory NodeDragUpdate.endDrag({
    String? nodeId,
    Set<String>? allNodeIds,
  }) {
    return NodeDragUpdate(
      dragType: NodeDragUpdateType.endDrag,
      nodeId: nodeId,
      allNodeIds: allNodeIds,
    );
  }

  /// 创建取消拖拽更新
  factory NodeDragUpdate.cancelDrag() {
    return NodeDragUpdate(
      dragType: NodeDragUpdateType.cancelDrag,
    );
  }
}

/// 节点拖拽行为
///
/// 当用户在节点上按下并拖动时，移动节点位置。
/// 支持多选拖动（同时移动多个选中的节点）。
///
/// ## 使用示例
///
/// ```dart
/// final dragBehavior = NodeDragBehavior(
///   dragThreshold: 5.0,
///   getNodePosition: (id) => nodes[id]?.position,
///   getSelectedNodes: () => state.selectedNodeIds,
/// );
///
/// // 添加到行为列表
/// behaviors.add(dragBehavior);
/// ```
class NodeDragBehavior extends Behavior<NodeDragState> {
  /// 拖拽阈值（像素），超过此距离才算拖拽
  final double dragThreshold;

  /// 获取节点位置的回调
  final Offset Function(String nodeId)? getNodePosition;

  /// 获取选中节点集合的回调
  final Set<String> Function()? getSelectedNodes;

  /// 是否启用多选拖拽
  final bool enableMultiDrag;

  NodeDragBehavior({
    super.priority = 20,
    super.name = 'NodeDrag',
    this.dragThreshold = 5.0,
    this.getNodePosition,
    this.getSelectedNodes,
    this.enableMultiDrag = true,
  });

  /// 是否正在拖拽
  bool get isDragging => state != null && state!.hasExceededThreshold;

  /// 当前拖拽的节点 ID
  String? get draggedNodeId => state?.nodeId;

  @override
  bool canHandle(BehaviorEvent event, BehaviorContext context) {
    // 只在编辑模式下处理（通过上下文判断）
    if (!_isEditMode(context)) return false;

    // 处理指针按下：检查是否在节点上
    if (event is NodeDragPointerDown) {
      return event.isLeftButton && context.isOnNode;
    }

    // 处理指针移动：正在拖拽时
    if (event is NodeDragPointerMove) {
      return isActive && event.isLeftButton;
    }

    // 处理指针抬起：结束拖拽
    if (event is NodeDragPointerUp) {
      return isActive;
    }

    return false;
  }

  @override
  Future<bool> handle(
    BehaviorEvent event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) async {
    if (event is NodeDragPointerDown) {
      return _handlePointerDown(event, context, update);
    }

    if (event is NodeDragPointerMove) {
      return _handlePointerMove(event, context, update);
    }

    if (event is NodeDragPointerUp) {
      return _handlePointerUp(event, context, update);
    }

    return false;
  }

  /// 处理指针按下
  bool _handlePointerDown(
    NodeDragPointerDown event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    final nodeId = context.hitId;
    if (nodeId == null) return false;

    final nodePosition = getNodePosition?.call(nodeId) ?? Offset.zero;
    final selectedNodes = getSelectedNodes?.call() ?? {};
    final isSelected = selectedNodes.contains(nodeId);

    // 判断是否为多选拖拽
    final isMultiDrag =
        enableMultiDrag && isSelected && selectedNodes.length > 1;

    // 收集其他选中的节点
    Set<String> additionalNodeIds = {};
    Map<String, Offset> additionalNodeStartPositions = {};

    if (isMultiDrag) {
      for (final id in selectedNodes) {
        if (id != nodeId) {
          additionalNodeIds.add(id);
          final pos = getNodePosition?.call(id);
          if (pos != null) {
            additionalNodeStartPositions[id] = pos;
          }
        }
      }
    }

    // 更新状态
    state = NodeDragState(
      nodeId: nodeId,
      startPosition: event.localPosition,
      nodeStartPosition: nodePosition,
      hasExceededThreshold: false,
      currentPosition: event.localPosition,
      isMultiDrag: isMultiDrag,
      additionalNodeIds: additionalNodeIds,
      additionalNodeStartPositions: additionalNodeStartPositions,
    );

    // 选择节点
    if (event.isCtrlPressed) {
      // Ctrl+点击：切换选择
      update(NodeDragUpdate.selectNode(nodeId, addToSelection: true));
    } else if (!isSelected) {
      // 点击未选中的节点：单选
      update(NodeDragUpdate.selectNode(nodeId));
    }
    // 如果点击已选中的节点，保持当前选择（用于多选拖拽）

    return true;
  }

  /// 处理指针移动
  bool _handlePointerMove(
    NodeDragPointerMove event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    // 检查是否超过拖拽阈值
    final delta = event.localPosition - state!.startPosition;
    final hasExceededThreshold =
        state!.hasExceededThreshold || delta.distance > dragThreshold;

    // 更新状态
    state = state!.copyWith(
      hasExceededThreshold: hasExceededThreshold,
      currentPosition: event.localPosition,
    );

    // 如果已超过阈值，发送更新
    if (hasExceededThreshold) {
      update(NodeDragUpdate.updateDrag(
        event.localPosition,
        event.delta,
      ));
    }

    return true;
  }

  /// 处理指针抬起
  bool _handlePointerUp(
    NodeDragPointerUp event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    // 发送结束拖拽更新
    if (state!.hasExceededThreshold) {
      final allNodeIds = <String>{state!.nodeId};
      if (state!.isMultiDrag) {
        allNodeIds.addAll(state!.additionalNodeIds);
      }
      update(NodeDragUpdate.endDrag(
        nodeId: state!.nodeId,
        allNodeIds: allNodeIds,
      ));
    }

    // 重置状态
    reset();

    return true;
  }

  @override
  MouseCursor? getCursor(BehaviorContext context) {
    if (context.isOnNode && _isEditMode(context)) {
      if (isDragging) {
        return SystemMouseCursors.grabbing;
      }
      return SystemMouseCursors.grab;
    }
    return null;
  }

  @override
  void reset() {
    state = null;
  }

  /// 判断是否为编辑模式
  bool _isEditMode(BehaviorContext context) {
    // 默认为编辑模式，子类可以覆盖
    return true;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 事件类型定义
// ═══════════════════════════════════════════════════════════════════════════════

/// 节点拖拽指针按下事件
class NodeDragPointerDown extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 按下的按钮
  final int buttons;

  const NodeDragPointerDown({
    required this.localPosition,
    required this.position,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;

  /// 是否中键按下
  bool get isMiddleButton => buttons & kTertiaryMouseButton != 0;

  /// 是否按下 Ctrl
  final bool isCtrlPressed;

  /// 是否按下 Shift
  final bool isShiftPressed;

  /// 是否按下 Alt
  final bool isAltPressed;
}

/// 节点拖拽指针移动事件
class NodeDragPointerMove extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 移动增量
  final Offset delta;

  /// 当前按下的按钮
  final int buttons;

  const NodeDragPointerMove({
    required this.localPosition,
    required this.position,
    required this.delta,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;
}

/// 节点拖拽指针抬起事件
class NodeDragPointerUp extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  const NodeDragPointerUp({
    required this.localPosition,
    required this.position,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 鼠标按钮常量
const int kPrimaryMouseButton = 1;
const int kSecondaryMouseButton = 2;
const int kTertiaryMouseButton = 4;
