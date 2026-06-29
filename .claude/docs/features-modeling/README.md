# Modeling Module Documentation

## Module Path
`bkdmm/lib/features/modeling`

## Overview

Core modeling functionality for database entity design and ER diagram visualization. This module provides two main sub-modules:

1. **Entity Editor** (`entity_editor/`) - Table/entity editing with field management, index configuration, and DDL preview
2. **ER Diagram** (`er_diagram/`) - Visual relationship diagram editor with node positioning, field-level connections, and layout tools

## Architecture

```
modeling/
├── entity_editor/                    # Entity editing sub-module
│   ├── entity_editor.dart           # Barrel file (exports)
│   ├── providers/
│   │   └── entity_provider.dart     # Entity editing state management
│   ├── views/
│   │   └── entity_editor_view.dart  # Main entity editor view
│   └── widgets/
│       ├── field_table.dart         # Field editing table widget
│       ├── index_editor.dart        # Index configuration widget
│       └── code_preview.dart        # DDL code preview widget
│
└── er_diagram/                       # ER diagram sub-module
    ├── er_diagram.dart              # Barrel file (exports)
    ├── models/
    │   └── er_diagram_ui_state.dart # UI state models
    ├── providers/
    │   └── er_diagram_ui_provider.dart # UI state provider
    ├── core/
    │   └── er_graph_builder.dart    # Graph construction logic
    ├── layout/
    │   └── layout_adapter.dart      # Layout algorithm adapter
    └── widgets/
        ├── er_diagram_canvas.dart   # Main diagram canvas
        ├── er_table_node_widget.dart # Table node renderer
        └── er_field_anchor_widget.dart # Field anchor widgets
```

## Key Components

### Entity Editor Components

| Component | Description |
|-----------|-------------|
| `EntityEditorView` | Main editor with 4 tabs: Summary, Fields, Indexes, Preview |
| `EntityEditState` | State class holding entity data and edit status |
| `EntityEditNotifier` | StateNotifier for entity modifications |
| `FieldTable` | TDTable-based field editor with inline editing |
| `IndexEditor` | Index configuration with type/field selection |
| `CodePreview` | Multi-database DDL preview and export |

### ER Diagram Components

| Component | Description |
|-----------|-------------|
| `ERDiagramCanvas` | Interactive canvas with zoom/pan/selection |
| `ERDiagramUIState` | UI-only state (viewport, selection, connection) |
| `ERDiagramUINotifier` | UI state management (no business data) |
| `ERGraphBuilder` | Converts Module to graphview Graph |
| `ERTableNodeWidget` | Flutter-rendered table node |
| `ERFieldAnchorWidget` | Connection anchor points for fields |

## Data Flow

### Entity Editor Data Flow
```
User Edit -> EntityEditNotifier -> _syncToProject() -> ProjectNotifier
                                      |
                            Project State Updated
                                      |
                            UI Re-renders (ref.watch)
```

### ER Diagram Data Flow
```
ProjectNotifier.project -> moduleEntitiesProvider -> ERGraphBuilder -> Graph
                                      |                              |
                            ERDiagramCanvas                    ERTableNodeWidget
                                      |
                            UI Interactions -> ERDiagramUINotifier
                                      |
                            ProjectNotifier.updateGraphNode/addGraphEdge
```

## Dependencies

### External Dependencies
- `flutter_riverpod` - State management
- `tdesign_flutter` - UI component library
- `graphview` - Graph visualization library (for ER Diagram)
- `json_annotation` - JSON serialization

### Internal Dependencies
- `shared/models/` - Entity, Field, Index, Module, GraphNode, GraphEdge
- `shared/providers/` - ProjectNotifierProvider
- `core/i18n/` - Internationalization
- `utils/id_generator.dart` - ID generation

## Interaction Modes (ER Diagram)

| Mode | Description | Mouse Behavior |
|------|-------------|----------------|
| Preview | Read-only view | Left-click: pan canvas, Double-click: preview popup |
| Edit | Full editing | Left-click: select/drag nodes, Right-click: pan canvas, Double-click: edit popup |

## Key Features

### Entity Editor
- 4-tab interface (Summary, Fields, Indexes, Preview)
- Inline field editing with TDTable
- Field type selection from DataType list
- Index type configuration (Normal/Unique/Fulltext)
- Multi-database DDL preview (MySQL, PostgreSQL, Oracle, SQL Server)
- Copy/download DDL functionality

### ER Diagram
- Infinite canvas with grid background
- Zoom/pan with InteractiveViewer
- Field-level connection anchors
- Multi-node selection (Ctrl+click, box selection)
- Multi-node drag support
- Sugiyama layout algorithm
- Preview/Edit mode toggle

## Usage Examples

### Opening Entity Editor
```dart
// In tab navigation
ref.read(tabProvider.notifier).openTab(
  'entity_editor',
  entityId: entity.id,
  moduleId: module.id,
);
```

### Watching Entity State
```dart
// In a widget
final state = ref.watch(entityEditProvider((entity, moduleId)));
if (state.isDirty) {
  // Show save indicator
}
```

### Updating Entity Fields
```dart
// Add new field
ref.read(entityEditProvider((entity, moduleId)).notifier).addField(
  name: 'user_id',
  type: 'String',
  chnname: 'User ID',
  pk: true,
);

// Update existing field
ref.read(entityEditProvider((entity, moduleId)).notifier).updateField(
  fieldId,
  field.copyWith(name: 'new_name'),
);
```

### ER Diagram Interaction
```dart
// Enter edit mode
ref.read(erDiagramUIProvider(moduleId).notifier).enterEditMode();

// Watch selected nodes
final selectedIds = ref.watch(erDiagramUIProvider(moduleId)).selectedNodeIds;

// Apply layout
ref.read(erDiagramUIProvider(moduleId).notifier).applyLayout(positions);
```

## Related Documentation
- [API Reference](api-modeling.md) - Detailed API documentation
- [Data Models](data-model.md) - State and business data models
- [Pitfalls and Solutions](pitfalls.md) - Common issues and solutions