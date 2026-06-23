import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../models/er_diagram_models.dart';

/// ER 图状态 Notifier
///
/// 管理 ER 图的状态，包括节点、边、选择、交互等
class ERDiagramNotifier extends StateNotifier<ERDiagramState> {
  final Ref ref;
  final String moduleId;

  ERDiagramNotifier(this.ref, this.moduleId)
      : super(ERDiagramState(
          moduleId: moduleId,
          nodes: const {},
          edges: const {},
        )) {
    _loadFromModule();
  }

  /// 从模块加载数据
  void _loadFromModule() {
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;

    try {
      final module = project.modules.firstWhere((m) => m.id == moduleId);
      state = ERDiagramState.fromModule(module);
    } catch (_) {
      // 模块未找到
    }
  }

  /// 重新加载
  void reload() {
    _loadFromModule();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 节点操作
  // ═══════════════════════════════════════════════════════════════════

  /// 选择节点
  void selectNode(String nodeId, {bool addToSelection = false}) {
    Set<String> newSelection;
    if (addToSelection) {
      newSelection = Set<String>.from(state.selection.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
    } else {
      newSelection = {nodeId};
    }

    state = state.copyWith(
      selection: state.selection.copyWith(selectedNodeIds: newSelection),
    );
  }

  /// 取消选择
  void clearSelection() {
    state = state.copyWith(
      selection: state.selection.copyWith(
        selectedNodeIds: const {},
        selectedEdgeIds: const {},
      ),
    );
  }

  /// 全选
  void selectAll() {
    state = state.copyWith(
      selection: state.selection.copyWith(
        selectedNodeIds: Set<String>.from(state.nodes.keys),
      ),
    );
  }

  /// 设置悬停节点
  void setHoveredNode(String? nodeId) {
    if (state.selection.hoveredNodeId != nodeId) {
      state = state.copyWith(
        selection: state.selection.copyWith(hoveredNodeId: nodeId),
      );
    }
  }

  /// 移动节点
  void moveNode(String nodeId, double x, double y) {
    final node = state.nodes[nodeId];
    if (node == null) return;

    final erNode = node as ERNode;
    final newGraphNode = erNode.graphNode.copyWith(x: x, y: y);
    final newNode = erNode.copyWith(graphNode: newGraphNode);

    final newNodes = Map<String, DiagramNode>.from(state.nodes);
    newNodes[nodeId] = newNode;

    state = state.copyWith(nodes: newNodes);
    _syncToProject();
  }

  /// 开始拖拽
  void startDrag(String nodeId) {
    final nodeStates = Map<String, NodeState>.from(state.nodeStates);
    nodeStates[nodeId] =
        (nodeStates[nodeId] ?? const NodeState()).copyWith(isDragging: true);
    state = state.copyWith(nodeStates: nodeStates);
  }

  /// 结束拖拽
  void endDrag(String nodeId) {
    final nodeStates = Map<String, NodeState>.from(state.nodeStates);
    nodeStates[nodeId] =
        (nodeStates[nodeId] ?? const NodeState()).copyWith(isDragging: false);
    state = state.copyWith(nodeStates: nodeStates);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 边操作
  // ═══════════════════════════════════════════════════════════════════

  /// 添加边（字段级）
  void addEdgeWithFields(
    String sourceId,
    String targetId, {
    String? sourceField,
    String? targetField,
    String? label,
    String? relationType,
  }) {
    final newGraphEdge = GraphEdge(
      source: sourceId,
      target: targetId,
      sourceField: sourceField,
      targetField: targetField,
      label: label,
      relationType: relationType,
    );

    final newEdge = ERRelationEdge(graphEdge: newGraphEdge);
    final edgeId = newEdge.id;

    final newEdges = Map<String, DiagramEdge>.from(state.edges);
    newEdges[edgeId] = newEdge;

    state = state.copyWith(edges: newEdges);
    _syncToProject();
  }

  /// 移除边
  void removeEdge(String sourceId, String targetId) {
    final edgeId = '$sourceId:$targetId';
    final newEdges = Map<String, DiagramEdge>.from(state.edges);
    newEdges.remove(edgeId);

    state = state.copyWith(edges: newEdges);
    _syncToProject();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 交互操作
  // ═══════════════════════════════════════════════════════════════════

  /// 设置交互模式
  void setInteractionMode(InteractionMode mode) {
    state = state.copyWith(
      interaction: state.interaction.copyWith(mode: mode),
    );
  }

  /// 切换交互模式
  void toggleInteractionMode() {
    final newMode = state.interaction.mode == InteractionMode.move
        ? InteractionMode.edit
        : InteractionMode.move;
    setInteractionMode(newMode);
  }

  /// 开始连线
  void startConnection(String anchorId) {
    state = state.copyWith(
      interaction: state.interaction.copyWith(
        type: InteractionType.edgeCreate,
        isConnecting: true,
        connectionSourceAnchorId: anchorId,
      ),
    );
  }

  /// 更新连线预览
  void updateConnectionPreview(Offset position) {
    state = state.copyWith(
      interaction: state.interaction.copyWith(
        connectionPreviewEnd: position,
      ),
    );
  }

  /// 取消连线
  void cancelConnection() {
    state = state.copyWith(
      interaction: const InteractionState(),
    );
  }

  /// 完成连线
  void completeConnection(String targetAnchorId) {
    final sourceAnchorId = state.interaction.connectionSourceAnchorId;
    if (sourceAnchorId == null) {
      cancelConnection();
      return;
    }

    // 解析锚点 ID
    final sourceParts = sourceAnchorId.split(':');
    final targetParts = targetAnchorId.split(':');

    if (sourceParts.length < 2 || targetParts.length < 2) {
      cancelConnection();
      return;
    }

    final sourceNodeId = sourceParts.first;
    final targetNodeId = targetParts.first;

    // 不允许自连接
    if (sourceNodeId == targetNodeId) {
      cancelConnection();
      return;
    }

    // 检查是否已存在
    final exists = state.edges.values
        .any((e) => e.sourceNodeId == sourceNodeId && e.targetNodeId == targetNodeId);

    if (!exists) {
      // 提取字段信息
      String? sourceField;
      String? targetField;

      for (var i = 0; i < sourceParts.length; i++) {
        if (sourceParts[i] == 'field' && i + 1 < sourceParts.length) {
          sourceField = sourceParts[i + 1];
          break;
        }
      }

      for (var i = 0; i < targetParts.length; i++) {
        if (targetParts[i] == 'field' && i + 1 < targetParts.length) {
          targetField = targetParts[i + 1];
          break;
        }
      }

      addEdgeWithFields(
        sourceNodeId,
        targetNodeId,
        sourceField: sourceField,
        targetField: targetField,
      );
    }

    cancelConnection();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 视口操作
  // ═══════════════════════════════════════════════════════════════════

  /// 设置缩放
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(0.1, 5.0);
    state = state.copyWith(
      viewport: state.viewport.copyWith(zoom: clampedZoom),
    );
  }

  /// 放大
  void zoomIn() => setZoom(state.viewport.zoom * 1.2);

  /// 缩小
  void zoomOut() => setZoom(state.viewport.zoom / 1.2);

  /// 重置视口
  void resetViewport() {
    state = state.copyWith(
      viewport: const ViewportState(),
    );
  }

  /// 适应内容
  void fitContent(Size viewportSize) {
    final bounds = state.calculateContentBounds();
    if (bounds == Rect.zero) return;

    state = state.copyWith(
      viewport: state.viewport.fitContent(bounds, viewportSize),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 布局
  // ═══════════════════════════════════════════════════════════════════

  /// 应用布局结果
  void applyLayout(Map<String, Offset> positions) {
    final newNodes = <String, DiagramNode>{};

    for (final entry in state.nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value as ERNode;
      final position = positions[nodeId];

      if (position != null) {
        final newGraphNode = node.graphNode.copyWith(
          x: position.dx,
          y: position.dy,
        );
        newNodes[nodeId] = node.copyWith(graphNode: newGraphNode);
      } else {
        newNodes[nodeId] = node;
      }
    }

    state = state.copyWith(nodes: newNodes);
    _syncToProject();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 同步到项目
  // ═══════════════════════════════════════════════════════════════════

  void _syncToProject() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    final project = ref.read(projectNotifierProvider).project;

    if (project == null) return;

    // 转换回 GraphNode 和 GraphEdge
    final graphNodes = state.nodes.values.map((n) {
      final erNode = n as ERNode;
      return erNode.graphNode;
    }).toList();

    final graphEdges = state.edges.values.map((e) {
      final erEdge = e as ERRelationEdge;
      return erEdge.graphEdge;
    }).toList();

    // 更新模块
    final modules = project.modules.map((m) {
      if (m.id == moduleId) {
        return m.copyWith(
          graphCanvas: m.graphCanvas.copyWith(
            nodes: graphNodes,
            edges: graphEdges,
          ),
          updatedAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    final updatedProject = project.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );

    projectNotifier.updateProject(updatedProject);
  }
}

/// ER 图 Provider
final erDiagramProvider =
    StateNotifierProvider.family<ERDiagramNotifier, ERDiagramState, String>(
  (ref, moduleId) => ERDiagramNotifier(ref, moduleId),
);

/// 判断模块是否有实体
final hasEntitiesProvider = Provider.family<bool, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return false;

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.entities.isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// 获取模块实体数量
final entityCountProvider = Provider.family<int, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return 0;

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.entities.length;
  } catch (_) {
    return 0;
  }
});