/// ER 关系绘制器适配器
///
/// 适配 GraphView 的 GraphEdgePainter 接口，
/// 委托给 ERRelationPainter 进行实际绘制。
library;

import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import '../../../../shared/diagram_editor/diagram_editor.dart';

/// ER 关系绘制器适配器
///
/// 实现 GraphEdgePainter 接口，用于 GraphView 中绘制 ER 关系边。
/// 内部使用 ERRelationPainter 进行实际绘制。
class ERRelationPainterAdapter implements GraphEdgePainter {
  /// 内部绘制器
  final ERRelationPainter _painter = ERRelationPainter();

  /// 绘制配置
  final ERRelationPainterConfig config;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 创建适配器
  ERRelationPainterAdapter({
    this.config = const ERRelationPainterConfig(),
    this.isDarkMode = false,
  });

  @override
  void paint(
    Canvas canvas,
    DiagramEdge edge,
    EdgeState edgeState,
    Offset sourcePosition,
    Offset targetPosition,
    Matrix4 transform,
    bool isDark,
  ) {
    // 确保边是 ERRelationEdgeModel
    if (edge is! ERRelationEdgeModel) {
      // 对于非 ER 边，使用默认绘制
      _drawDefaultEdge(canvas, sourcePosition, targetPosition, edgeState, transform);
      return;
    }

    final erEdge = edge as ERRelationEdgeModel;

    // 获取缩放比例
    final zoom = transform.getMaxScaleOnAxis();

    // 获取锚点方向（从锚点 ID 解析）
    final sourceDirection = _parseDirection(erEdge.sourceAnchorId);
    final targetDirection = _parseDirection(erEdge.targetAnchorId);

    // 获取有效样式
    final style = _getEffectiveStyle(erEdge, edgeState, isDark);

    // 绘制选中/悬停高亮
    if (edgeState.isSelected || edgeState.isHovered) {
      _drawHighlight(
        canvas,
        sourcePosition,
        targetPosition,
        sourceDirection,
        targetDirection,
        style,
        zoom,
      );
    }

    // 绘制关系线
    _drawRelationLine(
      canvas: canvas,
      sourcePos: sourcePosition,
      targetPos: targetPosition,
      sourceDirection: sourceDirection,
      targetDirection: targetDirection,
      style: style,
      zoom: zoom,
      edge: erEdge,
    );

    // 绘制源端标记
    _drawCardinalityMarker(
      canvas: canvas,
      position: sourcePosition,
      direction: sourceDirection,
      cardinality: erEdge.sourceCardinality,
      isSource: true,
      zoom: zoom,
      color: style.color,
    );

    // 绘制目标端标记
    _drawCardinalityMarker(
      canvas: canvas,
      position: targetPosition,
      direction: targetDirection,
      cardinality: erEdge.targetCardinality,
      isSource: false,
      zoom: zoom,
      color: style.color,
    );

    // 绘制关系名称标签
    if (config.showRelationName &&
        erEdge.relationName != null &&
        erEdge.relationName!.isNotEmpty) {
      _drawRelationLabel(
        canvas: canvas,
        label: erEdge.relationName!,
        sourcePos: sourcePosition,
        targetPos: targetPosition,
        style: style,
        zoom: zoom,
      );
    }
  }

  /// 绘制默认边（非 ER 边）
  void _drawDefaultEdge(
    Canvas canvas,
    Offset sourcePosition,
    Offset targetPosition,
    EdgeState edgeState,
    Matrix4 transform,
  ) {
    final paint = Paint()
      ..color = edgeState.isSelected
          ? config.selectedColor
          : config.lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(sourcePosition, targetPosition, paint);
  }

  /// 获取有效样式
  EdgeStyle _getEffectiveStyle(
    ERRelationEdgeModel edge,
    EdgeState edgeState,
    bool isDark,
  ) {
    final baseColor = isDark
        ? const Color(0xFFA0AEC0)
        : config.lineColor;

    final baseStyle = edge.getStyle().copyWith(
      color: baseColor,
      width: config.lineWidth,
    );

    if (edgeState.isSelected) {
      return baseStyle.copyWith(
        color: config.selectedColor,
        width: 3.0,
      );
    }

    if (edgeState.isHovered) {
      return baseStyle.copyWith(
        color: config.hoverColor,
        width: 2.5,
      );
    }

    return baseStyle;
  }

  /// 从锚点 ID 解析方向
  AnchorDirection _parseDirection(String anchorId) {
    final parts = anchorId.split(':');
    if (parts.length >= 2) {
      final lastPart = parts.last.toLowerCase();
      switch (lastPart) {
        case 'left':
          return AnchorDirection.left;
        case 'right':
          return AnchorDirection.right;
        case 'top':
          return AnchorDirection.top;
        case 'bottom':
          return AnchorDirection.bottom;
      }
    }
    // 默认方向
    return AnchorDirection.right;
  }

  /// 绘制高亮效果
  void _drawHighlight(
    Canvas canvas,
    Offset sourcePos,
    Offset targetPos,
    AnchorDirection sourceDirection,
    AnchorDirection targetDirection,
    EdgeStyle style,
    double zoom,
  ) {
    final highlightPaint = Paint()
      ..color = config.selectedColor.withValues(alpha: 0.2)
      ..strokeWidth = style.width * zoom + 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawPath(
      canvas: canvas,
      sourcePos: sourcePos,
      targetPos: targetPos,
      sourceDirection: sourceDirection,
      targetDirection: targetDirection,
      paint: highlightPaint,
    );
  }

  /// 绘制关系线
  void _drawRelationLine({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required EdgeStyle style,
    required double zoom,
    required ERRelationEdgeModel edge,
  }) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = style.width * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (edge.isNonIdentifying) {
      // 非标识关系使用虚线
      final dashConfig = style.dashConfig ?? config.nonIdentifyingDashConfig;
      _drawDashedPath(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceDirection,
        targetDirection: targetDirection,
        paint: paint,
        dashPattern: dashConfig.pattern.map((d) => d * zoom).toList(),
      );
    } else {
      _drawPath(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceDirection,
        targetDirection: targetDirection,
        paint: paint,
      );
    }
  }

  /// 绘制路径
  void _drawPath({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required Paint paint,
  }) {
    final path = Path();

    final controlPoints = _computeBezierControlPoints(
      sourcePos,
      targetPos,
      sourceDirection,
      targetDirection,
      0.3,
    );

    path.moveTo(sourcePos.dx, sourcePos.dy);
    path.cubicTo(
      controlPoints[0].dx,
      controlPoints[0].dy,
      controlPoints[1].dx,
      controlPoints[1].dy,
      targetPos.dx,
      targetPos.dy,
    );

    canvas.drawPath(path, paint);
  }

  /// 绘制虚线贝塞尔路径
  void _drawDashedPath({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required Paint paint,
    required List<double> dashPattern,
  }) {
    final controlPoints = _computeBezierControlPoints(
      sourcePos,
      targetPos,
      sourceDirection,
      targetDirection,
      0.3,
    );

    final points = _approximateBezierCurve(
      sourcePos,
      controlPoints[0],
      controlPoints[1],
      targetPos,
      20,
    );

    double accumulatedDistance = 0;
    bool isDrawing = true;
    int patternIndex = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segmentLength = (end - start).distance;

      double remainingLength = segmentLength;
      double segmentStartOffset = 0;

      while (remainingLength > 0) {
        final dashLength = dashPattern[patternIndex % dashPattern.length];
        final availableLength = dashLength - accumulatedDistance;

        if (isDrawing) {
          final drawLength =
              remainingLength < availableLength ? remainingLength : availableLength;
          final drawStart = Offset(
            start.dx + (end.dx - start.dx) * (segmentStartOffset / segmentLength),
            start.dy + (end.dy - start.dy) * (segmentStartOffset / segmentLength),
          );
          final drawEnd = Offset(
            start.dx +
                (end.dx - start.dx) * ((segmentStartOffset + drawLength) / segmentLength),
            start.dy +
                (end.dy - start.dy) * ((segmentStartOffset + drawLength) / segmentLength),
          );
          canvas.drawLine(drawStart, drawEnd, paint);
        }

        segmentStartOffset +=
            remainingLength < availableLength ? remainingLength : availableLength;
        remainingLength -=
            remainingLength < availableLength ? remainingLength : availableLength;
        accumulatedDistance +=
            remainingLength < availableLength ? remainingLength : availableLength;

        if (accumulatedDistance >= dashLength) {
          accumulatedDistance = 0;
          isDrawing = !isDrawing;
          patternIndex++;
        }
      }
    }
  }

  /// 近似贝塞尔曲线为一系列点
  List<Offset> _approximateBezierCurve(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    int segments,
  ) {
    final points = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final point = _cubicBezierPoint(p0, p1, p2, p3, t);
      points.add(point);
    }
    return points;
  }

  /// 计算贝塞尔曲线上的点
  Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

    return Offset(x, y);
  }

  /// 计算贝塞尔曲线控制点
  List<Offset> _computeBezierControlPoints(
    Offset source,
    Offset target,
    AnchorDirection sourceDirection,
    AnchorDirection targetDirection,
    double factor,
  ) {
    final distance = (target - source).distance;
    final controlLength = distance * factor;

    Offset control1;
    Offset control2;

    switch (sourceDirection) {
      case AnchorDirection.left:
        control1 = Offset(source.dx - controlLength, source.dy);
      case AnchorDirection.right:
        control1 = Offset(source.dx + controlLength, source.dy);
      case AnchorDirection.top:
        control1 = Offset(source.dx, source.dy - controlLength);
      case AnchorDirection.bottom:
        control1 = Offset(source.dx, source.dy + controlLength);
    }

    switch (targetDirection) {
      case AnchorDirection.left:
        control2 = Offset(target.dx - controlLength, target.dy);
      case AnchorDirection.right:
        control2 = Offset(target.dx + controlLength, target.dy);
      case AnchorDirection.top:
        control2 = Offset(target.dx, target.dy - controlLength);
      case AnchorDirection.bottom:
        control2 = Offset(target.dx, target.dy + controlLength);
    }

    return [control1, control2];
  }

  /// 绘制基数标记
  void _drawCardinalityMarker({
    required Canvas canvas,
    required Offset position,
    required AnchorDirection direction,
    required ERCardinalityEnd cardinality,
    required bool isSource,
    required double zoom,
    required Color color,
  }) {
    final size = config.markerSize * zoom;

    if (cardinality.isOptional) {
      _drawOptionalMarker(canvas, position, direction, size, color, isSource);
    }

    switch (cardinality.type) {
      case ERCardinalityType.one:
        _drawOneMarker(canvas, position, direction, size, color, isSource);

      case ERCardinalityType.many:
        _drawManyMarker(canvas, position, direction, size, color, isSource);

      case ERCardinalityType.custom:
        _drawCustomMarker(
          canvas,
          position,
          direction,
          size,
          color,
          isSource,
          cardinality.displayText,
        );
    }
  }

  /// 绘制可选性标记（圆圈）
  void _drawOptionalMarker(
    Canvas canvas,
    Offset position,
    AnchorDirection direction,
    double size,
    Color color,
    bool isSource,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final angle = _directionToAngle(direction);
    final offsetAngle = isSource ? angle : angle + math.pi;
    final circleOffset = size * 0.8;

    final circleCenter = Offset(
      position.dx + math.cos(offsetAngle) * circleOffset,
      position.dy + math.sin(offsetAngle) * circleOffset,
    );

    canvas.drawCircle(circleCenter, size * 0.35, paint);
  }

  /// 绘制"一"标记（单竖线）
  void _drawOneMarker(
    Canvas canvas,
    Offset position,
    AnchorDirection direction,
    double size,
    Color color,
    bool isSource,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    final perpAngle = angle + math.pi / 2 + offset;
    final halfSize = size / 2;

    canvas.drawLine(
      Offset(
        position.dx + math.cos(perpAngle) * halfSize,
        position.dy + math.sin(perpAngle) * halfSize,
      ),
      Offset(
        position.dx - math.cos(perpAngle) * halfSize,
        position.dy - math.sin(perpAngle) * halfSize,
      ),
      paint,
    );
  }

  /// 绘制"多"标记（鸦脚）
  void _drawManyMarker(
    Canvas canvas,
    Offset position,
    AnchorDirection direction,
    double size,
    Color color,
    bool isSource,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    final perpAngle = angle + math.pi / 2 + offset;
    final halfSize = size / 2;

    // 竖线
    canvas.drawLine(
      Offset(
        position.dx + math.cos(perpAngle) * halfSize,
        position.dy + math.sin(perpAngle) * halfSize,
      ),
      Offset(
        position.dx - math.cos(perpAngle) * halfSize,
        position.dy - math.sin(perpAngle) * halfSize,
      ),
      paint,
    );

    // 鸦脚分叉
    final centerAngle = angle + offset;
    final len = size * 1.2;

    for (final sign in [-1, 1]) {
      final branchAngle = centerAngle + sign * (math.pi / 6);
      canvas.drawLine(
        position,
        Offset(
          position.dx + math.cos(branchAngle) * len,
          position.dy + math.sin(branchAngle) * len,
        ),
        paint,
      );
    }
  }

  /// 绘制自定义标记
  void _drawCustomMarker(
    Canvas canvas,
    Offset position,
    AnchorDirection direction,
    double size,
    Color color,
    bool isSource,
    String text,
  ) {
    final textStyle = TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final angle = _directionToAngle(direction);
    final offsetAngle = isSource ? angle : angle + math.pi;
    final textOffset = size * 1.5;

    final textPosition = Offset(
      position.dx + math.cos(offsetAngle) * textOffset - textPainter.width / 2,
      position.dy + math.sin(offsetAngle) * textOffset - textPainter.height / 2,
    );

    textPainter.paint(canvas, textPosition);
  }

  /// 绘制关系名称标签
  void _drawRelationLabel({
    required Canvas canvas,
    required String label,
    required Offset sourcePos,
    required Offset targetPos,
    required EdgeStyle style,
    required double zoom,
  }) {
    final midPoint = Offset(
      (sourcePos.dx + targetPos.dx) / 2,
      (sourcePos.dy + targetPos.dy) / 2,
    );

    final fontSize = config.labelFontSize * zoom;
    final textStyle = TextStyle(
      color: style.color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final padding = 4.0 * zoom;
    final bgRect = Rect.fromLTWH(
      midPoint.dx - textPainter.width / 2 - padding,
      midPoint.dy - textPainter.height / 2 - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );

    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xE6374151) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(4.0 * zoom));
    canvas.drawRRect(rrect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }

  /// 将锚点方向转换为角度（弧度）
  double _directionToAngle(AnchorDirection direction) {
    switch (direction) {
      case AnchorDirection.right:
        return 0.0;
      case AnchorDirection.bottom:
        return math.pi / 2;
      case AnchorDirection.left:
        return math.pi;
      case AnchorDirection.top:
        return -math.pi / 2;
    }
  }
}