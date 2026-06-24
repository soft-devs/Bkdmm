import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';
import '../../shared/models/models.dart';
import '../core/field_anchor_registry.dart';
import 'er_table_node_widget.dart';

/// ER 图节点 Widget 构建器
///
/// 实现 graphview 的 NodeWidgetBuilder 接口，
/// 为每个 graphview Node 创建对应的 Flutter Widget
class ERNodeWidgetBuilder {
  /// 实体映射（nodeId -> Entity）
  final Map<String, Entity> _entityMap = {};

  /// 是否显示锚点
  final bool showAnchors;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 选中的节点 ID 集合
  final Set<String> selectedNodeIds;

  /// 悬停的节点 ID
  final String? hoveredNodeId;

  /// 锚点点击回调
  final void Function(FieldAnchor)? onAnchorTap;

  /// 节点点击回调
  final void Function(String nodeId)? onNodeTap;

  /// 节点双击回调
  final void Function(String nodeId)? onNodeDoubleTap;

  ERNodeWidgetBuilder({
    this.showAnchors = false,
    this.isDarkMode = false,
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.onAnchorTap,
    this.onNodeTap,
    this.onNodeDoubleTap,
  });

  /// 注册实体
  void registerEntity(String nodeId, Entity entity) {
    _entityMap[nodeId] = entity;
  }

  /// 批量注册实体
  void registerEntities(Map<String, Entity> entities) {
    _entityMap.addAll(entities);
  }

  /// 移除实体
  void removeEntity(String nodeId) {
    _entityMap.remove(nodeId);
  }

  /// 清空所有实体
  void clearEntities() {
    _entityMap.clear();
  }

  /// 获取实体
  Entity? getEntity(String nodeId) => _entityMap[nodeId];

  /// 构建 NodeWidgetBuilder 函数
  ///
  /// 返回符合 graphview 要求的 NodeWidgetBuilder 类型
  NodeWidgetBuilder build() {
    return (Node node) {
      final nodeId = node.key?.value.toString() ?? '';
      final entity = _entityMap[nodeId];

      if (entity == null) {
        // 如果没有找到实体，返回占位 Widget
        return _buildPlaceholder(nodeId);
      }

      return ERTableNodeWidget(
        node: node,
        entity: entity,
        isSelected: selectedNodeIds.contains(nodeId),
        isHovered: hoveredNodeId == nodeId,
        showAnchors: showAnchors,
        isDarkMode: isDarkMode,
        onAnchorTap: onAnchorTap,
        onTap: () => onNodeTap?.call(nodeId),
        onDoubleTap: () => onNodeDoubleTap?.call(nodeId),
      );
    };
  }

  /// 构建占位 Widget（当实体不存在时）
  Widget _buildPlaceholder(String nodeId) {
    return Container(
      width: ERTableNodeWidget.defaultWidth,
      height: ERTableNodeWidget.headerHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          nodeId,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  /// 创建副本并更新属性
  ERNodeWidgetBuilder copyWith({
    bool? showAnchors,
    bool? isDarkMode,
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    void Function(FieldAnchor)? onAnchorTap,
    void Function(String)? onNodeTap,
    void Function(String)? onNodeDoubleTap,
  }) {
    final builder = ERNodeWidgetBuilder(
      showAnchors: showAnchors ?? this.showAnchors,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      onAnchorTap: onAnchorTap ?? this.onAnchorTap,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
    );
    builder._entityMap.addAll(_entityMap);
    return builder;
  }
}

/// ERNodeWidgetBuilder 的状态管理扩展
///
/// 用于与 Riverpod 状态管理集成
class ERNodeWidgetBuilderState {
  /// 当前选中的节点 ID 集合
  final Set<String> selectedNodeIds;

  /// 当前悬停的节点 ID
  final String? hoveredNodeId;

  /// 交互模式
  final InteractionMode interactionMode;

  /// 是否暗色模式
  final bool isDarkMode;

  const ERNodeWidgetBuilderState({
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.interactionMode = InteractionMode.move,
    this.isDarkMode = false,
  });

  /// 是否显示锚点（仅在编辑模式下显示）
  bool get showAnchors => interactionMode == InteractionMode.edit;

  /// 创建 ERNodeWidgetBuilder
  ERNodeWidgetBuilder createBuilder({
    required Map<String, Entity> entityMap,
    void Function(FieldAnchor)? onAnchorTap,
    void Function(String)? onNodeTap,
    void Function(String)? onNodeDoubleTap,
  }) {
    final builder = ERNodeWidgetBuilder(
      showAnchors: showAnchors,
      isDarkMode: isDarkMode,
      selectedNodeIds: selectedNodeIds,
      hoveredNodeId: hoveredNodeId,
      onAnchorTap: onAnchorTap,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
    );
    builder.registerEntities(entityMap);
    return builder;
  }

  ERNodeWidgetBuilderState copyWith({
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    InteractionMode? interactionMode,
    bool? isDarkMode,
  }) {
    return ERNodeWidgetBuilderState(
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      interactionMode: interactionMode ?? this.interactionMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// 交互模式
enum InteractionMode {
  /// 移动模式（仅查看，可平移/缩放）
  move,

  /// 编辑模式（可拖拽节点、创建连线）
  edit,
}