# Modeling Module Data Models

## Entity Editor Data Models

### EntityEditState

```dart
class EntityEditState {
  final Entity entity;           // The entity being edited
  final String moduleId;         // Parent module ID
  final bool isDirty;            // Unsaved changes flag
  final int selectedTab;         // Current tab (0=summary, 1=fields, 2=indexes, 3=preview)
  final String selectedDatabase; // Selected database for DDL preview
}
```

**State Transitions:**
```
Initial → Editing (isDirty=true) → Saved (isDirty=false)
                                  ↓
                              Reset (original entity restored)
```

---

## ER Diagram UI State Models

### ERDiagramUIState

Root state class - only UI state, no business data.

```dart
class ERDiagramUIState {
  final String moduleId;
  final ERInteractionMode interactionMode;
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final Set<String> draggingNodeIds;
  final ERViewportState viewport;
  final ERConnectionState connection;
  final ERSelectionState selection;
}
```

**Design Principle:**
- Business data (node positions, edges) stored in `Project.modules[].graphCanvas`
- UI state (selection, viewport, interaction) stored in `ERDiagramUIState`
- Clear separation of concerns

---

### ERInteractionMode

```dart
enum ERInteractionMode {
  preview,  // Read-only: pan, zoom, preview popups
  edit,     // Full edit: drag, connect, select
}
```

---

### ERViewportState

```dart
class ERViewportState {
  final double zoom;      // 0.1 to 5.0
  final Offset pan;       // Canvas offset
}
```

---

### ERConnectionState

```dart
class ERConnectionState {
  final bool isConnecting;
  final ERFieldAnchor? sourceAnchor;
  final Offset previewEnd;  // Current mouse position during connection
}
```

**Connection Flow:**
```
1. Click anchor → startConnection(sourceAnchor)
2. Move mouse   → updateConnectionPreview(position)
3a. Click target → completeConnection(targetAnchor) → Create GraphEdge
3b. Escape/Cancel → cancelConnection()
```

---

### ERSelectionState

```dart
class ERSelectionState {
  final bool isSelecting;
  final Offset startPoint;     // Screen coordinates
  final Offset currentPoint;   // Screen coordinates

  Rect get selectionRect;      // Computed selection rectangle
}
```

**Box Selection Flow:**
```
1. Click empty area → startSelection(startPoint)
2. Drag mouse       → updateSelection(currentPoint)
3. Release          → completeSelection(nodeRects) → selectedNodeIds updated
```

---

### ERFieldAnchor

```dart
class ERFieldAnchor {
  final String nodeId;           // Entity ID
  final int fieldIndex;          // 0-based field position
  final ERAnchorDirection direction;
  final Offset position;         // Absolute canvas position

  String get id => '$nodeId:field:$fieldIndex:${direction.name}';
}
```

**ID Format:** `entity_abc:field:2:left` = Entity "entity_abc", field index 2, left anchor

---

### ERAnchorDirection

```dart
enum ERAnchorDirection {
  left,   // Outgoing connection point
  right,  // Incoming connection point
}
```

---

## Business Data Models (from shared/models)

### Entity

```dart
class Entity {
  final String id;
  final String title;       // Table name (English)
  final String chnname;     // Table name (Chinese)
  final String? remark;
  final List<Field> fields;
  final List<Index> indexes;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<Field> get primaryKeys;  // Fields where pk == true

  // Validation
  bool validateFieldIds();
  bool validateIndexIds();
  bool validateAllIds();
  bool hasEmptyFieldIds();
  bool hasEmptyIndexIds();
}
```

---

### Field

```dart
class Field {
  final String id;
  final String name;          // Column name
  final String type;          // Data type code (String, Int, etc.)
  final String chnname;       // Display name (Chinese)
  final String? remark;
  final bool pk;              // Primary key
  final bool notNull;
  final bool autoIncrement;
  final String? defaultValue;
  final int? length;
  final int? decimal;
}
```

---

### Index

```dart
class Index {
  final String id;
  final String name;
  final List<String> fieldIds;  // References to Field.id
  final IndexType type;
  final String? remark;

  List<String> getFieldNames(List<Field> fields);  // Resolve field IDs to names
}
```

---

### IndexType

```dart
enum IndexType {
  normal,    // Regular index
  unique,    // Unique constraint
  fulltext,  // Full-text search (MySQL)
}
```

---

### Module

```dart
class Module {
  final String id;
  final String name;         // Module code (English)
  final String chnname;      // Module name (Chinese)
  final String? description;
  final List<Entity> entities;
  final GraphCanvas graphCanvas;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Validation
  bool validateEntityIds();
  bool validateAllIds();
  bool hasEmptyIds();
  Module fixAllIds();  // Auto-fix empty/duplicate IDs
}
```

---

### GraphCanvas

```dart
class GraphCanvas {
  final List<GraphNode> nodes;  // Node positions
  final List<GraphEdge> edges;  // Relationships
  final Viewport? viewport;     // Saved viewport state
}
```

---

### GraphNode

```dart
class GraphNode {
  final String title;       // Format: "tableName:index"
  final double x;           // X position
  final double y;           // Y position
  final String? moduleName; // Entity ID reference
}
```

**Note:** `moduleName` actually stores the Entity ID, not a module name.

---

### GraphEdge

```dart
class GraphEdge {
  final String source;       // Source entity ID
  final String target;       // Target entity ID
  final String? sourceField; // Source field index (as string)
  final String? targetField; // Target field index (as string)
  final String? label;
  final String? relationType;  // "1:1", "1:N", "N:1", "N:M"
}
```

---

### Viewport

```dart
class Viewport {
  final double scale;    // Zoom level
  final double offsetX;  // Pan X
  final double offsetY;  // Pan Y
}
```

---

## Data Relationships

```
Project
  └── modules: List<Module>
        ├── entities: List<Entity>
        │     ├── fields: List<Field>
        │     └── indexes: List<Index>
        │           └── fieldIds: List<String> → Field.id
        │
        └── graphCanvas: GraphCanvas
              ├── nodes: List<GraphNode>
              │     └── moduleName → Entity.id
              │
              └── edges: List<GraphEdge>
                    ├── source → Entity.id
                    └── target → Entity.id
```

---

## State Synchronization

### Entity Editor Sync

```
User edits field
       ↓
EntityEditNotifier.updateField()
       ↓
_syncToProject()
       ↓
ProjectNotifier.updateProject()
       ↓
Project state updated
       ↓
All listeners rebuild
```

### ER Diagram Sync

```
User drags node
       ↓
ERDiagramUINotifier.moveNode()
       ↓
ProjectNotifier.updateGraphNode()
       ↓
Project.modules[].graphCanvas.nodes updated
       ↓
moduleGraphNodesProvider rebuilds
       ↓
ERDiagramCanvas rebuilds
```

**Key Point:** Both editors write to the same Project state, ensuring consistency.