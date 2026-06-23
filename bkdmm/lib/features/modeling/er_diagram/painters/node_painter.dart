import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/models.dart';
import '../providers/graph_provider.dart';

/// Paints a single table node in the ER diagram
class NodePainter {
  /// Default width for a table node
  static const double defaultWidth = 200.0;

  /// Default height for a table node header
  static const double headerHeight = 40.0;

  /// Default height per field row
  static const double fieldRowHeight = 28.0;

  /// Minimum height for a node
  static const double minHeight = 80.0;

  /// Corner radius for the rounded rectangle
  static const double cornerRadius = 8.0;

  /// Padding inside the node
  static const double padding = 12.0;

  /// Anchor point size for edge creation
  static const double anchorSize = 6.0;

  /// Field anchor size (smaller, on field rows)
  static const double fieldAnchorSize = 6.0;

  /// Anchor offset from node edge
  static const double anchorOffset = 8.0;

  /// Get left field anchor position for a specific field (for outgoing connections)
  static Offset getLeftFieldAnchor(Rect rect, int fieldIndex) {
    final rowY = rect.top + headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;
    return Offset(rect.left - anchorOffset, rowY);
  }

  /// Get right field anchor position for a specific field (for incoming connections)
  static Offset getRightFieldAnchor(Rect rect, int fieldIndex) {
    final rowY = rect.top + headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;
    return Offset(rect.right + anchorOffset, rowY);
  }

  /// Get all left field anchor positions
  static List<(int, Offset)> getLeftFieldAnchors(Rect rect, Entity entity) {
    final positions = <(int, Offset)>[];
    for (var i = 0; i < entity.fields.length; i++) {
      positions.add((i, getLeftFieldAnchor(rect, i)));
    }
    return positions;
  }

  /// Get all right field anchor positions
  static List<(int, Offset)> getRightFieldAnchors(Rect rect, Entity entity) {
    final positions = <(int, Offset)>[];
    for (var i = 0; i < entity.fields.length; i++) {
      positions.add((i, getRightFieldAnchor(rect, i)));
    }
    return positions;
  }

  /// Hit test for field anchor
  /// Returns (fieldIndex, isLeftAnchor) if hit, null otherwise
  static (int, bool)? hitTestFieldAnchor(ERGraphNode node, Offset point, InteractionMode mode) {
    if (mode != InteractionMode.edit) return null;

    final entity = node.entity;
    if (entity == null) return null;

    final rect = getNodeRect(node);

    // Check left anchors (outgoing)
    for (var i = 0; i < entity.fields.length; i++) {
      final anchorPos = getLeftFieldAnchor(rect, i);
      final anchorRect = Rect.fromCenter(
        center: anchorPos,
        width: fieldAnchorSize * 2.5,
        height: fieldAnchorSize * 2.5,
      );
      if (anchorRect.contains(point)) {
        return (i, true); // Left anchor (outgoing)
      }
    }

    // Check right anchors (incoming)
    for (var i = 0; i < entity.fields.length; i++) {
      final anchorPos = getRightFieldAnchor(rect, i);
      final anchorRect = Rect.fromCenter(
        center: anchorPos,
        width: fieldAnchorSize * 2.5,
        height: fieldAnchorSize * 2.5,
      );
      if (anchorRect.contains(point)) {
        return (i, false); // Right anchor (incoming)
      }
    }

    return null;
  }

  /// Get the Y position for a specific field
  static double getFieldYPosition(Rect rect, int fieldIndex) {
    return rect.top + headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;
  }

  /// Anchor point positions (node-level, kept for compatibility)
  static List<Offset> getAnchorPositions(Rect rect) {
    return [
      Offset(rect.left + rect.width / 2, rect.top), // Top center
      Offset(rect.right, rect.top + rect.height / 2), // Right center
      Offset(rect.left + rect.width / 2, rect.bottom), // Bottom center
      Offset(rect.left, rect.top + rect.height / 2), // Left center
    ];
  }

  /// Check if a point hits an anchor
  /// Returns the anchor index (0-3) if hit, null otherwise
  static int? hitTestAnchorIndex(ERGraphNode node, Offset point, InteractionMode mode) {
    if (mode != InteractionMode.edit) return null;

    final rect = getNodeRect(node);
    final anchors = getAnchorPositions(rect);

    for (var i = 0; i < anchors.length; i++) {
      final anchorRect = Rect.fromCenter(
        center: anchors[i],
        width: anchorSize * 2.5, // Slightly larger hit area
        height: anchorSize * 2.5,
      );
      if (anchorRect.contains(point)) {
        return i; // Return anchor index
      }
    }
    return null;
  }

  /// Check if a point hits an anchor (legacy method for compatibility)
  static String? hitTestAnchor(ERGraphNode node, Offset point, InteractionMode mode) {
    final index = hitTestAnchorIndex(node, point, mode);
    return index != null ? node.id : null;
  }

  /// Check if a point hits a node (excluding anchor areas)
  static bool hitTestNodeBody(ERGraphNode node, Offset point, InteractionMode mode) {
    final rect = getNodeRect(node);

    // If in edit mode, check if point is on an anchor first
    if (mode == InteractionMode.edit) {
      // Check node-level anchors
      final anchors = getAnchorPositions(rect);
      for (final anchor in anchors) {
        final anchorRect = Rect.fromCenter(
          center: anchor,
          width: anchorSize * 2.5,
          height: anchorSize * 2.5,
        );
        if (anchorRect.contains(point)) {
          return false; // Point is on anchor, not node body
        }
      }

      // Check field-level anchors
      final entity = node.entity;
      if (entity != null) {
        for (var i = 0; i < entity.fields.length; i++) {
          final leftAnchor = getLeftFieldAnchor(rect, i);
          final rightAnchor = getRightFieldAnchor(rect, i);

          final leftRect = Rect.fromCenter(
            center: leftAnchor,
            width: fieldAnchorSize * 2.5,
            height: fieldAnchorSize * 2.5,
          );
          if (leftRect.contains(point)) {
            return false;
          }

          final rightRect = Rect.fromCenter(
            center: rightAnchor,
            width: fieldAnchorSize * 2.5,
            height: fieldAnchorSize * 2.5,
          );
          if (rightRect.contains(point)) {
            return false;
          }
        }
      }
    }

    return rect.contains(point);
  }

  /// Paint the node
  static void paint({
    required Canvas canvas,
    required ERGraphNode node,
    required double scale,
    required bool isDarkMode,
    bool showAnchors = false,
  }) {
    final entity = node.entity;
    if (entity == null) return;

    final size = calculateNodeSize(entity);
    final rect = Rect.fromLTWH(node.x, node.y, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));

    // Draw shadow
    _drawShadow(canvas, rect, node.isDragging);

    // Draw background
    _drawBackground(canvas, rrect, node, isDarkMode);

    // Draw header
    _drawHeader(canvas, rect, entity, node, isDarkMode);

    // Draw fields
    _drawFields(canvas, rect, entity, node, isDarkMode);

    // Draw selection border
    if (node.isSelected) {
      _drawSelectionBorder(canvas, rect);
    }

    // Draw hover highlight
    if (node.isHighlighted) {
      _drawHighlightBorder(canvas, rect);
    }

    // Draw field anchors in edit mode (primary way to create edges)
    if (showAnchors) {
      _drawFieldAnchors(canvas, rect, entity, isDarkMode);
    }
  }

  /// Calculate the size needed for a node based on its fields
  static Size calculateNodeSize(Entity entity) {
    final fieldCount = entity.fields.length;
    final height = headerHeight + (fieldCount * fieldRowHeight) + padding;
    return Size(defaultWidth, math.max(minHeight, height));
  }

  /// Get the rect for a node at a given position
  static Rect getNodeRect(ERGraphNode node) {
    final entity = node.entity;
    if (entity == null) {
      return Rect.fromLTWH(node.x, node.y, defaultWidth, minHeight);
    }
    final size = calculateNodeSize(entity);
    return Rect.fromLTWH(node.x, node.y, size.width, size.height);
  }

  /// Check if a point hits a node
  static bool hitTest(ERGraphNode node, Offset point) {
    final rect = getNodeRect(node);
    return rect.contains(point);
  }

  /// Draw shadow effect
  static void _drawShadow(Canvas canvas, Rect rect, bool isDragging) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDragging ? 0.3 : 0.15)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isDragging ? 12 : 6,
      );

    final shadowRect = rect.shift(Offset(isDragging ? 4 : 2, isDragging ? 4 : 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(cornerRadius)),
      shadowPaint,
    );
  }

  /// Draw node background
  static void _drawBackground(Canvas canvas, RRect rrect, ERGraphNode node, bool isDarkMode) {
    final bgColor = isDarkMode
        ? (node.isSelected ? Colors.blue.shade900 : const Color(0xFF2D3748))
        : (node.isSelected ? Colors.blue.shade50 : Colors.white);

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(rrect, bgPaint);
  }

  /// Draw the header section
  static void _drawHeader(
    Canvas canvas,
    Rect rect,
    Entity entity,
    ERGraphNode node,
    bool isDarkMode,
  ) {
    final headerRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      headerHeight,
    );

    // Header background gradient
    final headerColor = isDarkMode ? Colors.blue.shade700 : Colors.blue.shade600;
    final headerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [headerColor, headerColor.withValues(alpha: 0.8)],
      ).createShader(headerRect);

    final headerRRect = RRect.fromRectAndCorners(
      headerRect,
      topLeft: const Radius.circular(cornerRadius),
      topRight: const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(headerRRect, headerPaint);

    // Table icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.table_rows.codePoint),
        style: const TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(rect.left + padding, rect.top + (headerHeight - 16) / 2),
    );

    // Table name
    final namePainter = TextPainter(
      text: TextSpan(
        text: entity.title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - 60);

    namePainter.paint(
      canvas,
      Offset(rect.left + padding + 24, rect.top + (headerHeight - namePainter.height) / 2),
    );
  }

  /// Draw the fields section
  static void _drawFields(
    Canvas canvas,
    Rect rect,
    Entity entity,
    ERGraphNode node,
    bool isDarkMode,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final rowY = rect.top + headerHeight + (i * fieldRowHeight);

      // Alternate row background
      if (i % 2 == 1) {
        final rowRect = Rect.fromLTWH(
          rect.left,
          rowY,
          rect.width,
          fieldRowHeight,
        );
        final rowPaint = Paint()
          ..color = isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50;
        canvas.drawRect(rowRect, rowPaint);
      }

      // Primary key indicator
      final pkIcon = field.pk ? String.fromCharCode(Icons.vpn_key.codePoint) : '';
      final pkColor = Colors.amber.shade600;

      if (field.pk) {
        final pkPainter = TextPainter(
          text: TextSpan(
            text: pkIcon,
            style: TextStyle(
              fontFamily: 'MaterialIcons',
              fontSize: 14,
              color: pkColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        pkPainter.paint(
          canvas,
          Offset(rect.left + padding, rowY + (fieldRowHeight - 14) / 2),
        );
      }

      // Field name
      final nameOffset = field.pk ? padding + 20.0 : padding;
      textPainter.text = TextSpan(
        text: field.name,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontWeight: field.pk ? FontWeight.w600 : FontWeight.normal,
        ),
      );
      textPainter.layout(maxWidth: rect.width - nameOffset - 80);
      textPainter.paint(
        canvas,
        Offset(rect.left + nameOffset, rowY + (fieldRowHeight - textPainter.height) / 2),
      );

      // Field type
      final typePainter = TextPainter(
        text: TextSpan(
          text: _formatFieldType(field),
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      typePainter.paint(
        canvas,
        Offset(
          rect.right - padding - typePainter.width,
          rowY + (fieldRowHeight - typePainter.height) / 2,
        ),
      );
    }
  }

  /// Draw selection border
  static void _drawSelectionBorder(Canvas canvas, Rect rect) {
    final borderPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(1),
        const Radius.circular(cornerRadius + 1),
      ),
      borderPaint,
    );
  }

  /// Draw highlight border for search results
  static void _drawHighlightBorder(Canvas canvas, Rect rect) {
    final highlightPaint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(2),
        const Radius.circular(cornerRadius + 2),
      ),
      highlightPaint,
    );
  }

  /// Format field type for display
  static String _formatFieldType(Field field) {
    var type = field.type;
    if (field.length != null) {
      type += '(${field.length}';
      if (field.decimal != null) {
        type += ',${field.decimal}';
      }
      type += ')';
    }
    return type;
  }

  /// Draw field anchor points for edge creation
  static void _drawFieldAnchors(Canvas canvas, Rect rect, Entity entity, bool isDarkMode) {
    final anchorColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
    final pkColor = Colors.amber.shade600;

    // Draw anchors for each field
    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final leftAnchor = getLeftFieldAnchor(rect, i);
      final rightAnchor = getRightFieldAnchor(rect, i);

      // Use different color for primary key fields
      final color = field.pk ? pkColor : anchorColor;

      // Left anchor (outgoing connection)
      _drawSingleAnchor(canvas, leftAnchor, color, field.pk, true);

      // Right anchor (incoming connection)
      _drawSingleAnchor(canvas, rightAnchor, color, field.pk, false);
    }
  }

  /// Draw a single anchor point
  static void _drawSingleAnchor(Canvas canvas, Offset position, Color color, bool isPk, bool isLeft) {
    // Anchor background
    final anchorPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, fieldAnchorSize, anchorPaint);

    // Anchor border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(position, fieldAnchorSize, borderPaint);

    // Draw direction indicator (arrow)
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (isLeft) {
      // Left anchor: arrow pointing left (outgoing)
      canvas.drawLine(
        Offset(position.dx + 2, position.dy - 2),
        Offset(position.dx - 2, position.dy),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(position.dx + 2, position.dy + 2),
        Offset(position.dx - 2, position.dy),
        arrowPaint,
      );
    } else {
      // Right anchor: arrow pointing right (incoming)
      canvas.drawLine(
        Offset(position.dx - 2, position.dy - 2),
        Offset(position.dx + 2, position.dy),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(position.dx - 2, position.dy + 2),
        Offset(position.dx + 2, position.dy),
        arrowPaint,
      );
    }

    // Draw PK indicator (small circle inside)
    if (isPk) {
      final pkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 2, pkPaint);
    }
  }

}
