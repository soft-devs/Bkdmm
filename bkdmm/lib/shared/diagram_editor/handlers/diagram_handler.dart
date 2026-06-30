/// 图表事件处理器抽象
///
/// 定义事件处理器的接口和优先级机制
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';

/// 图表事件处理器抽象类
///
/// 所有事件处理器都需要继承此类并实现 canHandle 和 handle 方法。
/// 处理器按优先级排序，优先级低的先处理。
abstract class DiagramEventHandler {
  /// 处理器优先级
  ///
  /// 数值越小优先级越高，越先被处理。
  /// 例如：锚点点击处理器优先级为 10，节点拖动处理器优先级为 20。
  final int priority;

  /// 处理器名称（用于调试）
  final String name;

  const DiagramEventHandler({
    this.priority = 100,
    this.name = 'unnamed',
  });

  /// 判断是否可以处理该事件
  ///
  /// 返回 true 表示可以处理，事件将传递给 handle 方法。
  /// 返回 false 表示不处理，事件将传递给下一个处理器。
  bool canHandle(DiagramEvent event, DiagramContext context);

  /// 处理事件
  ///
  /// 返回 true 表示事件已处理，不再传递给后续处理器。
  /// 返回 false 表示事件未被完全处理，继续传递。
  ///
  /// [event] - 图表事件
  /// [context] - 图表上下文
  /// [updateState] - 更新状态的回调函数
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  );

  /// 获取当前光标样式
  ///
  /// 如果处理器处于活动状态，返回对应的光标样式。
  MouseCursor? getCursor(DiagramContext context) => null;

  /// 重置处理器状态
  ///
  /// 当交互结束或取消时调用。
  void reset() {}

  @override
  String toString() => 'DiagramEventHandler($name, priority=$priority)';
}

/// 处理器状态更新
///
/// 处理器通过此对象请求状态更新
class HandlerUpdate {
  /// 更新类型
  final HandlerUpdateType type;

  /// 相关数据
  final Map<String, dynamic> data;

  const HandlerUpdate({
    required this.type,
    this.data = const {},
  });

  /// 创建选择节点更新
  factory HandlerUpdate.selectNode(String nodeId, {bool addToSelection = false}) {
    return HandlerUpdate(
      type: HandlerUpdateType.selectNode,
      data: {'nodeId': nodeId, 'addToSelection': addToSelection},
    );
  }

  /// 创建取消选择更新
  factory HandlerUpdate.deselectNode(String nodeId) {
    return HandlerUpdate(
      type: HandlerUpdateType.deselectNode,
      data: {'nodeId': nodeId},
    );
  }

  /// 创建清空选择更新
  factory HandlerUpdate.clearSelection() {
    return const HandlerUpdate(type: HandlerUpdateType.clearSelection);
  }

  /// 创建开始拖拽更新
  factory HandlerUpdate.startDrag(String nodeId, Offset startPosition) {
    return HandlerUpdate(
      type: HandlerUpdateType.startDrag,
      data: {'nodeId': nodeId, 'startPosition': startPosition},
    );
  }

  /// 创建更新拖拽更新
  factory HandlerUpdate.updateDrag(Offset currentPosition) {
    return HandlerUpdate(
      type: HandlerUpdateType.updateDrag,
      data: {'currentPosition': currentPosition},
    );
  }

  /// 创建结束拖拽更新
  factory HandlerUpdate.endDrag() {
    return const HandlerUpdate(type: HandlerUpdateType.endDrag);
  }

  /// 创建开始连线更新
  factory HandlerUpdate.startConnection(String anchorId, Offset position) {
    return HandlerUpdate(
      type: HandlerUpdateType.startConnection,
      data: {'anchorId': anchorId, 'position': position},
    );
  }

  /// 创建更新连线预览更新
  factory HandlerUpdate.updateConnectionPreview(Offset position) {
    return HandlerUpdate(
      type: HandlerUpdateType.updateConnectionPreview,
      data: {'position': position},
    );
  }

  /// 创建完成连线更新
  factory HandlerUpdate.completeConnection(String targetAnchorId) {
    return HandlerUpdate(
      type: HandlerUpdateType.completeConnection,
      data: {'targetAnchorId': targetAnchorId},
    );
  }

  /// 创建取消连线更新
  factory HandlerUpdate.cancelConnection() {
    return const HandlerUpdate(type: HandlerUpdateType.cancelConnection);
  }

  /// 创建开始框选更新
  factory HandlerUpdate.startBoxSelection(Offset startPosition) {
    return HandlerUpdate(
      type: HandlerUpdateType.startBoxSelection,
      data: {'startPosition': startPosition},
    );
  }

  /// 创建更新框选更新
  factory HandlerUpdate.updateBoxSelection(Offset currentPosition) {
    return HandlerUpdate(
      type: HandlerUpdateType.updateBoxSelection,
      data: {'currentPosition': currentPosition},
    );
  }

  /// 创建完成框选更新
  factory HandlerUpdate.completeBoxSelection() {
    return const HandlerUpdate(type: HandlerUpdateType.completeBoxSelection);
  }

  /// 创建平移画布更新
  factory HandlerUpdate.panCanvas(Offset delta) {
    return HandlerUpdate(
      type: HandlerUpdateType.panCanvas,
      data: {'delta': delta},
    );
  }

  /// 创建缩放画布更新
  factory HandlerUpdate.zoomCanvas(double zoom, Offset center) {
    return HandlerUpdate(
      type: HandlerUpdateType.zoomCanvas,
      data: {'zoom': zoom, 'center': center},
    );
  }

  /// 创建设置悬停节点更新
  factory HandlerUpdate.setHoveredNode(String? nodeId) {
    return HandlerUpdate(
      type: HandlerUpdateType.setHoveredNode,
      data: {'nodeId': nodeId},
    );
  }

  /// 创建打开节点编辑器更新
  factory HandlerUpdate.openNodeEditor(String nodeId) {
    return HandlerUpdate(
      type: HandlerUpdateType.openNodeEditor,
      data: {'nodeId': nodeId},
    );
  }

  /// 创建打开上下文菜单更新
  factory HandlerUpdate.openContextMenu(Offset position, {String? nodeId}) {
    return HandlerUpdate(
      type: HandlerUpdateType.openContextMenu,
      data: {'position': position, 'nodeId': nodeId},
    );
  }
}

/// 处理器更新类型
enum HandlerUpdateType {
  /// 选择节点
  selectNode,

  /// 取消选择节点
  deselectNode,

  /// 清空选择
  clearSelection,

  /// 开始拖拽
  startDrag,

  /// 更新拖拽
  updateDrag,

  /// 结束拖拽
  endDrag,

  /// 开始连线
  startConnection,

  /// 更新连线预览
  updateConnectionPreview,

  /// 完成连线
  completeConnection,

  /// 取消连线
  cancelConnection,

  /// 开始框选
  startBoxSelection,

  /// 更新框选
  updateBoxSelection,

  /// 完成框选
  completeBoxSelection,

  /// 平移画布
  panCanvas,

  /// 缩放画布
  zoomCanvas,

  /// 设置悬停节点
  setHoveredNode,

  /// 打开节点编辑器
  openNodeEditor,

  /// 打开上下文菜单
  openContextMenu,
}
