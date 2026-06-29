# Modeling Module API Reference

## Entity Editor API

### EntityEditorView

Main view for editing database entities.

```dart
class EntityEditorView extends ConsumerStatefulWidget {
  final Entity entity;      // Entity to edit
  final String moduleId;    // Parent module ID

  const EntityEditorView({
    super.key,
    required this.entity,
    required this.moduleId,
  });
}
```

**Features:**
- 4-tab interface: Summary, Fields, Indexes, Preview
- Real-time sync with ProjectNotifier
- Unsaved changes indicator
- Entity statistics display

**Tab Structure:**
| Tab Index | Content |
|-----------|---------|
| 0 | Summary - Basic info, statistics, fields preview |
| 1 | Fields - FieldTable widget |
| 2 | Indexes - IndexEditor widget |
| 3 | Preview - CodePreview widget |

---

### EntityEditState

Immutable state class for entity editing.

```dart
class EntityEditState {
  final Entity entity;           // Entity being edited
  final String moduleId;         // Parent module ID
  final bool isDirty;            // Has unsaved changes
  final int selectedTab;         // Current tab (0-3)
  final String selectedDatabase; // Database for preview (MYSQL, etc.)

  const EntityEditState({
    required this.entity,
    required this.moduleId,
    this.isDirty = false,
    this.selectedTab = 0,
    this.selectedDatabase = 'MYSQL',
  });

  EntityEditState copyWith({...});
}
```

---

### EntityEditNotifier

StateNotifier managing entity edit operations.

```dart
class EntityEditNotifier extends StateNotifier<EntityEditState> {
  // Basic Info
  void updateBasicInfo({String? title, String? chnname, String? remark});

  // Field Operations
  void addField({String? name, String? type, String? chnname, bool pk, bool notNull, bool autoIncrement, String? remark});
  void updateField(String fieldId, Field updatedField);
  void deleteField(String fieldId);
  void reorderFields(int oldIndex, int newIndex);

  // Index Operations
  void addIndex({String? name, List<String>? fieldIds, IndexType type, String? remark});
  void updateIndex(String indexId, Index updatedIndex);
  void deleteIndex(String indexId);

  // Tab/Database Selection
  void selectTab(int tabIndex);
  void selectDatabase(String databaseCode);

  // State Management
  void markClean();
  void resetEntity(Entity originalEntity);
}
```

**Important:** All mutations automatically sync to ProjectNotifier via `_syncToProject()`.

---

### entityEditProvider

Family provider for per-entity state management.

```dart
final entityEditProvider = StateNotifierProvider.family<
  EntityEditNotifier,
  EntityEditState,
  (Entity, String)  // (entity, moduleId)
>((ref, params) {
  return EntityEditNotifier(ref, params.$1, params.$2);
});
```

**Usage:**
```dart
// Watch entity state
final state = ref.watch(entityEditProvider((entity, moduleId)));

// Update entity
ref.read(entityEditProvider((entity, moduleId)).notifier).updateBasicInfo(title: 'new_name');
```

---

### FieldTable

TDTable-based field editor with inline editing.

```dart
class FieldTable extends StatefulWidget {
  final List<Field> fields;
  final List<DataType> dataTypes;
  final Function(Field) onAddField;
  final Function(String, Field) onUpdateField;
  final Function(String) onDeleteField;
  final Function(int, int) onReorderFields;
}
```

**Columns:**
| Column | Editable | Description |
|--------|----------|-------------|
| # | No | Row number |
| PK | Click | Primary key toggle |
| Name | Inline | Field name |
| Type | Dropdown | Data type selector |
| Chinese Name | Inline | Display name |
| Not Null | Click | Not null toggle |
| Auto Increment | Click | Auto increment toggle |
| Remark | Inline | Field comment |
| Actions | Buttons | Edit/Delete |

---

### IndexEditor

Index configuration widget.

```dart
class IndexEditor extends StatefulWidget {
  final List<Index> indexes;
  final List<Field> availableFields;
  final Function(Index) onAddIndex;
  final Function(String, Index) onUpdateIndex;
  final Function(String) onDeleteIndex;
}
```

**Index Types:**
- `IndexType.normal` - Regular index
- `IndexType.unique` - Unique constraint
- `IndexType.fulltext` - Full-text search (MySQL only)

---

### CodePreview

DDL preview and export widget.

```dart
class CodePreview extends StatefulWidget {
  final Entity entity;
  final List<DatabaseTemplate> databases;
  final String selectedDatabase;
  final Function(String) onDatabaseChanged;
}
```

**Supported Databases:**
| Code | Name | Features |
|------|------|----------|
| MYSQL | MySQL | AUTO_INCREMENT, COMMENT |
| POSTGRESQL | PostgreSQL | TIMESTAMP, SERIAL |
| ORACLE | Oracle | NUMBER, CLOB, SEQUENCE |
| SQLSERVER | SQL Server | IDENTITY, NVARCHAR |

**Type Mapping:**
```dart
// Abstract type -> Database-specific type
'idorkey' -> VARCHAR(32)
'name'    -> VARCHAR(128)
'intro'   -> VARCHAR(512)
'longtext' -> TEXT/CLOB/NVARCHAR(MAX)
'integer' -> INT/INTEGER/NUMBER(10)
'long'    -> BIGINT/NUMBER(19)
'money'   -> DECIMAL(32,8)
'datetime' -> DATETIME/TIMESTAMP
'yesno'   -> VARCHAR(1)/CHAR(1)
```

---

## ER Diagram API

### ERDiagramCanvas

Main canvas for ER diagram visualization.

```dart
class ERDiagramCanvas extends ConsumerStatefulWidget {
  final String moduleId;
  final void Function(Entity entity)? onEntityEdit;     // Edit mode double-click
  final void Function(Entity entity)? onEntityPreview;  // Preview mode double-click
  final void Function(Offset position, Entity? entity)? onContextMenu;
}
```

**Interaction Modes:**

| Mode | Pan | Select | Drag Node | Connect | Double-Click |
|------|-----|--------|-----------|---------|--------------|
| Preview | Left-drag | - | - | - | Preview popup |
| Edit | Right-drag | Left-click/Ctrl+click/Box | Left-drag | Anchor click | Edit popup |

**Toolbar Actions:**
- Preview mode toggle
- Edit mode toggle
- Zoom in/out
- Fit to screen
- Auto layout (Sugiyama)

---

### ERDiagramUIState

UI-only state (no business data).

```dart
class ERDiagramUIState {
  final String moduleId;
  final ERInteractionMode interactionMode;  // preview/edit
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final Set<String> draggingNodeIds;
  final ERViewportState viewport;
  final ERConnectionState connection;
  final ERSelectionState selection;

  // Computed properties
  bool get isEditMode;
  bool get isPreviewMode;
  bool get isConnecting;
  bool get isDragging;
  bool get isSelecting;
  bool get hasMultipleSelected;
}
```

---

### ERDiagramUINotifier

UI state management (business data in ProjectNotifier).

```dart
class ERDiagramUINotifier extends StateNotifier<ERDiagramUIState> {
  // Mode
  void setInteractionMode(ERInteractionMode mode);
  void enterPreviewMode();
  void enterEditMode();
  void toggleMode();

  // Selection
  void selectNodeSingle(String nodeId);
  void selectNodeMultiple(String nodeId);  // Ctrl+click behavior
  void selectNodesByRect(Set<String> nodeIds);
  void clearSelection();
  void selectAll(List<String> nodeIds);
  void setHoveredNode(String? nodeId);

  // Drag
  void startDragging(String nodeId);
  void endDragging();
  void moveNode(String entityId, double x, double y);
  void moveNodes(Map<String, Offset> positions);

  // Connection
  void startConnection(ERFieldAnchor sourceAnchor);
  void updateConnectionPreview(Offset position);
  void cancelConnection();
  void completeConnection(ERFieldAnchor targetAnchor);

  // Selection Box
  void startSelection(Offset startPoint);
  void updateSelection(Offset currentPoint);
  void completeSelection(Map<String, Rect> nodeRects);
  void cancelSelection();

  // Viewport
  void setZoom(double zoom);
  void zoomIn();
  void zoomOut();
  void setPan(Offset pan);
  void resetViewport();

  // Layout
  void applyLayout(Map<String, Offset> positions);
}
```

---

### erDiagramUIProvider

Family provider for per-module UI state.

```dart
final erDiagramUIProvider = StateNotifierProvider.family<
  ERDiagramUINotifier,
  ERDiagramUIState,
  String  // moduleId
>((ref, moduleId) => ERDiagramUINotifier(ref, moduleId));
```

---

### Helper Providers

```dart
// Get module entities
final moduleEntitiesProvider = Provider.family<List<Entity>, String>((ref, moduleId));

// Get graph nodes
final moduleGraphNodesProvider = Provider.family<List<GraphNode>, String>((ref, moduleId));

// Get graph edges
final moduleGraphEdgesProvider = Provider.family<List<GraphEdge>, String>((ref, moduleId));

// Check if module has entities
final hasModuleEntitiesProvider = Provider.family<bool, String>((ref, moduleId));

// Get entity count
final moduleEntityCountProvider = Provider.family<int, String>((ref, moduleId));
```

---

### ERGraphBuilder

Converts Module data to graphview Graph.

```dart
class ERGraphBuilder {
  static const double nodeWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double minNodeHeight = 80.0;

  Graph buildGraph(Module module);
  Node? getNode(String nodeId);

  // Anchor position calculation
  static Offset calculateAnchorPosition(
    Offset nodePosition,
    Entity entity,
    int fieldIndex,
    ERAnchorDirection direction,
  );

  static List<ERFieldAnchor> getFieldAnchors(
    String nodeId,
    Entity entity,
    Offset nodePosition,
  );
}
```

---

### ERTableNodeWidget

Flutter-rendered table node.

```dart
class ERTableNodeWidget extends StatefulWidget {
  final Node node;
  final Entity entity;
  final GraphNode graphNode;
  final bool isSelected;
  final ERInteractionMode interactionMode;
  final bool isDarkMode;
  final void Function(ERFieldAnchor, GraphNode)? onAnchorTap;
  final void Function(bool isCtrlPressed)? onTap;
  final VoidCallback? onDoubleTap;
  final void Function(DragStartDetails)? onDragStart;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragEnd;

  // Layout constants
  static const double defaultWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double cornerRadius = 8.0;

  // Size calculation
  static double calculateNodeHeight(int fieldCount);
  static Size calculateNodeSize(int fieldCount);
}
```

---

### ERFieldAnchorWidget

Connection anchor for field-level relationships.

```dart
class ERFieldAnchorWidget extends StatelessWidget {
  final ERAnchorDirection direction;
  final int fieldIndex;
  final bool isPrimaryKey;
  final VoidCallback? onTap;

  // Layout constants
  static const double visualSize = 6.0;    // Visible dot size
  static const double hitSize = 20.0;      // Clickable area
  static const double anchorOffset = 8.0;  // Distance from node edge
}
```

**Anchor Direction:**
- `ERAnchorDirection.left` - Outgoing connection
- `ERAnchorDirection.right` - Incoming connection

---

### ERFieldAnchor

Data class for field anchor.

```dart
class ERFieldAnchor {
  final String nodeId;           // Entity ID
  final int fieldIndex;          // Field position
  final ERAnchorDirection direction;
  final Offset position;         // Absolute position

  String get id => '$nodeId:field:$fieldIndex:${direction.name}';
}
```

---

### NoOpLayoutAlgorithm

Layout algorithm that preserves node positions.

```dart
class NoOpLayoutAlgorithm extends Algorithm {
  // Does not modify node positions
  // Used when nodes are manually positioned
}
```

---

## Provider Dependencies

```
projectNotifierProvider
       ↓
       ├── moduleEntitiesProvider
       ├── moduleGraphNodesProvider
       ├── moduleGraphEdgesProvider
       │
       └── ERDiagramUINotifier
              ↓
              └── updateGraphNode/addGraphEdge → projectNotifierProvider
```

**Key Insight:** ER diagram business data (node positions, edges) is stored in `Project.modules[].graphCanvas`, not in `ERDiagramUIState`. The UI state only tracks transient interaction state (selection, viewport, connection preview).