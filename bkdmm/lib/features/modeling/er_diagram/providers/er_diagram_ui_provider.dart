import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../models/er_diagram_ui_state.dart';

/// ER 图 UI 状态 Notifier
///
/// 只管理 UI 状态，业务数据直接操作 ProjectNotifier。
/// 业务数据包括：
/// - 实体列表：project.modules[].entities
/// - 节点位置：project.modules[].graphCanvas.nodes
/// - 关系连线：project.modules[].graphCanvas.edges
class ERDiagramUINotifier extends StateNotifier<ERDiagramUIState> {
  final Ref ref;
  final String moduleId;

  ERDiagramUINotifier(this.ref, this.moduleId)
      : super(ERDiagramUIState.empty(moduleId));

  // ═══════════════════════════════════════════════════════════════════
  // 模式切换
  // ═══════════════════════════════════════════════════════════════════

  /// 设置交互模式
  void setInteractionMode(ERInteractionMode mode) {
    if (state.interactionMode != mode) {
      state = state.copyWith(interactionMode: mode);
    }
  }

  /// 切换到移动模式
  void enterMoveMode() {
    setInteractionMode(ERInteractionMode.move);
  }

  /// 切换到编辑模式
  void enterEditMode() {
    setInteractionMode(ERInteractionMode.edit);
  }

  /// 切换模式
  void toggleMode() {
    if (state.isEditMode) {
      enterMoveMode();
    } else {
      enterEditMode();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 节点选择
  // ═══════════════════════════════════════════════════════════════════

  /// 选择节点
  void selectNode(String nodeId, {bool addToSelection = false}) {
    Set<String> newSelection;
    if (addToSelection) {
      newSelection = Set<String>.from(state.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
    } else {
      newSelection = {nodeId};
    }
    state = state.copyWith(selectedNodeIds: newSelection);
  }

  /// 取消选择
  void clearSelection() {
    state = state.copyWith(selectedNodeIds: const {});
  }

  /// 全选
  void selectAll(List<String> nodeIds) {
    state = state.copyWith(selectedNodeIds: Set<String>.from(nodeIds));
  }

  /// 设置悬停节点
  void setHoveredNode(String? nodeId) {
    if (state.hoveredNodeId != nodeId) {
      state = state.copyWith(hoveredNodeId: nodeId);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 节点拖动
  // ═══════════════════════════════════════════════════════════════════

  /// 开始拖动节点
  void startDragging(String nodeId) {
    state = state.copyWith(draggingNodeId: nodeId);
  }

  /// 结束拖动节点
  void endDragging() {
    state = state.copyWith(draggingNodeId: null);
  }

  /// 移动节点位置（直接更新到 Project）
  void moveNode(String entityId, double x, double y) {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    projectNotifier.updateGraphNode(moduleId, entityId, x, y);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 连线操作
  // ═══════════════════════════════════════════════════════════════════

  /// 开始连线
  void startConnection(ERFieldAnchor sourceAnchor) {
    state = state.copyWith(
      connection: ERConnectionState(
        isConnecting: true,
        sourceAnchor: sourceAnchor,
        previewEnd: sourceAnchor.position,
      ),
    );
  }

  /// 更新连线预览
  void updateConnectionPreview(Offset position) {
    if (state.isConnecting) {
      state = state.copyWith(
        connection: state.connection.copyWith(previewEnd: position),
      );
    }
  }

  /// 取消连线
  void cancelConnection() {
    state = state.copyWith(connection: const ERConnectionState());
  }

  /// 完成连线
  void completeConnection(ERFieldAnchor targetAnchor) {
    final sourceAnchor = state.connection.sourceAnchor;
    cancelConnection();

    if (sourceAnchor == null) return;

    // 不允许连接到自己
    if (sourceAnchor.nodeId == targetAnchor.nodeId) return;

    // 创建关系
    final edge = GraphEdge(
      source: sourceAnchor.nodeId,
      target: targetAnchor.nodeId,
      sourceField: sourceAnchor.fieldIndex.toString(),
      targetField: targetAnchor.fieldIndex.toString(),
      relationType: '1:N',
    );

    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    projectNotifier.addGraphEdge(moduleId, edge);
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
  void zoomIn() {
    setZoom(state.viewport.zoom * 1.2);
  }

  /// 缩小
  void zoomOut() {
    setZoom(state.viewport.zoom / 1.2);
  }

  /// 设置平移
  void setPan(Offset pan) {
    state = state.copyWith(
      viewport: state.viewport.copyWith(pan: pan),
    );
  }

  /// 重置视口
  void resetViewport() {
    state = state.copyWith(viewport: const ERViewportState());
  }

  // ═══════════════════════════════════════════════════════════════════
  // 布局操作
  // ═══════════════════════════════════════════════════════════════════

  /// 应用布局结果
  void applyLayout(Map<String, Offset> positions) {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    projectNotifier.applyGraphLayout(moduleId, positions);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 重置状态
  // ═══════════════════════════════════════════════════════════════════

  /// 重置所有状态
  void reset() {
    state = ERDiagramUIState.empty(moduleId);
  }
}

/// ER 图 UI 状态 Provider
///
/// 使用 family provider，按 moduleId 区分不同模块的状态
final erDiagramUIProvider =
    StateNotifierProvider.family<ERDiagramUINotifier, ERDiagramUIState, String>(
  (ref, moduleId) => ERDiagramUINotifier(ref, moduleId),
);

/// 辅助 Provider：获取模块的实体列表
final moduleEntitiesProvider = Provider.family<List<Entity>, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return [];

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.entities;
  } catch (_) {
    return [];
  }
});

/// 辅助 Provider：获取模块的图节点列表
final moduleGraphNodesProvider = Provider.family<List<GraphNode>, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return [];

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.graphCanvas.nodes;
  } catch (_) {
    return [];
  }
});

/// 辅助 Provider：获取模块的关系连线列表
final moduleGraphEdgesProvider = Provider.family<List<GraphEdge>, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return [];

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.graphCanvas.edges;
  } catch (_) {
    return [];
  }
});

/// 辅助 Provider：判断模块是否有实体
final hasModuleEntitiesProvider = Provider.family<bool, String>((ref, moduleId) {
  final entities = ref.watch(moduleEntitiesProvider(moduleId));
  return entities.isNotEmpty;
});

/// 辅助 Provider：获取模块实体数量
final moduleEntityCountProvider = Provider.family<int, String>((ref, moduleId) {
  final entities = ref.watch(moduleEntitiesProvider(moduleId));
  return entities.length;
});
