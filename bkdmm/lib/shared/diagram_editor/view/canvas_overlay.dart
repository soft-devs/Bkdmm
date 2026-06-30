import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_state.dart';

/// 画布叠加层
///
/// 使用 CustomPaint 绘制节点和边，提供高性能的图表渲染。
/// 作为 Widget 层的替代方案，适用于大量节点场景。
///
/// 特性：
/// - 使用 CustomPainter 直接绘制，避免 Widget 开销
/// - 支持视口变换（缩放、平移）
/// - 支持节点/边状态渲染（选中、悬停、高亮）
/// - 支持自定义渲染器扩展
class CanvasOverlay extends StatelessWidget {
  /// 图表状态
  final DiagramState state;

  /// 视口变换矩阵
  final Matrix4 transform;

  /// 视口尺寸
  final Size viewportSize;

  /// 节点渲染器
  final NodeRenderer? nodeRenderer;

  /// 边渲染器
  final EdgeRenderer? edgeRenderer;

  /// 是否显示网格
  final bool showGrid;

  /// 网格尺寸
  final double gridSize;

  /// 网格颜色
  final Color? gridColor;

  /// 背景颜色
  final Color? backgroundColor;

  /// 是否暗色模式
  final bool isDarkMode;

  const CanvasOverlay({
    super.key,
    required this.state,
    required this.transform,
    required this.viewportSize,
    this.nodeRenderer,
    this.edgeRenderer,
    this.showGrid = true,
    this.gridSize = 20.0,
    this.gridColor,
    this.backgroundColor,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: viewportSize,
      painter: _CanvasOverlayPainter(
        state: state,
        transform: transform,
        viewportSize: viewportSize,
        nodeRenderer: nodeRenderer ?? DefaultNodeRenderer(),
        edgeRenderer: edgeRenderer ?? DefaultEdgeRenderer(),
        showGrid: showGrid,
        gridSize: gridSize,
        gridColor: gridColor ?? _defaultGridColor(),
        backgroundColor: backgroundColor ?? _defaultBackgroundColor(),
        isDarkMode: isDarkMode,
      ),
    );
  }

  Color _defaultGridColor() {
    return isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
  }

  Color _defaultBackgroundColor() {
    return isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA);
  }
}

/// 画布叠加层绘制器
class _CanvasOverlayPainter extends CustomPainter {
  final DiagramState state;
  final Matrix4 transform;
  final Size viewportSize;
  final NodeRenderer nodeRenderer;
  final EdgeRenderer edgeRenderer;
  final bool showGrid;
  final double gridSize;
  final Color gridColor;
  final Color backgroundColor;
  final bool isDarkMode;

  _CanvasOverlayPainter({
    required this.state,
    required this.transform,
    required this.viewportSize,
    required this.nodeRenderer,
    required this.edgeRenderer,
    required this.showGrid,
    required this.gridSize,
    required this.gridColor,
    required this.backgroundColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    _drawBackground(canvas, size);

    // 绘制网格
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // 保存当前画布状态
    canvas.save();

    // 应用视口变换
    canvas.transform(transform.storage);

    // 绘制边（在节点下层）
    _drawEdges(canvas);

    // 绘制节点
    _drawNodes(canvas);

    // 恢复画布状态
    canvas.restore();
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// 绘制无限网格
  void _drawGrid(Canvas canvas, Size size) {
    final scale = transform.getMaxScaleOnAxis();
    final inverseMatrix = Matrix4.tryInvert(transform) ?? Matrix4.identity();

    // 计算可见区域在场景坐标系中的范围
    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverseMatrix,
      Offset(size.width, size.height),
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 / scale // 保持网格线宽度在视觉上一致
      ..style = PaintingStyle.stroke;

    // 计算网格起始位置（对齐到网格）
    final startX = (topLeft.dx / gridSize).floor() * gridSize;
    final endX = (bottomRight.dx / gridSize).ceil() * gridSize;
    final startY = (topLeft.dy / gridSize).floor() * gridSize;
    final endY = (bottomRight.dy / gridSize).ceil() * gridSize;

    // 绘制垂直网格线
    for (var x = startX; x <= endX; x += gridSize) {
      final screenX = MatrixUtils.transformPoint(transform, Offset(x, 0)).dx;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, size.height),
        gridPaint,
      );
    }

    // 绘制水平网格线
    for (var y = startY; y <= endY; y += gridSize) {
      final screenY = MatrixUtils.transformPoint(transform, Offset(0, y)).dy;
      canvas.drawLine(
        Offset(0, screenY),
        Offset(size.width, screenY),
        gridPaint,
      );
    }
  }

  /// 绘制所有边
  void _drawEdges(Canvas canvas) {
    for (final edge in state.edges.values) {
      final edgeState = state.getEdgeState(edge.id);
      final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
      final targetAnchor = state.getAnchor(edge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      edgeRenderer.render(
        canvas: canvas,
        edge: edge,
        edgeState: edgeState,
        sourceAnchor: sourceAnchor,
        targetAnchor: targetAnchor,
        isDarkMode: isDarkMode,
      );
    }
  }

  /// 绘制所有节点
  void _drawNodes(Canvas canvas) {
    for (final node in state.nodes.values) {
      final nodeState = state.getNodeState(node.id);
      nodeRenderer.render(
        canvas: canvas,
        node: node,
        nodeState: nodeState,
        isDarkMode: isDarkMode,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasOverlayPainter oldDelegate) {
    return state != oldDelegate.state ||
        transform != oldDelegate.transform ||
        viewportSize != oldDelegate.viewportSize ||
        showGrid != oldDelegate.showGrid ||
        gridSize != oldDelegate.gridSize ||
        gridColor != oldDelegate.gridColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}

/// 节点渲染器抽象类
///
/// 提供自定义节点渲染的扩展点
abstract class NodeRenderer {
  const NodeRenderer();

  /// 渲染节点
  void render({
    required Canvas canvas,
    required DiagramNode node,
    required NodeState nodeState,
    required bool isDarkMode,
  });
}

/// 默认节点渲染器
///
/// 渲染简单的矩形节点
class DefaultNodeRenderer extends NodeRenderer {
  /// 节点背景颜色
  final Color? bgColor;

  /// 节点边框颜色
  final Color? borderColor;

  /// 选中边框颜色
  final Color? selectionColor;

  /// 节点圆角
  final double cornerRadius;

  const DefaultNodeRenderer({
    this.bgColor,
    this.borderColor,
    this.selectionColor,
    this.cornerRadius = 8.0,
  });

  @override
  void render({
    required Canvas canvas,
    required DiagramNode node,
    required NodeState nodeState,
    required bool isDarkMode,
  }) {
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );

    // 绘制背景
    final bgPaint = Paint()
      ..color = bgColor ?? (isDarkMode ? const Color(0xFF2D3748) : Colors.white)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 绘制阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect.shift(const Offset(2, 2)), shadowPaint);

    // 绘制边框
    if (nodeState.isSelected) {
      final selectionPaint = Paint()
        ..color = selectionColor ?? Colors.blue.shade500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rrect, selectionPaint);
    } else {
      final borderPaint = Paint()
        ..color = borderColor ?? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, borderPaint);
    }

    // 绘制标题
    final titlePainter = TextPainter(
      text: TextSpan(
        text: node.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    titlePainter.layout(maxWidth: node.size.width - 24);
    titlePainter.paint(
      canvas,
      Offset(
        rect.left + 12,
        rect.top + 12,
      ),
    );
  }
}

/// 边渲染器抽象类
///
/// 提供自定义边渲染的扩展点
abstract class EdgeRenderer {
  const EdgeRenderer();

  /// 渲染边
  void render({
    required Canvas canvas,
    required DiagramEdge edge,
    required EdgeState edgeState,
    required AnchorPoint sourceAnchor,
    required AnchorPoint targetAnchor,
    required bool isDarkMode,
  });
}

/// 默认边渲染器
///
/// 渲染直线或曲线边
class DefaultEdgeRenderer extends EdgeRenderer {
  /// 边颜色
  final Color? color;

  /// 边宽度
  final double width;

  /// 是否显示箭头
  final bool showArrow;

  /// 箭头大小
  final double arrowSize;

  const DefaultEdgeRenderer({
    this.color,
    this.width = 2.0,
    this.showArrow = true,
    this.arrowSize = 10.0,
  });

  @override
  void render({
    required Canvas canvas,
    required DiagramEdge edge,
    required EdgeState edgeState,
    required AnchorPoint sourceAnchor,
    required AnchorPoint targetAnchor,
    required bool isDarkMode,
  }) {
    final style = edge.getStyle();
    final edgeColor = color ?? style.color;
    final edgeWidth = width * style.width;

    final paint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth
      ..strokeCap = StrokeCap.round;

    final sourcePos = sourceAnchor.position;
    final targetPos = targetAnchor.position;

    // 绘制线条
    switch (style.shape) {
      case EdgeShape.straight:
        if (style.lineType == EdgeLineType.dashed) {
          _drawDashedLine(canvas, sourcePos, targetPos, paint, 10.0, 5.0);
        } else if (style.lineType == EdgeLineType.dotted) {
          _drawDashedLine(canvas, sourcePos, targetPos, paint, 3.0, 3.0);
        } else {
          canvas.drawLine(sourcePos, targetPos, paint);
        }
        break;
      case EdgeShape.curved:
        _drawCurvedLine(canvas, sourcePos, targetPos, paint, style.curveFactor, style.lineType);
        break;
      case EdgeShape.orthogonal:
        _drawOrthogonalLine(canvas, sourcePos, targetPos, paint, style.lineType);
        break;
      case EdgeShape.bezier:
        _drawBezierLine(canvas, sourcePos, targetPos, paint, style.lineType);
        break;
    }

    // 绘制箭头
    if (showArrow || style.showArrow) {
      _drawArrow(canvas, targetPos, sourcePos, paint, arrowSize);
    }

    // 绘制源端标记
    final sourceMarker = edge.getSourceMarker();
    if (sourceMarker != null) {
      _drawMarker(canvas, sourcePos, targetPos, sourceMarker, isDarkMode);
    }

    // 绘制目标端标记
    final targetMarker = edge.getTargetMarker();
    if (targetMarker != null) {
      _drawMarker(canvas, targetPos, sourcePos, targetMarker, isDarkMode);
    }

    // 绘制标签
    if (edge.label != null) {
      _drawLabel(canvas, sourcePos, targetPos, edge.label!, edgeColor, isDarkMode);
    }

    // 选中状态
    if (edgeState.isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.shade500.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth + 4.0;
      canvas.drawLine(sourcePos, targetPos, selectionPaint);
    }
  }

  /// 绘制曲线
  void _drawCurvedLine(
    Canvas canvas,
    Offset source,
    Offset target,
    Paint paint,
    double curveFactor,
    [EdgeLineType lineType = EdgeLineType.solid]
  ) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final controlOffset = distance * curveFactor;

    // 计算控制点（垂直于连线方向偏移）
    final midX = (source.dx + target.dx) / 2;
    final midY = (source.dy + target.dy) / 2;
    final normalX = -dy / distance;
    final normalY = dx / distance;

    final controlPoint = Offset(
      midX + normalX * controlOffset,
      midY + normalY * controlOffset,
    );

    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        target.dx,
        target.dy,
      );

    if (lineType == EdgeLineType.dashed) {
      _drawDashedPath(canvas, path, paint, 10.0, 5.0);
    } else if (lineType == EdgeLineType.dotted) {
      _drawDashedPath(canvas, path, paint, 3.0, 3.0);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制正交线（折线）
  void _drawOrthogonalLine(
    Canvas canvas,
    Offset source,
    Offset target,
    Paint paint,
    [EdgeLineType lineType = EdgeLineType.solid]
  ) {
    final midX = (source.dx + target.dx) / 2;

    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..lineTo(midX, source.dy)
      ..lineTo(midX, target.dy)
      ..lineTo(target.dx, target.dy);

    if (lineType == EdgeLineType.dashed) {
      _drawDashedPath(canvas, path, paint, 10.0, 5.0);
    } else if (lineType == EdgeLineType.dotted) {
      _drawDashedPath(canvas, path, paint, 3.0, 3.0);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制贝塞尔曲线
  void _drawBezierLine(
    Canvas canvas,
    Offset source,
    Offset target,
    Paint paint,
    [EdgeLineType lineType = EdgeLineType.solid]
  ) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final controlOffset = distance * 0.3;

    // 计算控制点
    final control1 = Offset(
      source.dx + controlOffset,
      source.dy,
    );
    final control2 = Offset(
      target.dx - controlOffset,
      target.dy,
    );

    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        target.dx,
        target.dy,
      );

    if (lineType == EdgeLineType.dashed) {
      _drawDashedPath(canvas, path, paint, 10.0, 5.0);
    } else if (lineType == EdgeLineType.dotted) {
      _drawDashedPath(canvas, path, paint, 3.0, 3.0);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制虚线路径
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    // 使用 PathMetric 来绘制虚线
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          final end = (distance + dashLength).clamp(0.0, metric.length);
          canvas.drawPath(
            metric.extractPath(distance, end),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  /// 绘制虚线
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = dx * dx + dy * dy;

    if (distance == 0) return;

    final length = sqrt(distance);
    final unitX = dx / length;
    final unitY = dy / length;

    var currentDistance = 0.0;
    while (currentDistance < length) {
      final dashStartX = start.dx + unitX * currentDistance;
      final dashStartY = start.dy + unitY * currentDistance;
      final dashEndX = start.dx + unitX * (currentDistance + dashLength).clamp(0.0, length);
      final dashEndY = start.dy + unitY * (currentDistance + dashLength).clamp(0.0, length);

      canvas.drawLine(
        Offset(dashStartX, dashStartY),
        Offset(dashEndX, dashEndY),
        paint,
      );

      currentDistance += dashLength + gapLength;
    }
  }

  /// 绘制箭头
  void _drawArrow(
    Canvas canvas,
    Offset tip,
    Offset base,
    Paint paint,
    double size,
  ) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final angle = math.atan2(dy, dx);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - size * math.cos(angle - math.pi / 6),
        tip.dy - size * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        tip.dx - size * math.cos(angle + math.pi / 6),
        tip.dy - size * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  /// 绘制端点标记
  void _drawMarker(
    Canvas canvas,
    Offset position,
    OppositePosition opposite,
    EdgeMarker marker,
    bool isDarkMode,
  ) {
    final markerColor = marker.color ?? (isDarkMode ? Colors.white70 : Colors.black87);
    final markerSize = marker.size;

    switch (marker.type) {
      case EdgeMarkerType.one:
        // 绘制单线标记
        final paint = Paint()
          ..color = markerColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          position,
          position.translate(markerSize, 0),
          paint,
        );
        break;

      case EdgeMarkerType.many:
        // 绘制鸦脚标记（"多"）
        _drawCrowFoot(canvas, position, opposite, markerColor, markerSize);
        break;

      case EdgeMarkerType.multiple:
        // 绘制 M 标记
        _drawTextMarker(canvas, position, 'M', markerColor, markerSize);
        break;

      case EdgeMarkerType.arrow:
        // 绘制箭头标记
        final paint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill;
        _drawArrow(canvas, position, opposite, paint, markerSize);
        break;

      case EdgeMarkerType.circle:
        // 绘制圆点标记
        final paint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, markerSize / 2, paint);
        break;

      case EdgeMarkerType.diamond:
        // 绘制菱形标记
        _drawDiamond(canvas, position, opposite, markerColor, markerSize);
        break;

      case EdgeMarkerType.custom:
        // 绘制自定义文本标记
        if (marker.text != null) {
          _drawTextMarker(canvas, position, marker.text!, markerColor, markerSize);
        }
        break;

      case EdgeMarkerType.none:
        // 无标记
        break;
    }
  }

  /// 绘制鸦脚标记
  void _drawCrowFoot(
    Canvas canvas,
    Offset position,
    OppositePosition opposite,
    Color color,
    double size,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final angle = math.atan2(
      opposite.dy - position.dy,
      opposite.dx - position.dx,
    );

    // 鸦脚是三条线，中间一条直的，两边各偏转30度
    for (final offset in [-math.pi / 6, 0.0, math.pi / 6]) {
      final endAngle = angle + offset;
      canvas.drawLine(
        position,
        Offset(
          position.dx + size * math.cos(endAngle),
          position.dy + size * math.sin(endAngle),
        ),
        paint,
      );
    }
  }

  /// 绘制菱形标记
  void _drawDiamond(
    Canvas canvas,
    Offset position,
    OppositePosition opposite,
    Color color,
    double size,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final angle = math.atan2(
      opposite.dy - position.dy,
      opposite.dx - position.dx,
    );

    final path = Path()
      ..moveTo(position.dx, position.dy)
      ..lineTo(
        position.dx + size * 0.5 * math.cos(angle - math.pi / 2),
        position.dy + size * 0.5 * math.sin(angle - math.pi / 2),
      )
      ..lineTo(
        position.dx + size * math.cos(angle),
        position.dy + size * math.sin(angle),
      )
      ..lineTo(
        position.dx + size * 0.5 * math.cos(angle + math.pi / 2),
        position.dy + size * 0.5 * math.sin(angle + math.pi / 2),
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  /// 绘制文本标记
  void _drawTextMarker(
    Canvas canvas,
    Offset position,
    String text,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// 绘制边标签
  void _drawLabel(
    Canvas canvas,
    Offset source,
    Offset target,
    String label,
    Color color,
    bool isDarkMode,
  ) {
    final midX = (source.dx + target.dx) / 2;
    final midY = (source.dy + target.dy) / 2;

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white70 : Colors.black87,
          backgroundColor: isDarkMode
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(midX - painter.width / 2, midY - painter.height / 2),
    );
  }
}

/// 辅助类型：表示相对位置的点
typedef OppositePosition = Offset;

/// 数学辅助函数
double sqrt(double x) => math.sqrt(x);

/// 连线预览绘制器
///
/// 用于绘制正在创建中的连线预览
class ConnectionPreviewPainter extends CustomPainter {
  /// 源锚点位置
  final Offset sourcePos;

  /// 目标位置（鼠标位置）
  final Offset targetPos;

  /// 线条颜色
  final Color color;

  /// 是否显示箭头
  final bool showArrow;

  const ConnectionPreviewPainter({
    required this.sourcePos,
    required this.targetPos,
    required this.color,
    this.showArrow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, sourcePos, targetPos, paint);

    if (showArrow) {
      _drawArrow(canvas, targetPos, sourcePos, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = dx * dx + dy * dy;

    if (distance == 0) return;

    final length = sqrt(distance);
    final unitX = dx / length;
    final unitY = dy / length;

    var currentDistance = 0.0;
    while (currentDistance < length) {
      final dashStartX = start.dx + unitX * currentDistance;
      final dashStartY = start.dy + unitY * currentDistance;
      final dashEndX = start.dx + unitX * (currentDistance + dashLength).clamp(0.0, length);
      final dashEndY = start.dy + unitY * (currentDistance + dashLength).clamp(0.0, length);

      canvas.drawLine(
        Offset(dashStartX, dashStartY),
        Offset(dashEndX, dashEndY),
        paint,
      );

      currentDistance += dashLength + gapLength;
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset base, Paint paint) {
    const arrowSize = 10.0;

    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final angle = math.atan2(dy, dx);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle - math.pi / 6),
        tip.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle + math.pi / 6),
        tip.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ConnectionPreviewPainter oldDelegate) {
    return sourcePos != oldDelegate.sourcePos ||
        targetPos != oldDelegate.targetPos ||
        color != oldDelegate.color;
  }
}

/// 框选矩形绘制器
class SelectionRectPainter extends CustomPainter {
  /// 框选矩形
  final Rect rect;

  /// 边框颜色
  final Color color;

  const SelectionRectPainter({
    required this.rect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 边框
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SelectionRectPainter oldDelegate) {
    return rect != oldDelegate.rect || color != oldDelegate.color;
  }
}
