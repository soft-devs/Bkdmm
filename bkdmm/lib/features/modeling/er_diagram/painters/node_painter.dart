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

  /// Paint the node
  static void paint({
    required Canvas canvas,
    required ERGraphNode node,
    required double scale,
    required bool isDarkMode,
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
      ..color = Colors.black.withOpacity(isDragging ? 0.3 : 0.15)
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
        colors: [headerColor, headerColor.withOpacity(0.8)],
      ).createShader(headerRect);

    final headerRRect = RRect.fromRectAndCorners(
      headerRect,
      topLeft: const Radius.circular(cornerRadius),
      topRight: const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(headerRRect, headerPaint);

    // Table icon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: String.fromCharCode(Icons.table.codePoint),
        style: TextStyle(
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
          ..color = isDarkMode ? Colors.white.withOpacity(0.02) : Colors.grey.shade50;
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
}
