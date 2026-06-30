import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../../core/diagram_node.dart';
import '../../core/diagram_state.dart';

/// 节点绘制器
///
/// 负责绘制图表节点的自定义绘制器。支持：
/// - 基础矩形节点绘制
/// - 选中、悬停、高亮等状态视觉反馈
/// - 自定义节点样式配置
/// - 锚点绘制（可选）
class NodePainter extends CustomPainter {
  /// 要绘制的节点
  final DiagramNode node;

  /// 节点状态
  final NodeState state;

  /// 视口状态（用于坐标变换）
  final ViewportState? viewport;

  /// 绘制配置
  final NodePainterConfig config;

  NodePainter({
    required this.node,
    this.state = const NodeState(),
    this.viewport,
    this.config = const NodePainterConfig(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 应用视口变换
    if (viewport != null) {
      canvas.save();
      canvas.translate(viewport!.panOffset.dx, viewport!.panOffset.dy);
      canvas.scale(viewport!.zoom, viewport!.zoom);
    }

    // 绘制节点
    _drawNode(canvas);

    // 绘制锚点（如果配置启用）
    if (config.showAnchors) {
      _drawAnchors(canvas);
    }

    if (viewport != null) {
      canvas.restore();
    }
  }

  /// 绘制节点主体
  void _drawNode(Canvas canvas) {
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );

    // 绘制阴影
    if (config.showShadow) {
      _drawShadow(canvas, rect);
    }

    // 绘制背景
    _drawBackground(canvas, rect);

    // 绘制边框
    _drawBorder(canvas, rect);

    // 绘制标题
    _drawTitle(canvas, rect);

    // 绘制选中指示器
    if (state.isSelected) {
      _drawSelectionIndicator(canvas, rect);
    }

    // 绘制悬停指示器
    if (state.isHovered && !state.isSelected) {
      _drawHoverIndicator(canvas, rect);
    }

    // 绘制高亮指示器
    if (state.isHighlighted) {
      _drawHighlightIndicator(canvas, rect);
    }

    // 绘制拖拽指示器
    if (state.isDragging) {
      _drawDragIndicator(canvas, rect);
    }
  }

  /// 绘制阴影
  void _drawShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = config.shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.shadowBlur);

    final shadowRect = rect.shift(config.shadowOffset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, config.borderRadius),
      shadowPaint,
    );
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas, Rect rect) {
    final bgColor = _getBackgroundColor();
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.borderRadius),
      bgPaint,
    );
  }

  /// 绘制边框
  void _drawBorder(Canvas canvas, Rect rect) {
    final borderColor = _getBorderColor();
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _getBorderWidth();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.borderRadius),
      borderPaint,
    );
  }

  /// 绘制标题
  void _drawTitle(Canvas canvas, Rect rect) {
    if (node.title.isEmpty) return;

    final titleStyle = TextStyle(
      color: config.titleColor,
      fontSize: config.titleFontSize,
      fontWeight: config.titleFontWeight,
      fontFamily: config.fontFamily,
    );

    final textSpan = TextSpan(
      text: node.title,
      style: titleStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: rect.width - config.titlePadding * 2);

    final titleOffset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + config.titleTopPadding,
    );

    textPainter.paint(canvas, titleOffset);
  }

  /// 绘制选中指示器
  void _drawSelectionIndicator(Canvas canvas, Rect rect) {
    final indicatorPaint = Paint()
      ..color = config.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.selectionStrokeWidth;

    // 绘制选中边框
    final selectionRect = rect.inflate(config.selectionPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(selectionRect, config.borderRadius),
      indicatorPaint,
    );

    // 绘制选中角标
    if (config.showSelectionHandles) {
      _drawSelectionHandles(canvas, selectionRect);
    }
  }

  /// 绘制选中角标
  void _drawSelectionHandles(Canvas canvas, Rect rect) {
    final handleSize = config.selectionHandleSize;
    final handlePaint = Paint()
      ..color = config.selectionColor
      ..style = PaintingStyle.fill;

    // 四个角的把手位置
    final handles = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (final handle in handles) {
      canvas.drawRect(
        Rect.fromCenter(center: handle, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  /// 绘制悬停指示器
  void _drawHoverIndicator(Canvas canvas, Rect rect) {
    final hoverPaint = Paint()
      ..color = config.hoverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.hoverStrokeWidth;

    final hoverRect = rect.inflate(config.hoverPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hoverRect, config.borderRadius),
      hoverPaint,
    );
  }

  /// 绘制高亮指示器
  void _drawHighlightIndicator(Canvas canvas, Rect rect) {
    final highlightPaint = Paint()
      ..color = config.highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.highlightStrokeWidth;

    final highlightRect = rect.inflate(config.highlightPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, config.borderRadius),
      highlightPaint,
    );
  }

  /// 绘制拖拽指示器
  void _drawDragIndicator(Canvas canvas, Rect rect) {
    // 拖拽时绘制半透明原位置指示
    final dragPaint = Paint()
      ..color = config.dragColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.borderRadius),
      dragPaint,
    );
  }

  /// 绘制锚点
  void _drawAnchors(Canvas canvas) {
    final anchors = node.getAnchors();
    for (final anchor in anchors) {
      _drawAnchor(canvas, anchor);
    }
  }

  /// 绘制单个锚点
  void _drawAnchor(Canvas canvas, AnchorPoint anchor) {
    final anchorPaint = Paint()
      ..color = config.anchorColor
      ..style = PaintingStyle.fill;

    final anchorBorderPaint = Paint()
      ..color = config.anchorBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.anchorBorderWidth;

    final anchorRect = Rect.fromCenter(
      center: anchor.position,
      width: config.anchorSize,
      height: config.anchorSize,
    );

    // 根据锚点类型选择形状
    if (config.anchorShape == AnchorShape.circle) {
      canvas.drawCircle(anchor.position, config.anchorSize / 2, anchorPaint);
      canvas.drawCircle(anchor.position, config.anchorSize / 2, anchorBorderPaint);
    } else {
      canvas.drawRect(anchorRect, anchorPaint);
      canvas.drawRect(anchorRect, anchorBorderPaint);
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (state.isDragging) {
      return config.backgroundColor.withValues(alpha: config.dragOpacity);
    }
    if (state.isSelected) {
      return config.selectedBackgroundColor;
    }
    if (state.isHovered) {
      return config.hoverBackgroundColor;
    }
    if (state.isHighlighted) {
      return config.highlightBackgroundColor;
    }
    return config.backgroundColor;
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (state.isSelected) {
      return config.selectionColor;
    }
    if (state.isHovered) {
      return config.hoverBorderColor;
    }
    if (state.isHighlighted) {
      return config.highlightColor;
    }
    return config.borderColor;
  }

  /// 获取边框宽度
  double _getBorderWidth() {
    if (state.isSelected) {
      return config.selectionStrokeWidth;
    }
    if (state.isHovered) {
      return config.hoverStrokeWidth;
    }
    return config.borderWidth;
  }

  @override
  bool shouldRepaint(covariant NodePainter oldDelegate) {
    return node != oldDelegate.node ||
        state != oldDelegate.state ||
        viewport != oldDelegate.viewport ||
        config != oldDelegate.config;
  }

  @override
  bool? hitTest(Offset position) {
    // 将屏幕坐标转换为节点本地坐标
    final localPosition = viewport != null
        ? Offset(
            (position.dx - viewport!.panOffset.dx) / viewport!.zoom,
            (position.dy - viewport!.panOffset.dy) / viewport!.zoom,
          )
        : position;

    // 检测是否在节点边界内
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );
    return rect.contains(localPosition);
  }
}

/// 节点绘制配置
class NodePainterConfig {
  /// 背景颜色
  final Color backgroundColor;

  /// 选中时背景颜色
  final Color selectedBackgroundColor;

  /// 悬停时背景颜色
  final Color hoverBackgroundColor;

  /// 高亮时背景颜色
  final Color highlightBackgroundColor;

  /// 边框颜色
  final Color borderColor;

  /// 悬停时边框颜色
  final Color hoverBorderColor;

  /// 边框宽度
  final double borderWidth;

  /// 边框圆角
  final Radius borderRadius;

  /// 标题颜色
  final Color titleColor;

  /// 标题字体大小
  final double titleFontSize;

  /// 标题字体粗细
  final FontWeight titleFontWeight;

  /// 标题字体
  final String? fontFamily;

  /// 标题上边距
  final double titleTopPadding;

  /// 标题左右内边距
  final double titlePadding;

  /// 选中颜色
  final Color selectionColor;

  /// 选中边框宽度
  final double selectionStrokeWidth;

  /// 选中内边距
  final double selectionPadding;

  /// 是否显示选中角标
  final bool showSelectionHandles;

  /// 选中角标大小
  final double selectionHandleSize;

  /// 悬停颜色
  final Color hoverColor;

  /// 悬停边框宽度
  final double hoverStrokeWidth;

  /// 悬停内边距
  final double hoverPadding;

  /// 高亮颜色
  final Color highlightColor;

  /// 高亮边框宽度
  final double highlightStrokeWidth;

  /// 高亮内边距
  final double highlightPadding;

  /// 拖拽颜色
  final Color dragColor;

  /// 拖拽透明度
  final double dragOpacity;

  /// 是否显示阴影
  final bool showShadow;

  /// 阴影颜色
  final Color shadowColor;

  /// 阴影模糊半径
  final double shadowBlur;

  /// 阴影偏移
  final Offset shadowOffset;

  /// 是否显示锚点
  final bool showAnchors;

  /// 锚点颜色
  final Color anchorColor;

  /// 锚点边框颜色
  final Color anchorBorderColor;

  /// 锚点边框宽度
  final double anchorBorderWidth;

  /// 锚点大小
  final double anchorSize;

  /// 锚点形状
  final AnchorShape anchorShape;

  const NodePainterConfig({
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.selectedBackgroundColor = const Color(0xFFE3F2FD),
    this.hoverBackgroundColor = const Color(0xFFF5F5F5),
    this.highlightBackgroundColor = const Color(0xFFFFF8E1),
    this.borderColor = const Color(0xFFE0E0E0),
    this.hoverBorderColor = const Color(0xFFBDBDBD),
    this.borderWidth = 1.0,
    this.borderRadius = const Radius.circular(8.0),
    this.titleColor = const Color(0xFF212121),
    this.titleFontSize = 14.0,
    this.titleFontWeight = FontWeight.w600,
    this.fontFamily,
    this.titleTopPadding = 12.0,
    this.titlePadding = 16.0,
    this.selectionColor = const Color(0xFF2196F3),
    this.selectionStrokeWidth = 2.0,
    this.selectionPadding = 4.0,
    this.showSelectionHandles = true,
    this.selectionHandleSize = 8.0,
    this.hoverColor = const Color(0xFF2196F3),
    this.hoverStrokeWidth = 1.0,
    this.hoverPadding = 2.0,
    this.highlightColor = const Color(0xFFFFC107),
    this.highlightStrokeWidth = 2.0,
    this.highlightPadding = 4.0,
    this.dragColor = const Color(0xFF2196F3),
    this.dragOpacity = 0.3,
    this.showShadow = true,
    this.shadowColor = const Color(0x1F000000),
    this.shadowBlur = 8.0,
    this.shadowOffset = const Offset(2, 2),
    this.showAnchors = false,
    this.anchorColor = const Color(0xFF2196F3),
    this.anchorBorderColor = const Color(0xFFFFFFFF),
    this.anchorBorderWidth = 2.0,
    this.anchorSize = 10.0,
    this.anchorShape = AnchorShape.circle,
  });

  /// 创建暗色主题配置
  factory NodePainterConfig.dark() {
    return const NodePainterConfig(
      backgroundColor: Color(0xFF2D3748),
      selectedBackgroundColor: Color(0xFF1E3A5F),
      hoverBackgroundColor: Color(0xFF3D4758),
      highlightBackgroundColor: Color(0xFF3D3D1F),
      borderColor: Color(0xFF4A5568),
      hoverBorderColor: Color(0xFF718096),
      titleColor: Color(0xFFE2E8F0),
      selectionColor: Color(0xFF63B3ED),
      hoverColor: Color(0xFF63B3ED),
      highlightColor: Color(0xFFF6AD55),
      dragColor: Color(0xFF63B3ED),
      shadowColor: Color(0x3F000000),
      anchorColor: Color(0xFF63B3ED),
      anchorBorderColor: Color(0xFF2D3748),
    );
  }

  /// 复制并修改配置
  NodePainterConfig copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    Color? hoverBackgroundColor,
    Color? highlightBackgroundColor,
    Color? borderColor,
    Color? hoverBorderColor,
    double? borderWidth,
    Radius? borderRadius,
    Color? titleColor,
    double? titleFontSize,
    FontWeight? titleFontWeight,
    String? fontFamily,
    double? titleTopPadding,
    double? titlePadding,
    Color? selectionColor,
    double? selectionStrokeWidth,
    double? selectionPadding,
    bool? showSelectionHandles,
    double? selectionHandleSize,
    Color? hoverColor,
    double? hoverStrokeWidth,
    double? hoverPadding,
    Color? highlightColor,
    double? highlightStrokeWidth,
    double? highlightPadding,
    Color? dragColor,
    double? dragOpacity,
    bool? showShadow,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? showAnchors,
    Color? anchorColor,
    Color? anchorBorderColor,
    double? anchorBorderWidth,
    double? anchorSize,
    AnchorShape? anchorShape,
  }) {
    return NodePainterConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor: selectedBackgroundColor ?? this.selectedBackgroundColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      highlightBackgroundColor: highlightBackgroundColor ?? this.highlightBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      titleColor: titleColor ?? this.titleColor,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      titleTopPadding: titleTopPadding ?? this.titleTopPadding,
      titlePadding: titlePadding ?? this.titlePadding,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionStrokeWidth: selectionStrokeWidth ?? this.selectionStrokeWidth,
      selectionPadding: selectionPadding ?? this.selectionPadding,
      showSelectionHandles: showSelectionHandles ?? this.showSelectionHandles,
      selectionHandleSize: selectionHandleSize ?? this.selectionHandleSize,
      hoverColor: hoverColor ?? this.hoverColor,
      hoverStrokeWidth: hoverStrokeWidth ?? this.hoverStrokeWidth,
      hoverPadding: hoverPadding ?? this.hoverPadding,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightStrokeWidth: highlightStrokeWidth ?? this.highlightStrokeWidth,
      highlightPadding: highlightPadding ?? this.highlightPadding,
      dragColor: dragColor ?? this.dragColor,
      dragOpacity: dragOpacity ?? this.dragOpacity,
      showShadow: showShadow ?? this.showShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      showAnchors: showAnchors ?? this.showAnchors,
      anchorColor: anchorColor ?? this.anchorColor,
      anchorBorderColor: anchorBorderColor ?? this.anchorBorderColor,
      anchorBorderWidth: anchorBorderWidth ?? this.anchorBorderWidth,
      anchorSize: anchorSize ?? this.anchorSize,
      anchorShape: anchorShape ?? this.anchorShape,
    );
  }
}

/// 锚点形状
enum AnchorShape {
  /// 圆形
  circle,

  /// 矩形
  rectangle,
}

/// 节点绘制工具函数
class NodePainterUtils {
  NodePainterUtils._();

  /// 计算节点边界矩形
  static Rect calculateBounds(DiagramNode node) {
    return Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );
  }

  /// 计算节点中心点
  static Offset calculateCenter(DiagramNode node) {
    return Offset(
      node.position.dx + node.size.width / 2,
      node.position.dy + node.size.height / 2,
    );
  }

  /// 计算锚点位置
  static Offset calculateAnchorPosition(
    DiagramNode node,
    AnchorDirection direction, {
    double offset = 0.0,
  }) {
    final rect = calculateBounds(node);

    switch (direction) {
      case AnchorDirection.left:
        return Offset(rect.left - offset, rect.center.dy);
      case AnchorDirection.right:
        return Offset(rect.right + offset, rect.center.dy);
      case AnchorDirection.top:
        return Offset(rect.center.dx, rect.top - offset);
      case AnchorDirection.bottom:
        return Offset(rect.center.dx, rect.bottom + offset);
    }
  }

  /// 检测点是否在节点内
  static bool containsPoint(DiagramNode node, Offset point, {double padding = 0.0}) {
    final rect = calculateBounds(node).inflate(padding);
    return rect.contains(point);
  }

  /// 计算两点之间的连线与节点边界的交点
  static Offset? calculateEdgeIntersection(
    DiagramNode node,
    Offset externalPoint,
  ) {
    final rect = calculateBounds(node);
    final center = calculateCenter(node);

    // 计算方向向量
    final dx = externalPoint.dx - center.dx;
    final dy = externalPoint.dy - center.dy;

    if (dx == 0 && dy == 0) return null;

    // 计算与各边的交点参数 t
    final intersections = <double, Offset>{};

    // 左边
    if (dx != 0) {
      final t = (rect.left - center.dx) / dx;
      if (t > 0) {
        final y = center.dy + t * dy;
        if (y >= rect.top && y <= rect.bottom) {
          intersections[t] = Offset(rect.left, y);
        }
      }
    }

    // 右边
    if (dx != 0) {
      final t = (rect.right - center.dx) / dx;
      if (t > 0) {
        final y = center.dy + t * dy;
        if (y >= rect.top && y <= rect.bottom) {
          intersections[t] = Offset(rect.right, y);
        }
      }
    }

    // 上边
    if (dy != 0) {
      final t = (rect.top - center.dy) / dy;
      if (t > 0) {
        final x = center.dx + t * dx;
        if (x >= rect.left && x <= rect.right) {
          intersections[t] = Offset(x, rect.top);
        }
      }
    }

    // 下边
    if (dy != 0) {
      final t = (rect.bottom - center.dy) / dy;
      if (t > 0) {
        final x = center.dx + t * dx;
        if (x >= rect.left && x <= rect.right) {
          intersections[t] = Offset(x, rect.bottom);
        }
      }
    }

    // 返回最近的交点
    if (intersections.isEmpty) return null;
    final minT = intersections.keys.reduce(math.min);
    return intersections[minT];
  }

  /// 绘制圆角矩形路径
  static Path createRoundedRectPath(Rect rect, Radius radius) {
    return Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
  }

  /// 绘制带箭头的线
  static void drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double arrowSize = 10.0,
    double arrowAngle = 0.5, // 弧度
  }) {
    // 绘制主线
    canvas.drawLine(start, end, paint);

    // 计算箭头
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // 绘制箭头
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle - arrowAngle),
      end.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle + arrowAngle),
      end.dy - arrowSize * math.sin(angle + arrowAngle),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }
}
