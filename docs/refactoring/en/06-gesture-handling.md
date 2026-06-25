# Gesture Handling in Flutter

## Overview

Flutter's gesture system is powerful but can be complex when multiple gesture detectors compete for the same input. This document covers best practices for handling gestures in diagram editors.

## Core Concepts

### Gesture Disambiguation

When multiple gesture detectors are in the widget tree, Flutter uses a **gesture arena** to determine which one wins:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Widget Tree                                   │
│                                                                      │
│  InteractiveViewer (pan)                                            │
│    └── GestureDetector (tap, drag)                                  │
│          └── Listener (pointer events)                              │
│                └── Node Widget                                      │
│                      └── GestureDetector (tap)                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Gesture Arena                                 │
│                                                                      │
│  All GestureRecognizers register with the arena.                    │
│  When a gesture starts, each recognizer claims it.                  │
│  The arena decides which one wins based on:                         │
│  - Gesture type (tap vs drag vs pan)                                │
│  - Timing (which gesture declared first)                            │
│  - Distance threshold                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Listener vs GestureDetector

| Aspect | Listener | GestureDetector |
|--------|----------|-----------------|
| **Level** | Low-level pointer events | High-level gesture recognition |
| **Events** | onPointerDown/Move/Up | onTap, onPan, onScale, etc. |
| **Conflict Handling** | None (all events received) | Uses gesture arena |
| **Use Case** | Custom gesture logic | Standard gestures |
| **Hit Test Behavior** | Configurable | Opaque by default |

### HitTestBehavior

```dart
enum HitTestBehavior {
  /// Events pass through to children and siblings
  deferToChild,

  /// Events hit this widget and can pass to children
  translucent,

  /// Events hit this widget only (children don't receive)
  opaque,
}
```

## Common Problems in Diagram Editors

### Problem 1: Pan Conflicts with Node Drag

```dart
// Problem: Both InteractiveViewer and GestureDetector want to handle drag
InteractiveViewer(
  panEnabled: true,  // ❌ Competes with node drag
  child: Stack(
    children: nodes.map((node) => GestureDetector(
      onPanUpdate: (details) {
        // ❌ Might not receive events if pan wins
        moveNode(node.id, details.localPosition);
      },
      child: NodeWidget(node),
    )).toList(),
  ),
)
```

**Solution: Conditional Pan**

```dart
InteractiveViewer(
  panEnabled: !isEditingMode || isRightClick,  // ✅ Only pan when not editing
  child: Stack(
    children: nodes.map((node) => GestureDetector(
      onPanStart: (details) {
        // ✅ Will receive events because pan is disabled
        startDrag(node.id, details.localPosition);
      },
      onPanUpdate: (details) {
        moveNode(node.id, details.localPosition);
      },
      child: NodeWidget(node),
    )).toList(),
  ),
)
```

### Problem 2: Tap vs Drag Disambiguation

```dart
// Problem: How to distinguish tap from drag?
GestureDetector(
  onTap: () {
    // Called on tap
  },
  onPanStart: (details) {
    // Called on drag start
    // But also fires on tap if finger moves slightly!
  },
  child: Widget(),
)
```

**Solution: Drag Threshold**

```dart
class TapOrDragHandler extends StatefulWidget {
  final VoidCallback onTap;
  final void Function(Offset position) onDragStart;
  final void Function(Offset delta) onDragUpdate;
  final VoidCallback onDragEnd;

  const TapOrDragHandler({...});
}

class _TapOrDragHandlerState extends State<TapOrDragHandler> {
  bool _isDragging = false;
  Offset? _startPosition;
  static const double dragThreshold = 5.0; // pixels

  void _handlePointerDown(PointerDownEvent event) {
    _startPosition = event.localPosition;
    _isDragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_startPosition == null) return;

    final delta = event.localPosition - _startPosition!;

    if (!_isDragging && delta.distance > dragThreshold) {
      _isDragging = true;
      widget.onDragStart(_startPosition!);
    }

    if (_isDragging) {
      widget.onDragUpdate(event.localPosition - _lastPosition);
    }
    _lastPosition = event.localPosition;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isDragging) {
      widget.onTap();
    } else {
      widget.onDragEnd();
    }
    _startPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: widget.child,
    );
  }
}
```

### Problem 3: Right-Click Handling

```dart
// Problem: GestureDetector doesn't distinguish left/right click
GestureDetector(
  onSecondaryTap: () {
    // Only fires on tap, not on drag
  },
  // No onSecondaryPanStart!
)
```

**Solution: Use Listener**

```dart
Listener(
  onPointerDown: (event) {
    if (event.buttons & kSecondaryMouseButton != 0) {
      // Right-click down
      _startRightClickDrag(event.localPosition);
    } else if (event.buttons & kPrimaryMouseButton != 0) {
      // Left-click down
      _startLeftClickAction(event.localPosition);
    }
  },
  onPointerMove: (event) {
    if (event.buttons & kSecondaryMouseButton != 0) {
      // Right-click drag
      _updateRightClickDrag(event.localPosition);
    }
  },
  child: Widget(),
)
```

### Problem 4: Event Propagation Control

```dart
// Problem: Events bubble up to parent handlers
Stack(
  children: [
    // Parent listener
    Listener(
      onPointerDown: (event) {
        // Always fires
      },
      child: Container(),
    ),
    // Child listener
    Listener(
      onPointerDown: (event) {
        // Also fires
        // How to stop propagation?
      },
      child: NodeWidget(),
    ),
  ],
)
```

**Solution: HitTestBehavior**

```dart
Stack(
  children: [
    // Parent listener
    Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // Fires if no child handled it
      },
      child: Container(),
    ),
    // Child listener
    Listener(
      behavior: HitTestBehavior.opaque,  // ✅ Blocks events from parent
      onPointerDown: (event) {
        // Fires and stops propagation
      },
      child: NodeWidget(),
    ),
  ],
)
```

## Best Practices for Diagram Editors

### 1. Use Listener for Canvas-Level Events

```dart
// Canvas uses Listener for complete control
class DiagramCanvas extends StatefulWidget {
  @override
  State<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends State<DiagramCanvas> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,  // Capture all events
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,  // Scroll wheel
      child: Stack(
        children: [
          InteractiveViewer(
            panEnabled: false,  // We handle pan ourselves
            scaleEnabled: true,
            child: CustomPaint(...),
          ),
          // Overlay elements (selection rect, connection preview)
          ..._buildOverlays(),
        ],
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    // Check which button
    if (event.buttons & kPrimaryMouseButton != 0) {
      _handleLeftClick(event);
    } else if (event.buttons & kSecondaryMouseButton != 0) {
      _handleRightClick(event);
    }
  }
}
```

### 2. Use GestureDetector for Node-Level Events

```dart
// Nodes use GestureDetector for simple gestures
class NodeWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final void Function(DragStartDetails)? onDragStart;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onPanStart: onDragStart,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd != null ? (_) => onDragEnd!() : null,
      child: Container(...),
    );
  }
}
```

### 3. Use RawGestureDetector for Custom Gestures

```dart
// When you need fine control over gesture recognition
RawGestureDetector(
  gestures: {
    PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
      () => PanGestureRecognizer(),
      (instance) {
        instance.onStart = _onPanStart;
        instance.onUpdate = _onPanUpdate;
        instance.onEnd = _onPanEnd;
        instance.dragStartBehavior = DragStartBehavior.start;
      },
    ),
    ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
      () => ScaleGestureRecognizer(),
      (instance) {
        instance.onStart = _onScaleStart;
        instance.onUpdate = _onScaleUpdate;
      },
    ),
  },
  child: Widget(),
)
```

### 4. Coordinate Conversion

```dart
class DiagramCanvasState extends State<DiagramCanvas> {
  final TransformationController _transformController = TransformationController();

  /// Convert screen coordinates to scene coordinates
  Offset toScene(Offset localPosition) {
    final matrix = _transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, localPosition);
  }

  /// Convert scene coordinates to screen coordinates
  Offset toScreen(Offset scenePosition) {
    return MatrixUtils.transformPoint(_transformController.value, scenePosition);
  }

  /// Get current zoom level
  double get zoom => _transformController.value.getMaxScaleOnAxis();

  void _onPointerDown(PointerDownEvent event) {
    final scenePosition = toScene(event.localPosition);
    // Work in scene coordinates
    final hitNode = _hitTest(scenePosition);
  }
}
```

### 5. Mode-Based Gesture Handling

```dart
enum InteractionMode {
  preview,  // Left-click pans, no node interaction
  edit,     // Left-click selects/drags, right-click pans
}

class DiagramCanvasState extends State<DiagramCanvas> {
  InteractionMode _mode = InteractionMode.edit;

  void _onPointerDown(PointerDownEvent event) {
    switch (_mode) {
      case InteractionMode.preview:
        if (event.buttons & kPrimaryMouseButton != 0) {
          _startPan(event.localPosition);
        }
        break;

      case InteractionMode.edit:
        if (event.buttons & kPrimaryMouseButton != 0) {
          final scenePos = toScene(event.localPosition);
          final hitResult = _hitTest(scenePos);

          if (hitResult.isOnAnchor) {
            _startConnection(hitResult.anchorId);
          } else if (hitResult.isOnNode) {
            _startDrag(hitResult.nodeId, scenePos);
          } else {
            _startSelection(event.localPosition);
          }
        } else if (event.buttons & kSecondaryMouseButton != 0) {
          _startPan(event.localPosition);
        }
        break;
    }
  }
}
```

## Mouse Button Constants

```dart
// From Flutter's gestures.dart
const int kPrimaryMouseButton = 0x01;       // Left button
const int kSecondaryMouseButton = 0x02;     // Right button
const int kTertiaryMouseButton = 0x04;      // Middle button
const int kBackMouseButton = 0x08;          // Back button
const int kForwardMouseButton = 0x10;       // Forward button

// Check button
if (event.buttons & kPrimaryMouseButton != 0) {
  // Left button is pressed
}
```

## Keyboard State Check

```dart
// Check modifier keys during pointer event
void _onPointerDown(PointerDownEvent event) {
  final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.controlLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.controlRight);

  final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.shiftLeft);

  final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.altLeft);

  if (isCtrlPressed && event.buttons & kPrimaryMouseButton != 0) {
    // Ctrl+Click: Add to selection
  }
}
```

## References

- [Flutter Gestures Documentation](https://docs.flutter.dev/ui/advanced/gestures)
- [GestureDetector Class](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [Listener Class](https://api.flutter.dev/flutter/widgets/Listener-class.html)
- [RawGestureDetector Class](https://api.flutter.dev/flutter/widgets/RawGestureDetector-class.html)
- [HitTestBehavior Enum](https://api.flutter.dev/flutter/rendering/HitTestBehavior.html)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*