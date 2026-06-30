/// ER 图交互覆盖层
///
/// 处理连线预览和框选矩形的渲染。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/diagram_editor/diagram_editor.dart';

/// ER 图交互覆盖层 Widget
///
/// 根据 DiagramState 的交互状态显示：
/// - 连线预览（虚线 + 箭头）
/// - 框选矩形（半透明填充 + 边框）
class ERInteractionOverlay extends StatelessWidget {
  /// 图表状态
  final DiagramState state;

  /// 交互扩展状态（包含框选和连线信息）
  final ERInteractionExtension interactionExtension;

  /// 变换矩阵（用于坐标转换）
  final Matrix4 transform;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 创建交互覆盖层
  const ERInteractionOverlay({
    super.key,
    required this.state,
    required this.interactionExtension,
    required this.transform,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 连线预览
        if (_isConnecting)
          CustomPaint(
            painter: ConnectionPreviewPainter(
              sourcePosition: _connectionSourcePosition,
              targetPosition: _connectionPreviewEnd,
              transform: transform,
              isDark: isDarkMode,
            ),
          ),
        // 框选矩形
        if (_isSelecting)
          CustomPaint(
            painter: SelectionRectPainter(
              rect: _selectionRect,
              isDark: isDarkMode,
            ),
          ),
      ],
    );
  }

  /// 是否正在连线
  bool get _isConnecting => interactionExtension.isConnecting;

  /// 是否正在框选
  bool get _isSelecting => interactionExtension.isSelecting;

  /// 连线源位置
  Offset get _connectionSourcePosition =>
      interactionExtension.connectionSourcePosition ?? Offset.zero;

  /// 连线预览终点
  Offset get _connectionPreviewEnd =>
      interactionExtension.connectionPreviewEnd ?? Offset.zero;

  /// 框选矩形
  Rect get _selectionRect => interactionExtension.selectionRect ?? Rect.zero;
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

    // 填充
    final fillPaint = Paint()
      ..color = selectionColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);

    // 边框
    final strokePaint = Paint()
      ..color = selectionColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, strokePaint);

    // 绘制尺寸标签（可选）
    _drawSizeLabel(canvas, rect, selectionColor);
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

/// ER 交互状态扩展
///
/// 用于存储连线预览和框选的临时状态。
class ERInteractionExtension {
  /// 是否正在连线
  final bool isConnecting;

  /// 连线源锚点 ID
  final String? connectionSourceAnchorId;

  /// 连线源位置（场景坐标）
  final Offset? connectionSourcePosition;

  /// 连线预览终点（场景坐标）
  final Offset? connectionPreviewEnd;

  /// 是否正在框选
  final bool isSelecting;

  /// 框选起点（屏幕坐标）
  final Offset? selectionStartPoint;

  /// 框选终点（屏幕坐标）
  final Offset? selectionEndPoint;

  /// 框选矩形（屏幕坐标）
  final Rect? selectionRect;

  const ERInteractionExtension({
    this.isConnecting = false,
    this.connectionSourceAnchorId,
    this.connectionSourcePosition,
    this.connectionPreviewEnd,
    this.isSelecting = false,
    this.selectionStartPoint,
    this.selectionEndPoint,
    this.selectionRect,
  });

  /// 复制并修改
  ERInteractionExtension copyWith({
    bool? isConnecting,
    String? connectionSourceAnchorId,
    Offset? connectionSourcePosition,
    Offset? connectionPreviewEnd,
    bool? isSelecting,
    Offset? selectionStartPoint,
    Offset? selectionEndPoint,
    Rect? selectionRect,
    bool clearConnection = false,
    bool clearSelection = false,
  }) {
    return ERInteractionExtension(
      isConnecting: clearConnection ? false : (isConnecting ?? this.isConnecting),
      connectionSourceAnchorId:
          clearConnection ? null : (connectionSourceAnchorId ?? this.connectionSourceAnchorId),
      connectionSourcePosition:
          clearConnection ? null : (connectionSourcePosition ?? this.connectionSourcePosition),
      connectionPreviewEnd:
          clearConnection ? null : (connectionPreviewEnd ?? this.connectionPreviewEnd),
      isSelecting: clearSelection ? false : (isSelecting ?? this.isSelecting),
      selectionStartPoint: clearSelection ? null : (selectionStartPoint ?? this.selectionStartPoint),
      selectionEndPoint: clearSelection ? null : (selectionEndPoint ?? this.selectionEndPoint),
      selectionRect: clearSelection ? null : (selectionRect ?? this.selectionRect),
    );
  }

  /// 计算框选矩形
  static Rect calculateSelectionRect(Offset start, Offset end) {
    return Rect.fromPoints(start, end);
  }

  /// 空状态
  static const empty = ERInteractionExtension();
}