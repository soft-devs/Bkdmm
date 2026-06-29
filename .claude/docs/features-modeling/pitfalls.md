# Modeling Module Pitfalls and Solutions

## Entity Editor Pitfalls

### 1. Empty ID on New Field/Index

**Problem:** When creating new Field or Index from UI, the `id` may be empty string.

**Location:** `entity_editor_view.dart` lines 468-476, 511-517

**Solution:** Check and generate ID before saving:
```dart
onAddField: (fieldData) {
  final newField = fieldData.id.isEmpty
      ? fieldData.copyWith(id: IdGenerator.generate())
      : fieldData;
  // ... save to project
},
```

**Why it happens:** Dialog creates Field/Index with empty ID, relying on parent to generate.

---

### 2. TextController Not Syncing with Entity Updates

**Problem:** When entity updates from project state, TextControllers still show old values.

**Location:** `entity_editor_view.dart` lines 68-88

**Solution:** Sync controllers in build():
```dart
Entity currentEntity = widget.entity;
if (project != null) {
  for (final module in project.modules) {
    if (module.id == widget.moduleId) {
      final found = module.entities.where((e) => e.id == widget.entity.id).firstOrNull;
      if (found != null) {
        currentEntity = found;
        if (_titleController.text != found.title) {
          _titleController.text = found.title;
        }
        // ... sync other controllers
      }
    }
  }
}
```

**Warning:** This can cause cursor position reset during typing. Consider debouncing.

---

### 3. isDirty Not Tracking All Changes

**Problem:** `_hasLocalChanges` in EntityEditorView doesn't track field/index changes.

**Location:** `entity_editor_view.dart` line 34

**Explanation:** Field and index changes go directly to ProjectNotifier, bypassing the local dirty flag.

**Better Approach:** Use ProjectNotifier's isDirty flag instead:
```dart
final projectState = ref.watch(projectNotifierProvider);
// Use projectState.isDirty for save indicator
```

---

### 4. Database Type Mapping Incomplete

**Problem:** Only predefined abstract types have mappings; custom types pass through unchanged.

**Location:** `code_preview.dart` lines 197-223

**Current Code:**
```dart
String _getMySQLType(Field field) {
  switch (field.type.toLowerCase()) {
    case 'idorkey': return 'VARCHAR(32)';
    // ... other predefined types
    default:
      return field.length != null
          ? '${field.type.toUpperCase()}(${field.length}...)'
          : field.type.toUpperCase();
  }
}
```

**Risk:** Unknown types like `JSON` or `BLOB` may not map correctly.

**Solution:** Add project-level DataType mapping configuration.

---

## ER Diagram Pitfalls

### 1. graphview Bug: Single Node Not Rendered

**Problem:** When there's only one node with no edges, graphview's `GraphChildDelegate.getVisibleGraphOnly()` only renders the first node.

**Location:** `er_diagram_canvas.dart` lines 1029-1083

**Workaround:** Custom `_ERGraphView` widget that manually renders all nodes:
```dart
class _ERGraphView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    algorithm.run(graph, 0, 0);
    return SizedBox(
      width: virtualCanvasSize,
      height: virtualCanvasSize,
      child: Stack(
        children: [
          // Manually render all nodes
          for (final node in graph.nodes)
            Positioned(
              left: node.x,
              top: node.y,
              child: nodeBuilder(node),
            ),
        ],
      ),
    );
  }
}
```

---

### 2. Node Click Detection in Edit Mode

**Problem:** Node widgets don't receive click events correctly; canvas starts box selection instead.

**Location:** `er_diagram_canvas.dart` lines 274-421

**Root Cause:** Hit testing in graphview doesn't work reliably with Flutter widgets.

**Solution:** Manual hit testing in `_onPointerDown`:
```dart
void _onPointerDown(PointerDownEvent event, ERDiagramUIState uiState) {
  // Transform screen coords to canvas coords
  final transform = _transformationController.value;
  final inverseTransform = Matrix4.inverted(transform);
  final canvasPos = MatrixUtils.transformPoint(inverseTransform, event.localPosition);

  // Check each node
  for (final entity in module.entities) {
    final graphNode = module.graphCanvas.nodes.firstWhere(...);
    final nodeRect = Rect.fromLTWH(graphNode.x, graphNode.y, width, height);
    if (nodeRect.contains(canvasPos)) {
      clickedOnNode = true;
      break;
    }
  }

  if (!clickedOnNode) {
    // Start box selection
  }
}
```

---

### 3. Multi-Select Drag Position Calculation

**Problem:** When dragging multiple selected nodes, other nodes move at wrong speed/direction.

**Location:** `er_diagram_canvas.dart` lines 454-483

**Solution:** Track all start positions when drag begins:
```dart
void startDragging(String nodeId) {
  // ...
  if (state.selectedNodeIds.contains(nodeId) && state.hasMultipleSelected) {
    toDrag = Set<String>.from(state.selectedNodeIds);
  }
}

// In drag handler:
void _handleNodeDrag(PointerMoveEvent event) {
  final scale = transform.getMaxScaleOnAxis();
  final canvasDelta = screenDelta / scale;

  for (final entry in _multiDragStartPositions.entries) {
    final newX = entry.value.dx + canvasDelta.dx;
    final newY = entry.value.dy + canvasDelta.dy;
    projectNotifier.updateGraphNode(moduleId, entry.key, newX, newY);
  }
}
```

---

### 4. Anchor Position Stale After Node Move

**Problem:** Field anchors show at old positions after node is dragged.

**Location:** `er_diagram_canvas.dart` lines 826-853

**Root Cause:** Anchor position is computed once during connection start, not updated during drag.

**Solution:** Recalculate anchor position when completing connection:
```dart
void _onAnchorTap(ERFieldAnchor anchor, GraphNode graphNode) {
  final rowY = headerHeight + (anchor.fieldIndex * fieldRowHeight) + fieldRowHeight / 2;
  final anchorPosition = Offset(
    anchor.direction == ERAnchorDirection.left
        ? graphNode.x - ERFieldAnchorWidget.anchorOffset
        : graphNode.x + ERTableNodeWidget.defaultWidth + ERFieldAnchorWidget.anchorOffset,
    graphNode.y + rowY,
  );

  final updatedAnchor = ERFieldAnchor(
    nodeId: anchor.nodeId,
    fieldIndex: anchor.fieldIndex,
    direction: anchor.direction,
    position: anchorPosition,  // Fresh position
  );
}
```

---

### 5. Right-Click Pan in Edit Mode

**Problem:** InteractiveViewer's pan is disabled in edit mode; canvas can't be panned.

**Location:** `er_diagram_canvas.dart` lines 258-260

**Solution:** Manual right-click drag handling:
```dart
void _onPointerDown(PointerDownEvent event, ERDiagramUIState uiState) {
  if (event.buttons == kSecondaryMouseButton && uiState.isEditMode) {
    _isRightDragging = true;
    _rightDragStart = event.localPosition;
    _rightDragTransformStart = _transformationController.value.clone();
  }
}

void _onPointerMove(PointerMoveEvent event, ERDiagramUIState uiState) {
  if (event.buttons == kSecondaryMouseButton && _isRightDragging) {
    final delta = event.localPosition - _rightDragStart;
    final newMatrix = _rightDragTransformStart.clone();
    newMatrix.translate(delta.dx, delta.dy);
    _transformationController.value = newMatrix;
  }
}
```

---

### 6. GraphNode.moduleName Confusion

**Problem:** `moduleName` field actually stores Entity ID, not module name.

**Location:** `module.dart` line 201

**Historical Reason:** Field name comes from original Bkdmm data format.

**Code Pattern:**
```dart
// Find GraphNode for entity
final graphNode = module.graphCanvas.nodes.firstWhere(
  (gn) => gn.moduleName == entity.id,  // Actually entity ID
);
```

**Recommendation:** Add documentation comment or rename field.

---

### 7. Infinite Canvas Virtual Size

**Problem:** Need infinite canvas but Flutter requires finite dimensions.

**Location:** `er_diagram_canvas.dart` lines 1037-1038

**Solution:** Use large virtual size with `boundaryMargin`:
```dart
static const double virtualCanvasSize = 50000.0;

InteractiveViewer(
  boundaryMargin: const EdgeInsets.all(double.infinity),
  child: SizedBox(
    width: virtualCanvasSize,
    height: virtualCanvasSize,
    child: Stack(...),
  ),
)
```

**Trade-off:** Large virtual size increases memory usage; `boundaryMargin: double.infinity` allows infinite pan.

---

### 8. Grid Drawing Performance

**Problem:** Drawing grid lines for entire virtual canvas is slow.

**Location:** `er_diagram_canvas.dart` lines 1118-1197

**Solution:** Only draw grid in visible area:
```dart
void paint(Canvas canvas, Size size) {
  // Calculate visible area from transform
  final inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
  final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
  final bottomRight = MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height));

  // Only draw lines in visible range
  for (var x = startX; x <= endX; x += gridSize) {
    final screenX = MatrixUtils.transformPoint(matrix, Offset(x, 0)).dx;
    canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
  }
}
```

---

## General Pitfalls

### 1. Provider Family Key Equality

**Problem:** `entityEditProvider` uses `(Entity, String)` as key. Entity equality checks all fields.

**Location:** `entity_provider.dart` line 250

**Risk:** Creating new Entity instance with same ID won't reuse provider state.

**Best Practice:** Always pass the same Entity instance or use Entity.id as key.

---

### 2. State Notifier vs Project Notifier

**Problem:** Confusion about where state lives.

**Guideline:**
- `EntityEditNotifier` - Transient edit state (selectedTab, isDirty)
- `ERDiagramUINotifier` - Transient UI state (selection, viewport)
- `ProjectNotifier` - Persistent business data (entities, graph nodes, edges)

**Rule of Thumb:** If data should be saved to file, it belongs in ProjectNotifier.

---

### 3. CopyWith Pattern with Nullable Fields

**Problem:** `copyWith` with nullable parameters can accidentally set fields to null.

**Example:**
```dart
Entity copyWith({String? remark}) {
  return Entity(
    remark: remark ?? this.remark,  // Can't set remark to null
  );
}
```

**Solution (if nulling is needed):** Use sentinel value or Optional pattern:
```dart
Entity copyWith({String? remark, bool clearRemark = false}) {
  return Entity(
    remark: clearRemark ? null : (remark ?? this.remark),
  );
}
```

---

### 4. DateTime.now() in copyWith

**Problem:** Every copyWith call updates timestamp, even for non-substantive changes.

**Location:** `entity_provider.dart` lines 64-71

**Current Behavior:** All mutations update `updatedAt`.

**Consideration:** This is usually correct for audit purposes, but may cause excessive file churn.

---

## Testing Considerations

### 1. Mock Providers for Widget Tests
```dart
// Provide mock entities
ProviderScope(
  overrides: [
    moduleEntitiesProvider.overrideWith((ref, _) => mockEntities),
  ],
  child: ERDiagramCanvas(moduleId: 'test'),
)
```

### 2. Graph State Testing
```dart
// Test connection creation
final anchor1 = ERFieldAnchor(nodeId: 'e1', fieldIndex: 0, direction: ERAnchorDirection.right, position: Offset.zero);
final anchor2 = ERFieldAnchor(nodeId: 'e2', fieldIndex: 0, direction: ERAnchorDirection.left, position: Offset.zero);

notifier.startConnection(anchor1);
notifier.completeConnection(anchor2);

// Verify edge was created
final edges = ref.read(moduleGraphEdgesProvider('module1'));
expect(edges.length, 1);
expect(edges.first.source, 'e1');
```

---

## Performance Tips

1. **Use `const` constructors** for state classes (EntityEditState, ERDiagramUIState, etc.)
2. **Memoize derived data** with Provider `select`:
   ```dart
   final fieldCount = ref.watch(moduleEntitiesProvider(moduleId).select(
     (entities) => entities.fold(0, (sum, e) => sum + e.fields.length),
   ));
   ```
3. **Debounce rapid updates** for node drag:
   ```dart
   // Consider batching moveNode calls
   void moveNodes(Map<String, Offset> positions) {
     for (final entry in positions.entries) {
       projectNotifier.updateGraphNode(...);
     }
   }
   ```
4. **Use `RepaintBoundary`** around frequently updating widgets (not currently implemented).