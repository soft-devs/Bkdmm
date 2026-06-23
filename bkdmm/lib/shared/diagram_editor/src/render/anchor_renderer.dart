import 'package:flutter/material.dart';

/// 锚点渲染器
///
/// 负责绘制各种类型的锚点
class AnchorRenderer {
  /// 默认锚点尺寸
  static const double defaultSize = 6.0;

  /// 字段锚点尺寸
  static const double fieldAnchorSize = 6.0;

  /// 绘制节点级锚点
  static void paintNodeAnchor(
    Canvas canvas,
    Offset position, {
    Color? color,
    double size = defaultSize,
    bool isActive = false,
  }) {
    final anchorColor = color ?? Colors.blue.shade500;

    // 背景
    final bgPaint = Paint()
      ..color = isActive ? anchorColor.withOpacity(0.5) : anchorColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, size, bgPaint);

    // 边框
    final borderPaint = Paint()
      ..color = anchorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(position, size, borderPaint);

    // 加号图标
    if (!isActive) {
      final plusPaint = Paint()
        ..color = anchorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(position.dx - size / 2, position.dy),
        Offset(position.dx + size / 2, position.dy),
        plusPaint,
      );
      canvas.drawLine(
        Offset(position.dx, position.dy - size / 2),
        Offset(position.dx, position.dy + size / 2),
        plusPaint,
      );
    }
  }

  /// 绘制字段级锚点（用于 ER 图）
  static void paintFieldAnchor(
    Canvas canvas,
    Offset position, {
    Color? color,
    double size = fieldAnchorSize,
    bool isPrimaryKey = false,
    bool isLeft = true,
    bool isHovered = false,
  }) {
    // 主键使用不同颜色
    final anchorColor = isPrimaryKey
        ? Colors.amber.shade600
        : (color ?? Colors.green.shade600);

    // 背景
    final bgPaint = Paint()
      ..color = isHovered
          ? anchorColor.withOpacity(0.6)
          : anchorColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, size, bgPaint);

    // 边框
    final borderPaint = Paint()
      ..color = anchorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(position, size, borderPaint);

    // 方向指示器（箭头）
    final arrowPaint = Paint()
      ..color = anchorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (isLeft) {
      // 左锚点：箭头向左（出边）
      canvas.drawLine(
        Offset(position.dx + 2, position.dy - 2),
        Offset(position.dx - 2, position.dy),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(position.dx + 2, position.dy + 2),
        Offset(position.dx - 2, position.dy),
        arrowPaint,
      );
    } else {
      // 右锚点：箭头向右（入边）
      canvas.drawLine(
        Offset(position.dx - 2, position.dy - 2),
        Offset(position.dx + 2, position.dy),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(position.dx - 2, position.dy + 2),
        Offset(position.dx + 2, position.dy),
        arrowPaint,
      );
    }

    // 主键指示器（小圆点）
    if (isPrimaryKey) {
      final pkPaint = Paint()
        ..color = anchorColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 2, pkPaint);
    }
  }

  /// 绘制端口锚点（用于流程图）
  static void paintPortAnchor(
    Canvas canvas,
    Offset position, {
    Color? color,
    Size size = const Size(12, 8),
    bool isInput = true,
    bool isConnected = false,
  }) {
    final portColor = color ?? Colors.purple.shade500;

    final rect = Rect.fromCenter(
      center: position,
      width: size.width,
      height: size.height,
    );

    // 背景
    final bgPaint = Paint()
      ..color = isConnected ? portColor : portColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // 绘制梯形/三角形端口
    final path = Path();
    if (isInput) {
      // 输入端口（指向右）
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.right - 4, rect.top);
      path.lineTo(rect.right, rect.center.dy);
      path.lineTo(rect.right - 4, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
    } else {
      // 输出端口（指向左）
      path.moveTo(rect.left, rect.center.dy);
      path.lineTo(rect.left + 4, rect.top);
      path.lineTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.left + 4, rect.bottom);
    }
    path.close();

    canvas.drawPath(path, bgPaint);

    // 边框
    if (!isConnected) {
      final borderPaint = Paint()
        ..color = portColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  /// 绘制悬停高亮
  static void paintHoverHighlight(
    Canvas canvas,
    Offset position, {
    double size = defaultSize * 2,
    Color? color,
  }) {
    final highlightPaint = Paint()
      ..color = (color ?? Colors.blue.shade500).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, size, highlightPaint);
  }
}