/// ER 图交互状态 Provider
///
/// 使用 Riverpod 管理 ER 图的交互状态
library;

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'er_interaction_manager.dart';

/// ER 图交互状态
class ERInteractionNotifier extends StateNotifier<ERInteractionState> {
  ERInteractionNotifier() : super(const ERInteractionState());

  void enterEditMode() {
    state = state.copyWith(mode: InteractionMode.edit);
  }

  void enterPreviewMode() {
    state = state.copyWith(mode: InteractionMode.move);
  }

  void toggleMode() {
    if (state.isEditMode) {
      enterPreviewMode();
    } else {
      enterEditMode();
    }
  }

  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (addToSelection) {
      final newSelection = Set<String>.from(state.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
      state = state.copyWith(selectedNodeIds: newSelection);
    } else {
      state = state.copyWith(selectedNodeIds: {nodeId});
    }
  }

  void selectNodes(Set<String> nodeIds) {
    state = state.copyWith(selectedNodeIds: nodeIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedNodeIds: const {});
  }

  void startDragging(String nodeId, Offset startPosition) {
    state = state.copyWith(
      draggingNodeId: nodeId,
      dragStartPosition: startPosition,
    );
  }

  void endDragging() {
    state = state.copyWith(
      draggingNodeId: null,
      dragStartPosition: null,
      clearDragging: true,
    );
  }

  void startConnection(String anchorId, Offset position) {
    state = state.copyWith(
      connectionSourceAnchorId: anchorId,
      connectionPreviewEnd: position,
    );
  }

  void updateConnectionPreview(Offset position) {
    state = state.copyWith(connectionPreviewEnd: position);
  }

  void endConnection() {
    state = state.copyWith(
      connectionSourceAnchorId: null,
      connectionPreviewEnd: null,
      clearConnection: true,
    );
  }

  void startBoxSelection(Offset position) {
    state = state.copyWith(
      selectionRect: Rect.fromLTWH(position.dx, position.dy, 0, 0),
    );
  }

  void updateBoxSelection(Offset position) {
    if (state.selectionRect == null) return;

    final start = state.selectionRect!.topLeft;
    final rect = Rect.fromPoints(start, position);
    state = state.copyWith(selectionRect: rect);
  }

  void endBoxSelection() {
    state = state.copyWith(
      selectionRect: null,
      clearSelection: true,
    );
  }

  void setHoveredNode(String? nodeId) {
    state = state.copyWith(hoveredNodeId: nodeId);
  }

  void reset() {
    state = const ERInteractionState();
  }
}

/// ER 图交互状态 Provider
final erInteractionProvider = StateNotifierProvider.family<
    ERInteractionNotifier,
    ERInteractionState,
    String>((ref, diagramId) {
  return ERInteractionNotifier();
});

/// 选中节点 ID 列表 Provider
final selectedNodeIdsProvider = Provider.family<Set<String>, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).selectedNodeIds;
});

/// 是否有选中节点 Provider
final hasSelectionProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).selectedNodeIds.isNotEmpty;
});

/// 是否正在拖动 Provider
final isDraggingProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).isDragging;
});

/// 是否正在连线 Provider
final isConnectingProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).isConnecting;
});

/// 是否正在框选 Provider
final isSelectingProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).isSelecting;
});

/// 交互模式 Provider
final interactionModeProvider = Provider.family<InteractionMode, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).mode;
});

/// 是否为编辑模式 Provider
final isEditModeProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).isEditMode;
});

/// 是否为预览模式 Provider
final isPreviewModeProvider = Provider.family<bool, String>((ref, diagramId) {
  return ref.watch(erInteractionProvider(diagramId)).isPreviewMode;
});