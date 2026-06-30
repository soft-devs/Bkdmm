/// 交互层覆盖组件
///
/// 显示框选区域和连线预览等交互状态的可视化反馈。
/// 作为独立的覆盖层渲染，不影响底层图表内容。
library;

import 'package:flutter/material.dart';
import '../core/diagram_node.dart';
import '../core/diagram_state.dart' hide InteractionMode;
import '../handlers/diagram_context.dart';

/// 交互覆盖层
///
/// 在图表画布上显示交互状态的视觉反馈，包括：
/// - 框选区域预览
/// - 连线预览
/// - 拖拽占位符
///
/// 使用方式：
/// ```dart
/// Stack(
///   children: [
///     DiagramCanvas(...),
///     ModificationOverlay(
///       state: diagramState,
///       context: diagramContext,
///     ),
///   ],
/// )
/// ```
class ModificationOverlay extends StatelessWidget {
  /// 图表状态
  final DiagramState state;

  /// 图表上下文（用于坐标转换）
  final DiagramContext context;

  /// 框选区域颜色
  final Color boxSelectionColor;

  /// 框选区域边框宽度
  final double boxSelectionStrokeWidth;

  /// 连线预览颜色
  final Color connectionPreviewColor;

  /// 连线预览宽度
  final double connectionPreviewStrokeWidth;

  /// 连线预览箭头大小
  final double connectionArrowSize;

  /// 拖拽占位符颜色
  final Color dragPlaceholderColor;

  /// 动画持续时间
  final Duration animationDuration;

  const ModificationOverlay({
    super.key,
    required this.state,
    required this.context,
    this.boxSelectionColor = Colors.blue,
    this.boxSelectionStrokeWidth = 1.5,
    this.connectionPreviewColor = Colors.blue,
    this.connectionPreviewStrokeWidth = 2.0,
    this.connectionArrowSize = 10.0,
    this.dragPlaceholderColor = const Color(0x400000FF),
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // 框选区域
    final boxRect = state.selection.boxSelectRect;
    if (boxRect != null) {
      children.add(_buildBoxSelection(boxRect));
    }

    // 连线预览
    if (state.interaction.isConnecting) {
      final sourceAnchorId = state.interaction.connectionSourceAnchorId;
      final previewEnd = state.interaction.connectionPreviewEnd;
      if (sourceAnchorId != null && previewEnd != null) {
        children.add(_buildConnectionPreview(sourceAnchorId, previewEnd));
      }
    }

    // 拖拽占位符（多选拖拽时显示）
    if (state.interaction.isDragging &&
        state.interaction.draggedNodeId != null &&
        state.selection.selectedNodeIds.length > 1) {
      children.add(_buildDragPlaceholders());
    }

    // 使用 Stack 确保覆盖层在正确位置
    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }

  /// 构建框选区域
  Widget _buildBoxSelection(Rect rect) {
    return Positioned.fromRect(
      rect: rect,
      child: CustomPaint(
        painter: _BoxSelectionPainter(
          color: boxSelectionColor,
          strokeWidth: boxSelectionStrokeWidth,
        ),
      ),
    );
  }

  /// 构建连线预览
  Widget _buildConnectionPreview(String sourceAnchorId, Offset previewEnd) {
    // 获取源锚点位置
    final sourceAnchor = state.getAnchor(sourceAnchorId);
    if (sourceAnchor == null) return const SizedBox.shrink();

    // 转换坐标
    final sourceScreen = context.toScreen(sourceAnchor.position);
    final targetScreen = previewEnd;

    // 计算边界矩形
    final left = sourceScreen.dx < targetScreen.dx
        ? sourceScreen.dx
        : targetScreen.dx;
    final top = sourceScreen.dy < targetScreen.dy
        ? sourceScreen.dy
        : targetScreen.dy;
    final right = sourceScreen.dx > targetScreen.dx
        ? sourceScreen.dx
        : targetScreen.dx;
    final bottom = sourceScreen.dy > targetScreen.dy
        ? sourceScreen.dy
        : targetScreen.dy;

    // 添加边距以容纳箭头
    final padding = connectionArrowSize + connectionPreviewStrokeWidth;
    final bounds = Rect.fromLTRB(
      left - padding,
      top - padding,
      right + padding,
      bottom + padding,
    );

    return Positioned.fromRect(
      rect: bounds,
      child: CustomPaint(
        painter: _ConnectionPreviewPainter(
          sourcePosition: Offset(
            sourceScreen.dx - bounds.left,
            sourceScreen.dy - bounds.top,
          ),
          targetPosition: Offset(
            targetScreen.dx - bounds.left,
            targetScreen.dy - bounds.top,
          ),
          color: connectionPreviewColor,
          strokeWidth: connectionPreviewStrokeWidth,
          arrowSize: connectionArrowSize,
        ),
      ),
    );
  }

  /// 构建拖拽占位符
  Widget _buildDragPlaceholders() {
    final selectedIds = state.selection.selectedNodeIds;

    return Stack(
      children: selectedIds.map((nodeId) {
        final node = state.nodes[nodeId];
        if (node == null) return const SizedBox.shrink();

        // 计算屏幕位置
        final screenPos = context.toScreen(node.position);
        final screenSize = Size(
          node.size.width * context.zoom,
          node.size.height * context.zoom,
        );

        return Positioned.fromRect(
          rect: Rect.fromLTWH(
            screenPos.dx,
            screenPos.dy,
            screenSize.width,
            screenSize.height,
          ),
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: animationDuration,
              decoration: BoxDecoration(
                color: dragPlaceholderColor,
                borderRadius: BorderRadius.circular(4 * context.zoom),
                border: Border.all(
                  color: dragPlaceholderColor.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 框选区域绘制器
class _BoxSelectionPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _BoxSelectionPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 绘制半透明填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 绘制虚线边框
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    final dashWidth = 5.0;
    final dashSpace = 3.0;

    // 上边
    double x = 0;
    while (x < rect.width) {
      path.moveTo(x, 0);
      path.lineTo((x + dashWidth).clamp(0, rect.width), 0);
      x += dashWidth + dashSpace;
    }

    // 右边
    double y = 0;
    while (y < rect.height) {
      path.moveTo(rect.width, y);
      path.lineTo(rect.width, (y + dashWidth).clamp(0, rect.height));
      y += dashWidth + dashSpace;
    }

    // 下边
    x = 0;
    while (x < rect.width) {
      path.moveTo(x, rect.height);
      path.lineTo((x + dashWidth).clamp(0, rect.width), rect.height);
      x += dashWidth + dashSpace;
    }

    // 左边
    y = 0;
    while (y < rect.height) {
      path.moveTo(0, y);
      path.lineTo(0, (y + dashWidth).clamp(0, rect.height));
      y += dashWidth + dashSpace;
    }

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_BoxSelectionPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// 连线预览绘制器
class _ConnectionPreviewPainter extends CustomPainter {
  final Offset sourcePosition;
  final Offset targetPosition;
  final Color color;
  final double strokeWidth;
  final double arrowSize;

  _ConnectionPreviewPainter({
    required this.sourcePosition,
    required this.targetPosition,
    required this.color,
    required this.strokeWidth,
    required this.arrowSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(sourcePosition.dx, sourcePosition.dy);

    // 计算贝塞尔曲线控制点
    final dx = (targetPosition.dx - sourcePosition.dx).abs();
    final controlOffset = (dx * 0.5).clamp(50.0, 150.0);

    final controlPoint1 = Offset(
      sourcePosition.dx + controlOffset,
      sourcePosition.dy,
    );
    final controlPoint2 = Offset(
      targetPosition.dx - controlOffset,
      targetPosition.dy,
    );

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      targetPosition.dx,
      targetPosition.dy,
    );

    // 绘制连线
    canvas.drawPath(path, paint);

    // 绘制箭头
    _drawArrow(canvas, targetPosition, controlPoint2);
  }

  void _drawArrow(Canvas canvas, Offset target, Offset controlPoint) {
    // 计算箭头方向
    final direction = target - controlPoint;
    if (direction.distance < 0.001) return;

    final normalizedDirection = direction / direction.distance;

    // 箭头顶点
    final arrowTip = target;

    // 箭头两侧点
    final perpendicular = Offset(-normalizedDirection.dy, normalizedDirection.dx);
    final arrowBase1 = arrowTip -
        normalizedDirection * arrowSize +
        perpendicular * arrowSize * 0.5;
    final arrowBase2 = arrowTip -
        normalizedDirection * arrowSize -
        perpendicular * arrowSize * 0.5;

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowBase1.dx, arrowBase1.dy)
      ..lineTo(arrowBase2.dx, arrowBase2.dy)
      ..close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(_ConnectionPreviewPainter oldDelegate) {
    return sourcePosition != oldDelegate.sourcePosition ||
        targetPosition != oldDelegate.targetPosition ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        arrowSize != oldDelegate.arrowSize;
  }
}

/// 连线预览组件（独立使用）
///
/// 用于单独显示连线预览，不包含其他交互元素。
class ConnectionPreview extends StatelessWidget {
  /// 源锚点
  final AnchorPoint sourceAnchor;

  /// 目标位置（屏幕坐标）
  final Offset targetPosition;

  /// 图表上下文
  final DiagramContext context;

  /// 颜色
  final Color color;

  /// 线宽
  final double strokeWidth;

  /// 箭头大小
  final double arrowSize;

  const ConnectionPreview({
    super.key,
    required this.sourceAnchor,
    required this.targetPosition,
    required this.context,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.arrowSize = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    // 转换坐标
    final sourceScreen = this.context.toScreen(sourceAnchor.position);
    final targetScreen = targetPosition;

    // 计算边界
    final left = sourceScreen.dx < targetScreen.dx
        ? sourceScreen.dx
        : targetScreen.dx;
    final top = sourceScreen.dy < targetScreen.dy
        ? sourceScreen.dy
        : targetScreen.dy;
    final right = sourceScreen.dx > targetScreen.dx
        ? sourceScreen.dx
        : targetScreen.dx;
    final bottom = sourceScreen.dy > targetScreen.dy
        ? sourceScreen.dy
        : targetScreen.dy;

    final padding = arrowSize + strokeWidth;
    final bounds = Rect.fromLTRB(
      left - padding,
      top - padding,
      right + padding,
      bottom + padding,
    );

    return Positioned.fromRect(
      rect: bounds,
      child: CustomPaint(
        painter: _ConnectionPreviewPainter(
          sourcePosition: Offset(
            sourceScreen.dx - bounds.left,
            sourceScreen.dy - bounds.top,
          ),
          targetPosition: Offset(
            targetScreen.dx - bounds.left,
            targetScreen.dy - bounds.top,
          ),
          color: color,
          strokeWidth: strokeWidth,
          arrowSize: arrowSize,
        ),
      ),
    );
  }
}

/// 框选区域组件（独立使用）
///
/// 用于单独显示框选区域，不包含其他交互元素。
class BoxSelectionOverlay extends StatelessWidget {
  /// 框选矩形
  final Rect rect;

  /// 颜色
  final Color color;

  /// 边框宽度
  final double strokeWidth;

  const BoxSelectionOverlay({
    super.key,
    required this.rect,
    this.color = Colors.blue,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: CustomPaint(
        painter: _BoxSelectionPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// 拖拽占位符组件（独立使用）
///
/// 用于在拖拽过程中显示节点占位符。
class DragPlaceholderOverlay extends StatelessWidget {
  /// 节点列表
  final List<DiagramNode> nodes;

  /// 图表上下文
  final DiagramContext context;

  /// 颜色
  final Color color;

  /// 动画持续时间
  final Duration animationDuration;

  const DragPlaceholderOverlay({
    super.key,
    required this.nodes,
    required this.context,
    this.color = const Color(0x400000FF),
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: nodes.map((node) {
        // 计算屏幕位置
        final screenPos = this.context.toScreen(node.position);
        final screenSize = Size(
          node.size.width * this.context.zoom,
          node.size.height * this.context.zoom,
        );

        return Positioned.fromRect(
          rect: Rect.fromLTWH(
            screenPos.dx,
            screenPos.dy,
            screenSize.width,
            screenSize.height,
          ),
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: animationDuration,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4 * this.context.zoom),
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 交互状态装饰器
///
/// 用于根据交互状态添加视觉效果（如悬停、选中）。
class InteractionStateDecorator extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 是否选中
  final bool isSelected;

  /// 是否悬停
  final bool isHovered;

  /// 是否正在拖拽
  final bool isDragging;

  /// 选中边框颜色
  final Color selectedBorderColor;

  /// 悬停边框颜色
  final Color hoveredBorderColor;

  /// 拖拽边框颜色
  final Color draggingBorderColor;

  /// 边框宽度
  final double borderWidth;

  /// 圆角半径
  final double borderRadius;

  const InteractionStateDecorator({
    super.key,
    required this.child,
    this.isSelected = false,
    this.isHovered = false,
    this.isDragging = false,
    this.selectedBorderColor = Colors.blue,
    this.hoveredBorderColor = Colors.grey,
    this.draggingBorderColor = Colors.orange,
    this.borderWidth = 2.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    if (isDragging) {
      borderColor = draggingBorderColor;
    } else if (isSelected) {
      borderColor = selectedBorderColor;
    } else if (isHovered) {
      borderColor = hoveredBorderColor;
    }

    return Container(
      decoration: borderColor != null
          ? BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            )
          : null,
      child: child,
    );
  }
}