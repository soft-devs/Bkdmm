import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/models.dart';
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
    final sourceRect = NodePainter.getNodeRect(sourceNode);
    final targetRect = NodePainter.getNodeRect(targetNode);

    // Get connection points based on whether we have field info
    Offset sourcePoint;
    Offset targetPoint;

    // Determine source point
    if (edge.sourceField != null && sourceNode.entity != null) {
      final sourceFieldIndex = _findFieldIndex(sourceNode.entity!, edge.sourceField!);
      if (sourceFieldIndex != null) {
        // Use left anchor for source (outgoing connection)
        sourcePoint = NodePainter.getLeftFieldAnchor(sourceRect, sourceFieldIndex);
      } else {
        sourcePoint = _getEdgePoint(sourceRect, targetRect.center);
      }
    } else {
      sourcePoint = _getEdgePoint(sourceRect, targetRect.center);
    }

    // Determine target point
    if (edge.targetField != null && targetNode.entity != null) {
      final targetFieldIndex = _findFieldIndex(targetNode.entity!, edge.targetField!);
      if (targetFieldIndex != null) {
        // Use right anchor for target (incoming connection)
        targetPoint = NodePainter.getRightFieldAnchor(targetRect, targetFieldIndex);
      } else {
        targetPoint = _getEdgePoint(targetRect, sourceRect.center);
      }
    } else {
      targetPoint = _getEdgePoint(targetRect, sourceRect.center);
    }

    // Draw the edge line
    _drawEdgeLine(
      canvas,
      sourcePoint,
      targetPoint,
      isDarkMode,
      isHighlighted,
    );

    // Draw relationship markers
    _drawRelationshipMarker(
      canvas,
      sourcePoint,
      targetPoint,
      isDarkMode,
      isHighlighted,
      edge.relationType,
      isSource: true,
    );

    _drawRelationshipMarker(
      canvas,
      targetPoint,
      sourcePoint,
      isDarkMode,
      isHighlighted,
      edge.relationType,
      isSource: false,
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

  /// Find field index by name
  static int? _findFieldIndex(Entity entity, String fieldName) {
    for (var i = 0; i < entity.fields.length; i++) {
      if (entity.fields[i].name == fieldName) {
        return i;
      }
    }
    return null;
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

  /// Draw relationship marker (1, N, M) at endpoint
  static void _drawRelationshipMarker(
    Canvas canvas,
    Offset point,
    Offset otherPoint,
    bool isDarkMode,
    bool isHighlighted,
    String? relationType,
    {required bool isSource}
  ) {
    final color = isHighlighted
        ? Colors.orange.shade400
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    // Determine marker based on relation type
    String? marker;
    if (relationType != null) {
      // Parse relation type: "1:1", "1:N", "N:1", "N:M"
      final parts = relationType.split(':');
      if (parts.length == 2) {
        marker = isSource ? parts[0] : parts[1];
      }
    }

    if (marker == null) return;

    // Calculate direction away from the other point
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    // Normalize direction
    final dirX = dx / distance;
    final dirY = dy / distance;

    // Position marker slightly away from the endpoint
    final markerOffset = 12.0;
    final markerPos = Offset(
      point.dx + dirX * markerOffset,
      point.dy + dirY * markerOffset,
    );

    // Draw marker text
    final textPainter = TextPainter(
      text: TextSpan(
        text: marker,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        markerPos.dx - textPainter.width / 2,
        markerPos.dy - textPainter.height / 2,
      ),
    );

    // Draw crow's foot for N/M
    if (marker == 'N' || marker == 'M') {
      _drawCrowsFoot(canvas, point, otherPoint, color);
    } else if (marker == '1') {
      // Draw single line for 1
      _drawOneMarker(canvas, point, otherPoint, color);
    }
  }

  /// Draw crow's foot marker (for "many" relationship)
  static void _drawCrowsFoot(Canvas canvas, Offset point, Offset otherPoint, Color color) {
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final angle = math.atan2(dy, dx);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final size = 8.0;

    // Draw three lines forming crow's foot
    canvas.drawLine(
      point,
      Offset(
        point.dx - size * math.cos(angle - math.pi / 6),
        point.dy - size * math.sin(angle - math.pi / 6),
      ),
      paint,
    );
    canvas.drawLine(
      point,
      Offset(
        point.dx - size * math.cos(angle + math.pi / 6),
        point.dy - size * math.sin(angle + math.pi / 6),
      ),
      paint,
    );
    canvas.drawLine(
      point,
      Offset(
        point.dx - size * math.cos(angle),
        point.dy - size * math.sin(angle),
      ),
      paint,
    );
  }

  /// Draw "one" marker (single vertical line)
  static void _drawOneMarker(Canvas canvas, Offset point, Offset otherPoint, Color color) {
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final angle = math.atan2(dy, dx);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final size = 6.0;
    // Perpendicular line
    canvas.drawLine(
      Offset(
        point.dx + size * math.cos(angle + math.pi / 2),
        point.dy + size * math.sin(angle + math.pi / 2),
      ),
      Offset(
        point.dx + size * math.cos(angle - math.pi / 2),
        point.dy + size * math.sin(angle - math.pi / 2),
      ),
      paint,
    );
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
