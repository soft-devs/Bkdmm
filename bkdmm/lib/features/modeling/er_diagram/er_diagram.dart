/// ER Diagram visualization module
///
/// Provides interactive visualization of entity-relationship diagrams
/// with CustomPainter-based rendering.
///
/// Usage:
/// ```dart
/// ERDiagramWidget(
///   moduleId: 'module-id',
///   onEntityEdit: (entity) => // Open entity editor,
///   onContextMenu: (position, entity) => // Show context menu,
/// )
/// ```
library;

export 'widgets/er_diagram_widget.dart';
export 'providers/graph_provider.dart';
export 'painters/er_graph_painter.dart';
export 'painters/node_painter.dart';
export 'painters/edge_painter.dart';
export 'layout/dagre_layout.dart';
export 'export/image_export.dart';
