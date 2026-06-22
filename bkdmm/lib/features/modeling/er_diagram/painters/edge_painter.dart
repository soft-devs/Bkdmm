import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/graph_provider.dart';
import 'node_painter.dart';

/// Paints edges (relationship lines) between nodes in the ER diagram
class EdgePainter {
  /// Arrow head size
  static const double arrowSize = 10.0;

  /// Edge line width
  static const double lineWidth = 2.0;

  /// Label background padding
  static const double labelPadding = 4.0;

  /// Paint an edge between two nodes
  static void paint({
    required Canvas canvas,
    required ERGraphEdge edge,
    required ERGraphNode sourceNode,
    required ERGraphNode targetNode,
    required double scale,
    required bool isDarkMode,
    required bool isHighlighted,
  }) {
    // Get connection points
    final sourceRect = NodePainter.getNodeRect(sourceNode);
    final targetRect = NodePainter.getNodeRect(targetNode);

    final sourceCenter = sourceRect.center;
    final targetCenter = targetRect.center;

    // Calculate edge points (from edge of nodes, not centers)
    final sourcePoint = _getEdgePoint(sourceRect, targetCenter);
    final targetPoint = _getEdgePoint(targetRect, sourceCenter);

    // Draw the edge line
    _drawEdgeLine(
      canvas,
      sourcePoint,
      targetPoint,
      isDarkMode,
      isHighlighted,
    );

    // Draw arrow head at target
    _drawArrowHead(
      canvas,
      targetPoint,
      sourcePoint,
      isDarkMode,
      isHighlighted,
    );

    // Draw label if present
    if (edge.label != null && edge.label!.isNotEmpty) {
      _drawLabel(
        canvas,
        sourcePoint,
        targetPoint,
        edge.label!,
        isDarkMode,
      );
    }
  }

  /// Get the point on the edge of a rect towards a target point
  static Offset _getEdgePoint(Rect rect, Offset target) {
    final center = rect.center;
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    if (dx == 0 && dy == 0) return center;

    // Calculate intersection with rectangle edges
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;

    final absDx = dx.abs();
    final absDy = dy.abs();

    double t;
    if (absDx * halfHeight > absDy * halfWidth) {
      // Intersects left or right edge
      t = halfWidth / absDx;
    } else {
      // Intersects top or bottom edge
      t = halfHeight / absDy;
    }

    return Offset(
      center.dx + dx * t,
      center.dy + dy * t,
    );
  }

  /// Draw the edge line
  static void _drawEdgeLine(
    Canvas canvas,
    Offset source,
    Offset target,
    bool isDarkMode,
    bool isHighlighted,
  ) {
    final color = isHighlighted
        ? Colors.orange.shade400
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? lineWidth + 1 : lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw curved line for better aesthetics
    final path = _createCurvedPath(source, target);
    canvas.drawPath(path, paint);
  }

  /// Create a curved path between two points
  static Path _createCurvedPath(Offset source, Offset target) {
    final path = Path();
    path.moveTo(source.dx, source.dy);

    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Use straight line for short distances, curve for longer
    if (distance < 100) {
      path.lineTo(target.dx, target.dy);
    } else {
      // Create a slight curve
      final controlOffset = distance * 0.2;
      final midX = (source.dx + target.dx) / 2;
      final midY = (source.dy + target.dy) / 2;

      // Perpendicular offset for control point
      final perpX = -dy / distance * controlOffset;
      final perpY = dx / distance * controlOffset;

      path.quadraticBezierTo(
        midX + perpX,
        midY + perpY,
        target.dx,
        target.dy,
      );
    }

    return path;
  }

  /// Draw arrow head at target point
  static void _drawArrowHead(
    Canvas canvas,
    Offset target,
    Offset source,
    bool isDarkMode,
    bool isHighlighted,
  ) {
    final color = isHighlighted
        ? Colors.orange.shade400
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate arrow direction
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final angle = math.atan2(dy, dx);

    // Create arrow head path
    final path = Path();
    path.moveTo(target.dx, target.dy);
    path.lineTo(
      target.dx - arrowSize * math.cos(angle - math.pi / 6),
      target.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      target.dx - arrowSize * math.cos(angle + math.pi / 6),
      target.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw relationship label
  static void _drawLabel(
    Canvas canvas,
    Offset source,
    Offset target,
    String label,
    bool isDarkMode,
  ) {
    final midX = (source.dx + target.dx) / 2;
    final midY = (source.dy + target.dy) / 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Draw label background
    final bgRect = Rect.fromCenter(
      center: Offset(midX, midY),
      width: textPainter.width + labelPadding * 2,
      height: textPainter.height + labelPadding * 2,
    );

    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2D3748) : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );

    // Draw label text
    textPainter.paint(
      canvas,
      Offset(
        midX - textPainter.width / 2,
        midY - textPainter.height / 2,
      ),
    );
  }
}

/// Edge style configuration
enum EdgeStyle {
  /// Straight line
  straight,

  /// Curved line (default)
  curved,

  /// Orthogonal (right-angle) line
  orthogonal,
}

/// Edge endpoint marker
enum EdgeMarker {
  /// No marker
  none,

  /// Arrow head
  arrow,

  /// Filled circle
  circle,

  /// Diamond
  diamond,

  /// Crow's foot (many relationship)
  crowFoot,
}
