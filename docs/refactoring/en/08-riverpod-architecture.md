# Riverpod Architecture for Diagram Editor

## Overview

Riverpod is a reactive state management library for Flutter. This document covers best practices for using Riverpod in a diagram editor context.

## Why Riverpod

| Feature | Provider | Riverpod |
|---------|----------|----------|
| **Safety** | Runtime errors common | Compile-time safety |
| **Testability** | Hard to mock | Easy to override |
| **Performance** | All consumers rebuild | Selective rebuild |
| **Async** | Manual handling | Built-in support |
| **Family** | Manual keying | Built-in family |

## Provider Types for Diagram Editor

### 1. StateNotifierProvider (Main State)

```dart
/// UI state for a specific diagram
@riverpod
class DiagramState extends _$DiagramState {
  @override
  DiagramStateData build(String diagramId) {
    return DiagramStateData.empty(diagramId);
  }

  void selectNode(String nodeId) {
    state = state.copyWith(
      selectedNodeIds: {...state.selectedNodeIds, nodeId},
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedNodeIds: const {});
  }

  void startDragging(String nodeId) {
    state = state.copyWith(
      draggingNodeId: nodeId,
      interactionType: InteractionType.nodeDrag,
    );
  }
}
```

### 2. Provider (Computed State)

```dart
/// Compute derived state without rebuilding unnecessarily
@riverpod
List<DiagramNode> selectedNodes(SelectedNodesRef ref, String diagramId) {
  final state = ref.watch(diagramStateNotifierProvider(diagramId));
  final allNodes = ref.watch(allNodesProvider(diagramId));

  return allNodes
      .where((node) => state.selectedNodeIds.contains(node.id))
      .toList();
}

/// Check if a specific node is selected (minimal rebuilds)
@riverpod
bool isNodeSelected(IsNodeSelectedRef ref, String diagramId, String nodeId) {
  final state = ref.watch(diagramStateNotifierProvider(diagramId));
  return state.selectedNodeIds.contains(nodeId);
}
```

### 3. Family Providers

```dart
/// Each diagram has its own state
final diagramStateProvider = StateNotifierProvider.family<
    DiagramStateNotifier,
    DiagramStateData,
    String>((ref, diagramId) {
  return DiagramStateNotifier(ref, diagramId);
});

/// Each node can watch its own selection state
final nodeStateProvider = Provider.family<NodeState, (String, String)>((ref, params) {
  final (diagramId, nodeId) = params;
  final diagramState = ref.watch(diagramStateProvider(diagramId));

  return NodeState(
    isSelected: diagramState.selectedNodeIds.contains(nodeId),
    isHovered: diagramState.hoveredNodeId == nodeId,
    isDragging: diagramState.draggingNodeId == nodeId,
  );
});
```

### 4. Async Providers (for persistence)

```dart
/// Load diagram from storage
@riverpod
Future<DiagramData> loadDiagram(LoadDiagramRef ref, String diagramId) {
  return ref.watch(storageServiceProvider).loadDiagram(diagramId);
}

/// Auto-save diagram state
@riverpod
Stream<void> autoSaveDiagram(AutoSaveDiagramRef ref, String diagramId) {
  final state = ref.watch(diagramStateProvider(diagramId));

  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => ref.read(storageServiceProvider).saveDiagram(diagramId, state),
  );
}
```

## Architecture Pattern

### Separation of Concerns

```
┌─────────────────────────────────────────────────────────────────────┐
│                          UI Layer                                    │
│                                                                      │
│  DiagramCanvas (Widget)                                             │
│    ├── watch diagramStateProvider                                   │
│    ├── read diagramStateNotifier (for actions)                      │
│    └── watch nodeStateProvider (for each node)                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ ref.watch / ref.read
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       State Layer                                    │
│                                                                      │
│  Providers:                                                          │
│    ├── diagramStateProvider (StateNotifier)                         │
│    ├── nodeStateProvider (computed from diagramState)               │
│    ├── historyProvider (Command history)                            │
│    └── spatialIndexProvider (Spatial index)                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ ref.read (business logic)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Domain Layer                                   │
│                                                                      │
│  ProjectNotifier:                                                    │
│    ├── updateGraphNode(moduleId, nodeId, x, y)                      │
│    ├── addGraphEdge(moduleId, edge)                                 │
│    └── removeGraphEdge(moduleId, edgeId)                            │
│                                                                      │
│  Models:                                                             │
│    ├── Entity, Field, GraphNode, GraphEdge                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ read/write
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Data Layer                                     │
│                                                                      │
│  Hive Storage:                                                       │
│    ├── projectBox.put(project)                                      │
│    ├── projectBox.get(projectId)                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Provider File Structure

```
lib/shared/diagram_editor/
├── providers/
│   ├── diagram_state_provider.dart     # Main state
│   ├── node_state_provider.dart        # Per-node state
│   ├── selection_provider.dart         # Selection helpers
│   ├── interaction_provider.dart       # Interaction state machine
│   ├── history_provider.dart           # Undo/redo
│   ├── viewport_provider.dart          # Zoom/pan
│   └── spatial_index_provider.dart     # Spatial index
│
├── controllers/                         # Notifiers (logic)
│   ├── diagram_state_notifier.dart
│   ├── interaction_controller.dart
│   ├── history_controller.dart
│   └── viewport_controller.dart
│
└── widgets/
│   ├── diagram_canvas.dart              # watch providers
│   ├── node_widget.dart                 # watch nodeStateProvider
│   └── toolbar.dart                     # read/write providers
```

## Implementation Examples

### Main Diagram State

```dart
/// lib/shared/diagram_editor/providers/diagram_state_provider.dart

@riverpod
class DiagramStateNotifier extends _$DiagramStateNotifier {
  final String diagramId;

  @override
  DiagramStateData build(String diagramId) {
    this.diagramId = diagramId;

    // Listen to project changes
    ref.listen(projectNotifierProvider, (previous, next) {
      // Update when project data changes
      state = _syncFromProject(next.project);
    });

    return DiagramStateData.empty(diagramId);
  }

  DiagramStateData _syncFromProject(Project? project) {
    if (project == null) return DiagramStateData.empty(diagramId);

    final module = project.modules.firstWhere(
      (m) => m.id == diagramId,
      orElse: () => Module.empty,
    );

    return DiagramStateData.fromModule(module);
  }

  // Actions

  void selectNode(String nodeId, {bool additive = false}) {
    if (additive) {
      state = state.copyWith(
        selectedNodeIds: {...state.selectedNodeIds, nodeId},
      );
    } else {
      state = state.copyWith(
        selectedNodeIds: {nodeId},
      );
    }
  }

  void deselectNode(String nodeId) {
    state = state.copyWith(
      selectedNodeIds: state.selectedNodeIds.where((id) => id != nodeId).toSet(),
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedNodeIds: const {});
  }

  void setHoveredNode(String? nodeId) {
    if (state.hoveredNodeId != nodeId) {
      state = state.copyWith(hoveredNodeId: nodeId);
    }
  }

  void startDrag(String nodeId, Offset startPosition) {
    state = state.copyWith(
      draggingNodeId: nodeId,
      dragStartPosition: startPosition,
      interactionType: InteractionType.nodeDrag,
    );
  }

  void updateDrag(Offset currentPosition) {
    if (state.draggingNodeId == null) return;

    final delta = currentPosition - state.dragStartPosition!;

    // Update node position via ProjectNotifier
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    projectNotifier.updateGraphNode(
      diagramId,
      state.draggingNodeId!,
      state.nodePositions[state.draggingNodeId!]!.dx + delta.dx,
      state.nodePositions[state.draggingNodeId!]!.dy + delta.dy,
    );
  }

  void endDrag() {
    state = state.copyWith(
      draggingNodeId: null,
      dragStartPosition: null,
      interactionType: InteractionType.none,
    );
  }
}
```

### Per-Node State Provider

```dart
/// lib/shared/diagram_editor/providers/node_state_provider.dart

/// Minimal state for a single node
class NodeState {
  final bool isSelected;
  final bool isHovered;
  final bool isDragging;
  final bool isEditing;
  final bool isConnecting;

  const NodeState({
    this.isSelected = false,
    this.isHovered = false,
    this.isDragging = false,
    this.isEditing = false,
    this.isConnecting = false,
  });

  bool get isActive => isSelected || isHovered || isDragging || isEditing;
}

@riverpod
NodeState nodeState(NodeStateRef ref, String diagramId, String nodeId) {
  final diagramState = ref.watch(diagramStateNotifierProvider(diagramId));

  return NodeState(
    isSelected: diagramState.selectedNodeIds.contains(nodeId),
    isHovered: diagramState.hoveredNodeId == nodeId,
    isDragging: diagramState.draggingNodeId == nodeId,
    isEditing: diagramState.editingNodeId == nodeId,
  );
}
```

### Selection Provider

```dart
/// lib/shared/diagram_editor/providers/selection_provider.dart

@riverpod
Set<String> selectedNodeIds(SelectedNodeIdsRef ref, String diagramId) {
  return ref.watch(diagramStateNotifierProvider(diagramId)).selectedNodeIds;
}

@riverpod
int selectedCount(SelectedCountRef ref, String diagramId) {
  return ref.watch(selectedNodeIdsProvider(diagramId)).length;
}

@riverpod
bool hasSelection(HasSelectionRef ref, String diagramId) {
  return ref.watch(selectedCountProvider(diagramId)) > 0;
}

@riverpod
bool hasMultiSelection(HasMultiSelectionRef ref, String diagramId) {
  return ref.watch(selectedCountProvider(diagramId)) > 1;
}
```

### History Provider

```dart
/// lib/shared/diagram_editor/providers/history_provider.dart

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  HistoryState build(String diagramId) {
    return HistoryState.empty();
  }

  void execute(DiagramCommand command) {
    command.execute();
    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: const [],
    );
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final command = state.undoStack.removeLast();
    command.undo();

    state = state.copyWith(
      undoStack: state.undoStack,
      redoStack: [...state.redoStack, command],
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final command = state.redoStack.removeLast();
    command.execute();

    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: state.redoStack,
    );
  }
}

@riverpod
bool canUndo(CanUndoRef ref, String diagramId) {
  return ref.watch(historyNotifierProvider(diagramId)).undoStack.isNotEmpty;
}

@riverpod
bool canRedo(CanRedoRef ref, String diagramId) {
  return ref.watch(historyNotifierProvider(diagramId)).redoStack.isNotEmpty;
}
```

### Spatial Index Provider

```dart
/// lib/shared/diagram_editor/providers/spatial_index_provider.dart

@riverpod
DiagramSpatialIndex spatialIndex(SpatialIndexRef ref, String diagramId) {
  final state = ref.watch(diagramStateNotifierProvider(diagramId));

  final index = DiagramSpatialIndex(
    bounds: Rect.fromLTWH(0, 0, 50000, 50000),
  );

  // Populate from state
  for (final entry in state.nodePositions.entries) {
    final nodeId = entry.key;
    final position = entry.value;
    final size = state.nodeSizes[nodeId] ?? const Size(200, 100);

    index.nodeIndex.insert(BoundedItem(
      id: nodeId,
      bounds: Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
    ));
  }

  return index;
}
```

## Widget Usage

### Canvas Widget

```dart
/// lib/shared/diagram_editor/widgets/diagram_canvas.dart

class DiagramCanvas extends ConsumerStatefulWidget {
  final String diagramId;

  const DiagramCanvas({required this.diagramId});
}

class _DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  @override
  Widget build(BuildContext context) {
    // Watch main state
    final state = ref.watch(diagramStateNotifierProvider(widget.diagramId));

    // Watch spatial index (rebuilds when nodes change)
    final spatialIndex = ref.watch(spatialIndexProvider(widget.diagramId));

    // Read notifier for actions
    final notifier = ref.read(diagramStateNotifierProvider(widget.diagramId).notifier);

    return Listener(
      onPointerDown: (event) {
        final scenePos = toScene(event.localPosition);
        final hitResult = spatialIndex.hitTest(scenePos);

        if (hitResult.isOnNode) {
          notifier.selectNode(hitResult.nodeId!);
        }
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: DiagramPainter(state: state),
          ),
          // Render nodes
          ...state.nodePositions.entries.map((entry) {
            final nodeId = entry.key;
            final position = entry.value;

            // Watch per-node state (minimal rebuilds)
            final nodeState = ref.watch(nodeStateProvider(widget.diagramId, nodeId));

            return Positioned(
              left: position.dx,
              top: position.dy,
              child: NodeWidget(
                nodeId: nodeId,
                isSelected: nodeState.isSelected,
                isHovered: nodeState.isHovered,
              ),
            );
          }),
        ],
      ),
    );
  }
}
```

### Node Widget

```dart
/// lib/shared/diagram_editor/widgets/node_widget.dart

class NodeWidget extends ConsumerWidget {
  final String diagramId;
  final String nodeId;

  const NodeWidget({
    required this.diagramId,
    required this.nodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when this node's state changes
    final nodeState = ref.watch(nodeStateProvider(diagramId, nodeId));

    // Read notifier for actions (doesn't cause rebuilds)
    final notifier = ref.read(diagramStateNotifierProvider(diagramId).notifier);

    return GestureDetector(
      onTap: () => notifier.selectNode(nodeId),
      child: Container(
        decoration: BoxDecoration(
          border: nodeState.isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Text('Node: $nodeId'),
      ),
    );
  }
}
```

### Toolbar Widget

```dart
/// lib/shared/diagram_editor/widgets/diagram_toolbar.dart

class DiagramToolbar extends ConsumerWidget {
  final String diagramId;

  const DiagramToolbar({required this.diagramId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider(diagramId));
    final canRedo = ref.watch(canRedoProvider(diagramId));
    final selectedCount = ref.watch(selectedCountProvider(diagramId));

    final historyNotifier = ref.read(historyNotifierProvider(diagramId).notifier);
    final diagramNotifier = ref.read(diagramStateNotifierProvider(diagramId).notifier);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: canUndo ? () => historyNotifier.undo() : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: canRedo ? () => historyNotifier.redo() : null,
        ),
        if (selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => diagramNotifier.deleteSelected(),
          ),
      ],
    );
  }
}
```

## Best Practices

### 1. Use `watch` for State, `read` for Actions

```dart
// ✅ Correct
final state = ref.watch(diagramStateProvider(diagramId)); // UI rebuilds when state changes
final notifier = ref.read(diagramStateProvider(diagramId).notifier); // Actions don't rebuild

// ❌ Wrong - causes unnecessary rebuilds
final notifier = ref.watch(diagramStateProvider(diagramId).notifier);
```

### 2. Use `select` for Selective Rebuilds

```dart
// ✅ Only rebuilds when selection changes
final isSelected = ref.watch(
  diagramStateProvider(diagramId).select((s) => s.selectedNodeIds.contains(nodeId)),
);

// ❌ Rebuilds on any state change
final state = ref.watch(diagramStateProvider(diagramId));
final isSelected = state.selectedNodeIds.contains(nodeId);
```

### 3. Use Family for Per-Instance State

```dart
// ✅ Each diagram has independent state
final diagramStateProvider = StateNotifierProvider.family<...>();

// ❌ Shared state between all diagrams
final diagramStateProvider = StateNotifierProvider<...>();
```

### 4. Use code generation for cleaner code

```dart
// With riverpod_annotation
@riverpod
class DiagramState extends _$DiagramState {
  @override
  DiagramData build(String diagramId) => DiagramData.empty();
}

// Generated code handles provider setup
```

## References

- [Riverpod Documentation](https://riverpod.dev)
- [Riverpod Annotation Package](https://pub.dev/packages/riverpod_annotation)
- [Flutter State Management Comparison](https://docs.flutter.dev/data-and-backend/state-mgmt/options)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*