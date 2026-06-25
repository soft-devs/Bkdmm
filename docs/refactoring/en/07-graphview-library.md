# GraphView Library Documentation

## Overview

GraphView is a Flutter library for graph visualization. This document analyzes its capabilities, limitations, and suitability for the Bkdmm project.

## Library Information

- **Package**: `graphview`
- **Version**: 1.2.0
- **Publisher**: nabil6391
- **Repository**: https://github.com/nabil6391/graphview
- **Pub.dev**: https://pub.dev/packages/graphview

## Features

### Layout Algorithms

| Algorithm | Description | Best For |
|-----------|-------------|----------|
| **BuchheimWalker** | Tree layout with optimized edge routing | Organization charts, file trees |
| **Sugiyama** | Hierarchical layered layout | ER diagrams, dependency graphs |
| **Tree** | Simple tree visualization | Rooted trees |
| **RadialTree** | Circular tree arrangement | Mind maps, network topology |
| **Circular** | Nodes in a circle | Ring networks |
| **ForceDirected** | Physics-based simulation | Social networks, mesh networks |
| **Grid** | Regular grid arrangement | Matrices, game boards |

### Graph Types

```dart
// Directed graph
final graph = Graph();
graph.addNode(node1);
graph.addNode(node2);
graph.addEdge(node1, node2); // Direction: node1 → node2

// Undirected graph
final graph = Graph();
graph.addEdge(node1, node2);
graph.addEdge(node2, node1); // Bidirectional

// Tree
final root = Node.Id('root');
final child1 = Node.Id('child1');
graph.addEdge(root, child1);
```

### Node Builder Pattern

```dart
GraphView(
  graph: graph,
  algorithm: builder,
  builder: (Node node) {
    // Custom widget for each node
    return Container(
      width: 100,
      height: 50,
      child: Text(node.key?.value.toString() ?? ''),
    );
  },
)
```

### InteractiveViewer Integration

GraphView integrates with InteractiveViewer for pan and zoom:

```dart
InteractiveViewer(
  constrained: false,
  minScale: 0.1,
  maxScale: 5.0,
  child: GraphView(
    graph: graph,
    algorithm: algorithm,
    builder: nodeBuilder,
  ),
)
```

## Limitations for ER Diagrams

### 1. No Field-Level Anchors

GraphView's edges connect entire nodes, not specific fields:

```dart
// GraphView: Edge connects whole nodes
graph.addEdge(table1, table2);

// ER Diagram need: Edge connects specific fields
// table1.primaryKey → table2.foreignKey
```

**Impact**: Cannot represent ER relationships accurately (one-to-many, many-to-many with specific fields).

### 2. Limited Edge Customization

```dart
// GraphView edge rendering is limited to:
- Straight lines
- Curved lines (Bezier)
- Arrows

// ER Diagram needs:
- Crow's foot notation (1:N, N:M)
- Field-level connection points
- Relationship labels
- Optional/mandatory indicators
```

### 3. No Built-in Undo/Redo

GraphView doesn't track operations:

```dart
// When you move a node:
node.position = newOffset; // Direct mutation, no history

// No way to undo:
// ❌ graph.undo(); // Doesn't exist
```

### 4. Node ID Uniqueness

```dart
// If two nodes have the same ID, one is overwritten
final node1 = Node.Id('User');
final node2 = Node.Id('User'); // Same ID!
graph.addNode(node1);
graph.addNode(node2); // Replaces node1!
```

### 5. Performance with Large Graphs

| Node Count | Performance |
|------------|-------------|
| < 100 | Smooth |
| 100-500 | Acceptable |
| > 500 | Laggy, especially with ForceDirected |

### 6. Gesture Conflicts

GraphView's gesture handling conflicts with InteractiveViewer:

```dart
// Problem: Pan gesture conflicts
InteractiveViewer(
  panEnabled: true,  // Wants to handle pan
  child: GraphView(
    // GraphView may also handle pan
    // Result: Unpredictable behavior
  ),
)
```

## When to Use GraphView

### Good Fit

✅ Simple organization charts
✅ Tree visualizations
✅ Network topology diagrams
✅ Quick prototyping
✅ Small graphs (< 100 nodes)

### Not a Good Fit

❌ ER diagrams with field-level relationships
❌ Flowcharts with custom connectors
❌ Large graphs (> 500 nodes)
❌ Diagrams requiring undo/redo
❌ Complex custom rendering

## Bkdmm's Hybrid Approach

The current implementation uses GraphView partially:

```
bkdmm/lib/features/modeling/er_diagram/
├── core/er_graph_builder.dart    # Uses graphview Graph class
├── layout/layout_adapter.dart    # Uses SugiyamaAlgorithm
└── widgets/er_diagram_canvas.dart # Custom canvas (not GraphView widget)
```

### What's Used

- `Graph` class for data structure
- `SugiyamaAlgorithm` for automatic layout
- `Node` class for node representation

### What's Custom

- Node rendering (`ERTableNodeWidget`)
- Edge rendering (`CustomPainter`)
- Anchor system (`ERFieldAnchorWidget`)
- Gesture handling (`Listener` + custom logic)
- State management (`Riverpod`)

### Rationale

```
Why this hybrid approach?

1. GraphView's Graph class is useful for:
   - Storing nodes and edges
   - Running layout algorithms

2. GraphView's rendering is insufficient:
   - No field-level anchors
   - Limited edge styles
   - No custom overlays (selection, connection preview)

3. Custom rendering provides:
   - Full control over appearance
   - Field-level anchors
   - Custom edge styles (crow's foot)
   - Overlay widgets
```

## Alternative Libraries

### flutter_flow_chart

```yaml
dependencies:
  flutter_flow_chart: ^2.0.0
```

- Designed for flowcharts
- Node-based editor
- Drag and drop support
- **Limitation**: Not suitable for ER diagrams

### interactive_graph

```yaml
dependencies:
  interactive_graph: ^0.1.0
```

- Interactive network graphs
- Force-directed layout
- **Limitation**: Limited customization

### diagram_editor

```yaml
dependencies:
  diagram_editor: ^0.2.0
```

- Generic diagram editor framework
- Customizable nodes and connections
- **Limitation**: Requires more setup

## Recommendation for Bkdmm

### Continue Hybrid Approach

1. **Keep using GraphView for**:
   - Data structure (`Graph` class)
   - Layout algorithms (`SugiyamaAlgorithm`)

2. **Continue custom implementation for**:
   - Node rendering (ER tables with fields)
   - Edge rendering (crow's foot notation)
   - Anchor system (field-level connections)
   - Gesture handling (event delegation)
   - State management (Riverpod)

3. **Add missing features**:
   - Undo/redo (Command pattern)
   - Better hit testing (Spatial index)
   - State machine for interactions

### Future Consideration

If GraphView adds:
- Field-level anchors
- Custom edge renderers
- Better performance for large graphs

Then consider using more of the library.

## Code Example: Current Usage

```dart
// er_graph_builder.dart
class ERGraphBuilder {
  Graph buildGraph(Module module) {
    final graph = Graph();

    // Add nodes
    for (final entity in module.entities) {
      final node = Node.Id(entity.id);
      node.position = Offset(graphNode.x, graphNode.y);
      node.size = _calculateNodeSize(entity);
      graph.addNode(node);
    }

    // Add edges
    for (final edge in module.graphCanvas.edges) {
      final sourceNode = graph.getNodeUsingId(edge.source);
      final targetNode = graph.getNodeUsingId(edge.target);
      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }

    return graph;
  }
}

// layout_adapter.dart
void autoLayout(Module module) {
  final config = SugiyamaConfiguration()
    ..nodeSeparation = 200
    ..levelSeparation = 150
    ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

  final algorithm = SugiyamaAlgorithm(config);
  algorithm.run(graph, canvasWidth, canvasHeight);

  // Extract positions from graph
  for (final node in graph.nodes) {
    positions[node.key?.value] = Offset(node.x, node.y);
  }
}
```

## References

- [GraphView on pub.dev](https://pub.dev/packages/graphview)
- [GraphView GitHub Repository](https://github.com/nabil6391/graphview)
- [GraphView Example App](https://github.com/nabil6391/graphview/tree/master/example)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*