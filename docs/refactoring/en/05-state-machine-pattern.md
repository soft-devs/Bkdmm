# State Machine Pattern with Dart 3 Sealed Classes

## Overview

Dart 3 introduced sealed classes, which enable exhaustive pattern matching. This is ideal for implementing state machines in UI components like diagram editors, where the interaction state has clear transitions.

## Problem: Boolean State Flags

### Current Approach (Anti-pattern)

```dart
// In er_diagram_ui_state.dart
class ERDiagramUIState {
  final ERInteractionMode interactionMode;
  final bool isConnecting;
  final bool isSelecting;
  final bool isDragging;
  final Set<String> draggingNodeIds;
  final ERFieldAnchor? connectionSourceAnchor;
  final Offset selectionStartPoint;
  // ... more flags

  // ❌ Problem: Invalid states are possible!
  // isConnecting && isSelecting can both be true
  // isDragging && isConnecting can both be true
}
```

### Issues with Boolean Flags

1. **Invalid State Combinations**
   - `isConnecting && isSelecting` = true (nonsensical)
   - `isDragging && !draggingNodeIds.isEmpty` = false (inconsistent)

2. **Complex Conditionals**
   ```dart
   if (uiState.isEditMode && !uiState.isSelecting && !uiState.isConnecting) {
     // Can start selection
   }
   ```

3. **Incomplete State Handling**
   - Easy to forget a condition
   - No compiler enforcement

4. **Hard to Trace State Transitions**
   - Multiple boolean changes in different places
   - No central transition logic

## Solution: State Machine with Sealed Classes

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     InteractionState (sealed)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐   click anchor    ┌──────────────┐               │
│  │    Idle      │ ────────────────► │  Connecting  │               │
│  │              │ ◄──────────────── │              │               │
│  └──────────────┘   cancel/complete └──────────────┘               │
│         │                                                            │
│         │ click node                                                 │
│         ▼                                                            │
│  ┌──────────────┐   drag start      ┌──────────────┐               │
│  │ NodeSelected │ ────────────────► │ DraggingNode │               │
│  │              │ ◄──────────────── │              │               │
│  └──────────────┘   drag end        └──────────────┘               │
│         │                                                            │
│         │ click canvas (edit mode)                                   │
│         ▼                                                            │
│  ┌──────────────┐                                                   │
│  │ BoxSelecting │                                                   │
│  │              │                                                   │
│  └──────────────┘                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Implementation

#### 1. Base State Definition

```dart
/// lib/shared/diagram_editor/core/interaction_state.dart

/// Base state for diagram interactions
/// Sealed class ensures all subtypes are known at compile time
sealed class InteractionState {
  const InteractionState();

  /// Current cursor for this state
  MouseCursor get cursor;

  /// Whether panning is allowed in this state
  bool get canPan => false;

  /// Whether selection is allowed in this state
  bool get canSelect => false;

  /// Whether editing is allowed in this state
  bool get canEdit => false;

  /// Human-readable state name (for debugging)
  String get name;

  /// Handle an event and transition to next state
  /// Returns the new state (may be same as current)
  InteractionState handle(DiagramEvent event, DiagramContext context);
}
```

#### 2. Concrete States

```dart
/// Idle state - no active interaction
class IdleState extends InteractionState {
  const IdleState();

  @override
  MouseCursor get cursor => SystemMouseCursors.basic;

  @override
  bool get canPan => true;
  @override
  bool get canSelect => true;
  @override
  bool get canEdit => true;

  @override
  String get name => 'Idle';

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerDownEvent(:final isPrimaryButton, :final isSecondaryButton)
        when context.isEditMode && isPrimaryButton && context.hitAnchorId != null =>
          ConnectingState(sourceAnchorId: context.hitAnchorId!),

      DiagramPointerDownEvent(:final isPrimaryButton)
        when context.isEditMode && isPrimaryButton && context.hitNodeId != null =>
          NodeSelectedState(nodeId: context.hitNodeId!),

      DiagramPointerDownEvent(:final isPrimaryButton)
        when context.isEditMode && isPrimaryButton && context.isOnCanvas =>
          BoxSelectingState(startPoint: event.localPosition),

      DiagramPointerDownEvent(:final isSecondaryButton)
        when isSecondaryButton =>
          PanningState(startPoint: event.localPosition),

      DiagramPointerMoveEvent()
        when context.hitNodeId != null =>
          HoveringNodeState(nodeId: context.hitNodeId!),

      _ => this, // Stay in idle
    };
  }
}

/// Hovering over a node
class HoveringNodeState extends InteractionState {
  final String nodeId;

  const HoveringNodeState({required this.nodeId});

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  String get name => 'HoveringNode';

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerDownEvent(:final isPrimaryButton)
        when isPrimaryButton && context.hitNodeId == nodeId =>
          NodeSelectedState(nodeId: nodeId),

      DiagramPointerMoveEvent()
        when context.hitNodeId != nodeId =>
          context.hitNodeId != null
            ? HoveringNodeState(nodeId: context.hitNodeId!)
            : const IdleState(),

      _ => this,
    };
  }
}

/// Node is selected
class NodeSelectedState extends InteractionState {
  final String nodeId;
  final Offset? dragStartPoint;

  const NodeSelectedState({
    required this.nodeId,
    this.dragStartPoint,
  });

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  bool get canEdit => true;

  @override
  String get name => 'NodeSelected';

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerDownEvent(:final isPrimaryButton)
        when isPrimaryButton && context.hitNodeId == nodeId =>
          PotentialDragState(
            nodeId: nodeId,
            startPoint: event.scenePosition,
          ),

      DiagramPointerDownEvent(:final isPrimaryButton)
        when isPrimaryButton && context.hitNodeId != null =>
          NodeSelectedState(nodeId: context.hitNodeId!), // Select different node

      DiagramPointerDownEvent(:final isPrimaryButton)
        when isPrimaryButton && context.isOnCanvas =>
          const BoxSelectingState(startPoint: Offset.zero), // Deselect

      _ => this,
    };
  }
}

/// Potential drag - waiting to exceed threshold
class PotentialDragState extends InteractionState {
  final String nodeId;
  final Offset startPoint;

  const PotentialDragState({
    required this.nodeId,
    required this.startPoint,
  });

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  String get name => 'PotentialDrag';

  static const double dragThreshold = 5.0;

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerMoveEvent(:final scenePosition) =>
        (scenePosition - startPoint).distance > dragThreshold
          ? DraggingNodeState(
              nodeId: nodeId,
              startPosition: startPoint,
              currentPosition: scenePosition,
            )
          : this,

      DiagramPointerUpEvent() =>
        NodeSelectedState(nodeId: nodeId), // Was a tap, not drag

      _ => this,
    };
  }
}

/// Actively dragging a node
class DraggingNodeState extends InteractionState {
  final String nodeId;
  final Offset startPosition;
  final Offset currentPosition;

  const DraggingNodeState({
    required this.nodeId,
    required this.startPosition,
    required this.currentPosition,
  });

  @override
  MouseCursor get cursor => SystemMouseCursors.grabbing;

  @override
  String get name => 'DraggingNode';

  DraggingNodeState copyWith({
    Offset? currentPosition,
  }) {
    return DraggingNodeState(
      nodeId: nodeId,
      startPosition: startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerMoveEvent(:final scenePosition) =>
        copyWith(currentPosition: scenePosition),

      DiagramPointerUpEvent() =>
        const IdleState(),

      _ => this,
    };
  }

  /// Get the delta from start position
  Offset get delta => currentPosition - startPosition;
}

/// Creating a connection between two anchors
class ConnectingState extends InteractionState {
  final String sourceAnchorId;
  final Offset previewEnd;

  const ConnectingState({
    required this.sourceAnchorId,
    this.previewEnd = Offset.zero,
  });

  @override
  MouseCursor get cursor => SystemMouseCursors.cell;

  @override
  String get name => 'Connecting';

  ConnectingState copyWith({Offset? previewEnd}) {
    return ConnectingState(
      sourceAnchorId: sourceAnchorId,
      previewEnd: previewEnd ?? this.previewEnd,
    );
  }

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerMoveEvent(:final scenePosition) =>
        copyWith(previewEnd: scenePosition),

      DiagramPointerUpEvent()
        when context.hitAnchorId != null &&
             context.hitAnchorId != sourceAnchorId =>
          const IdleState(), // Connection completed

      DiagramPointerUpEvent() =>
        const IdleState(), // Connection cancelled

      _ => this,
    };
  }
}

/// Box selection in progress
class BoxSelectingState extends InteractionState {
  final Offset startPoint;
  final Offset currentPoint;

  const BoxSelectingState({
    required this.startPoint,
    this.currentPoint = Offset.zero,
  });

  @override
  MouseCursor get cursor => SystemMouseCursors.cell;

  @override
  String get name => 'BoxSelecting';

  Rect get selectionRect => Rect.fromPoints(startPoint, currentPoint);

  BoxSelectingState copyWith({Offset? currentPoint}) {
    return BoxSelectingState(
      startPoint: startPoint,
      currentPoint: currentPoint ?? this.currentPoint,
    );
  }

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerMoveEvent(:final localPosition) =>
        copyWith(currentPoint: localPosition),

      DiagramPointerUpEvent() =>
        const IdleState(), // Selection complete

      _ => this,
    };
  }
}

/// Panning the canvas
class PanningState extends InteractionState {
  final Offset startPoint;

  const PanningState({required this.startPoint});

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  String get name => 'Panning';

  @override
  InteractionState handle(DiagramEvent event, DiagramContext context) {
    return switch (event) {
      DiagramPointerUpEvent() => const IdleState(),
      _ => this,
    };
  }
}
```

#### 3. State Machine Controller

```dart
/// lib/shared/diagram_editor/controllers/interaction_controller.dart

class InteractionController extends StateNotifier<InteractionState> {
  InteractionController() : super(const IdleState());

  /// Handle an event and update state
  void handleEvent(DiagramEvent event, DiagramContext context) {
    final newState = state.handle(event, context);
    if (newState != state) {
      state = newState;
    }
  }

  /// Reset to idle state
  void reset() {
    state = const IdleState();
  }

  // Convenience getters
  bool get isIdle => state is IdleState;
  bool get isDragging => state is DraggingNodeState;
  bool get isConnecting => state is ConnectingState;
  bool get isSelecting => state is BoxSelectingState;

  /// Get current drag info (if dragging)
  DraggingNodeState? get dragState => state is DraggingNodeState
      ? state as DraggingNodeState
      : null;

  /// Get current connection info (if connecting)
  ConnectingState? get connectionState => state is ConnectingState
      ? state as ConnectingState
      : null;
}
```

#### 4. Provider Integration

```dart
/// lib/shared/diagram_editor/providers/interaction_provider.dart

final interactionControllerProvider =
    StateNotifierProvider.family<InteractionController, InteractionState, String>(
  (ref, diagramId) => InteractionController(),
);
```

#### 5. Usage in Canvas

```dart
/// lib/shared/diagram_editor/core/diagram_canvas.dart

abstract class DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  @override
  Widget build(BuildContext context) {
    final interactionState = ref.watch(
      interactionControllerProvider(widget.diagramId),
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _handlePointerEvent(event),
      onPointerMove: (event) => _handlePointerEvent(event),
      onPointerUp: (event) => _handlePointerEvent(event),
      child: MouseRegion(
        cursor: interactionState.cursor,
        child: Stack(
          children: [
            // Main canvas
            InteractiveViewer(
              panEnabled: interactionState.canPan,
              child: CustomPaint(...),
            ),

            // Selection rect (if selecting)
            if (interactionState is BoxSelectingState)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SelectionRectPainter(
                      rect: interactionState.selectionRect,
                    ),
                  ),
                ),
              ),

            // Connection preview (if connecting)
            if (interactionState is ConnectingState)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ConnectionPreviewPainter(
                      source: _getAnchorPosition(interactionState.sourceAnchorId),
                      target: interactionState.previewEnd,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePointerEvent(PointerEvent event) {
    final diagramEvent = _convertEvent(event);
    final context = _buildContext(diagramEvent);

    ref.read(interactionControllerProvider(widget.diagramId).notifier)
        .handleEvent(diagramEvent, context);
  }
}
```

### Pattern Matching Benefits

#### Exhaustive Switch

```dart
// Compiler ensures all cases are handled
String getStateDescription(InteractionState state) {
  return switch (state) {
    IdleState() => 'Ready',
    HoveringNodeState(:final nodeId) => 'Hovering over $nodeId',
    NodeSelectedState(:final nodeId) => 'Selected: $nodeId',
    PotentialDragState(:final nodeId) => 'About to drag $nodeId',
    DraggingNodeState(:final nodeId, :final delta) =>
      'Dragging $nodeId by ${delta.dx}, ${delta.dy}',
    ConnectingState(:final sourceAnchorId) =>
      'Connecting from $sourceAnchorId',
    BoxSelectingState(:final selectionRect) =>
      'Selecting ${selectionRect.width}x${selectionRect.height}',
    PanningState() => 'Panning canvas',
  };
}
```

#### Impossible Invalid States

```dart
// Before: Could have both flags true
if (isDragging && isConnecting) {
  // This should never happen, but compiler allows it!
}

// After: State machine makes this impossible
// A state can only be ONE of these, never both
final state = interactionState;
if (state is DraggingNodeState) {
  // Guaranteed NOT to be ConnectingState
}
```

### State Transition Diagram

```
┌─────────┐
│  Idle   │◄──────────────────────────────────────────┐
└────┬────┘                                            │
     │                                                 │
     ├──[click anchor]──►┌──────────────┐             │
     │                    │  Connecting  │─────────────┤
     │                    └──────────────┘ [complete]  │
     │                                                 │
     ├──[click node]────►┌──────────────┐             │
     │                    │ NodeSelected │             │
     │                    └──────┬───────┘             │
     │                           │                     │
     │                           ├──[drag]──►┌────────────────┐
     │                           │            │ DraggingNode   │
     │                           │            └────────┬───────┘
     │                           │                     │
     │                           │◄────[drop]──────────┘
     │                           │
     │                           ├──[click other]──► loop back
     │                           │
     │                           └──[click canvas]──►┌──────────────┐
     │                                               │ BoxSelecting │
     │                                               └──────────────┘
     │                                                      │
     │◄─────────────────────────────────────────────────────┘
     │
     └──[right-click]──►┌──────────┐
                         │ Panning  │
                         └──────────┘
```

## References

- [Dart 3 Sealed Classes](https://dart.dev/language/class-modifiers#sealed)
- [Pattern Matching in Dart](https://dart.dev/language/patterns)
- [State Machine Pattern](https://refactoring.guru/design-patterns/state)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*