# Diagram Editor Refactoring Documentation

This directory contains comprehensive documentation for refactoring the Bkdmm diagram editor module.

## Document Index

| # | Document | Description |
|---|----------|-------------|
| 01 | [Refactoring Plan](01-refactoring-plan.md) | Overall refactoring strategy, phases, and file checklist |
| 02 | [Event Delegation Pattern](02-event-delegation-pattern.md) | Centralized event handling with priority-based dispatch |
| 03 | [Command Pattern](03-command-pattern-undo-redo.md) | Undo/redo implementation with command objects |
| 04 | [Spatial Indexing](04-spatial-indexing.md) | O(log n) hit testing with quadtree/spatial index |
| 05 | [State Machine Pattern](05-state-machine-pattern.md) | Dart 3 sealed classes for interaction states |
| 06 | [Gesture Handling](06-gesture-handling.md) | Flutter gesture disambiguation and best practices |
| 07 | [GraphView Library](07-graphview-library.md) | GraphView capabilities and limitations |
| 08 | [Riverpod Architecture](08-riverpod-architecture.md) | State management patterns with Riverpod |

## Quick Start

### Current Architecture Problems

1. **~400 lines of event handling code** scattered across multiple widgets
2. **No undo/redo** - all operations are irreversible
3. **O(n) hit testing** - performance degrades with node count
4. **Gesture conflicts** - node drag vs canvas pan
5. **Tight coupling** - ER-specific logic mixed with generic code

### Target Architecture

```
lib/shared/diagram_editor/
├── controllers/           # State management
│   ├── interaction_controller.dart
│   ├── selection_controller.dart
│   ├── viewport_controller.dart
│   └── history_controller.dart
│
├── handlers/              # Event handling (NEW)
│   ├── handler_registry.dart
│   ├── anchor_click_handler.dart
│   ├── node_drag_handler.dart
│   ├── selection_handler.dart
│   └── canvas_pan_handler.dart
│
├── commands/              # Undo/redo (NEW)
│   ├── diagram_command.dart
│   ├── move_node_command.dart
│   └── add_edge_command.dart
│
├── spatial/               # Hit testing (NEW)
│   ├── spatial_index.dart
│   └── quadtree.dart
│
└── widgets/
    ├── diagram_canvas.dart
    └── diagram_toolbar.dart
```

### Implementation Phases

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| 1. Foundation | 2-3 days | Handler registry, spatial index |
| 2. Core Handlers | 2-3 days | All event handlers |
| 3. Commands | 1-2 days | Undo/redo system |
| 4. ER Migration | 2-3 days | Migrate ER diagram to new framework |
| 5. Extensions | Ongoing | Flowchart, UML diagrams |

## Key Patterns

### Event Delegation

```dart
// Single entry point for all events
Listener(
  onPointerDown: (event) => handlerRegistry.dispatch(event, context),
  child: Canvas(),
)

// Priority-based handling
handlers = [
  AnchorClickHandler(priority: 10),   // First
  NodeDragHandler(priority: 20),      // Second
  SelectionHandler(priority: 50),     // Third
  CanvasPanHandler(priority: 100),    // Last
];
```

### Command Pattern

```dart
// Every mutation is a command
final command = MoveNodeCommand(
  nodeId: 'table1',
  oldPosition: Offset(100, 100),
  newPosition: Offset(200, 150),
);

historyController.execute(command);  // Execute + track
historyController.undo();            // Reverse
historyController.redo();            // Re-execute
```

### State Machine

```dart
// Exhaustive state handling with sealed classes
sealed class InteractionState { ... }
class IdleState extends InteractionState { ... }
class DraggingNodeState extends InteractionState { ... }
class ConnectingState extends InteractionState { ... }

// Compiler ensures all states are handled
switch (state) {
  case IdleState(): return 'Ready';
  case DraggingNodeState(:final nodeId): return 'Dragging $nodeId';
  // Missing cases = compiler error
}
```

### Spatial Index

```dart
// O(log n) instead of O(n)
final hitResult = spatialIndex.hitTest(point);

// Quadtree for large graphs
if (nodeCount > 100) {
  spatialIndex = QuadtreeSpatialIndex(bounds: canvasBounds);
}
```

## Performance Targets

| Metric | Current | Target |
|--------|---------|--------|
| Hit Testing (100 nodes) | ~5ms | ~0.5ms |
| Event Dispatch | N/A | < 1ms |
| Max Nodes | ~100 | ~500+ |
| Memory per Node | ~2KB | ~1KB |

## File Checklist

### New Files (22)

- [ ] `controllers/interaction_controller.dart`
- [ ] `controllers/selection_controller.dart`
- [ ] `controllers/viewport_controller.dart`
- [ ] `controllers/history_controller.dart`
- [ ] `handlers/diagram_event.dart`
- [ ] `handlers/diagram_context.dart`
- [ ] `handlers/diagram_handler.dart`
- [ ] `handlers/handler_registry.dart`
- [ ] `handlers/anchor_click_handler.dart`
- [ ] `handlers/node_drag_handler.dart`
- [ ] `handlers/selection_handler.dart`
- [ ] `handlers/canvas_pan_handler.dart`
- [ ] `commands/diagram_command.dart`
- [ ] `commands/move_node_command.dart`
- [ ] `commands/add_edge_command.dart`
- [ ] `commands/delete_elements_command.dart`
- [ ] `spatial/spatial_index.dart`
- [ ] `spatial/simple_index.dart`
- [ ] `spatial/quadtree.dart`
- [ ] `widgets/diagram_toolbar.dart`
- [ ] `widgets/coordinate_display.dart`
- [ ] `providers/history_provider.dart`

### Modified Files (4)

- [ ] `core/diagram_canvas.dart`
- [ ] `core/diagram_state.dart`
- [ ] `features/modeling/er_diagram/er_diagram_canvas.dart`
- [ ] `diagram_editor.dart` (exports)

## References

### Flutter Documentation
- [Flutter Gestures](https://docs.flutter.dev/ui/advanced/gestures)
- [Flutter Performance](https://docs.flutter.dev/perf)

### Dart Features
- [Dart 3 Sealed Classes](https://dart.dev/language/class-modifiers#sealed)
- [Pattern Matching](https://dart.dev/language/patterns)

### Design Patterns
- [Command Pattern](https://refactoring.guru/design-patterns/command)
- [State Pattern](https://refactoring.guru/design-patterns/state)
- [Chain of Responsibility](https://refactoring.guru/design-patterns/chain-of-responsibility)

### Libraries
- [Riverpod](https://riverpod.dev)
- [GraphView](https://pub.dev/packages/graphview)

---

*Documentation Version: 1.0*
*Last Updated: 2025-06-25*
