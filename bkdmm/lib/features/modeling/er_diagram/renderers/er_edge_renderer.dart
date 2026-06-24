import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';
import '../../shared/theme/td_theme.dart';
import '../core/er_graph_edge.dart';
import '../core/field_anchor_registry.dart';

/// ER 图关系边渲染器
///
/// 继承 graphview 的 EdgeRenderer，自定义 ER 图关系线的渲染：
/// - 字段级锚点连接
/// - 关系标记（1, N, M）
/// - 鸦脚（crow's foot）标记
class ERRelationEdgeRenderer extends EdgeRenderer {
  /// 字段锚点注册表
  final FieldAnchorRegistry anchorRegistry;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 默认线条宽度
  static const double defaultLineWidth = 2.0;

  /// 高亮线条宽度
  static const double highlightLineWidth = 3.0;

  /// 鸦脚尺寸
  static const double crowsFootSize = 8.0;

  /// 标记文本距离
  static const double markerTextDistance = 12.0;

  ERRelationEdgeRenderer({
    required this.anchorRegistry,
    this.isDarkMode = false,
  });

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    if (edge is! ERGraphEdge) {
      // 默认渲染
      _renderDefaultEdge(canvas, edge, paint);
      return;
    }

    final erEdge = edge;
    final sourceNode = erEdge.source;
    final targetNode = erEdge.destination;

    // 计算连接点位置
    final sourcePos = _getSourcePosition(sourceNode, erEdge);
    final targetPos = _getTargetPosition(targetNode, erEdge);

    // 绘制连线
    canvas.drawLine(sourcePos, targetPos, paint);

    // 绘制关系标记
    _drawRelationMarkers(canvas, sourcePos, targetPos, erEdge, paint.color);
  }

  /// 渲染默认边（非 ERGraphEdge 类型）
  void _renderDefaultEdge(Canvas canvas, Edge edge, Paint paint) {
    final sourcePos = getNodeCenter(edge.source);
    final targetPos = getNodeCenter(edge.destination);
    canvas.drawLine(sourcePos, targetPos, paint);
  }

  /// 获取源端连接位置
  Offset _getSourcePosition(Node node, ERGraphEdge edge) {
    if (edge.sourceFieldIndex != null) {
      final anchor = anchorRegistry.getAnchor(
        node.key?.value.toString() ?? '',
        edge.sourceFieldIndex!,
        FieldAnchorDirection.left,
      );
      if (anchor != null) {
        return anchor.position;
      }
    }
    // 默认使用节点右侧中点
    return Offset(node.x + node.width!, node.y + node.height! / 2);
  }

  /// 获取目标端连接位置
  Offset _getTargetPosition(Node node, ERGraphEdge edge) {
    if (edge.targetFieldIndex != null) {
      final anchor = anchorRegistry.getAnchor(
        node.key?.value.toString() ?? '',
        edge.targetFieldIndex!,
        FieldAnchorDirection.right,
      );
      if (anchor != null) {
        return anchor.position;
      }
    }
    // 默认使用节点左侧中点
    return Offset(node.x, node.y + node.height! / 2);
  }

  /// 绘制关系标记
  void _drawRelationMarkers(
    Canvas canvas,
    Offset sourcePos,
    Offset targetPos,
    ERGraphEdge edge,
    Color color,
  ) {
    // 源端标记
    final sourceMarkerType = RelationMarkerHelper.parseMarker(edge.sourceMarker);
    if (sourceMarkerType != null) {
      _drawMarker(canvas, sourcePos, targetPos, sourceMarkerType, color);
    }

    // 目标端标记
    final targetMarkerType = RelationMarkerHelper.parseMarker(edge.targetMarker);
    if (targetMarkerType != null) {
      _drawMarker(canvas, targetPos, sourcePos, targetMarkerType, color);
    }

    // 绘制标签（如果有）
    if (edge.label != null) {
      _drawLabel(canvas, sourcePos, targetPos, edge.label!, color);
    }
  }

  /// 绘制单个标记
  void _drawMarker(
    Canvas canvas,
    Offset pos,
    Offset otherPos,
    RelationMarkerType type,
    Color color,
  ) {
    final dx = pos.dx - otherPos.dx;
    final dy = pos.dy - otherPos.dy;
    final angle = math.atan2(dy, dx);

    final markerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = defaultLineWidth
        ..strokeCap = StrokeCap.round;

    if (RelationMarkerHelper.shouldDrawCrowsFoot(type)) {
      // 鸦脚标记
      _drawCrowsFoot(canvas, pos, angle, markerPaint);
    }

    // 绘制文本标记
    final text = RelationMarkerHelper.getMarkerText(type);
    if (text != null) {
      _drawMarkerText(canvas, pos, angle, text, color);
    }
  }

  /// 绘制鸦脚标记
  void _drawCrowsFoot(Canvas canvas, Offset pos, double angle, Paint paint) {
    final size = crowsFootSize;

    // 三条分叉线
    for (var i = -1; i <= 1; i++) {
      final branchAngle = angle + (i * math.pi / 6);
      final endX = pos.dx - size * math.cos(branchAngle);
      final endY = pos.dy - size * math.sin(branchAngle);
      canvas.drawLine(pos, Offset(endX, endY), paint);
    }
  }

  /// 绘制标记文本
  void _drawMarkerText(
    Canvas canvas,
    Offset pos,
    double angle,
    String text,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offsetX = pos.dx + markerTextDistance * math.cos(angle);
    final offsetY = pos.dy + markerTextDistance * math.sin(angle);

    textPainter.paint(
      canvas,
      Offset(
        offsetX - textPainter.width / 2,
        offsetY - textPainter.height / 2,
      ),
    );
  }

  /// 绘制标签
  void _drawLabel(
    Canvas canvas,
    Offset start,
    Offset end,
    String label,
    Color color,
  ) {
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );

    // 文本
    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
    );
  }

  /// 绘制连线预览（创建连线时使用）
  void renderConnectionPreview(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final paint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

    // 绘制虚线
    _drawDashedLine(canvas, start, end, paint);

    // 绘制箭头
    _drawArrow(canvas, end, start, Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill);
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    var currentDistance = 0.0;
    while (currentDistance < distance) {
      final dashStartX = start.dx + unitX * currentDistance;
      final dashStartY = start.dy + unitY * currentDistance;
      final dashEndX = start.dx + unitX * math.min(currentDistance + dashLength, distance);
      final dashEndY = start.dy + unitY * math.min(currentDistance + dashLength, distance);

      canvas.drawLine(
        Offset(dashStartX, dashStartY),
        Offset(dashEndX, dashEndY),
        paint,
      );

      currentDistance += dashLength + gapLength;
    }
  }

  /// 绘制箭头
  void _drawArrow(Canvas canvas, Offset tip, Offset base, Paint paint) {
    const arrowSize = 10.0;

    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final angle = math.atan2(dy, dx);

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - math.pi / 6),
      tip.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + math.pi / 6),
      tip.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  /// 创建默认 Paint
  Paint createDefaultPaint({bool highlight = false}) {
    return Paint()
        ..color = TDAppTheme.getEdgeColor(isDarkMode)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? highlightLineWidth : defaultLineWidth
        ..strokeCap = StrokeCap.round;
  }
}