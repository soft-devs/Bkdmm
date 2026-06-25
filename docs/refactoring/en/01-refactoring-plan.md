# Diagram Editor Refactoring Plan

## Executive Summary

This document outlines the refactoring plan for the Bkdmm diagram editor module. The goal is to transform the current ER diagram implementation into a reusable, extensible framework that supports multiple diagram types (ER diagrams, flowcharts, UML diagrams, etc.).

## Current State Analysis

### Existing Architecture

```
lib/
├── shared/diagram_editor/          # Generic framework (partial)
│   ├── core/
│   │   ├── diagram_node.dart       # ✅ Node abstraction + anchors
│   │   ├── diagram_edge.dart       # ✅ Edge abstraction
│   │   ├── diagram_state.dart      # ✅ State definitions
│   │   └── diagram_canvas.dart     # ✅ Canvas base class
│   ├── layout/
│   │   └── layout_engine.dart      # ✅ Layout interface
│   └── render/
│       └── renderers.dart          # ✅ Renderer interface
│
└── features/modeling/er_diagram/   # ER diagram implementation
    ├── er_diagram.dart
    ├── widgets/
    │   ├── er_diagram_canvas.dart  # ❌ Duplicates DiagramCanvas logic
    │   ├── er_table_node_widget.dart
    │   └── er_field_anchor_widget.dart
    ├── models/
    │   └── er_diagram_ui_state.dart
    └── providers/
        └── er_diagram_ui_provider.dart
```

### Problems Identified

1. **Duplicated Event Handling Logic**
   - ~400 lines in `er_diagram_canvas.dart`
   - ~80 lines in `er_table_node_widget.dart`
   - ~50 lines in `er_field_anchor_widget.dart`
   - Event interception via `Listener` causes scattered logic

2. **No Undo/Redo Support**
   - All operations are irreversible
   - Users cannot recover from mistakes

3. **O(n) Hit Testing Performance**
   - Every click iterates through all nodes
   - Will become bottleneck with large diagrams (100+ nodes)

4. **Gesture Conflicts**
   - Node drag conflicts with canvas pan
   - Anchor click conflicts with node selection
   - Selection box conflicts with node interaction

5. **Tight Coupling**
   - ER-specific logic mixed with generic canvas logic
   - Adding new diagram types requires significant refactoring

## Target Architecture

```
lib/shared/diagram_editor/
├── core/
│   ├── diagram_node.dart           # Node abstraction
│   ├── diagram_edge.dart           # Edge abstraction
│   ├── diagram_state.dart          # State definitions
│   └── diagram_canvas.dart         # Enhanced canvas base
│
├── controllers/                    # NEW: Controllers layer
│   ├── interaction_controller.dart # Interaction state management
│   ├── selection_controller.dart   # Selection management
│   ├── viewport_controller.dart    # Viewport (zoom/pan)
│   └── history_controller.dart     # Undo/redo
│
├── handlers/                       # NEW: Event handlers
│   ├── handler_registry.dart       # Handler registry
│   ├── diagram_event.dart          # Event definitions
│   ├── diagram_context.dart        # Context for handlers
│   ├── anchor_click_handler.dart   # Anchor click handling
│   ├── node_drag_handler.dart      # Node drag handling
│   ├── selection_handler.dart      # Selection box handling
│   ├── canvas_pan_handler.dart     # Canvas pan handling
│   └── connection_handler.dart     # Connection creation
│
├── commands/                       # NEW: Command pattern
│   ├── diagram_command.dart        # Command interface
│   ├── move_node_command.dart      # Move node command
│   ├── add_edge_command.dart       # Add edge command
│   ├── delete_elements_command.dart
│   └── composite_command.dart      # Batch commands
│
├── spatial/                        # NEW: Spatial indexing
│   ├── spatial_index.dart          # Interface
│   ├── quadtree.dart               # Quadtree implementation
│   └── simple_index.dart           # Simple bounding box index
│
├── layout/
│   ├── layout_engine.dart          # Layout interface
│   ├── hierarchical_layout.dart    # Sugiyama layout
│   ├── tree_layout.dart            # Tree layout
│   └── force_layout.dart           # Force-directed layout
│
└── widgets/
    ├── diagram_toolbar.dart        # Generic toolbar
    ├── mini_map.dart               # Navigation mini-map
    └── coordinate_display.dart     # Cursor coordinates
```

## Key Patterns

### 1. Event Delegation Pattern

Instead of scattered event handlers, all events flow through a central registry:

```
User Input → Listener → HandlerRegistry → Matching Handler → State Update
                ↓
         HitTestContext (spatial index)
```

**Benefits:**
- Single source of truth for event routing
- Priority-based conflict resolution
- Easy to add/remove handlers
- Testable in isolation

### 2. Command Pattern for Undo/Redo

Every mutating operation is wrapped as a command:

```dart
abstract class DiagramCommand {
  void execute();
  void undo();
  String get description;
}
```

**Benefits:**
- Full undo/redo support
- Operation history for debugging
- Batch operations support

### 3. State Machine for Interactions

Use Dart 3 sealed classes for exhaustive state handling:

```dart
sealed class InteractionState {
  const InteractionState();
  InteractionState handle(DiagramEvent event);
}

class Idle extends InteractionState { ... }
class NodeDragging extends InteractionState { ... }
class Connecting extends InteractionState { ... }
class BoxSelecting extends InteractionState { ... }
```

**Benefits:**
- Compiler enforces exhaustive handling
- Clear state transitions
- Impossible to have invalid states

### 4. Spatial Indexing

Replace O(n) hit testing with O(log n):

```
Simple Index (for < 100 nodes):
  - Map<String, Rect> bounding boxes
  - Linear scan but with early rejection

Quadtree (for 100+ nodes):
  - Hierarchical spatial subdivision
  - O(log n) average case query
```

## Implementation Phases

### Phase 1: Foundation (2-3 days)

**Goals:**
- Create handlers infrastructure
- Implement basic event delegation
- Add spatial indexing

**Files to Create:**
- `handlers/diagram_event.dart`
- `handlers/diagram_context.dart`
- `handlers/handler_registry.dart`
- `handlers/diagram_handler.dart` (abstract class)
- `spatial/spatial_index.dart`
- `spatial/simple_index.dart`

**Acceptance Criteria:**
- Handler registry can register and dispatch events
- Spatial index can perform hit testing
- Unit tests pass

### Phase 2: Core Handlers (2-3 days)

**Goals:**
- Implement essential handlers
- Integrate with existing DiagramCanvas

**Files to Create:**
- `handlers/anchor_click_handler.dart`
- `handlers/node_drag_handler.dart`
- `handlers/selection_handler.dart`
- `handlers/canvas_pan_handler.dart`
- `handlers/connection_handler.dart`

**Acceptance Criteria:**
- Node drag works correctly
- Selection box functions
- Canvas pan works in all modes
- Anchor click triggers connection

### Phase 3: Command Pattern (1-2 days)

**Goals:**
- Implement command infrastructure
- Add undo/redo support

**Files to Create:**
- `commands/diagram_command.dart`
- `commands/move_node_command.dart`
- `commands/add_edge_command.dart`
- `commands/delete_elements_command.dart`
- `controllers/history_controller.dart`

**Acceptance Criteria:**
- Ctrl+Z triggers undo
- Ctrl+Y / Ctrl+Shift+Z triggers redo
- All mutations are undoable

### Phase 4: ER Diagram Migration (2-3 days)

**Goals:**
- Migrate ER diagram to use new framework
- Remove duplicate code

**Files to Modify:**
- `features/modeling/er_diagram/er_diagram_canvas.dart`
- Delete redundant event handling code

**Acceptance Criteria:**
- ER diagram inherits from DiagramCanvas
- All existing functionality preserved
- Code reduced by ~40%

### Phase 5: New Diagram Types (Ongoing)

**Goals:**
- Add flowchart support
- Add UML class diagram support

**Example - Flowchart:**
```dart
class FlowchartCanvas extends DiagramCanvas {
  @override
  List<DiagramEventHandler> createHandlers() => [
    NodeDragHandler(),
    ConnectionHandler(edgeType: 'flow'),
    SelectionHandler(),
    CanvasPanHandler(),
  ];
}
```

## Performance Targets

| Metric | Current | Target |
|--------|---------|--------|
| Hit Testing (100 nodes) | O(n) ~5ms | O(log n) ~0.5ms |
| Event Dispatch | N/A | < 1ms |
| Node Count Support | ~100 | ~500+ |
| Memory per Node | ~2KB | ~1KB |

## Testing Strategy

### Unit Tests
- Handler priority ordering
- State transitions
- Command undo/redo correctness
- Spatial index accuracy

### Integration Tests
- Full interaction flows
- Multi-gesture scenarios
- Performance benchmarks

### Widget Tests
- Canvas rendering
- Toolbar functionality
- Mini-map accuracy

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing ER functionality | Medium | High | Incremental migration, extensive testing |
| Performance regression | Low | Medium | Benchmark before/after |
| Learning curve for new patterns | Medium | Low | Documentation, code examples |

## References

- [Flutter Gesture Disambiguation](https://docs.flutter.dev/ui/advanced/gestures)
- [Dart Sealed Classes](https://dart.dev/language/class-modifiers#sealed)
- [Command Pattern](https://refactoring.guru/design-patterns/command)
- [Quadtree Spatial Indexing](https://en.wikipedia.org/wiki/Quadtree)

## Appendix: File Checklist

### New Files (22 files)

**Controllers (4):**
- [ ] `controllers/interaction_controller.dart`
- [ ] `controllers/selection_controller.dart`
- [ ] `controllers/viewport_controller.dart`
- [ ] `controllers/history_controller.dart`

**Handlers (8):**
- [ ] `handlers/diagram_event.dart`
- [ ] `handlers/diagram_context.dart`
- [ ] `handlers/diagram_handler.dart`
- [ ] `handlers/handler_registry.dart`
- [ ] `handlers/anchor_click_handler.dart`
- [ ] `handlers/node_drag_handler.dart`
- [ ] `handlers/selection_handler.dart`
- [ ] `handlers/canvas_pan_handler.dart`

**Commands (4):**
- [ ] `commands/diagram_command.dart`
- [ ] `commands/move_node_command.dart`
- [ ] `commands/add_edge_command.dart`
- [ ] `commands/delete_elements_command.dart`

**Spatial (2):**
- [ ] `spatial/spatial_index.dart`
- [ ] `spatial/simple_index.dart`

**Widgets (2):**
- [ ] `widgets/diagram_toolbar.dart`
- [ ] `widgets/coordinate_display.dart`

### Modified Files (4 files)

- [ ] `core/diagram_canvas.dart` - Add handler integration
- [ ] `core/diagram_state.dart` - Add history state
- [ ] `features/modeling/er_diagram/er_diagram_canvas.dart` - Migrate to base class
- [ ] `diagram_editor.dart` - Export new modules

### Deleted Files (0 files)

No files will be deleted. Old code will be deprecated and removed in a future phase.

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*
