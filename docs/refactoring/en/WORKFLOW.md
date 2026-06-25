# Diagram Editor Refactoring Workflow

## Overview

This workflow guides the systematic refactoring of the Bkdmm diagram editor from a tightly-coupled ER diagram implementation to a reusable, extensible framework supporting multiple diagram types.

## Workflow Stages

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              WORKFLOW OVERVIEW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ Phase 1 │───►│ Phase 2 │───►│ Phase 3 │───►│ Phase 4 │───►│ Phase 5 │  │
│  │Foundation│    │ Handlers│    │Commands │    │Migration│    │Extension│  │
│  │ 2-3 days│    │ 2-3 days│    │ 1-2 days│    │ 2-3 days│    │Ongoing  │  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
│       │              │              │              │              │        │
│       ▼              ▼              ▼              ▼              ▼        │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ Tests   │    │ Tests   │    │ Tests   │    │ Tests   │    │ Tests   │  │
│  │ Pass    │    │ Pass    │    │ Pass    │    │ Pass    │    │ Pass    │  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation (2-3 days)

### Objective
Create the core infrastructure for event handling and spatial indexing.

### Prerequisites
- [ ] Read all documentation in `docs/refactoring/en/`
- [ ] Understand current `er_diagram` implementation
- [ ] Ensure Flutter analyze passes with no errors

### Tasks

#### Day 1: Event Infrastructure

```
Morning (3-4 hours):
├── Create directory structure
│   ├── lib/shared/diagram_editor/handlers/
│   ├── lib/shared/diagram_editor/spatial/
│   └── lib/shared/diagram_editor/commands/
│
├── Create diagram_event.dart
│   ├── DiagramEvent (sealed class)
│   ├── DiagramPointerDownEvent
│   ├── DiagramPointerMoveEvent
│   ├── DiagramPointerUpEvent
│   └── DiagramHoverEvent
│
└── Create diagram_context.dart
    ├── DiagramContext class
    ├── HitTestResult class
    └── Convenience methods

Afternoon (3-4 hours):
├── Create diagram_handler.dart
│   ├── DiagramEventHandler (abstract)
│   ├── priority property
│   ├── canHandle() method
│   └── handle() method
│
├── Create handler_registry.dart
│   ├── HandlerRegistry class
│   ├── register() method
│   ├── dispatch() method
│   └── getCursor() method
│
└── Write unit tests
    ├── test/handlers/diagram_event_test.dart
    ├── test/handlers/handler_registry_test.dart
    └── All tests passing ✓
```

#### Day 2: Spatial Indexing

```
Morning (3-4 hours):
├── Create spatial_index.dart
│   ├── SpatialIndex interface
│   ├── BoundedItem class
│   ├── insert() / remove() / update()
│   ├── queryPoint() / queryRect()
│   └── queryTopmost()
│
├── Create simple_index.dart
│   ├── SimpleSpatialIndex implementation
│   └── O(n) but with early exit
│
└── Write unit tests
    ├── test/spatial/simple_index_test.dart
    └── Performance benchmarks

Afternoon (3-4 hours):
├── Create quadtree.dart (optional, for Phase 4)
│   ├── _QuadNode class
│   ├── QuadtreeSpatialIndex
│   └── O(log n) queries
│
├── Create diagram_spatial_index.dart
│   ├── Multi-layer index (nodes, anchors, edges)
│   ├── hitTest() with priority
│   └── Integration with DiagramState
│
└── Write integration tests
    └── test/spatial/diagram_spatial_index_test.dart
```

#### Day 3: Integration & Documentation

```
Morning (2-3 hours):
├── Update diagram_editor.dart exports
│   └── Export new modules
│
├── Create example/test harness
│   └── Simple test canvas using new infrastructure
│
└── Verify all tests pass
    └── flutter test

Afternoon (2-3 hours):
├── Update documentation
│   ├── Update README.md with actual file paths
│   └── Add usage examples
│
└── Code review checkpoint
    ├── Self-review against coding standards
    └── Ready for Phase 2
```

### Deliverables

| File | Status |
|------|--------|
| `handlers/diagram_event.dart` | [x] Created |
| `handlers/diagram_context.dart` | [x] Created |
| `handlers/diagram_handler.dart` | [x] Created |
| `handlers/handler_registry.dart` | [x] Created |
| `spatial/spatial_index.dart` | [x] Created |
| `spatial/simple_index.dart` | [x] Created |
| `spatial/diagram_spatial_index.dart` | [x] Created (included in simple_index.dart) |
| `test/handlers/*_test.dart` | [x] Created |
| `test/spatial/*_test.dart` | [x] Created |

### Acceptance Criteria

- [x] All unit tests pass
- [x] `flutter analyze` shows no errors
- [x] Handler registry can dispatch events to handlers
- [x] Spatial index can perform hit testing
- [x] Code follows project style guide

---

## Phase 2: Core Handlers (2-3 days)

### Objective
Implement all event handlers for diagram interactions.

### Prerequisites
- [ ] Phase 1 complete
- [ ] All tests passing
- [ ] Understanding of current gesture handling in ER diagram

### Tasks

#### Day 1: High-Priority Handlers

```
Morning (3-4 hours):
├── Create anchor_click_handler.dart
│   ├── Priority: 10 (highest)
│   ├── canHandle: pointer down on anchor
│   ├── handle: trigger connection start
│   ├── Double-tap detection
│   └── Unit tests

Afternoon (3-4 hours):
├── Create node_drag_handler.dart
│   ├── Priority: 20
│   ├── Drag threshold (distinguish tap vs drag)
│   ├── Multi-node drag support
│   ├── State tracking: _isDragging, _startPosition
│   └── Unit tests

└── Integration test
    └── Test handler chain: anchor → node → canvas
```

#### Day 2: Medium-Priority Handlers

```
Morning (3-4 hours):
├── Create connection_handler.dart
│   ├── Priority: 30
│   ├── Connection preview
│   ├── Anchor-to-anchor validation
│   ├── Connection completion
│   └── Unit tests

Afternoon (3-4 hours):
├── Create selection_handler.dart
│   ├── Priority: 50
│   ├── Box selection
│   ├── Selection rect rendering
│   ├── Node intersection check
│   └── Unit tests
```

#### Day 3: Low-Priority Handlers & Integration

```
Morning (3-4 hours):
├── Create canvas_pan_handler.dart
│   ├── Priority: 100 (lowest, fallback)
│   ├── Mode-aware: edit vs preview
│   ├── Right-click pan in edit mode
│   └── Unit tests

Afternoon (3-4 hours):
├── Create hover_handler.dart (optional)
│   ├── Update hoveredNodeId
│   └── Cursor changes

├── Integration testing
│   ├── Test all handlers together
│   ├── Test priority ordering
│   └── Test edge cases
│
└── Update exports
```

### Deliverables

| File | Status |
|------|--------|
| `handlers/anchor_click_handler.dart` | [ ] Created |
| `handlers/node_drag_handler.dart` | [ ] Created |
| `handlers/connection_handler.dart` | [ ] Created |
| `handlers/selection_handler.dart` | [ ] Created |
| `handlers/canvas_pan_handler.dart` | [ ] Created |
| `test/handlers/*_handler_test.dart` | [ ] Created |

### Acceptance Criteria

- [ ] All handlers have unit tests
- [ ] Priority ordering verified
- [ ] Tap vs drag threshold works
- [ ] Selection box calculates correctly
- [ ] Canvas pan respects mode

---

## Phase 3: Command Pattern (1-2 days)

### Objective
Implement undo/redo support with the Command pattern.

### Prerequisites
- [ ] Phase 2 complete
- [ ] Understanding of operations that need undo

### Tasks

#### Day 1: Command Infrastructure

```
Morning (3-4 hours):
├── Create commands/diagram_command.dart
│   ├── DiagramCommand interface
│   ├── execute() / undo() / redo()
│   ├── canMergeWith() / mergeWith()
│   ├── toJson() / fromJson()
│   └── id, description, timestamp
│
├── Create controllers/history_controller.dart
│   ├── HistoryController class
│   ├── Undo/Redo stacks
│   ├── execute() / undo() / redo()
│   ├── clear()
│   └── History change stream
│
└── Unit tests

Afternoon (3-4 hours):
├── Create move_node_command.dart
│   ├── nodeId, oldPosition, newPosition
│   ├── Merging for continuous drag
│   └── Unit tests
│
├── Create add_edge_command.dart
│   ├── Create/delete edge pair
│   └── Unit tests
│
└── Create delete_elements_command.dart
    ├── Multi-select deletion
    ├── Store deleted data for undo
    └── Unit tests
```

#### Day 2: Integration & Keyboard Shortcuts

```
Morning (2-3 hours):
├── Create providers/history_provider.dart
│   ├── historyControllerProvider
│   ├── canUndoProvider
│   └── canRedoProvider
│
├── Update DiagramCanvas
│   ├── Add HistoryController
│   ├── Execute commands instead of direct mutation
│   └── Keyboard shortcut handling (Ctrl+Z/Y)

Afternoon (2-3 hours):
├── Create composite_command.dart
│   ├── Batch multiple commands
│   └── Atomic undo/redo
│
├── Integration tests
│   ├── Undo drag operation
│   ├── Undo connection creation
│   ├── Redo after undo
│   └── History limit
│
└── Update toolbar
    └── Undo/Redo buttons
```

### Deliverables

| File | Status |
|------|--------|
| `commands/diagram_command.dart` | [ ] Created |
| `commands/move_node_command.dart` | [ ] Created |
| `commands/add_edge_command.dart` | [ ] Created |
| `commands/delete_elements_command.dart` | [ ] Created |
| `commands/composite_command.dart` | [ ] Created |
| `controllers/history_controller.dart` | [ ] Created |
| `providers/history_provider.dart` | [ ] Created |

### Acceptance Criteria

- [ ] Ctrl+Z triggers undo
- [ ] Ctrl+Y triggers redo
- [ ] All mutations are undoable
- [ ] History persists across state changes
- [ ] Composite commands work atomically

---

## Phase 4: ER Diagram Migration (2-3 days)

### Objective
Migrate existing ER diagram to use the new framework.

### Prerequisites
- [ ] Phases 1-3 complete
- [ ] All tests passing
- [ ] Backup of current ER implementation

### Tasks

#### Day 1: Prepare for Migration

```
Morning (2-3 hours):
├── Create ERDiagramCanvasV2 (copy)
│   └── Don't modify original yet
│
├── Identify ER-specific logic
│   ├── Entity rendering
│   ├── Field anchors
│   ├── Edge rendering (crow's foot)
│   └── Entity editor callbacks
│
└── Plan handler customization
    └── What handlers need ER-specific behavior?

Afternoon (3-4 hours):
├── Create ER-specific handlers
│   ├── ERConnectionHandler (field-level)
│   └── ERNodeDragHandler (update GraphNode)
│
├── Create ER-specific commands
│   ├── ERMoveNodeCommand (via ProjectNotifier)
│   └── ERAddEdgeCommand (via ProjectNotifier)
│
└── Unit tests for ER-specific classes
```

#### Day 2: Migration

```
Morning (3-4 hours):
├── Update ERDiagramCanvasV2
│   ├── Extend DiagramCanvas
│   ├── Override createHandlers()
│   ├── Override createSpatialIndex()
│   └── Remove redundant code
│
├── Update ERDiagramUINotifier
│   ├── Use InteractionController
│   ├── Use HistoryController
│   └── Remove duplicate state

Afternoon (3-4 hours):
├── Test V2 against original
│   ├── All interactions work
│   ├── Performance is better or equal
│   └── Visual output identical
│
└── Fix any issues
```

#### Day 3: Cutover & Cleanup

```
Morning (2-3 hours):
├── Replace ERDiagramCanvas with V2
│   └── Update imports
│
├── Delete redundant code
│   ├── Old event handling in er_diagram_canvas.dart
│   ├── Duplicate state in er_diagram_ui_state.dart
│   └── Old gesture handling in widgets
│
└── Run flutter analyze

Afternoon (2-3 hours):
├── Integration testing
│   ├── Create entity
│   ├── Move entity
│   ├── Create connection
│   ├── Box select
│   ├── Undo/Redo
│   └── All ER features
│
└── Update documentation
    └── Mark Phase 4 complete
```

### Deliverables

| Task | Status |
|------|--------|
| ER-specific handlers | [ ] Created |
| ER-specific commands | [ ] Created |
| ERDiagramCanvas migrated | [ ] Complete |
| Redundant code removed | [ ] Deleted |
| All ER tests pass | [ ] Verified |

### Acceptance Criteria

- [ ] All existing ER functionality preserved
- [ ] Code reduced by ~40%
- [ ] Performance improved (hit testing)
- [ ] Undo/Redo works for all operations
- [ ] `flutter analyze` clean

---

## Phase 5: Extensions (Ongoing)

### Objective
Add new diagram types using the framework.

### Future Diagram Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Future Diagram Types                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Flowchart                    UML Class Diagram                     │
│  ├── ProcessNode             ├── ClassNode                          │
│  ├── DecisionNode            ├── InterfaceNode                      │
│  ├── StartEndNode            └── InheritanceEdge                    │
│  └── FlowEdge                                                      │
│                                                                      │
│  Mind Map                    Network Diagram                        │
│  ├── TopicNode               ├── DeviceNode                         │
│  ├── BranchNode              ├── ConnectionNode                     │
│  └── RadialLayout            └── NetworkEdge                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Adding a New Diagram Type

```
Step 1: Define Node Types
├── Create lib/features/[type]/
│   ├── models/[type]_node.dart
│   └── models/[type]_edge.dart
│
Step 2: Create Custom Handlers (if needed)
├── Create handlers specific to diagram
│   └── e.g., FlowchartConnectionHandler
│
Step 3: Create Canvas
├── Create [type]_canvas.dart
│   ├── Extend DiagramCanvas
│   ├── Override createHandlers()
│   └── Override rendering methods
│
Step 4: Create Commands
├── Create commands for mutations
│   └── e.g., AddFlowNodeCommand
│
Step 5: Test & Document
├── Create tests
└── Update documentation
```

### Example: Flowchart Implementation

```dart
// 1. Define nodes
class FlowchartNode extends DiagramNode {
  final FlowchartNodeType type;
  // ...
}

// 2. Create canvas
class FlowchartCanvas extends DiagramCanvas {
  @override
  List<DiagramEventHandler> createHandlers() {
    return [
      FlowchartConnectionHandler(),
      NodeDragHandler(),
      SelectionHandler(),
      CanvasPanHandler(),
    ];
  }
}

// 3. Create commands
class AddFlowNodeCommand extends DiagramCommand {
  final FlowchartNode node;
  // ...
}
```

---

## Testing Strategy

### Unit Tests

```
test/
├── handlers/
│   ├── diagram_event_test.dart
│   ├── handler_registry_test.dart
│   ├── anchor_click_handler_test.dart
│   ├── node_drag_handler_test.dart
│   └── ...
│
├── commands/
│   ├── move_node_command_test.dart
│   ├── add_edge_command_test.dart
│   └── history_controller_test.dart
│
└── spatial/
    ├── simple_index_test.dart
    └── diagram_spatial_index_test.dart
```

### Integration Tests

```
test/integration/
├── diagram_canvas_test.dart
├── er_diagram_test.dart
└── undo_redo_flow_test.dart
```

### Widget Tests

```
test/widgets/
├── diagram_toolbar_test.dart
├── node_widget_test.dart
└── connection_preview_test.dart
```

---

## Quality Gates

### Each Phase Must Pass

```
┌─────────────────────────────────────────────────────────────────────┐
│                        QUALITY GATES                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. flutter analyze ─────────────────────► No errors, no warnings   │
│                                                                      │
│  2. flutter test ─────────────────────────► All tests passing       │
│                                                                      │
│  3. Code coverage ───────────────────────► > 80% for new code       │
│                                                                      │
│  4. Performance ──────────────────────────► No regression           │
│                                                                      │
│  5. Documentation ────────────────────────► Updated README          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Rollback Plan

### If Phase Fails

```
Phase 1-3 Failure:
├── These are additive changes
├── Simply delete new files
└── No impact on existing code

Phase 4 Failure:
├── Keep ERDiagramCanvasV2 separate
├── Revert to original ERDiagramCanvas
└── V2 can be fixed and retried

Phase 5 Failure:
├── New diagram type isolated
└── Remove its directory
```

---

## Progress Tracking

### Checklist

#### Phase 1: Foundation
- [ ] Day 1: Event infrastructure complete
- [ ] Day 2: Spatial indexing complete
- [ ] Day 3: Integration & docs complete
- [ ] All tests passing
- [ ] Code review approved

#### Phase 2: Handlers
- [ ] Day 1: High-priority handlers
- [ ] Day 2: Medium-priority handlers
- [ ] Day 3: Low-priority & integration
- [ ] All tests passing
- [ ] Code review approved

#### Phase 3: Commands
- [ ] Day 1: Command infrastructure
- [ ] Day 2: Integration & shortcuts
- [ ] All tests passing
- [ ] Code review approved

#### Phase 4: Migration
- [ ] Day 1: Preparation complete
- [ ] Day 2: Migration complete
- [ ] Day 3: Cutover & cleanup
- [ ] All ER tests passing
- [ ] Code review approved

#### Phase 5: Extensions
- [ ] Flowchart support
- [ ] UML class diagram support
- [ ] Other diagram types

---

## Daily Workflow

### Start of Day

```
1. Pull latest changes
   $ git pull origin refactor/ui-tdesign-full

2. Check current task
   $ Read this workflow document

3. Run tests to verify clean state
   $ flutter test
   $ flutter analyze
```

### During Development

```
1. Create feature branch (if not exists)
   $ git checkout -b refactor/diagram-editor-phase-N

2. Write code + tests
   $ Follow TDD: test first, then implementation

3. Run tests frequently
   $ flutter test test/handlers/

4. Commit often
   $ git commit -m "feat(handlers): add anchor click handler"
```

### End of Day

```
1. Run all tests
   $ flutter test

2. Run analyze
   $ flutter analyze

3. Commit & push
   $ git push origin refactor/diagram-editor-phase-N

4. Update this workflow document
   $ Check completed items
```

---

## Communication

### Daily Standup Format

```
Yesterday:
- Completed: [tasks]
- Blocked: [issues]

Today:
- Working on: [tasks]
- Need help with: [questions]

Blockers:
- [Description of blocker]
```

### Code Review Checklist

```
□ Code follows style guide
□ All tests passing
□ No unnecessary complexity
□ Documentation updated
□ No commented-out code
□ Meaningful variable names
□ Single responsibility principle
□ No magic numbers
```

---

*Workflow Version: 1.0*
*Last Updated: 2025-06-25*
