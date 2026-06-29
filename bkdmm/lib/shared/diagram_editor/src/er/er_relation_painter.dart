/// ER 关系绘制器
///
/// 专门用于绘制 ER 图中实体关系的自定义绘制器。
/// 支持绘制各种关系类型（标识关系、非标识关系）和基数标记。
library;

import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_node.dart';
import '../core/diagram_state.dart';
import 'er_relation_edge_model.dart';

/// ER 关系绘制器
///
/// 负责绘制 ER 图中的关系边，包括：
/// - 实线（标识关系）和虚线（非标识关系）
/// - 基数标记（1, N, M）
/// - 可选性标记（圆圈表示可选）
/// - 鸦脚标记（表示"多"端）
class ERRelationPainter {
  /// 默认关系线颜色
  static const Color defaultLineColor = Color(0xFF666666);

  /// 选中时的高亮颜色
  static const Color selectedColor = Color(0xFF1890FF);

  /// 悬停时的颜色
  static const Color hoverColor = Color(0xFF40A9FF);

  /// 基数标记的默认颜色
  static const Color defaultMarkerColor = Color(0xFF666666);

  /// 标记大小基础值
  static const double baseMarkerSize = 12.0;

  /// 绘制 ER 关系边
  ///
  /// [canvas] - 绘制画布
  /// [edge] - 要绘制的关系边模型
  /// [state] - 图表状态
  /// [viewport] - 视口状态（用于坐标变换）
  void paintEdge(
    Canvas canvas,
    ERRelationEdgeModel edge,
    DiagramState state,
    ViewportState viewport,
  ) {
    final edgeState = state.getEdgeState(edge.id);

    // 获取源和目标锚点
    final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
    final targetAnchor = state.getAnchor(edge.targetAnchorId);

    if (sourceAnchor == null || targetAnchor == null) return;

    // 转换为屏幕坐标
    final sourcePos = viewport.toScreen(sourceAnchor.position);
    final targetPos = viewport.toScreen(targetAnchor.position);

    // 获取有效样式
    final style = _getEffectiveStyle(edge, edgeState);

    // 绘制选中/悬停高亮
    if (edgeState.isSelected || edgeState.isHovered) {
      _drawHighlight(canvas, sourcePos, targetPos, sourceAnchor.direction,
          targetAnchor.direction, style, viewport.zoom);
    }

    // 绘制关系线
    _drawRelationLine(
      canvas: canvas,
      sourcePos: sourcePos,
      targetPos: targetPos,
      sourceDirection: sourceAnchor.direction,
      targetDirection: targetAnchor.direction,
      style: style,
      zoom: viewport.zoom,
      edge: edge,
    );

    // 绘制源端标记
    _drawCardinalityMarker(
      canvas: canvas,
      position: sourcePos,
      direction: sourceAnchor.direction,
      cardinality: edge.sourceCardinality,
      isSource: true,
      zoom: viewport.zoom,
      color: style.color,
    );

    // 绘制目标端标记
    _drawCardinalityMarker(
      canvas: canvas,
      position: targetPos,
      direction: targetAnchor.direction,
      cardinality: edge.targetCardinality,
      isSource: false,
      zoom: viewport.zoom,
      color: style.color,
    );

    // 绘制关系名称标签
    if (edge.relationName != null && edge.relationName!.isNotEmpty) {
      _drawRelationLabel(
        canvas: canvas,
        label: edge.relationName!,
        sourcePos: sourcePos,
        targetPos: targetPos,
        style: style,
        zoom: viewport.zoom,
      );
    }
  }

  /// 绘制正在创建中的关系预览
  ///
  /// [canvas] - 绘制画布
  /// [sourceAnchor] - 源锚点
  /// [targetPos] - 目标位置（场景坐标）
  /// [viewport] - 视口状态
  /// [previewCardinality] - 预览的基数类型
  void paintCreatingRelation(
    Canvas canvas,
    AnchorPoint sourceAnchor,
    Offset targetPos,
    ViewportState viewport, {
    ERCardinalityEnd? previewCardinality,
  }) {
    final sourceScreen = viewport.toScreen(sourceAnchor.position);
    final targetScreen = viewport.toScreen(targetPos);

    // 绘制预览线（虚线）- 使用手动绘制虚线的方式
    final previewPaint = Paint()
      ..color = selectedColor.withValues(alpha: 0.6)
      ..strokeWidth = 2.0 * viewport.zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 手动绘制虚线
    _drawDashedLine(
      canvas: canvas,
      start: sourceScreen,
      end: targetScreen,
      paint: previewPaint,
      dashPattern: [6.0 * viewport.zoom, 4.0 * viewport.zoom],
    );

    // 绘制源端预览标记
    if (previewCardinality != null) {
      _drawCardinalityMarker(
        canvas: canvas,
        position: sourceScreen,
        direction: sourceAnchor.direction,
        cardinality: previewCardinality,
        isSource: true,
        zoom: viewport.zoom,
        color: selectedColor,
      );
    }
  }

  /// 获取有效样式
  EdgeStyle _getEffectiveStyle(ERRelationEdgeModel edge, EdgeState edgeState) {
    final baseStyle = edge.getStyle();

    if (edgeState.isSelected) {
      return baseStyle.copyWith(
        color: selectedColor,
        width: 3.0,
      );
    }

    if (edgeState.isHovered || edgeState.isHighlighted) {
      return baseStyle.copyWith(
        color: hoverColor,
        width: 2.5,
      );
    }

    return baseStyle;
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
      ..color = selectedColor.withValues(alpha: 0.2)
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

    // 根据关系类型设置线条样式
    if (edge.isNonIdentifying) {
      // 非标识关系使用虚线 - 手动绘制
      final dashConfig = style.dashConfig ?? DashConfig.dashed;
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

    // 使用贝塞尔曲线绘制平滑路径
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

  /// 绘制虚线（直线）
  void _drawDashedLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    required List<double> dashPattern,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    bool isDrawing = true;
    int patternIndex = 0;

    while (currentDistance < distance) {
      final dashLength = dashPattern[patternIndex % dashPattern.length];
      final segmentEnd = currentDistance + dashLength;

      if (isDrawing) {
        final segmentStartPoint = Offset(
          start.dx + unitX * currentDistance,
          start.dy + unitY * currentDistance,
        );
        final actualEnd = segmentEnd > distance ? distance : segmentEnd;
        final segmentEndPoint = Offset(
          start.dx + unitX * actualEnd,
          start.dy + unitY * actualEnd,
        );
        canvas.drawLine(segmentStartPoint, segmentEndPoint, paint);
      }

      currentDistance = segmentEnd;
      isDrawing = !isDrawing;
      patternIndex++;
    }
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
    // 计算贝塞尔控制点
    final controlPoints = _computeBezierControlPoints(
      sourcePos,
      targetPos,
      sourceDirection,
      targetDirection,
      0.3,
    );

    // 使用多个点近似贝塞尔曲线，然后绘制虚线段
    final points = _approximateBezierCurve(
      sourcePos,
      controlPoints[0],
      controlPoints[1],
      targetPos,
      20, // 细分数
    );

    // 绘制虚线段
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
          final drawLength = remainingLength < availableLength
              ? remainingLength
              : availableLength;
          final drawStart = Offset(
            start.dx + (end.dx - start.dx) * (segmentStartOffset / segmentLength),
            start.dy + (end.dy - start.dy) * (segmentStartOffset / segmentLength),
          );
          final drawEnd = Offset(
            start.dx + (end.dx - start.dx) * ((segmentStartOffset + drawLength) / segmentLength),
            start.dy + (end.dy - start.dy) * ((segmentStartOffset + drawLength) / segmentLength),
          );
          canvas.drawLine(drawStart, drawEnd, paint);
        }

        segmentStartOffset += remainingLength < availableLength
            ? remainingLength
            : availableLength;
        remainingLength -= remainingLength < availableLength
            ? remainingLength
            : availableLength;
        accumulatedDistance += remainingLength < availableLength
            ? remainingLength
            : availableLength;

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
    final size = baseMarkerSize * zoom;

    // 先绘制可选性标记（如果是可选的）
    if (cardinality.isOptional) {
      _drawOptionalMarker(canvas, position, direction, size, color, isSource);
    }

    // 根据基数类型绘制标记
    switch (cardinality.type) {
      case ERCardinalityType.one:
        _drawOneMarker(canvas, position, direction, size, color, isSource);

      case ERCardinalityType.many:
        _drawManyMarker(canvas, position, direction, size, color, isSource);

      case ERCardinalityType.custom:
        _drawCustomMarker(
            canvas, position, direction, size, color, isSource, cardinality.displayText);
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
      ..strokeWidth = 1.5 * size / baseMarkerSize;

    // 圆圈位于线的端点外侧
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
      ..strokeWidth = 2.0 * size / baseMarkerSize
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    // 绘制垂直于连线方向的竖线
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
      ..strokeWidth = 2.0 * size / baseMarkerSize
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    // 鸦脚的三条线
    final len = size * 1.2; // 线条长度

    // 中心方向（沿线方向）
    final centerAngle = angle + offset;

    // 三条线：一个竖线 + 两条斜线
    // 竖线（垂直于连线）
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

    // 两条斜线（鸦脚的分叉）
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

    // 在位置旁边绘制文本
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
    // 计算中点
    final midPoint = Offset(
      (sourcePos.dx + targetPos.dx) / 2,
      (sourcePos.dy + targetPos.dy) / 2,
    );

    final fontSize = 11.0 * zoom;
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

    // 绘制背景
    final padding = 4.0 * zoom;
    final bgRect = Rect.fromLTWH(
      midPoint.dx - textPainter.width / 2 - padding,
      midPoint.dy - textPainter.height / 2 - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );

    final bgPaint = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(4.0 * zoom));
    canvas.drawRRect(rrect, bgPaint);

    // 绘制文本
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

  /// 点击测试：检查点是否靠近关系线
  ///
  /// [point] - 测试点（屏幕坐标）
  /// [edge] - 要测试的关系边
  /// [state] - 图表状态
  /// [viewport] - 视口状态
  /// [tolerance] - 容差距离
  String? hitTest(
    Offset point,
    ERRelationEdgeModel edge,
    DiagramState state,
    ViewportState viewport, {
    double tolerance = 10.0,
  }) {
    final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
    final targetAnchor = state.getAnchor(edge.targetAnchorId);

    if (sourceAnchor == null || targetAnchor == null) return null;

    final sourcePos = viewport.toScreen(sourceAnchor.position);
    final targetPos = viewport.toScreen(targetAnchor.position);

    if (_isPointNearEdge(point, sourcePos, targetPos, tolerance)) {
      return edge.id;
    }

    return null;
  }

  /// 检查点是否靠近边
  bool _isPointNearEdge(Offset point, Offset start, Offset end, double tolerance) {
    // 计算点到线段的距离
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - start).distance < tolerance;
    }

    // 计算投影
    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final nearestPoint = Offset(
      start.dx + clampedT * dx,
      start.dy + clampedT * dy,
    );

    return (point - nearestPoint).distance < tolerance;
  }

  /// 计算关系边的边界矩形
  Rect calculateEdgeBounds(
    ERRelationEdgeModel edge,
    DiagramState state,
    ViewportState viewport, {
    double padding = 20.0,
  }) {
    final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
    final targetAnchor = state.getAnchor(edge.targetAnchorId);

    if (sourceAnchor == null || targetAnchor == null) {
      return Rect.zero;
    }

    final sourcePos = viewport.toScreen(sourceAnchor.position);
    final targetPos = viewport.toScreen(targetAnchor.position);

    return Rect.fromPoints(sourcePos, targetPos).inflate(padding);
  }
}

/// ER 关系绘制配置
class ERRelationPainterConfig {
  /// 默认线条颜色
  final Color lineColor;

  /// 选中时颜色
  final Color selectedColor;

  /// 悬停时颜色
  final Color hoverColor;

  /// 标记颜色
  final Color markerColor;

  /// 标记大小
  final double markerSize;

  /// 线条宽度
  final double lineWidth;

  /// 非标识关系虚线配置
  final DashConfig nonIdentifyingDashConfig;

  /// 是否显示关系名称
  final bool showRelationName;

  /// 标签字体大小
  final double labelFontSize;

  const ERRelationPainterConfig({
    this.lineColor = ERRelationPainter.defaultLineColor,
    this.selectedColor = ERRelationPainter.selectedColor,
    this.hoverColor = ERRelationPainter.hoverColor,
    this.markerColor = ERRelationPainter.defaultMarkerColor,
    this.markerSize = ERRelationPainter.baseMarkerSize,
    this.lineWidth = 2.0,
    this.nonIdentifyingDashConfig = DashConfig.dashed,
    this.showRelationName = true,
    this.labelFontSize = 11.0,
  });

  /// 创建暗色主题配置
  factory ERRelationPainterConfig.dark() {
    return const ERRelationPainterConfig(
      lineColor: Color(0xFFA0AEC0),
      selectedColor: Color(0xFF63B3ED),
      hoverColor: Color(0xFF90CDF4),
      markerColor: Color(0xFFA0AEC0),
    );
  }

  /// 复制并修改配置
  ERRelationPainterConfig copyWith({
    Color? lineColor,
    Color? selectedColor,
    Color? hoverColor,
    Color? markerColor,
    double? markerSize,
    double? lineWidth,
    DashConfig? nonIdentifyingDashConfig,
    bool? showRelationName,
    double? labelFontSize,
  }) {
    return ERRelationPainterConfig(
      lineColor: lineColor ?? this.lineColor,
      selectedColor: selectedColor ?? this.selectedColor,
      hoverColor: hoverColor ?? this.hoverColor,
      markerColor: markerColor ?? this.markerColor,
      markerSize: markerSize ?? this.markerSize,
      lineWidth: lineWidth ?? this.lineWidth,
      nonIdentifyingDashConfig:
          nonIdentifyingDashConfig ?? this.nonIdentifyingDashConfig,
      showRelationName: showRelationName ?? this.showRelationName,
      labelFontSize: labelFontSize ?? this.labelFontSize,
    );
  }
}
