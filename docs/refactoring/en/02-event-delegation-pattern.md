# Event Delegation Pattern for Flutter Diagram Editor

## Overview

The Event Delegation Pattern centralizes event handling logic in a single registry, replacing scattered event handlers across multiple widgets. This pattern is ideal for complex interactive UIs like diagram editors where multiple gesture types compete for the same input.

## Problem: Scattered Event Handlers

### Current Approach (Problematic)

```dart
// In er_diagram_canvas.dart (400+ lines)
class _ERDiagramCanvasState extends ConsumerState<ERDiagramCanvas> {
  void _onPointerDown(PointerDownEvent event) {
    // Check if clicking on anchor...
    // Check if clicking on node...
    // Check if clicking on canvas...
    // Update state based on mode...
    // Handle right mouse button...
  }

  void _onPointerMove(PointerMoveEvent event) { /* similar complexity */ }
  void _onPointerUp(PointerUpEvent event) { /* similar complexity */ }
}

// In er_table_node_widget.dart (80+ lines)
class _ERTableNodeWidgetState extends State<ERTableNodeWidget> {
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        // Intercept event to prevent canvas handling
      },
      child: GestureDetector(
        onTap: _onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        // ... more handlers
      ),
    );
  }
}

// In er_field_anchor_widget.dart (50+ lines)
class ERFieldAnchorWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        onTap?.call();
      },
      // ... more handlers
    );
  }
}
```

### Issues with Current Approach

1. **Event Interception Complexity**: Using `Listener` to block events from propagating creates unclear event flow
2. **State Checking Everywhere**: Each handler must check `isEditMode`, `isSelecting`, `isConnecting`
3. **Gesture Conflicts**: Node drag and canvas pan compete for the same gesture
4. **Testing Difficulty**: Event logic is embedded in widgets, hard to test in isolation
5. **Code Duplication**: Similar hit-testing logic repeated in multiple places

## Solution: Event Delegation Pattern

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          User Input                                  │
│                     (PointerDown/Move/Up)                           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Listener                                    │
│                    (Single Entry Point)                              │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       HitTestContext                                 │
│              (Spatial Index + Coordinate Conversion)                 │
│                                                                      │
│  scenePosition: Offset                                               │
│  hitNodeId: String?                                                  │
│  hitAnchorId: String?                                                │
│  hitEdgeId: String?                                                  │
│  isCtrlPressed: bool                                                 │
│  isShiftPressed: bool                                                │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       HandlerRegistry                                │
│                    (Priority Chain)                                  │
│                                                                      │
│  ┌─────────────────┐                                                 │
│  │ AnchorHandler   │ priority: 10  ← Check first                    │
│  └─────────────────┘                                                 │
│  ┌─────────────────┐                                                 │
│  │ NodeDragHandler │ priority: 20                                    │
│  └─────────────────┘                                                 │
│  ┌─────────────────┐                                                 │
│  │ ConnectionHdlr  │ priority: 30                                    │
│  └─────────────────┘                                                 │
│  ┌─────────────────┐                                                 │
│  │ SelectionHdlr   │ priority: 50                                    │
│  └─────────────────┘                                                 │
│  ┌─────────────────┐                                                 │
│  │ CanvasPanHandler │ priority: 100  ← Check last                   │
│  └─────────────────┘                                                 │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                           First Match
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       DiagramHandler                                 │
│                   (Handles the Event)                                │
│                                                                      │
│  canHandle(event, context) → bool                                    │
│  handle(event, context) → void                                       │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       State Update                                   │
│              (via Notifier/Controller)                               │
└─────────────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. DiagramEvent (Sealed Class)

```dart
/// lib/shared/diagram_editor/handlers/diagram_event.dart

sealed class DiagramEvent {
  final Offset localPosition;   // Screen coordinates
  final Offset scenePosition;   // Canvas coordinates (transformed)
  final PointerDeviceKind deviceKind;
  final int buttons;            // Which mouse buttons are pressed
  final DateTime timestamp;

  const DiagramEvent({
    required this.localPosition,
    required this.scenePosition,
    required this.deviceKind,
    required this.buttons,
    required this.timestamp,
  });

  /// Check if primary (left) mouse button is pressed
  bool get isPrimaryButton => buttons & kPrimaryMouseButton != 0;

  /// Check if secondary (right) mouse button is pressed
  bool get isSecondaryButton => buttons & kSecondaryMouseButton != 0;
}

/// Pointer down event
class DiagramPointerDownEvent extends DiagramEvent {
  const DiagramPointerDownEvent({...});
}

/// Pointer move event
class DiagramPointerMoveEvent extends DiagramEvent {
  final Offset delta;  // Movement since last event

  const DiagramPointerMoveEvent({
    required this.delta,
    ...super arguments
  });
}

/// Pointer up event
class DiagramPointerUpEvent extends DiagramEvent {
  const DiagramPointerUpEvent({...});
}

/// Hover event (no button pressed)
class DiagramHoverEvent extends DiagramEvent {
  const DiagramHoverEvent({...});
}

/// Scroll/wheel event
class DiagramScrollEvent extends DiagramEvent {
  final Offset scrollDelta;

  const DiagramScrollEvent({
    required this.scrollDelta,
    ...super arguments
  });
}
```

#### 2. DiagramContext (Read-only View for Handlers)

```dart
/// lib/shared/diagram_editor/handlers/diagram_context.dart

class DiagramContext {
  /// Current diagram state
  final DiagramState state;

  /// Scene position of the pointer
  final Offset scenePosition;

  /// Node ID at pointer position (null if not on a node)
  final String? hitNodeId;

  /// Anchor ID at pointer position (null if not on an anchor)
  final String? hitAnchorId;

  /// Edge ID at pointer position (null if not on an edge)
  final String? hitEdgeId;

  /// Whether Ctrl key is pressed
  final bool isCtrlPressed;

  /// Whether Shift key is pressed
  final bool isShiftPressed;

  /// Whether Alt key is pressed
  final bool isAltPressed;

  /// Whether in edit mode
  final bool isEditMode;

  /// Whether in preview/move mode
  final bool isPreviewMode;

  const DiagramContext({
    required this.state,
    required this.scenePosition,
    this.hitNodeId,
    this.hitAnchorId,
    this.hitEdgeId,
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
  });

  // Convenience methods

  /// Check if pointer is on a specific node
  bool isOnNode(String nodeId) => hitNodeId == nodeId;

  /// Check if pointer is on a specific anchor
  bool isOnAnchor(String anchorId) => hitAnchorId == anchorId;

  /// Check if pointer is on canvas (not on any element)
  bool isOnCanvas => hitNodeId == null && hitAnchorId == null && hitEdgeId == null;

  /// Check if pointer is on any element
  bool isOnElement => hitNodeId != null || hitAnchorId != null || hitEdgeId != null;

  /// Get the node at pointer position
  DiagramNode? get hitNode => hitNodeId != null ? state.getNode(hitNodeId!) : null;

  /// Get the anchor at pointer position
  AnchorPoint? get hitAnchor => hitAnchorId != null ? state.getAnchor(hitAnchorId!) : null;

  /// Check if there are selected elements
  bool get hasSelection => state.selection.hasSelection;

  /// Check if a specific node is selected
  bool isNodeSelected(String nodeId) => state.selection.isNodeSelected(nodeId);
}
```

#### 3. DiagramHandler (Abstract Base)

```dart
/// lib/shared/diagram_editor/handlers/diagram_handler.dart

abstract class DiagramEventHandler {
  /// Handler priority (lower = higher priority)
  /// Anchors should be checked before nodes, nodes before canvas
  int get priority;

  /// Handler name for debugging
  String get name;

  /// Check if this handler can handle the given event
  /// Returns true if this handler should process the event
  bool canHandle(DiagramEvent event, DiagramContext context);

  /// Handle the event
  /// Called only when canHandle returns true
  void handle(DiagramEvent event, DiagramContext context);

  /// Optional: Reset handler state
  /// Called when interaction is interrupted
  void reset() {}

  /// Optional: Get cursor for current state
  MouseCursor get cursor => MouseCursor.defer;
}
```

#### 4. HandlerRegistry

```dart
/// lib/shared/diagram_editor/handlers/handler_registry.dart

class HandlerRegistry {
  final List<DiagramEventHandler> _handlers = [];

  /// Register a handler
  void register(DiagramEventHandler handler) {
    _handlers.add(handler);
    _handlers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Register multiple handlers
  void registerAll(List<DiagramEventHandler> handlers) {
    for (final handler in handlers) {
      register(handler);
    }
  }

  /// Dispatch an event to the first matching handler
  void dispatch(DiagramEvent event, DiagramContext context) {
    for (final handler in _handlers) {
      if (handler.canHandle(event, context)) {
        handler.handle(event, context);
        return; // Only first handler processes
      }
    }
  }

  /// Get cursor for current context
  /// Checks handlers in priority order
  MouseCursor getCursor(DiagramContext context) {
    for (final handler in _handlers) {
      final cursor = handler.cursor;
      if (cursor != MouseCursor.defer) {
        return cursor;
      }
    }
    return SystemMouseCursors.basic;
  }

  /// Reset all handlers
  void resetAll() {
    for (final handler in _handlers) {
      handler.reset();
    }
  }

  /// Get all registered handlers (for debugging)
  List<DiagramEventHandler> get handlers => List.unmodifiable(_handlers);
}
```

### Concrete Handler Examples

#### AnchorClickHandler (Highest Priority)

```dart
/// lib/shared/diagram_editor/handlers/anchor_click_handler.dart

class AnchorClickHandler extends DiagramEventHandler {
  /// Callback when anchor is clicked
  final void Function(String anchorId, DiagramNode node)? onAnchorTap;

  /// Callback when anchor is double-clicked
  final void Function(String anchorId, DiagramNode node)? onAnchorDoubleTap;

  // Double-tap detection
  String? _lastTappedAnchorId;
  DateTime? _lastTapTime;
  static const _doubleTapThreshold = Duration(milliseconds: 300);

  @override
  int get priority => 10; // Highest priority - anchors are smallest targets

  @override
  String get name => 'AnchorClick';

  @override
  MouseCursor get cursor => SystemMouseCursors.cell;

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // Only handle primary button down on anchors
    if (event is! DiagramPointerDownEvent) return false;
    if (!event.isPrimaryButton) return false;
    return context.hitAnchorId != null;
  }

  @override
  void handle(DiagramEvent event, DiagramContext context) {
    final anchorId = context.hitAnchorId!;
    final node = context.hitNode!;

    // Check for double-tap
    final now = DateTime.now();
    if (_lastTappedAnchorId == anchorId &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapThreshold) {
      onAnchorDoubleTap?.call(anchorId, node);
      _lastTappedAnchorId = null;
      _lastTapTime = null;
    } else {
      onAnchorTap?.call(anchorId, node);
      _lastTappedAnchorId = anchorId;
      _lastTapTime = now;
    }
  }

  @override
  void reset() {
    _lastTappedAnchorId = null;
    _lastTapTime = null;
  }
}
```

#### NodeDragHandler (Medium Priority)

```dart
/// lib/shared/diagram_editor/handlers/node_drag_handler.dart

class NodeDragHandler extends DiagramEventHandler {
  final void Function(String nodeId, Offset startPosition)? onDragStart;
  final void Function(String nodeId, Offset currentPosition)? onDrag;
  final void Function(String nodeId, Offset endPosition)? onDragEnd;

  bool _isDragging = false;
  String? _draggingNodeId;
  Offset? _dragStartPosition;

  /// Drag threshold to distinguish from tap
  static const double dragThreshold = 5.0;

  @override
  int get priority => 20;

  @override
  String get name => 'NodeDrag';

  @override
  MouseCursor get cursor => _isDragging
      ? SystemMouseCursors.grabbing
      : SystemMouseCursors.grab;

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // Must be in edit mode
    if (!context.isEditMode) return false;

    // Pointer down on a node (not anchor)
    if (event is DiagramPointerDownEvent) {
      return event.isPrimaryButton &&
             context.hitNodeId != null &&
             context.hitAnchorId == null;
    }

    // Pointer move while dragging
    if (event is DiagramPointerMoveEvent) {
      return _isDragging;
    }

    // Pointer up while dragging
    if (event is DiagramPointerUpEvent) {
      return _isDragging;
    }

    return false;
  }

  @override
  void handle(DiagramEvent event, DiagramContext context) {
    switch (event) {
      case DiagramPointerDownEvent():
        _draggingNodeId = context.hitNodeId!;
        _dragStartPosition = event.scenePosition;
        _isDragging = false; // Wait for threshold

      case DiagramPointerMoveEvent():
        if (_dragStartPosition == null) return;

        final delta = event.scenePosition - _dragStartPosition!;
        if (!_isDragging && delta.distance > dragThreshold) {
          // Exceeded threshold, start drag
          _isDragging = true;
          onDragStart?.call(_draggingNodeId!, _dragStartPosition!);
        }

        if (_isDragging) {
          onDrag?.call(_draggingNodeId!, event.scenePosition);
        }

      case DiagramPointerUpEvent():
        if (_isDragging) {
          onDragEnd?.call(_draggingNodeId!, event.scenePosition);
        }
        _isDragging = false;
        _draggingNodeId = null;
        _dragStartPosition = null;
    }
  }

  @override
  void reset() {
    _isDragging = false;
    _draggingNodeId = null;
    _dragStartPosition = null;
  }
}
```

#### SelectionHandler (Lower Priority)

```dart
/// lib/shared/diagram_editor/handlers/selection_handler.dart

class SelectionHandler extends DiagramEventHandler {
  final void Function(Rect selectionRect)? onSelectionStart;
  final void Function(Rect selectionRect)? onSelectionUpdate;
  final void Function(Rect selectionRect, Set<String> selectedIds)? onSelectionComplete;

  bool _isSelecting = false;
  Offset? _startPosition;

  @override
  int get priority => 50;

  @override
  String get name => 'Selection';

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // Must be in edit mode
    if (!context.isEditMode) return false;

    // Pointer down on canvas (not on any element)
    if (event is DiagramPointerDownEvent) {
      return event.isPrimaryButton && context.isOnCanvas;
    }

    // Pointer move/up while selecting
    return _isSelecting && (event is DiagramPointerMoveEvent || event is DiagramPointerUpEvent);
  }

  @override
  void handle(DiagramEvent event, DiagramContext context) {
    switch (event) {
      case DiagramPointerDownEvent():
        _isSelecting = true;
        _startPosition = event.localPosition;
        final rect = Rect.fromPoints(_startPosition!, _startPosition!);
        onSelectionStart?.call(rect);

      case DiagramPointerMoveEvent():
        if (_startPosition == null) return;
        final rect = Rect.fromPoints(_startPosition!, event.localPosition);
        onSelectionUpdate?.call(rect);

      case DiagramPointerUpEvent():
        if (_startPosition == null) return;
        final rect = Rect.fromPoints(_startPosition!, event.localPosition);
        final selectedIds = _getNodesInRect(rect, context.state);
        onSelectionComplete?.call(rect, selectedIds);
        _isSelecting = false;
        _startPosition = null;
    }
  }

  Set<String> _getNodesInRect(Rect rect, DiagramState state) {
    final ids = <String>{};
    for (final node in state.nodes.values) {
      final nodeRect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );
      if (rect.overlaps(nodeRect)) {
        ids.add(node.id);
      }
    }
    return ids;
  }

  @override
  void reset() {
    _isSelecting = false;
    _startPosition = null;
  }
}
```

#### CanvasPanHandler (Lowest Priority)

```dart
/// lib/shared/diagram_editor/handlers/canvas_pan_handler.dart

class CanvasPanHandler extends DiagramEventHandler {
  final void Function(Offset delta)? onPan;

  bool _isPanning = false;
  Offset? _startPosition;

  @override
  int get priority => 100; // Lowest priority - fallback handler

  @override
  String get name => 'CanvasPan';

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    // In preview mode: primary button pans
    if (context.isPreviewMode) {
      if (event is DiagramPointerDownEvent) {
        return event.isPrimaryButton;
      }
      return _isPanning && (event is DiagramPointerMoveEvent || event is DiagramPointerUpEvent);
    }

    // In edit mode: secondary (right) button pans
    if (context.isEditMode) {
      if (event is DiagramPointerDownEvent) {
        return event.isSecondaryButton;
      }
      return _isPanning && (event is DiagramPointerMoveEvent || event is DiagramPointerUpEvent);
    }

    return false;
  }

  @override
  void handle(DiagramEvent event, DiagramContext context) {
    switch (event) {
      case DiagramPointerDownEvent():
        _isPanning = true;
        _startPosition = event.localPosition;

      case DiagramPointerMoveEvent():
        if (_startPosition == null) return;
        final delta = event.localPosition - _startPosition!;
        onPan?.call(delta);
        _startPosition = event.localPosition;

      case DiagramPointerUpEvent():
        _isPanning = false;
        _startPosition = null;
    }
  }

  @override
  void reset() {
    _isPanning = false;
    _startPosition = null;
  }
}
```

### Integration with DiagramCanvas

```dart
/// lib/shared/diagram_editor/core/diagram_canvas.dart (enhanced)

abstract class DiagramCanvas extends ConsumerStatefulWidget {
  // ... existing properties

  /// Create handlers for this diagram type
  /// Subclasses override to add specific handlers
  List<DiagramEventHandler> createHandlers();

  const DiagramCanvas({...});
}

abstract class DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  late final HandlerRegistry _handlerRegistry;
  late final SpatialIndex _spatialIndex;

  @override
  void initState() {
    super.initState();
    _handlerRegistry = HandlerRegistry();
    _handlerRegistry.registerAll(widget.createHandlers());
  }

  /// Convert screen coordinates to scene coordinates
  Offset toScene(Offset local);

  /// Perform hit testing using spatial index
  HitTestResult performHitTest(Offset scenePosition) {
    // Check anchors first (higher priority)
    final anchorId = _spatialIndex.hitTestAnchor(scenePosition);
    if (anchorId != null) {
      return HitTestResult(anchorId: anchorId);
    }

    // Check nodes
    final nodeId = _spatialIndex.hitTestNode(scenePosition);
    if (nodeId != null) {
      return HitTestResult(nodeId: nodeId);
    }

    // Check edges
    final edgeId = _spatialIndex.hitTestEdge(scenePosition);
    if (edgeId != null) {
      return HitTestResult(edgeId: edgeId);
    }

    return HitTestResult(); // On canvas
  }

  /// Build context for event dispatch
  DiagramContext buildContext(DiagramEvent event) {
    final hitTest = performHitTest(event.scenePosition);
    final state = watchDiagramState();

    return DiagramContext(
      state: state,
      scenePosition: event.scenePosition,
      hitNodeId: hitTest.nodeId,
      hitAnchorId: hitTest.anchorId,
      hitEdgeId: hitTest.edgeId,
      isCtrlPressed: HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.controlLeft),
      isShiftPressed: HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.shiftLeft),
      isEditMode: state.interaction.mode == InteractionMode.edit,
      isPreviewMode: state.interaction.mode == InteractionMode.move,
    );
  }

  /// Single entry point for all pointer events
  void _dispatchPointerEvent(PointerEvent event) {
    final diagramEvent = _convertEvent(event);
    final context = buildContext(diagramEvent);
    _handlerRegistry.dispatch(diagramEvent, context);
  }

  DiagramEvent _convertEvent(PointerEvent event) {
    final scenePosition = toScene(event.localPosition);

    if (event is PointerDownEvent) {
      return DiagramPointerDownEvent(
        localPosition: event.localPosition,
        scenePosition: scenePosition,
        deviceKind: event.kind,
        buttons: event.buttons,
        timestamp: DateTime.now(),
      );
    }
    // ... other conversions
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _dispatchPointerEvent(e),
      onPointerMove: (e) => _dispatchPointerEvent(e),
      onPointerUp: (e) => _dispatchPointerEvent(e),
      child: MouseRegion(
        cursor: _handlerRegistry.getCursor(buildContext(_lastContext)),
        child: InteractiveViewer(
          // ... viewer config
          child: CustomPaint(
            painter: _createDiagramPainter(watchDiagramState(), isDark),
          ),
        ),
      ),
    );
  }
}
```

### ER Diagram Implementation

```dart
/// lib/features/modeling/er_diagram/er_diagram_canvas.dart

class ERDiagramCanvas extends DiagramCanvas {
  const ERDiagramCanvas({
    super.key,
    required String diagramId,
    super.onEntityEdit,
    super.onEntityPreview,
  }) : super(
    diagramId: diagramId,
    diagramType: 'er_diagram',
    enableSelection: true,
    enableDrag: true,
    enableConnection: true,
  );

  @override
  List<DiagramEventHandler> createHandlers() {
    return [
      // Priority order matters!
      AnchorClickHandler(
        onAnchorTap: _handleAnchorTap,
        onAnchorDoubleTap: _handleAnchorDoubleTap,
      ),
      NodeDragHandler(
        onDragStart: _handleNodeDragStart,
        onDrag: _handleNodeDrag,
        onDragEnd: _handleNodeDragEnd,
      ),
      ConnectionHandler(
        onStart: _handleConnectionStart,
        onUpdate: _handleConnectionUpdate,
        onComplete: _handleConnectionComplete,
      ),
      SelectionHandler(
        onSelectionStart: _handleSelectionStart,
        onSelectionUpdate: _handleSelectionUpdate,
        onSelectionComplete: _handleSelectionComplete,
      ),
      CanvasPanHandler(
        onPan: _handleCanvasPan,
      ),
    ];
  }

  @override
  ConsumerState<DiagramCanvas> createState() => _ERDiagramCanvasState();
}

class _ERDiagramCanvasState extends DiagramCanvasState {
  // Much simpler now - just implement:
  // 1. watchDiagramState()
  // 2. _createDiagramPainter()
  // 3. Handler callback implementations

  @override
  DiagramState watchDiagramState() {
    return ref.watch(erDiagramUIProvider(widget.diagramId));
  }

  @override
  CustomPainter _createDiagramPainter(DiagramState state, bool isDark) {
    return ERDiagramPainter(
      state: state,
      isDarkMode: isDark,
    );
  }

  // Handler callbacks - business logic only
  void _handleAnchorTap(String anchorId, DiagramNode node) {
    final notifier = ref.read(erDiagramUIProvider(widget.diagramId).notifier);
    notifier.startConnection(anchorId);
  }

  void _handleNodeDrag(String nodeId, Offset position) {
    final notifier = ref.read(projectNotifierProvider.notifier);
    notifier.updateGraphNode(widget.diagramId, nodeId, position.dx, position.dy);
  }
}
```

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Event Handling Code** | ~400 lines per widget | ~20 lines per handler |
| **Hit Testing** | O(n) per click | O(log n) via spatial index |
| **Gesture Conflicts** | Manual interception | Priority-based resolution |
| **Testing** | Widget tests only | Handler unit tests |
| **Extensibility** | Modify canvas | Add new handler |
| **Debugging** | Scattered logs | Single dispatch trace |

## References

- [Flutter Gestures Documentation](https://docs.flutter.dev/ui/advanced/gestures)
- [Flutter Listener vs GestureDetector](https://api.flutter.dev/flutter/widgets/Listener-class.html)
- [Chain of Responsibility Pattern](https://refactoring.guru/design-patterns/chain-of-responsibility)
- [Event Delegation in JavaScript](https://javascript.info/event-delegation) (similar concept)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*