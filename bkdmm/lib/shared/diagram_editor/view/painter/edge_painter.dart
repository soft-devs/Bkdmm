import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../../core/diagram_edge.dart';
import '../../core/diagram_node.dart';
import '../../core/diagram_state.dart';
import '../../model/edge_model.dart';

/// Edge painter for rendering diagram edges
///
/// Responsible for drawing edges between nodes with various styles,
/// markers, and visual states (selection, hover, etc.)
class EdgePainter {
  /// Default edge style
  static const EdgeStyle defaultStyle = EdgeStyle();

  /// Hover edge style
  static const EdgeStyle hoverStyle = EdgeStyle(
    color: Color(0xFF1890FF),
    width: 2.5,
  );

  /// Selected edge style
  static const EdgeStyle selectedStyle = EdgeStyle(
    color: Color(0xFF1890FF),
    width: 3.0,
  );

  /// Creating edge style (during edge creation preview)
  static const EdgeStyle creatingStyle = EdgeStyle(
    color: Color(0xFF1890FF),
    width: 2.0,
    lineType: EdgeLineType.dashed,
  );

  /// Paint edges onto a canvas
  ///
  /// [canvas] - The canvas to paint on
  /// [state] - The diagram state containing edges and nodes
  /// [viewport] - The current viewport state for coordinate transformation
  void paint(
    Canvas canvas,
    DiagramState state,
    ViewportState viewport,
  ) {
    // Draw all edges
    for (final edge in state.edges.values) {
      final edgeState = state.getEdgeState(edge.id);
      final style = _getEffectiveStyle(edge, edgeState);

      // Get anchor positions
      final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
      final targetAnchor = state.getAnchor(edge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      // Transform to screen coordinates
      final sourcePos = viewport.toScreen(sourceAnchor.position);
      final targetPos = viewport.toScreen(targetAnchor.position);

      // Draw the edge
      _drawEdge(
        canvas: canvas,
        edge: edge,
        style: style,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceAnchor.direction,
        targetDirection: targetAnchor.direction,
        edgeState: edgeState,
        zoom: viewport.zoom,
      );
    }
  }

  /// Paint a single edge being created (preview during connection)
  ///
  /// [canvas] - The canvas to paint on
  /// [sourceAnchor] - The source anchor point
  /// [targetPos] - The current target position (in scene coordinates)
  /// [viewport] - The current viewport state
  void paintCreatingEdge(
    Canvas canvas,
    AnchorPoint sourceAnchor,
    Offset targetPos,
    ViewportState viewport,
  ) {
    final sourceScreen = viewport.toScreen(sourceAnchor.position);
    final targetScreen = viewport.toScreen(targetPos);

    _drawEdgePath(
      canvas: canvas,
      sourcePos: sourceScreen,
      targetPos: targetScreen,
      style: creatingStyle,
      sourceDirection: sourceAnchor.direction,
      targetDirection: _inferDirection(targetScreen, sourceScreen),
      zoom: viewport.zoom,
    );

    // Draw source marker if present
    _drawMarkerAtPosition(
      canvas: canvas,
      marker: null, // Could be passed as parameter
      position: sourceScreen,
      direction: sourceAnchor.direction,
      isSource: true,
      zoom: viewport.zoom,
    );
  }

  /// Get the effective style for an edge based on its state
  EdgeStyle _getEffectiveStyle(DiagramEdge edge, EdgeState edgeState) {
    if (edgeState.isSelected) {
      return edge.getStyle().copyWith(
            color: selectedStyle.color,
            width: selectedStyle.width,
          );
    }
    if (edgeState.isHovered || edgeState.isHighlighted) {
      return edge.getStyle().copyWith(
            color: hoverStyle.color,
            width: hoverStyle.width,
          );
    }
    if (edgeState.isCreating) {
      return creatingStyle;
    }
    return edge.getStyle();
  }

  /// Draw a single edge with all its components
  void _drawEdge({
    required Canvas canvas,
    required DiagramEdge edge,
    required EdgeStyle style,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required EdgeState edgeState,
    required double zoom,
  }) {
    // Draw selection highlight (wider, semi-transparent path behind)
    if (edgeState.isSelected || edgeState.isHovered) {
      _drawSelectionHighlight(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceDirection,
        targetDirection: targetDirection,
        style: style,
        zoom: zoom,
      );
    }

    // Draw the main edge path
    _drawEdgePath(
      canvas: canvas,
      sourcePos: sourcePos,
      targetPos: targetPos,
      style: style,
      sourceDirection: sourceDirection,
      targetDirection: targetDirection,
      zoom: zoom,
    );

    // Draw source marker
    final sourceMarker = edge.getSourceMarker();
    if (sourceMarker != null) {
      _drawMarkerAtPosition(
        canvas: canvas,
        marker: sourceMarker,
        position: sourcePos,
        direction: sourceDirection,
        isSource: true,
        zoom: zoom,
      );
    }

    // Draw target marker
    final targetMarker = edge.getTargetMarker();
    if (targetMarker != null) {
      _drawMarkerAtPosition(
        canvas: canvas,
        marker: targetMarker,
        position: targetPos,
        direction: targetDirection,
        isSource: false,
        zoom: zoom,
      );
    }

    // Draw arrow if enabled
    if (style.showArrow && targetMarker == null) {
      _drawArrow(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        style: style,
        targetDirection: targetDirection,
        zoom: zoom,
      );
    }

    // Draw label if present
    if (edge.label != null && edge.label!.isNotEmpty) {
      _drawLabel(
        canvas: canvas,
        label: edge.label!,
        sourcePos: sourcePos,
        targetPos: targetPos,
        style: style,
        zoom: zoom,
      );
    }
  }

  /// Draw selection highlight behind the edge
  void _drawSelectionHighlight({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required EdgeStyle style,
    required double zoom,
  }) {
    final highlightPaint = Paint()
      ..color = const Color(0x331890FF)
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
      shape: style.shape,
      paint: highlightPaint,
      curveFactor: style.curveFactor,
    );
  }

  /// Draw the main edge path
  void _drawEdgePath({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required EdgeStyle style,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required double zoom,
  }) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = style.width * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Check if we need dashed/dotted line
    final isDashed = style.lineType == EdgeLineType.dashed ||
        style.lineType == EdgeLineType.dotted;

    if (isDashed) {
      final dashConfig = style.dashConfig ??
          (style.lineType == EdgeLineType.dotted
              ? DashConfig.dotted
              : DashConfig.dashed);
      // Scale dash pattern by zoom
      final scaledPattern =
          dashConfig.pattern.map((d) => d * zoom).toList();
      _drawDashedPath(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceDirection,
        targetDirection: targetDirection,
        shape: style.shape,
        paint: paint,
        curveFactor: style.curveFactor,
        dashPattern: scaledPattern,
      );
    } else {
      _drawPath(
        canvas: canvas,
        sourcePos: sourcePos,
        targetPos: targetPos,
        sourceDirection: sourceDirection,
        targetDirection: targetDirection,
        shape: style.shape,
        paint: paint,
        curveFactor: style.curveFactor,
      );
    }
  }

  /// Draw a dashed path between two points
  void _drawDashedPath({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required EdgeShape shape,
    required Paint paint,
    required double curveFactor,
    required List<double> dashPattern,
  }) {
    // Create the path first
    final path = Path();

    switch (shape) {
      case EdgeShape.straight:
        path.moveTo(sourcePos.dx, sourcePos.dy);
        path.lineTo(targetPos.dx, targetPos.dy);

      case EdgeShape.curved:
        final controlPoints = _computeCurveControlPoints(
          sourcePos,
          targetPos,
          sourceDirection,
          curveFactor,
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

      case EdgeShape.bezier:
        final controlPoints = _computeBezierControlPoints(
          sourcePos,
          targetPos,
          sourceDirection,
          targetDirection,
          curveFactor,
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

      case EdgeShape.orthogonal:
        final points = _computeOrthogonalPath(
          sourcePos,
          targetPos,
          sourceDirection,
          targetDirection,
        );
        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
    }

    // Draw dashed path using PathMetric
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final dashLength = dashPattern[patternIndex % dashPattern.length];
        if (draw) {
          final end = (distance + dashLength).clamp(0.0, metric.length);
          canvas.drawPath(
            metric.extractPath(distance, end),
            paint,
          );
        }
        distance += dashLength;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  /// Draw a path between two points with the given shape
  void _drawPath({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required AnchorDirection sourceDirection,
    required AnchorDirection targetDirection,
    required EdgeShape shape,
    required Paint paint,
    required double curveFactor,
  }) {
    final path = Path();

    switch (shape) {
      case EdgeShape.straight:
        path.moveTo(sourcePos.dx, sourcePos.dy);
        path.lineTo(targetPos.dx, targetPos.dy);

      case EdgeShape.curved:
        final controlPoints = _computeCurveControlPoints(
          sourcePos,
          targetPos,
          sourceDirection,
          curveFactor,
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

      case EdgeShape.bezier:
        final controlPoints = _computeBezierControlPoints(
          sourcePos,
          targetPos,
          sourceDirection,
          targetDirection,
          curveFactor,
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

      case EdgeShape.orthogonal:
        final points = _computeOrthogonalPath(
          sourcePos,
          targetPos,
          sourceDirection,
          targetDirection,
        );
        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
    }

    canvas.drawPath(path, paint);
  }

  /// Compute control points for a simple curve
  List<Offset> _computeCurveControlPoints(
    Offset source,
    Offset target,
    AnchorDirection direction,
    double factor,
  ) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;

    Offset control1;
    Offset control2;

    switch (direction) {
      case AnchorDirection.left:
        control1 = Offset(source.dx - dx * factor, source.dy);
        control2 = Offset(target.dx + dx * factor, target.dy);
      case AnchorDirection.right:
        control1 = Offset(source.dx + dx * factor, source.dy);
        control2 = Offset(target.dx - dx * factor, target.dy);
      case AnchorDirection.top:
        control1 = Offset(source.dx, source.dy - dy * factor);
        control2 = Offset(target.dx, target.dy + dy * factor);
      case AnchorDirection.bottom:
        control1 = Offset(source.dx, source.dy + dy * factor);
        control2 = Offset(target.dx, target.dy - dy * factor);
    }

    return [control1, control2];
  }

  /// Compute control points for a bezier curve considering both directions
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

  /// Compute orthogonal (manhattan) path points
  List<Offset> _computeOrthogonalPath(
    Offset source,
    Offset target,
    AnchorDirection sourceDirection,
    AnchorDirection targetDirection,
  ) {
    final points = <Offset>[source];

    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;

    // Determine routing based on anchor directions
    final sourceIsHorizontal =
        sourceDirection == AnchorDirection.left ||
            sourceDirection == AnchorDirection.right;
    final targetIsHorizontal =
        targetDirection == AnchorDirection.left ||
            targetDirection == AnchorDirection.right;

    if (sourceIsHorizontal && targetIsHorizontal) {
      // Both horizontal - need at least one vertical segment
      if (dx.abs() > 20) {
        // Enough horizontal space - simple Z or C routing
        final midX = source.dx + dx / 2;
        points.add(Offset(midX, source.dy));
        points.add(Offset(midX, target.dy));
      } else {
        // Not enough horizontal space - route around
        if (dy.abs() > 20) {
          points.add(Offset(source.dx + dx / 2, source.dy));
          points.add(Offset(source.dx + dx / 2, target.dy));
        }
      }
    } else if (!sourceIsHorizontal && !targetIsHorizontal) {
      // Both vertical - need at least one horizontal segment
      if (dy.abs() > 20) {
        final midY = source.dy + dy / 2;
        points.add(Offset(source.dx, midY));
        points.add(Offset(target.dx, midY));
      } else {
        if (dx.abs() > 20) {
          points.add(Offset(source.dx, source.dy + dy / 2));
          points.add(Offset(target.dx, source.dy + dy / 2));
        }
      }
    } else if (sourceIsHorizontal) {
      // Source horizontal, target vertical
      final midY = target.dy + (sourceDirection == AnchorDirection.top ? 30 : -30);
      points.add(Offset(source.dx + dx.sign * 30, source.dy));
      points.add(Offset(source.dx + dx.sign * 30, midY));
      points.add(Offset(target.dx, midY));
    } else {
      // Source vertical, target horizontal
      final midX = target.dx + (sourceDirection == AnchorDirection.left ? 30 : -30);
      points.add(Offset(source.dx, source.dy + dy.sign * 30));
      points.add(Offset(midX, source.dy + dy.sign * 30));
      points.add(Offset(midX, target.dy));
    }

    points.add(target);
    return points;
  }

  /// Draw a marker at a position
  void _drawMarkerAtPosition({
    required Canvas canvas,
    required EdgeMarker? marker,
    required Offset position,
    required AnchorDirection direction,
    required bool isSource,
    required double zoom,
  }) {
    if (marker == null) return;

    final size = marker.size * zoom;
    final color = marker.color ?? const Color(0xFF666666);

    switch (marker.type) {
      case EdgeMarkerType.none:
        break;

      case EdgeMarkerType.one:
        _drawOneMarker(canvas, position, direction, size, color, isSource);

      case EdgeMarkerType.many:
        _drawManyMarker(canvas, position, direction, size, color, isSource);

      case EdgeMarkerType.multiple:
        _drawTextMarker(canvas, position, marker.text ?? 'M', size, color);

      case EdgeMarkerType.arrow:
        _drawArrowMarker(canvas, position, direction, size, color, isSource);

      case EdgeMarkerType.circle:
        _drawCircleMarker(canvas, position, size, color);

      case EdgeMarkerType.diamond:
        _drawDiamondMarker(canvas, position, direction, size, color, isSource);

      case EdgeMarkerType.custom:
        if (marker.text != null) {
          _drawTextMarker(canvas, position, marker.text!, size, color);
        }
    }
  }

  /// Draw "1" marker (single vertical line)
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
      ..strokeWidth = 2.0 * size / 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    // Draw vertical line
    final perpX = math.cos(angle + math.pi / 2 + offset);
    final perpY = math.sin(angle + math.pi / 2 + offset);

    final halfSize = size / 2;
    canvas.drawLine(
      Offset(position.dx - perpX * halfSize, position.dy - perpY * halfSize),
      Offset(position.dx + perpX * halfSize, position.dy + perpY * halfSize),
      paint,
    );
  }

  /// Draw "many" marker (crow's foot)
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
      ..strokeWidth = 2.0 * size / 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;

    // Draw crow's foot (two diagonal lines spreading out)
    final spread = size * 0.6;
    final len = size;

    // Center line direction (toward edge)
    final centerX = math.cos(angle + offset);
    final centerY = math.sin(angle + offset);

    // Two spread lines
    for (final sign in [-1, 1]) {
      final spreadAngle = angle + offset + sign * math.pi / 6;
      final dx = math.cos(spreadAngle) * len;
      final dy = math.sin(spreadAngle) * len;
      canvas.drawLine(
        position,
        Offset(position.dx + dx, position.dy + dy),
        paint,
      );
    }

    // Also draw the vertical line
    final perpX = math.cos(angle + math.pi / 2 + offset);
    final perpY = math.sin(angle + math.pi / 2 + offset);
    canvas.drawLine(
      Offset(position.dx - perpX * spread, position.dy - perpY * spread),
      Offset(position.dx + perpX * spread, position.dy + perpY * spread),
      paint,
    );
  }

  /// Draw text marker
  void _drawTextMarker(
    Canvas canvas,
    Offset position,
    String text,
    double size,
    Color color,
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
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2),
    );
  }

  /// Draw arrow marker
  void _drawArrowMarker(
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
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final angle = _directionToAngle(direction);
    final offset = isSource ? math.pi : 0.0;

    // Arrow pointing toward/away from edge
    final tipAngle = angle + offset;
    final halfSize = size / 2;

    // Tip of arrow
    final tipX = position.dx + math.cos(tipAngle) * halfSize;
    final tipY = position.dy + math.sin(tipAngle) * halfSize;

    // Arrow base points
    final baseAngle1 = tipAngle + math.pi * 0.8;
    final baseAngle2 = tipAngle - math.pi * 0.8;

    path.moveTo(tipX, tipY);
    path.lineTo(
      position.dx + math.cos(baseAngle1) * halfSize,
      position.dy + math.sin(baseAngle1) * halfSize,
    );
    path.moveTo(tipX, tipY);
    path.lineTo(
      position.dx + math.cos(baseAngle2) * halfSize,
      position.dy + math.sin(baseAngle2) * halfSize,
    );

    canvas.drawPath(path, paint);
  }

  /// Draw circle marker
  void _drawCircleMarker(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(position, size / 2, paint);
  }

  /// Draw diamond marker
  void _drawDiamondMarker(
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
      ..strokeWidth = 2.0;

    final path = Path();
    final angle = _directionToAngle(direction);
    final offset = isSource ? 0.0 : math.pi;
    final halfSize = size / 2;

    // Diamond oriented along the edge direction
    final points = <Offset>[];
    for (int i = 0; i < 4; i++) {
      final pointAngle = angle + offset + i * math.pi / 2;
      final distance = (i % 2 == 0) ? halfSize : halfSize * 0.6;
      points.add(Offset(
        position.dx + math.cos(pointAngle) * distance,
        position.dy + math.sin(pointAngle) * distance,
      ));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < 4; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw arrow at target position
  void _drawArrow({
    required Canvas canvas,
    required Offset sourcePos,
    required Offset targetPos,
    required EdgeStyle style,
    required AnchorDirection targetDirection,
    required double zoom,
  }) {
    final paint = Paint()
      ..color = style.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.width * zoom
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowSize = style.arrowSize * zoom;
    final angle = _directionToAngle(targetDirection);

    // Arrow points away from target (toward the edge)
    final tip = targetPos;
    final baseAngle1 = angle + math.pi + math.pi / 6;
    final baseAngle2 = angle + math.pi - math.pi / 6;

    final base1 = Offset(
      tip.dx + math.cos(baseAngle1) * arrowSize,
      tip.dy + math.sin(baseAngle1) * arrowSize,
    );
    final base2 = Offset(
      tip.dx + math.cos(baseAngle2) * arrowSize,
      tip.dy + math.sin(baseAngle2) * arrowSize,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base2.dx, base2.dy);

    canvas.drawPath(path, paint);
  }

  /// Draw label at edge midpoint
  void _drawLabel({
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

    // Background for better readability
    final bgPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: style.color,
      fontSize: 12.0 * zoom,
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

  /// Convert anchor direction to angle in radians
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

  /// Infer direction from two positions
  AnchorDirection _inferDirection(Offset from, Offset to) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? AnchorDirection.right : AnchorDirection.left;
    } else {
      return dy > 0 ? AnchorDirection.bottom : AnchorDirection.top;
    }
  }

  /// Hit test: check if a point is near an edge
  ///
  /// Returns the edge ID if hit, null otherwise
  String? hitTest(
    Offset point,
    DiagramState state,
    ViewportState viewport, {
    double tolerance = 8.0,
  }) {
    for (final edge in state.edges.values) {
      final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
      final targetAnchor = state.getAnchor(edge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      final sourcePos = viewport.toScreen(sourceAnchor.position);
      final targetPos = viewport.toScreen(targetAnchor.position);

      if (_isPointNearEdge(point, sourcePos, targetPos, tolerance)) {
        return edge.id;
      }
    }
    return null;
  }

  /// Check if a point is near an edge segment
  bool _isPointNearEdge(Offset point, Offset start, Offset end, double tolerance) {
    // Calculate distance from point to line segment
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      // Start and end are the same point
      return (point - start).distance < tolerance;
    }

    // Calculate projection of point onto line
    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final nearestPoint = Offset(
      start.dx + clampedT * dx,
      start.dy + clampedT * dy,
    );

    return (point - nearestPoint).distance < tolerance;
  }

  /// Calculate the bounding rect for an edge
  Rect calculateEdgeBounds(
    DiagramEdge edge,
    DiagramState state,
    ViewportState viewport, {
    double padding = 10.0,
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