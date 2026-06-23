import 'package:flutter/material.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../models/flowchart_models.dart';

/// 流程图节点渲染器
///
/// 根据节点类型绘制不同形状：
/// - 开始/结束：椭圆
/// - 流程：矩形
/// - 判断：菱形
/// - 输入/输出：平行四边形
class FlowNodeRenderer extends BaseNodeRenderer {
  /// 默认尺寸
  static const double defaultWidth = 120.0;
  static const double defaultHeight = 60.0;

  /// 圆角半径
  static const double cornerRadius = 8.0;

  /// 内边距
  static const double padding = 12.0;

  @override
  void paint({
    required Canvas canvas,
    required DiagramNode node,
    required NodeState state,
    required RenderContext context,
  }) {
    final flowNode = node as FlowNode;
    final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);

    // 绘制阴影
    drawShadow(canvas, rect, isDragging: state.isDragging);

    // 根据类型绘制不同形状
    switch (flowNode.data.type) {
      case FlowNodeType.terminal:
        _drawTerminal(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.process:
        _drawProcess(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.decision:
        _drawDecision(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.inputOutput:
        _drawInputOutput(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.predefinedProcess:
        _drawPredefinedProcess(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.connector:
        _drawConnector(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.data:
        _drawData(canvas, rect, flowNode, state, context);
        break;
      case FlowNodeType.document:
        _drawDocument(canvas, rect, flowNode, state, context);
        break;
    }

    // 绘制选中边框
    if (state.isSelected) {
      drawSelectionBorder(canvas, rect);
    }
  }

  /// 绘制开始/结束节点（椭圆）
  void _drawTerminal(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF4CAF50) : Colors.green.shade100;
    final borderColor = isDark ? Colors.green.shade300 : Colors.green.shade600;

    // 椭圆背景
    final paint = Paint()..color = bgColor;
    canvas.drawOval(rect, paint);

    // 边框
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(rect, borderPaint);

    // 文本
    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制流程节点（圆角矩形）
  void _drawProcess(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF2196F3) : Colors.blue.shade100;
    final borderColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;

    // 背景
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
    final paint = Paint()..color = bgColor;
    canvas.drawRRect(rrect, paint);

    // 边框
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // 文本
    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制判断节点（菱形）
  void _drawDecision(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFFFF9800) : Colors.orange.shade100;
    final borderColor = isDark ? Colors.orange.shade300 : Colors.orange.shade600;

    // 菱形路径
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();

    final paint = Paint()..color = bgColor;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // 文本
    _drawText(canvas, rect, node.title, context.isDarkMode, fontSize: 11);
  }

  /// 绘制输入/输出节点（平行四边形）
  void _drawInputOutput(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF9C27B0) : Colors.purple.shade100;
    final borderColor = isDark ? Colors.purple.shade300 : Colors.purple.shade600;

    final skew = 15.0;

    // 平行四边形路径
    final path = Path()
      ..moveTo(rect.left + skew, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - skew, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();

    final paint = Paint()..color = bgColor;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // 文本
    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制预定义流程节点（双边矩形）
  void _drawPredefinedProcess(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF00BCD4) : Colors.cyan.shade100;
    final borderColor = isDark ? Colors.cyan.shade300 : Colors.cyan.shade600;

    // 外框
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
    final paint = Paint()..color = bgColor;
    canvas.drawRRect(rrect, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // 内部两条竖线
    final innerPadding = 10.0;
    canvas.drawLine(
      Offset(rect.left + innerPadding, rect.top + cornerRadius),
      Offset(rect.left + innerPadding, rect.bottom - cornerRadius),
      borderPaint,
    );
    canvas.drawLine(
      Offset(rect.right - innerPadding, rect.top + cornerRadius),
      Offset(rect.right - innerPadding, rect.bottom - cornerRadius),
      borderPaint,
    );

    // 文本
    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制连接点节点（圆形）
  void _drawConnector(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF607D8B) : Colors.grey.shade300;
    final borderColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final paint = Paint()..color = bgColor;
    canvas.drawCircle(rect.center, rect.width / 2, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(rect.center, rect.width / 2, borderPaint);

    // 文本（小字体）
    _drawText(canvas, rect, node.title, context.isDarkMode, fontSize: 10);
  }

  /// 绘制数据节点（波形左侧）
  void _drawData(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF8BC34A) : Colors.lightGreen.shade100;
    final borderColor = isDark ? Colors.lightGreen.shade300 : Colors.lightGreen.shade600;

    final skew = 15.0;

    final path = Path()
      ..moveTo(rect.left + skew, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();

    final paint = Paint()..color = bgColor;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制文档节点（波形底部）
  void _drawDocument(Canvas canvas, Rect rect, FlowNode node, NodeState state, RenderContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF795548) : Colors.brown.shade100;
    final borderColor = isDark ? Colors.brown.shade300 : Colors.brown.shade600;

    final waveHeight = 10.0;

    final path = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom - waveHeight * 2)
      // 波浪底部
      ..quadraticBezierTo(rect.right - rect.width / 4, rect.bottom - waveHeight, rect.right - rect.width / 2, rect.bottom - waveHeight * 2)
      ..quadraticBezierTo(rect.left + rect.width / 4, rect.bottom - waveHeight * 3, rect.left, rect.bottom - waveHeight * 2)
      ..close();

    final paint = Paint()..color = bgColor;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    _drawText(canvas, rect, node.title, context.isDarkMode);
  }

  /// 绘制文本
  void _drawText(Canvas canvas, Rect rect, String text, bool isDarkMode, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - padding * 2);

    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  Size calculateSize(DiagramNode node) {
    return node.size;
  }

  @override
  bool hitTest(DiagramNode node, Offset point) {
    final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);
    return rect.contains(point);
  }

  @override
  AnchorPoint? hitTestAnchor(DiagramNode node, Offset point, double threshold) {
    final flowNode = node as FlowNode;
    final anchors = flowNode.getAnchors();

    for (final anchor in anchors) {
      if ((point - anchor.position).distance < threshold * 2) {
        return anchor;
      }
    }
    return null;
  }
}

/// 流程图边渲染器
///
/// 绘制正交线（折线）和箭头
class FlowEdgeRenderer extends BaseEdgeRenderer {
  @override
  void paint({
    required Canvas canvas,
    required DiagramEdge edge,
    required AnchorPoint sourceAnchor,
    required AnchorPoint targetAnchor,
    required EdgeState state,
    required RenderContext context,
  }) {
    final flowEdge = edge as FlowEdge;
    final style = flowEdge.getStyle();

    final start = sourceAnchor.position;
    final end = targetAnchor.position;

    final paint = Paint()
      ..color = style.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.width
      ..strokeCap = StrokeCap.round;

    // 绘制正交线
    _drawOrthogonalPath(canvas, start, end, sourceAnchor.direction, targetAnchor.direction, paint);

    // 绘制箭头
    drawArrow(canvas, end, start, Paint()..color = style.color..style = PaintingStyle.fill);

    // 绘制标签
    if (flowEdge.label != null) {
      _drawLabel(canvas, start, end, flowEdge.label!, style.color);
    }
  }

  void _drawOrthogonalPath(
    Canvas canvas,
    Offset start,
    Offset end,
    AnchorDirection startDirection,
    AnchorDirection endDirection,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // 计算正交路径
    final midY = (start.dy + end.dy) / 2;

    // 简化的正交路径：先向下/上，再水平，再向下/上
    if (startDirection == AnchorDirection.bottom || startDirection == AnchorDirection.top) {
      // 从顶部或底部出发
      path.lineTo(start.dx, midY);
      path.lineTo(end.dx, midY);
      path.lineTo(end.dx, end.dy);
    } else {
      // 从左侧或右侧出发
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, Offset start, Offset end, String label, Color color) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 背景
    final bgRect = Rect.fromCenter(
      center: Offset(midX, midY),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );

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

    final paint = Paint()
      ..color = (context.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade500).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 虚线预览
    drawDashedLine(canvas, start, end, paint);

    // 箭头
    drawArrow(canvas, end, start, Paint()..color = paint.color..style = PaintingStyle.fill);
  }
}
