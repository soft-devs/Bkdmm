import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../../../../shared/models/models.dart';
import '../models/er_diagram_models.dart';

/// ER 图节点渲染器
///
/// 渲染 ER 图中的表节点
class ERNodeRenderer extends BaseNodeRenderer {
  /// 默认宽度
  static const double defaultWidth = 200.0;

  /// 表头高度
  static const double headerHeight = 40.0;

  /// 字段行高度
  static const double fieldRowHeight = 28.0;

  /// 内边距
  static const double padding = 12.0;

  /// 最小高度
  static const double minHeight = 80.0;

  /// 圆角半径
  static const double cornerRadius = 8.0;

  /// 锚点偏移
  static const double anchorOffset = 8.0;

  /// 字段锚点尺寸
  static const double fieldAnchorSize = 6.0;

  @override
  void paint({
    required Canvas canvas,
    required DiagramNode node,
    required NodeState state,
    required RenderContext context,
  }) {
    final erNode = node as ERNode;
    final entity = erNode.entity;

    final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);

    // 1. 绘制阴影
    drawShadow(canvas, rect, isDragging: state.isDragging);

    // 2. 绘制背景
    final bgColor = context.isDarkMode
        ? (state.isSelected ? const Color(0xFF1E3A5F) : const Color(0xFF2D3748))
        : (state.isSelected ? const Color(0xFFE3F2FD) : Colors.white);
    drawBackground(canvas, rect, color: bgColor, isSelected: state.isSelected, isDarkMode: context.isDarkMode);

    // 3. 绘制表头
    _drawHeader(canvas, rect, entity, context.isDarkMode);

    // 4. 绘制字段
    _drawFields(canvas, rect, entity, context.isDarkMode);

    // 5. 绘制选中边框
    if (state.isSelected) {
      drawSelectionBorder(canvas, rect);
    }

    // 6. 绘制高亮边框
    if (state.isHighlighted) {
      drawHighlightBorder(canvas, rect, color: Colors.orange.shade400);
    }

    // 7. 绘制字段锚点（仅在编辑模式）
    if (context.showAnchors && context.interactionMode == InteractionMode.edit) {
      _drawFieldAnchors(canvas, rect, entity, context.isDarkMode);
    }
  }

  void _drawHeader(Canvas canvas, Rect rect, Entity entity, bool isDarkMode) {
    final headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width, headerHeight);

    // 表头背景
    final headerColor = isDarkMode ? const Color(0xFF2563EB) : const Color(0xFF1976D2);
    final headerPaint = Paint()..color = headerColor;

    final headerRRect = RRect.fromRectAndCorners(
      headerRect,
      topLeft: const Radius.circular(cornerRadius),
      topRight: const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(headerRRect, headerPaint);

    // 表图标
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.table_rows.codePoint),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(rect.left + padding, rect.top + (headerHeight - 16) / 2));

    // 表名
    final namePainter = TextPainter(
      text: TextSpan(
        text: entity.title,
        style: TextStyle(
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

    // 中文名
    if (entity.chnname.isNotEmpty) {
      final chnPainter = TextPainter(
        text: TextSpan(
          text: entity.chnname,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      chnPainter.paint(
        canvas,
        Offset(rect.right - padding - chnPainter.width, rect.top + (headerHeight - chnPainter.height) / 2),
      );
    }
  }

  void _drawFields(Canvas canvas, Rect rect, Entity entity, bool isDarkMode) {
    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final rowY = rect.top + headerHeight + (i * fieldRowHeight);

      // 交替行背景
      if (i % 2 == 1) {
        final rowRect = Rect.fromLTWH(rect.left, rowY, rect.width, fieldRowHeight);
        final rowPaint = Paint()
          ..color = isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50;
        canvas.drawRect(rowRect, rowPaint);
      }

      // 主键图标
      if (field.pk) {
        final pkPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.vpn_key.codePoint),
            style: TextStyle(
              fontFamily: 'MaterialIcons',
              fontSize: 14,
              color: Colors.amber.shade600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        pkPainter.paint(canvas, Offset(rect.left + padding, rowY + (fieldRowHeight - 14) / 2));
      }

      // 字段名
      final nameOffset = field.pk ? padding + 20.0 : padding;
      final namePainter = TextPainter(
        text: TextSpan(
          text: field.name,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            fontWeight: field.pk ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - nameOffset - 80);
      namePainter.paint(canvas, Offset(rect.left + nameOffset, rowY + (fieldRowHeight - namePainter.height) / 2));

      // 字段类型
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
        Offset(rect.right - padding - typePainter.width, rowY + (fieldRowHeight - typePainter.height) / 2),
      );
    }
  }

  void _drawFieldAnchors(Canvas canvas, Rect rect, Entity entity, bool isDarkMode) {
    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final rowY = rect.top + headerHeight + (i * fieldRowHeight) + fieldRowHeight / 2;

      // 左锚点（出边）
      final leftAnchor = Offset(rect.left - anchorOffset, rowY);
      AnchorRenderer.paintFieldAnchor(
        canvas,
        leftAnchor,
        color: Colors.green.shade600,
        isPrimaryKey: field.pk,
        isLeft: true,
      );

      // 右锚点（入边）
      final rightAnchor = Offset(rect.right + anchorOffset, rowY);
      AnchorRenderer.paintFieldAnchor(
        canvas,
        rightAnchor,
        color: Colors.green.shade600,
        isPrimaryKey: field.pk,
        isLeft: false,
      );
    }
  }

  String _formatFieldType(Field field) {
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

  @override
  Size calculateSize(DiagramNode node) {
    final erNode = node as ERNode;
    final fieldCount = erNode.entity.fields.length;
    final height = headerHeight + (fieldCount * fieldRowHeight) + padding;
    return Size(defaultWidth, math.max(minHeight, height));
  }

  @override
  bool hitTest(DiagramNode node, Offset point) {
    final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);
    return rect.contains(point);
  }

  @override
  AnchorPoint? hitTestAnchor(DiagramNode node, Offset point, double threshold) {
    final erNode = node as ERNode;
    final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);

    for (var i = 0; i < erNode.entity.fields.length; i++) {
      final rowY = rect.top + headerHeight + (i * fieldRowHeight) + fieldRowHeight / 2;

      // 检查左锚点
      final leftAnchor = Offset(rect.left - anchorOffset, rowY);
      if ((point - leftAnchor).distance < threshold * 2.5) {
        return AnchorPoint.fieldAnchor(
          node: node,
          fieldIndex: i,
          direction: AnchorDirection.left,
          position: leftAnchor,
          fieldData: erNode.entity.fields[i],
        );
      }

      // 检查右锚点
      final rightAnchor = Offset(rect.right + anchorOffset, rowY);
      if ((point - rightAnchor).distance < threshold * 2.5) {
        return AnchorPoint.fieldAnchor(
          node: node,
          fieldIndex: i,
          direction: AnchorDirection.right,
          position: rightAnchor,
          fieldData: erNode.entity.fields[i],
        );
      }
    }

    return null;
  }
}

/// ER 图边渲染器
///
/// 渲染 ER 图中的关系连线
class EREdgeRenderer extends BaseEdgeRenderer {
  @override
  void paint({
    required Canvas canvas,
    required DiagramEdge edge,
    required AnchorPoint sourceAnchor,
    required AnchorPoint targetAnchor,
    required EdgeState state,
    required RenderContext context,
  }) {
    final erEdge = edge as ERRelationEdge;
    final start = sourceAnchor.position;
    final end = targetAnchor.position;

    // 边颜色
    final color = state.isHighlighted
        ? Colors.orange.shade400
        : (context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    // 线条 Paint
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = state.isHighlighted ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;

    // 绘制连线
    drawStraightLine(canvas, start, end, linePaint);

    // 绘制关系标记
    final sourceMarker = erEdge.getSourceMarker();
    if (sourceMarker != null) {
      _drawMarker(canvas, start, end, sourceMarker, color);
    }

    final targetMarker = erEdge.getTargetMarker();
    if (targetMarker != null) {
      _drawMarker(canvas, end, start, targetMarker, color);
    }

    // 绘制标签
    if (erEdge.graphEdge.label != null) {
      _drawLabel(canvas, start, end, erEdge.graphEdge.label!, context.isDarkMode);
    }
  }

  void _drawMarker(Canvas canvas, Offset point, Offset otherPoint, EdgeMarker marker, Color color) {
    switch (marker.type) {
      case EdgeMarkerType.one:
        drawOneMarker(canvas, point, otherPoint, color);
        // 绘制文本 "1"
        final textPainter = TextPainter(
          text: TextSpan(
            text: '1',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final offset = _getMarkerOffset(point, otherPoint, 12);
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
        break;

      case EdgeMarkerType.many:
        drawCrowsFoot(canvas, point, otherPoint, color);
        // 绘制文本 "N"
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'N',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final offset = _getMarkerOffset(point, otherPoint, 12);
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
        break;

      case EdgeMarkerType.multiple:
        drawCrowsFoot(canvas, point, otherPoint, color);
        // 绘制文本 "M"
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'M',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final offset = _getMarkerOffset(point, otherPoint, 12);
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
        break;

      case EdgeMarkerType.arrow:
        drawArrow(canvas, point, otherPoint, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
        break;

      default:
        break;
    }
  }

  Offset _getMarkerOffset(Offset point, Offset otherPoint, double distance) {
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return point;

    return Offset(
      point.dx + dx / length * distance,
      point.dy + dy / length * distance,
    );
  }

  void _drawLabel(Canvas canvas, Offset start, Offset end, String label, bool isDarkMode) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

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

    // 背景
    const padding = 4.0;
    final bgRect = Rect.fromCenter(
      center: Offset(midX, midY),
      width: textPainter.width + padding * 2,
      height: textPainter.height + padding * 2,
    );

    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2D3748) : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), borderPaint);

    // 文本
    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
    );
  }

  @override
  void paintPreview({
    required Canvas canvas,
    required AnchorPoint sourceAnchor,
    required Offset targetPosition,
    required RenderContext context,
  }) {
    final start = sourceAnchor.position;
    final end = targetPosition;

    final color = context.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade500;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 绘制虚线预览
    drawDashedLine(canvas, start, end, paint);

    // 绘制箭头
    drawArrow(canvas, end, start, Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill);
  }
}
