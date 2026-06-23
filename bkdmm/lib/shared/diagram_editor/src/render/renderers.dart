import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_state.dart';

/// 节点渲染器抽象接口
///
/// 负责将节点绘制到 Canvas 上
/// 不同的图表类型需要实现不同的渲染器
abstract class NodeRenderer {
  /// 绘制节点
  void paint({
    required Canvas canvas,
    required DiagramNode node,
    required NodeState state,
    required RenderContext context,
  });

  /// 计算节点尺寸
  Size calculateSize(DiagramNode node);

  /// 命中测试
  bool hitTest(DiagramNode node, Offset point);

  /// 锚点命中测试
  AnchorPoint? hitTestAnchor(DiagramNode node, Offset point, double threshold);

  /// 获取锚点位置
  List<Offset> getAnchorPositions(DiagramNode node);
}

/// 边渲染器抽象接口
abstract class EdgeRenderer {
  /// 绘制边
  void paint({
    required Canvas canvas,
    required DiagramEdge edge,
    required AnchorPoint sourceAnchor,
    required AnchorPoint targetAnchor,
    required EdgeState state,
    required RenderContext context,
  });

  /// 绘制边预览（创建过程中）
  void paintPreview({
    required Canvas canvas,
    required AnchorPoint sourceAnchor,
    required Offset targetPosition,
    required RenderContext context,
  });

  /// 命中测试
  bool hitTest(
    DiagramEdge edge,
    AnchorPoint sourceAnchor,
    AnchorPoint targetAnchor,
    Offset point, {
    double threshold = 10.0,
  });
}

/// 渲染上下文
class RenderContext {
  /// 缩放比例
  final double scale;

  /// 是否深色模式
  final bool isDarkMode;

  /// 是否显示锚点
  final bool showAnchors;

  /// 交互模式
  final InteractionMode interactionMode;

  const RenderContext({
    this.scale = 1.0,
    this.isDarkMode = false,
    this.showAnchors = false,
    this.interactionMode = InteractionMode.edit,
  });
}

/// 基础节点渲染器
///
/// 提供通用的绘制方法，子类可以复用
abstract class BaseNodeRenderer implements NodeRenderer {
  /// 默认节点宽度
  static const double defaultWidth = 120.0;

  /// 默认节点高度
  static const double defaultHeight = 80.0;

  /// 圆角半径
  static const double cornerRadius = 8.0;

  /// 绘制阴影
  void drawShadow(Canvas canvas, Rect rect, {bool isDragging = false}) {
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
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

  /// 绘制背景
  void drawBackground(
    Canvas canvas,
    Rect rect, {
    Color? color,
    bool isSelected = false,
    bool isDarkMode = false,
  }) {
    final bgColor = color ?? (isDarkMode ? const Color(0xFF2D3748) : Colors.white);
    final bgPaint = Paint()..color = bgColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius)),
      bgPaint,
    );
  }

  /// 绘制选中边框
  void drawSelectionBorder(Canvas canvas, Rect rect, {Color? color}) {
    final borderPaint = Paint()
      ..color = color ?? Colors.blue.shade600
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

  /// 绘制高亮边框
  void drawHighlightBorder(Canvas canvas, Rect rect, {Color? color}) {
    final highlightPaint = Paint()
      ..color = color ?? Colors.orange.shade400
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

  /// 绘制节点级锚点
  void drawNodeAnchors(Canvas canvas, Rect rect, {Color? color, bool isDarkMode = false}) {
    final anchorColor = color ?? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade500);
    final anchors = _getNodeAnchorPositions(rect);

    for (final anchor in anchors) {
      // 锚点背景
      final anchorPaint = Paint()
        ..color = anchorColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(anchor, 6, anchorPaint);

      // 锚点边框
      final borderPaint = Paint()
        ..color = anchorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(anchor, 6, borderPaint);

      // 加号图标
      final plusPaint = Paint()
        ..color = anchorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(anchor.dx - 3, anchor.dy), Offset(anchor.dx + 3, anchor.dy), plusPaint);
      canvas.drawLine(Offset(anchor.dx, anchor.dy - 3), Offset(anchor.dx, anchor.dy + 3), plusPaint);
    }
  }

  List<Offset> _getNodeAnchorPositions(Rect rect) {
    return [
      Offset(rect.left + rect.width / 2, rect.top), // top
      Offset(rect.right, rect.top + rect.height / 2), // right
      Offset(rect.left + rect.width / 2, rect.bottom), // bottom
      Offset(rect.left, rect.top + rect.height / 2), // left
    ];
  }

  @override
  List<Offset> getAnchorPositions(DiagramNode node) {
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );
    return _getNodeAnchorPositions(rect);
  }

  @override
  AnchorPoint? hitTestAnchor(DiagramNode node, Offset point, double threshold) {
    final positions = getAnchorPositions(node);
    for (var i = 0; i < positions.length; i++) {
      final anchor = positions[i];
      if ((point - anchor).distance < threshold) {
        final directions = [
          AnchorDirection.top,
          AnchorDirection.right,
          AnchorDirection.bottom,
          AnchorDirection.left,
        ];
        return AnchorPoint.nodeAnchor(node: node, direction: directions[i]);
      }
    }
    return null;
  }

  @override
  bool hitTest(DiagramNode node, Offset point) {
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );
    return rect.contains(point);
  }
}

/// 基础边渲染器
abstract class BaseEdgeRenderer implements EdgeRenderer {
  /// 线条宽度
  static const double lineWidth = 2.0;

  /// 箭头大小
  static const double arrowSize = 10.0;

  /// 绘制直线
  void drawStraightLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
  }

  /// 绘制曲线
  void drawCurvedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < 100) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final controlOffset = distance * 0.2;
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    // 垂直偏移
    final perpX = -dy / distance * controlOffset;
    final perpY = dx / distance * controlOffset;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(midX + perpX, midY + perpY, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  /// 绘制正交线（折线）
  void drawOrthogonalLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final midX = (start.dx + end.dx) / 2;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(midX, start.dy);
    path.lineTo(midX, end.dy);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  /// 绘制箭头
  void drawArrow(Canvas canvas, Offset target, Offset source, Paint paint) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final angle = math.atan2(dy, dx);

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

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

    canvas.drawPath(path, arrowPaint);
  }

  /// 绘制虚线
  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, {List<double>? pattern}) {
    final dashPattern = pattern ?? [10.0, 5.0];
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;

    var currentLength = 0.0;
    var isDash = true;
    var patternIndex = 0;

    while (currentLength < totalLength) {
      final segmentLength = dashPattern[patternIndex % dashPattern.length];
      final nextLength = currentLength + segmentLength;

      if (nextLength > totalLength) {
        if (isDash) {
          canvas.drawLine(
            start + direction * currentLength,
            end,
            paint,
          );
        }
        break;
      }

      if (isDash) {
        canvas.drawLine(
          start + direction * currentLength,
          start + direction * nextLength,
          paint,
        );
      }

      currentLength = nextLength;
      isDash = !isDash;
      patternIndex++;
    }
  }

  /// 绘制鸦脚标记
  void drawCrowsFoot(Canvas canvas, Offset point, Offset otherPoint, Color color) {
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final angle = math.atan2(dy, dx);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const size = 8.0;

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

  /// 绘制单线标记（表示 "一"）
  void drawOneMarker(Canvas canvas, Offset point, Offset otherPoint, Color color) {
    final dx = point.dx - otherPoint.dx;
    final dy = point.dy - otherPoint.dy;
    final angle = math.atan2(dy, dx);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const size = 6.0;
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

  @override
  bool hitTest(
    DiagramEdge edge,
    AnchorPoint sourceAnchor,
    AnchorPoint targetAnchor,
    Offset point, {
    double threshold = 10.0,
  }) {
    final start = sourceAnchor.position;
    final end = targetAnchor.position;

    // 计算点到线段的距离
    final distance = _distanceToLine(point, start, end);
    return distance < threshold;
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
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