import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import 'graph_provider.dart';

/// Undo/Redo state for ER diagram
class UndoRedoState {
  /// History stack of graph states
  final List<Map<String, dynamic>> history;

  /// Current position in history (0 = most recent)
  final int currentIndex;

  /// Maximum history size
  final int maxHistory;

  const UndoRedoState({
    this.history = const [],
    this.currentIndex = 0,
    this.maxHistory = 50,
  });

  UndoRedoState copyWith({
    List<Map<String, dynamic>>? history,
    int? currentIndex,
    int? maxHistory,
  }) {
    return UndoRedoState(
      history: history ?? this.history,
      currentIndex: currentIndex ?? this.currentIndex,
      maxHistory: maxHistory ?? this.maxHistory,
    );
  }

  /// Can undo if not at the beginning of history
  bool get canUndo => currentIndex < history.length - 1;

  /// Can redo if not at the end of history
  bool get canRedo => currentIndex > 0;

  /// Get current state
  Map<String, dynamic>? get currentState {
    if (history.isEmpty) return null;
    return history[currentIndex];
  }
}

/// Notifier for managing undo/redo operations
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  final Ref ref;
  final String moduleId;

  UndoRedoNotifier(this.ref, this.moduleId) : super(const UndoRedoState());

  /// Push a new state to history (called before each operation)
  void pushState(ERGraphState graphState) {
    // Serialize the state
    final serializedState = _serializeState(graphState);

    // If we're not at the most recent state, truncate forward history
    List<Map<String, dynamic>> newHistory;
    if (state.currentIndex > 0) {
      newHistory = state.history.sublist(state.currentIndex);
    } else {
      newHistory = List.from(state.history);
    }

    // Add new state at the beginning
    newHistory.insert(0, serializedState);

    // Limit history size
    if (newHistory.length > state.maxHistory) {
      newHistory = newHistory.sublist(0, state.maxHistory);
    }

    state = state.copyWith(
      history: newHistory,
      currentIndex: 0,
    );
  }

  /// Undo the last operation
  void undo() {
    if (!state.canUndo) return;

    final newIndex = state.currentIndex + 1;
    state = state.copyWith(currentIndex: newIndex);

    // Apply the previous state
    _applyState(state.history[newIndex]);
  }

  /// Redo a previously undone operation
  void redo() {
    if (!state.canRedo) return;

    final newIndex = state.currentIndex - 1;
    state = state.copyWith(currentIndex: newIndex);

    // Apply the next state
    _applyState(state.history[newIndex]);
  }

  /// Clear history
  void clearHistory() {
    state = const UndoRedoState();
  }

  /// Serialize graph state to a map
  Map<String, dynamic> _serializeState(ERGraphState graphState) {
    return {
      'nodes': graphState.nodes.map((n) => {
        'id': n.id,
        'x': n.x,
        'y': n.y,
        'isSelected': n.isSelected,
      }).toList(),
      'edges': graphState.edges.map((e) => {
        'source': e.source,
        'target': e.target,
        'label': e.label,
      }).toList(),
      'selectedNodeIds': graphState.selectedNodeIds.toList(),
      'zoom': graphState.zoom,
      'panOffset': {'dx': graphState.panOffset.dx, 'dy': graphState.panOffset.dy},
    };
  }

  /// Apply a serialized state to the graph
  void _applyState(Map<String, dynamic> serializedState) {
    final graphNotifier = ref.read(erGraphProvider(moduleId).notifier);

    // Apply nodes
    final nodes = (serializedState['nodes'] as List).map((n) {
      final node = graphNotifier.state.getNode(n['id'] as String);
      if (node != null) {
        return node.copyWith(
          data: node.data.copyWith(
            x: (n['x'] as num).toDouble(),
            y: (n['y'] as num).toDouble(),
          ),
          isSelected: n['isSelected'] as bool? ?? false,
        );
      }
      return null;
    }).where((n) => n != null).toList();

    // Apply edges
    final edges = (serializedState['edges'] as List).map((e) {
      return ERGraphEdge(
        data: GraphEdge(
          source: e['source'] as String,
          target: e['target'] as String,
          label: e['label'] as String?,
        ),
      );
    }).toList();

    // Apply selection
    final selectedIds = Set<String>.from(serializedState['selectedNodeIds'] as List);

    // Apply zoom and pan
    final zoom = (serializedState['zoom'] as num).toDouble();
    final panOffsetData = serializedState['panOffset'] as Map<String, dynamic>;
    final panOffset = Offset(
      (panOffsetData['dx'] as num).toDouble(),
      (panOffsetData['dy'] as num).toDouble(),
    );

    // Update the graph state
    graphNotifier.state = graphNotifier.state.copyWith(
      nodes: nodes.cast<ERGraphNode>(),
      edges: edges,
      selectedNodeIds: selectedIds,
      zoom: zoom,
      panOffset: panOffset,
    );

    // Sync to project by calling setZoom which triggers _syncToProject internally
    graphNotifier.setZoom(zoom);
    graphNotifier.setPanOffset(panOffset);
  }
}

/// Provider family for undo/redo - one provider per module
final undoRedoProvider = StateNotifierProvider.family<UndoRedoNotifier, UndoRedoState, String>(
  (ref, moduleId) {
    return UndoRedoNotifier(ref, moduleId);
  },
);