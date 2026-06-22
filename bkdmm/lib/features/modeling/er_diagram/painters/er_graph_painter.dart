import 'package:flutter/material.dart';
import '../providers/graph_provider.dart';
import 'edge_painter.dart';
import 'node_painter.dart';

/// Main painter for the ER diagram graph
///
/// Paints all nodes and edges in the graph, handling:
/// - Table nodes with headers and fields
/// - Relationship edges between tables
/// - Selection and highlight states
/// - Hover effects
class ERGraphPainter extends CustomPainter {
  /// The graph state to paint
  final ERGraphState graphState;

  /// Whether dark mode is enabled
  final bool isDarkMode;

  /// The hovered node ID
  final String? hoveredNodeId;

  /// The search query for filtering
  final String searchQuery;

  ERGraphPainter({
    required this.graphState,
    this.isDarkMode = false,
    this.hoveredNodeId,
    this.searchQuery = '',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid background (optional)
    _drawGrid(canvas, size);

    // Apply zoom transform
    canvas.save();
    canvas.scale(graphState.zoom, graphState.zoom);
    canvas.translate(graphState.panOffset.dx / graphState.zoom, graphState.panOffset.dy / graphState.zoom);

    // Draw edges first (below nodes)
    _drawEdges(canvas, size);

    // Draw nodes on top
    _drawNodes(canvas, size);

    canvas.restore();
  }

  /// Draw grid background
  void _drawGrid(Canvas canvas, Size size) {
    const gridSize = 20.0;
    final gridPaint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;

    // Calculate visible area based on pan and zoom
    final visibleRect = Rect.fromLTWH(
      -graphState.panOffset.dx / graphState.zoom,
      -graphState.panOffset.dy / graphState.zoom,
      size.width / graphState.zoom,
      size.height / graphState.zoom,
    );

    // Draw vertical lines
    final startX = (visibleRect.left / gridSize).floor() * gridSize;
    for (var x = startX; x <= visibleRect.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, visibleRect.top),
        Offset(x, visibleRect.bottom),
        gridPaint,
      );
    }

    // Draw horizontal lines
    final startY = (visibleRect.top / gridSize).floor() * gridSize;
    for (var y = startY; y <= visibleRect.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(visibleRect.left, y),
        Offset(visibleRect.right, y),
        gridPaint,
      );
    }
  }

  /// Draw all edges
  void _drawEdges(Canvas canvas, Size size) {
    for (final edge in graphState.edges) {
      final sourceNode = graphState.getNode(edge.source);
      final targetNode = graphState.getNode(edge.target);

      if (sourceNode == null || targetNode == null) continue;

      // Check if this edge is highlighted
      final isHighlighted = _isEdgeHighlighted(edge);

      EdgePainter.paint(
        canvas: canvas,
        edge: edge,
        sourceNode: sourceNode,
        targetNode: targetNode,
        scale: graphState.zoom,
        isDarkMode: isDarkMode,
        isHighlighted: isHighlighted,
      );
    }
  }

  /// Draw all nodes
  void _drawNodes(Canvas canvas, Size size) {
    // Sort nodes so selected/highlighted nodes are drawn last (on top)
    final sortedNodes = List<ERGraphNode>.from(graphState.nodes);
    sortedNodes.sort((a, b) {
      // Selected nodes go last
      if (a.isSelected && !b.isSelected) return 1;
      if (!a.isSelected && b.isSelected) return -1;
      // Highlighted nodes go last
      if (a.isHighlighted && !b.isHighlighted) return 1;
      if (!a.isHighlighted && b.isHighlighted) return -1;
      return 0;
    });

    for (final node in sortedNodes) {
      // Check if node should be visible based on search
      if (!_isNodeVisible(node)) continue;

      NodePainter.paint(
        canvas: canvas,
        node: node,
        scale: graphState.zoom,
        isDarkMode: isDarkMode,
      );
    }
  }

  /// Check if a node should be visible based on search query
  bool _isNodeVisible(ERGraphNode node) {
    if (searchQuery.isEmpty) return true;
    return node.isHighlighted ||
        (node.entity?.title.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false) ||
        (node.entity?.chnname.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false);
  }

  /// Check if an edge should be highlighted
  bool _isEdgeHighlighted(ERGraphEdge edge) {
    // Highlight if either connected node is highlighted
    final sourceNode = graphState.getNode(edge.source);
    final targetNode = graphState.getNode(edge.target);

    return (sourceNode?.isHighlighted ?? false) ||
        (targetNode?.isHighlighted ?? false) ||
        edge.isHighlighted;
  }

  @override
  bool shouldRepaint(covariant ERGraphPainter oldDelegate) {
    return oldDelegate.graphState != graphState ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.searchQuery != searchQuery;
  }

  /// Hit test for a point in the graph
  static ERGraphNode? hitTestNode(ERGraphState graphState, Offset point) {
    // Check nodes in reverse order (top to bottom)
    for (var i = graphState.nodes.length - 1; i >= 0; i--) {
      final node = graphState.nodes[i];
      if (NodePainter.hitTest(node, point)) {
        return node;
      }
    }
    return null;
  }

  /// Hit test for an edge
  static ERGraphEdge? hitTestEdge(ERGraphState graphState, Offset point, {double threshold = 10.0}) {
    for (final edge in graphState.edges) {
      if (_isPointNearEdge(graphState, edge, point, threshold)) {
        return edge;
      }
    }
    return null;
  }

  /// Check if a point is near an edge
  static bool _isPointNearEdge(ERGraphState graphState, ERGraphEdge edge, Offset point, double threshold) {
    final sourceNode = graphState.getNode(edge.source);
    final targetNode = graphState.getNode(edge.target);

    if (sourceNode == null || targetNode == null) return false;

    final sourceRect = NodePainter.getNodeRect(sourceNode);
    final targetRect = NodePainter.getNodeRect(targetNode);

    final sourceCenter = sourceRect.center;
    final targetCenter = targetRect.center;

    return _distanceToLine(point, sourceCenter, targetCenter) < threshold;
  }

  /// Calculate distance from point to line segment
  static double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - lineStart).distance;
    }

    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    final projection = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
    return (point - projection).distance;
  }
}
