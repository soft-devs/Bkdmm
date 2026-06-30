/// ER 图交互覆盖层
///
/// 处理连线预览和框选矩形的渲染。
/// V3 改造：直接从 DiagramState 读取状态，不再需要 ERInteractionExtension。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';

/// ER 图交互覆盖层 Widget
///
/// 根据 DiagramState 的交互状态显示：
/// - 连线预览（虚线 + 箭头）
/// - 框选矩形（半透明填充 + 边框）
class ERInteractionOverlay extends StatelessWidget {
  /// 图表状态
  final DiagramState state;

  /// 变换矩阵（用于坐标转换）
  final Matrix4 transform;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 框选矩形（屏幕坐标）- 由 View 临时维护
  final Rect? selectionRectScreen;

  /// 连线预览终点（屏幕坐标）- 由 View 临时维护
  final Offset? connectionPreviewEndScreen;

  /// 创建交互覆盖层
  const ERInteractionOverlay({
    super.key,
    required this.state,
    required this.transform,
    this.isDarkMode = false,
    this.selectionRectScreen,
    this.connectionPreviewEndScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 连线预览
        if (_isConnecting && connectionPreviewEndScreen != null)
          CustomPaint(
            painter: ConnectionPreviewPainter(
              sourcePosition: _connectionSourcePosition,
              targetPosition: connectionPreviewEndScreen!,
              transform: transform,
              isDark: isDarkMode,
            ),
          ),
        // 框选矩形
        if (_isSelecting && selectionRectScreen != null)
          CustomPaint(
            painter: SelectionRectPainter(
              rect: selectionRectScreen!,
              isDark: isDarkMode,
            ),
          ),
      ],
    );
  }

  /// 是否正在连线
  bool get _isConnecting => state.interaction.isConnecting;

  /// 是否正在框选
  bool get _isSelecting => state.selection.boxSelectRect != null;

  /// 连线源位置
  Offset get _connectionSourcePosition {
    final anchorId = state.interaction.connectionSourceAnchorId;
    if (anchorId == null) return Offset.zero;
    final anchor = state.getAnchor(anchorId);
    return anchor?.position ?? Offset.zero;
  }
}

/// 连线预览绘制器
///
/// 绘制虚线和箭头，表示正在创建的连线。
class ConnectionPreviewPainter extends CustomPainter {
  /// 源位置（场景坐标）
  final Offset sourcePosition;

  /// 目标位置（场景坐标）
  final Offset targetPosition;

  /// 变换矩阵
  final Matrix4 transform;

  /// 是否暗色模式
  final bool isDark;

  /// 预览颜色
  final Color previewColor;

  /// 创建连线预览绘制器
  ConnectionPreviewPainter({
    required this.sourcePosition,
    required this.targetPosition,
    required this.transform,
    required this.isDark,
    this.previewColor = const Color(0xFF1890FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 转换为屏幕坐标
    final sourceScreen = MatrixUtils.transformPoint(transform, sourcePosition);
    final targetScreen = MatrixUtils.transformPoint(transform, targetPosition);

    final zoom = transform.getMaxScaleOnAxis();

    // 绘制虚线
    final linePaint = Paint()
      ..color = previewColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.0 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, sourceScreen, targetScreen, linePaint, zoom);

    // 绘制箭头
    _drawArrow(canvas, targetScreen, sourceScreen, previewColor, zoom);
  }

  /// 绘制虚线
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double zoom,
  ) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final scaledDashLength = dashLength * zoom;
    final scaledGapLength = gapLength * zoom;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    bool isDrawing = true;

    while (currentDistance < distance) {
      final segmentLength = isDrawing ? scaledDashLength : scaledGapLength;
      final segmentEnd = currentDistance + segmentLength;

      if (isDrawing) {
        final actualEnd = segmentEnd > distance ? distance : segmentEnd;
        canvas.drawLine(
          Offset(start.dx + unitX * currentDistance, start.dy + unitY * currentDistance),
          Offset(start.dx + unitX * actualEnd, start.dy + unitY * actualEnd),
          paint,
        );
      }

      currentDistance = segmentEnd;
      isDrawing = !isDrawing;
    }
  }

  /// 绘制箭头
  void _drawArrow(
    Canvas canvas,
    Offset position,
    Offset opposite,
    Color color,
    double zoom,
  ) {
    final arrowSize = 10.0 * zoom;

    final angle = math.atan2(
      position.dy - opposite.dy,
      position.dx - opposite.dx,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(position.dx, position.dy);
    path.lineTo(
      position.dx - arrowSize * math.cos(angle - math.pi / 6),
      position.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      position.dx - arrowSize * math.cos(angle + math.pi / 6),
      position.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPreviewPainter oldDelegate) {
    return sourcePosition != oldDelegate.sourcePosition ||
        targetPosition != oldDelegate.targetPosition ||
        transform != oldDelegate.transform ||
        isDark != oldDelegate.isDark;
  }
}

/// 框选矩形绘制器
///
/// 绘制半透明填充和边框，表示框选区域。
class SelectionRectPainter extends CustomPainter {
  /// 框选矩形（屏幕坐标）
  final Rect rect;

  /// 是否暗色模式
  final bool isDark;

  /// 选择颜色
  final Color selectionColor;

  /// 创建框选矩形绘制器
  SelectionRectPainter({
    required this.rect,
    required this.isDark,
    this.selectionColor = const Color(0xFF1890FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rect == Rect.zero) return;

    // 使用固定的高可见度蓝色
    // 暗色模式：亮蓝色，亮色模式：标准蓝色
    final adjustedColor = isDark
        ? const Color(0xFF4DABF7)  // 暗色模式使用更亮的蓝色
        : const Color(0xFF228BE6); // 亮色模式使用鲜明的蓝色

    // 填充 - 提高透明度
    final fillPaint = Paint()
      ..color = adjustedColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);

    // 边框 - 提高透明度和线宽
    final strokePaint = Paint()
      ..color = adjustedColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, strokePaint);

    // 绘制尺寸标签
    _drawSizeLabel(canvas, rect, adjustedColor);
  }

  /// 绘制尺寸标签
  void _drawSizeLabel(Canvas canvas, Rect rect, Color color) {
    final width = rect.width.abs().toInt();
    final height = rect.height.abs().toInt();

    final text = '$width × $height';

    final textStyle = TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // 在矩形右下角显示
    final labelPosition = Offset(
      rect.right - textPainter.width - 4,
      rect.bottom - textPainter.height - 4,
    );

    // 背景
    final bgRect = Rect.fromLTWH(
      labelPosition.dx - 2,
      labelPosition.dy - 2,
      textPainter.width + 4,
      textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xE6374151) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(3));
    canvas.drawRRect(rrect, bgPaint);

    textPainter.paint(canvas, labelPosition);
  }

  @override
  bool shouldRepaint(covariant SelectionRectPainter oldDelegate) {
    return rect != oldDelegate.rect || isDark != oldDelegate.isDark;
  }
}

