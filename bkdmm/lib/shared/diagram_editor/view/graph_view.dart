/// 图表视图 - Stack 分层结构
///
/// 提供图表的主视图，采用 Stack 分层架构：
/// - 网格层 (GridLayer): 无限网格背景
/// - 边层 (EdgeLayer): 连接线绘制
/// - 节点层 (NodeLayer): 节点组件渲染
/// - 交互层 (InteractionLayer): 框选、连线预览等
/// - 装饰层 (DecorationLayer): 工具栏、坐标显示等
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/diagram_state.dart';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../handlers/diagram_context.dart' as diag_ctx show HitTestResult;

/// 图表主视图
///
/// 使用 Stack 分层架构组织图表组件，支持：
/// - 多层独立渲染和更新
/// - 坐标转换（屏幕/场景）
/// - 视口控制（缩放、平移）
/// - 命中测试
class GraphView extends StatefulWidget {
  /// 图表状态
  final DiagramState state;

  /// 节点构建器
  ///
  /// 根据节点数据构建对应的 Widget
  final Widget Function(DiagramNode node, NodeState nodeState) nodeBuilder;

  /// 边绘制器
  ///
  /// 自定义边的绘制逻辑
  final GraphEdgePainter? edgePainter;

  /// 网格配置
  final GraphGridConfig gridConfig;

  /// 视口配置
  final ViewportConfig viewportConfig;

  /// 交互模式
  final InteractionMode interactionMode;

  /// 命中测试回调
  ///
  /// 返回指定场景坐标下的命中结果
  final diag_ctx.HitTestResult Function(Offset scenePosition)? hitTest;

  /// 状态更新回调
  final void Function(ViewportState viewport)? onViewportChange;

  /// 是否显示工具栏
  final bool showToolbar;

  /// 是否显示坐标
  final bool showCoordinates;

  /// 工具栏构建器
  final Widget Function(BuildContext context)? toolbarBuilder;

  /// 自定义装饰层
  final Widget Function(BuildContext context)? decorationBuilder;

  /// 交互层覆盖构建器
  ///
  /// 用于绘制连线预览、框选矩形等临时交互元素
  final Widget Function(BuildContext context, DiagramState state)? interactionOverlayBuilder;

  const GraphView({
    super.key,
    required this.state,
    required this.nodeBuilder,
    this.edgePainter,
    this.gridConfig = const GraphGridConfig(),
    this.viewportConfig = const ViewportConfig(),
    this.interactionMode = InteractionMode.edit,
    this.hitTest,
    this.onViewportChange,
    this.showToolbar = true,
    this.showCoordinates = true,
    this.toolbarBuilder,
    this.decorationBuilder,
    this.interactionOverlayBuilder,
  });

  @override
  State<GraphView> createState() => GraphViewState();
}

/// GraphView 的状态
class GraphViewState extends State<GraphView> {
  /// 变换控制器
  late TransformationController _transformationController;

  /// 当前鼠标位置（屏幕坐标）
  Offset _mousePosition = Offset.zero;

  /// 是否正在平移
  bool _isPanning = false;

  /// 平移起始位置
  Offset _panStart = Offset.zero;

  /// 平移起始变换
  Matrix4 _panTransformStart = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(
      _computeTransformMatrix(widget.state.viewport),
    );
  }

  @override
  void didUpdateWidget(GraphView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新变换矩阵
    if (oldWidget.state.viewport != widget.state.viewport) {
      _transformationController.value = _computeTransformMatrix(widget.state.viewport);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 计算变换矩阵
  Matrix4 _computeTransformMatrix(ViewportState viewport) {
    final matrix = Matrix4.identity();
    matrix.translate(viewport.panOffset.dx, viewport.panOffset.dy);
    matrix.scale(viewport.zoom);
    return matrix;
  }

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset screen) {
    final inverse = Matrix4.tryInvert(_transformationController.value) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screen);
  }

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return MatrixUtils.transformPoint(_transformationController.value, scene);
  }

  /// 获取当前缩放比例
  double get zoom => _transformationController.value.getMaxScaleOnAxis();

  /// 获取当前平移偏移
  Offset get panOffset {
    final matrix = _transformationController.value;
    return Offset(matrix.entry(0, 3), matrix.entry(1, 3));
  }

  /// 缩放
  void zoomTo(double scale, Offset center) {
    final clampedScale = scale.clamp(
      widget.viewportConfig.minZoom,
      widget.viewportConfig.maxZoom,
    );

    final matrix = Matrix4.identity();
    matrix.translate(center.dx, center.dy);
    matrix.scale(clampedScale);
    matrix.translate(-center.dx, -center.dy);

    _transformationController.value = matrix;
    _notifyViewportChange();
  }

  /// 放大
  void zoomIn({Offset? center}) {
    final targetCenter = center ?? _mousePosition;
    final newZoom = zoom * widget.viewportConfig.zoomStep;
    zoomTo(newZoom, targetCenter);
  }

  /// 缩小
  void zoomOut({Offset? center}) {
    final targetCenter = center ?? _mousePosition;
    final newZoom = zoom / widget.viewportConfig.zoomStep;
    zoomTo(newZoom, targetCenter);
  }

  /// 平移
  void pan(Offset delta) {
    final matrix = _transformationController.value.clone();
    matrix.translate(delta.dx, delta.dy);
    _transformationController.value = matrix;
    _notifyViewportChange();
  }

  /// 适应内容
  void fitContent({double padding = 50.0}) {
    if (widget.state.nodes.isEmpty) return;

    final bounds = widget.state.calculateContentBounds(padding: padding);
    final viewportSize = context.size ?? Size.zero;

    final newViewport = widget.state.viewport.fitContent(
      bounds,
      viewportSize,
      padding: padding,
    );

    _transformationController.value = _computeTransformMatrix(newViewport);
    _notifyViewportChange();
  }

  /// 重置视口
  void resetViewport() {
    _transformationController.value = Matrix4.identity();
    _notifyViewportChange();
  }

  /// 通知视口变化
  void _notifyViewportChange() {
    if (widget.onViewportChange != null) {
      final viewport = ViewportState(
        zoom: zoom,
        panOffset: panOffset,
        minZoom: widget.viewportConfig.minZoom,
        maxZoom: widget.viewportConfig.maxZoom,
      );
      widget.onViewportChange!(viewport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 主画布层
        _buildMainCanvas(isDark),

        // 交互覆盖层
        if (widget.interactionOverlayBuilder != null)
          Positioned.fill(
            child: IgnorePointer(
              child: widget.interactionOverlayBuilder!(context, widget.state),
            ),
          ),

        // 装饰层
        if (widget.showToolbar || widget.showCoordinates || widget.decorationBuilder != null)
          _buildDecorationLayer(isDark),
      ],
    );
  }

  /// 构建主画布
  Widget _buildMainCanvas(bool isDark) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: EdgeInsets.all(widget.viewportConfig.boundaryMargin),
          minScale: widget.viewportConfig.minZoom,
          maxScale: widget.viewportConfig.maxZoom,
          panEnabled: widget.interactionMode == InteractionMode.move,
          scaleEnabled: widget.viewportConfig.scaleEnabled,
          clipBehavior: Clip.none,
          onInteractionStart: (details) {
            if (widget.interactionMode == InteractionMode.edit &&
                details.kind == PointerDeviceKind.touch) {
              _isPanning = true;
              _panStart = details.focalPoint;
              _panTransformStart = _transformationController.value.clone();
            }
          },
          onInteractionUpdate: (details) {
            // 交互更新时自动更新视口状态
            _notifyViewportChange();
          },
          onInteractionEnd: (details) {
            _isPanning = false;
            _notifyViewportChange();
          },
          child: SizedBox(
            width: widget.viewportConfig.virtualCanvasSize,
            height: widget.viewportConfig.virtualCanvasSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 背景层 - 填满整个虚拟画布
                Positioned.fill(
                  child: _buildBackground(isDark),
                ),

                // 边层
                if (widget.edgePainter != null || widget.state.edges.isNotEmpty)
                  CustomPaint(
                    painter: _DefaultEdgePainter(
                      state: widget.state,
                      transform: _transformationController.value,
                      isDark: isDark,
                      customPainter: widget.edgePainter,
                    ),
                    size: Size(
                      widget.viewportConfig.virtualCanvasSize,
                      widget.viewportConfig.virtualCanvasSize,
                    ),
                  ),

                // 节点层
                ...widget.state.nodes.values.map((node) {
                  final nodeState = widget.state.getNodeState(node.id);
                  return Positioned(
                    left: node.position.dx,
                    top: node.position.dy,
                    child: widget.nodeBuilder(node, nodeState),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建背景
  Widget _buildBackground(bool isDark) {
    if (!widget.gridConfig.showGrid) {
      return ColoredBox(
        color: isDark ? widget.gridConfig.darkBackgroundColor : widget.gridConfig.lightBackgroundColor,
      );
    }

    return ListenableBuilder(
      listenable: _transformationController,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _InfiniteGridPainter(
              transformationController: _transformationController,
              gridColor: isDark ? widget.gridConfig.darkGridColor : widget.gridConfig.lightGridColor,
              gridSize: widget.gridConfig.gridSize,
              backgroundColor: isDark ? widget.gridConfig.darkBackgroundColor : widget.gridConfig.lightBackgroundColor,
              majorGridInterval: widget.gridConfig.majorGridInterval,
              majorGridColor: isDark ? widget.gridConfig.darkMajorGridColor : widget.gridConfig.lightMajorGridColor,
            ),
          ),
        );
      },
    );
  }

  /// 构建装饰层
  Widget _buildDecorationLayer(bool isDark) {
    return Stack(
      children: [
        // 工具栏（右上角）
        if (widget.showToolbar)
          Positioned(
            top: widget.viewportConfig.toolbarOffset.dy,
            right: widget.viewportConfig.toolbarOffset.dx,
            child: widget.toolbarBuilder?.call(context) ?? _buildDefaultToolbar(isDark),
          ),

        // 坐标显示（左下角）
        if (widget.showCoordinates)
          Positioned(
            left: widget.viewportConfig.coordinateOffset.dx,
            bottom: widget.viewportConfig.coordinateOffset.dy,
            child: _buildCoordinateDisplay(isDark),
          ),

        // 自定义装饰
        if (widget.decorationBuilder != null)
          widget.decorationBuilder!(context),
      ],
    );
  }

  /// 构建默认工具栏
  Widget _buildDefaultToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 放大
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: zoomIn,
            tooltip: '放大',
          ),
          const SizedBox(width: 4),
          // 缩小
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: zoomOut,
            tooltip: '缩小',
          ),
          const SizedBox(width: 4),
          // 适应
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 20),
            onPressed: fitContent,
            tooltip: '适应内容',
          ),
          const SizedBox(width: 4),
          // 重置
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: resetViewport,
            tooltip: '重置视口',
          ),
        ],
      ),
    );
  }

  /// 构建坐标显示
  Widget _buildCoordinateDisplay(bool isDark) {
    final scenePos = toScene(_mousePosition);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        'X: ${scenePos.dx.toStringAsFixed(0)}  Y: ${scenePos.dy.toStringAsFixed(0)}  Zoom: ${(zoom * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 事件处理
  // ═══════════════════════════════════════════════════════════════════

  void _onPointerDown(PointerDownEvent event) {
    // 右键在编辑模式下用于平移
    if (event.buttons == kSecondaryMouseButton &&
        widget.interactionMode == InteractionMode.edit) {
      _isPanning = true;
      _panStart = event.localPosition;
      _panTransformStart = _transformationController.value.clone();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    // 右键平移（编辑模式）
    if (event.buttons == kSecondaryMouseButton && _isPanning) {
      final delta = event.localPosition - _panStart;
      final newMatrix = _panTransformStart.clone();
      newMatrix.translate(delta.dx, delta.dy);
      _transformationController.value = newMatrix;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPanning) {
      _isPanning = false;
      _notifyViewportChange();
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // 滚轮缩放由 InteractiveViewer 自动处理
  }
}

/// 网格配置
class GraphGridConfig {
  /// 是否显示网格
  final bool showGrid;

  /// 网格大小
  final double gridSize;

  /// 主要网格间隔（每多少个小格显示一个大格）
  final int majorGridInterval;

  /// 浅色模式网格颜色
  final Color lightGridColor;

  /// 深色模式网格颜色
  final Color darkGridColor;

  /// 浅色模式主要网格颜色
  final Color lightMajorGridColor;

  /// 深色模式主要网格颜色
  final Color darkMajorGridColor;

  /// 浅色模式背景颜色
  final Color lightBackgroundColor;

  /// 深色模式背景颜色
  final Color darkBackgroundColor;

  const GraphGridConfig({
    this.showGrid = true,
    this.gridSize = 20.0,
    this.majorGridInterval = 5,
    this.lightGridColor = const Color(0x14000000), // 8% black
    this.darkGridColor = const Color(0x14FFFFFF), // 8% white
    this.lightMajorGridColor = const Color(0x28000000), // 16% black
    this.darkMajorGridColor = const Color(0x28FFFFFF), // 16% white
    this.lightBackgroundColor = const Color(0xFFFAFAFA),
    this.darkBackgroundColor = const Color(0xFF1A1A2E),
  });
}

/// 视口配置
class ViewportConfig {
  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  /// 缩放步进
  final double zoomStep;

  /// 边界边距
  final double boundaryMargin;

  /// 虚拟画布大小
  final double virtualCanvasSize;

  /// 是否启用缩放
  final bool scaleEnabled;

  /// 工具栏偏移
  final Offset toolbarOffset;

  /// 坐标显示偏移
  final Offset coordinateOffset;

  const ViewportConfig({
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomStep = 1.2,
    this.boundaryMargin = double.infinity,
    this.virtualCanvasSize = 50000.0,
    this.scaleEnabled = true,
    this.toolbarOffset = const Offset(16, 16),
    this.coordinateOffset = const Offset(16, 16),
  });
}

/// 边绘制器接口
///
/// 用于自定义边的绘制逻辑
abstract class GraphEdgePainter {
  /// 绘制边
  void paint(
      Canvas canvas,
      DiagramEdge edge,
      EdgeState edgeState,
      Offset sourcePosition,
      Offset targetPosition,
      Matrix4 transform,
      bool isDark,
      );
}

/// 默认边绘制器
class _DefaultEdgePainter extends CustomPainter {
  final DiagramState state;
  final Matrix4 transform;
  final bool isDark;
  final GraphEdgePainter? customPainter;

  _DefaultEdgePainter({
    required this.state,
    required this.transform,
    required this.isDark,
    this.customPainter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in state.edges.values) {
      final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
      final targetAnchor = state.getAnchor(edge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      final edgeState = state.getEdgeState(edge.id);
      final style = edge.getStyle();

      if (customPainter != null) {
        customPainter!.paint(
          canvas,
          edge,
          edgeState,
          sourceAnchor.position,
          targetAnchor.position,
          transform,
          isDark,
        );
      } else {
        _drawDefaultEdge(
          canvas,
          edge,
          edgeState,
          sourceAnchor.position,
          targetAnchor.position,
          style,
        );
      }
    }
  }

  void _drawDefaultEdge(
      Canvas canvas,
      DiagramEdge edge,
      EdgeState edgeState,
      Offset sourcePos,
      Offset targetPos,
      EdgeStyle style,
      ) {
    final color = edgeState.isSelected
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade500)
        : style.color;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.width
      ..strokeCap = StrokeCap.round;

    // 绘制线条
    switch (style.shape) {
      case EdgeShape.straight:
        canvas.drawLine(sourcePos, targetPos, paint);
        break;

      case EdgeShape.curved:
        _drawCurvedEdge(canvas, sourcePos, targetPos, paint, style.curveFactor);
        break;

      case EdgeShape.bezier:
        _drawBezierEdge(canvas, sourcePos, targetPos, paint);
        break;

      case EdgeShape.orthogonal:
        _drawOrthogonalEdge(canvas, sourcePos, targetPos, paint);
        break;
    }

    // 绘制端点标记
    final sourceMarker = edge.getSourceMarker();
    final targetMarker = edge.getTargetMarker();

    if (sourceMarker != null) {
      _drawMarker(canvas, sourcePos, targetPos, sourceMarker, true);
    }
    if (targetMarker != null) {
      _drawMarker(canvas, targetPos, sourcePos, targetMarker, false);
    }
  }

  void _drawCurvedEdge(
      Canvas canvas,
      Offset source,
      Offset target,
      Paint paint,
      double curveFactor,
      ) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;

    final controlOffset = Offset(dx * curveFactor, dy.abs() * curveFactor);

    final path = Path();
    path.moveTo(source.dx, source.dy);
    path.quadraticBezierTo(
      source.dx + controlOffset.dx,
      source.dy + controlOffset.dy,
      target.dx,
      target.dy,
    );

    canvas.drawPath(path, paint);
  }

  void _drawBezierEdge(
      Canvas canvas,
      Offset source,
      Offset target,
      Paint paint,
      ) {
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;

    final control1 = Offset(source.dx + dx * 0.25, source.dy + dy * 0.5);
    final control2 = Offset(source.dx + dx * 0.75, source.dy + dy * 0.5);

    final path = Path();
    path.moveTo(source.dx, source.dy);
    path.cubicTo(
      control1.dx, control1.dy,
      control2.dx, control2.dy,
      target.dx, target.dy,
    );

    canvas.drawPath(path, paint);
  }

  void _drawOrthogonalEdge(
      Canvas canvas,
      Offset source,
      Offset target,
      Paint paint,
      ) {
    final midX = (source.dx + target.dx) / 2;

    final path = Path();
    path.moveTo(source.dx, source.dy);
    path.lineTo(midX, source.dy);
    path.lineTo(midX, target.dy);
    path.lineTo(target.dx, target.dy);

    canvas.drawPath(path, paint);
  }

  void _drawMarker(
      Canvas canvas,
      Offset position,
      Offset opposite,
      EdgeMarker marker,
      bool isSource,
      ) {
    final paint = Paint()
      ..color = marker.color ?? Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final size = marker.size;

    switch (marker.type) {
      case EdgeMarkerType.one:
      // 单线标记
        final angle = math.atan2(opposite.dy - position.dy, opposite.dx - position.dx);
        final perpAngle = angle + math.pi / 2;
        final offset = Offset(size * math.cos(perpAngle), size * math.sin(perpAngle));
        canvas.drawLine(position - offset, position + offset, paint);
        break;

      case EdgeMarkerType.many:
      // 鸦脚标记
        final angle = math.atan2(opposite.dy - position.dy, opposite.dx - position.dx);
        final spread = math.pi / 6;
        canvas.drawLine(
          position,
          Offset(
            position.dx + size * math.cos(angle - spread),
            position.dy + size * math.sin(angle - spread),
          ),
          paint,
        );
        canvas.drawLine(
          position,
          Offset(
            position.dx + size * math.cos(angle),
            position.dy + size * math.sin(angle),
          ),
          paint,
        );
        canvas.drawLine(
          position,
          Offset(
            position.dx + size * math.cos(angle + spread),
            position.dy + size * math.sin(angle + spread),
          ),
          paint,
        );
        break;

      case EdgeMarkerType.arrow:
      // 箭头
        final angle = math.atan2(position.dy - opposite.dy, position.dx - opposite.dx);
        final path = Path();
        path.moveTo(position.dx, position.dy);
        path.lineTo(
          position.dx - size * math.cos(angle - math.pi / 6),
          position.dy - size * math.sin(angle - math.pi / 6),
        );
        path.lineTo(
          position.dx - size * math.cos(angle + math.pi / 6),
          position.dy - size * math.sin(angle + math.pi / 6),
        );
        path.close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        break;

      case EdgeMarkerType.circle:
      // 圆点
        canvas.drawCircle(position, size / 2, paint..style = PaintingStyle.fill);
        break;

      case EdgeMarkerType.diamond:
      // 菱形
        final angle = math.atan2(position.dy - opposite.dy, position.dx - opposite.dx);
        final path = Path();
        path.moveTo(position.dx + size * math.cos(angle), position.dy + size * math.sin(angle));
        path.lineTo(
          position.dx + size / 2 * math.cos(angle + math.pi / 2),
          position.dy + size / 2 * math.sin(angle + math.pi / 2),
        );
        path.lineTo(
          position.dx - size * math.cos(angle),
          position.dy - size * math.sin(angle),
        );
        path.lineTo(
          position.dx + size / 2 * math.cos(angle - math.pi / 2),
          position.dy + size / 2 * math.sin(angle - math.pi / 2),
        );
        path.close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        break;

      case EdgeMarkerType.multiple:
      // 多对多标记 (M)
      // TODO: 添加文本绘制
        break;

      case EdgeMarkerType.custom:
      // 自定义文本
      // TODO: 添加文本绘制
        break;

      case EdgeMarkerType.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DefaultEdgePainter oldDelegate) {
    return state != oldDelegate.state ||
        transform != oldDelegate.transform ||
        isDark != oldDelegate.isDark ||
        customPainter != oldDelegate.customPainter;
  }
}

/// 无限网格绘制器
class _InfiniteGridPainter extends CustomPainter {
  final TransformationController transformationController;
  final Color gridColor;
  final double gridSize;
  final Color backgroundColor;
  final int majorGridInterval;
  final Color majorGridColor;

  _InfiniteGridPainter({
    required this.transformationController,
    required this.gridColor,
    required this.gridSize,
    required this.backgroundColor,
    required this.majorGridInterval,
    required this.majorGridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 获取变换矩阵
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // 计算逆变换：虚拟画布坐标 → 场景坐标
    final inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();

    // 可见区域（场景坐标系）
    // 虚拟画布左上角对应场景坐标
    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    // 虚拟画布右下角对应场景坐标
    final bottomRight = MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height));

    // 绘制背景色（填满虚拟画布）
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 网格线宽度根据缩放调整，保持视觉一致
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 / scale
      ..style = PaintingStyle.stroke;

    final majorGridPaint = Paint()
      ..color = majorGridColor
      ..strokeWidth = 1.0 / scale
      ..style = PaintingStyle.stroke;

    final majorGridStep = gridSize * majorGridInterval;

    // 绘制垂直网格线
    // 计算需要绘制的网格线范围（场景坐标）
    var startX = (topLeft.dx / gridSize).floor() * gridSize;
    var endX = (bottomRight.dx / gridSize).ceil() * gridSize;

    for (var x = startX; x <= endX; x += gridSize) {
      // 场景坐标转换为虚拟画布坐标
      final canvasX = MatrixUtils.transformPoint(matrix, Offset(x, 0)).dx;

      // 判断是否为主网格线
      final isMajor = (x % majorGridStep).abs() < 0.001;

      // 绘制整条垂直线（从虚拟画布顶部到底部）
      canvas.drawLine(
        Offset(canvasX, 0),
        Offset(canvasX, size.height),
        isMajor ? majorGridPaint : gridPaint,
      );
    }

    // 绘制水平网格线
    var startY = (topLeft.dy / gridSize).floor() * gridSize;
    var endY = (bottomRight.dy / gridSize).ceil() * gridSize;

    for (var y = startY; y <= endY; y += gridSize) {
      // 场景坐标转换为虚拟画布坐标
      final canvasY = MatrixUtils.transformPoint(matrix, Offset(0, y)).dy;

      // 判断是否为主网格线
      final isMajor = (y % majorGridStep).abs() < 0.001;

      // 绘制整条水平线（从虚拟画布左边到右边）
      canvas.drawLine(
        Offset(0, canvasY),
        Offset(size.width, canvasY),
        isMajor ? majorGridPaint : gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteGridPainter oldDelegate) {
    return transformationController.value != oldDelegate.transformationController.value ||
        gridColor != oldDelegate.gridColor ||
        gridSize != oldDelegate.gridSize ||
        backgroundColor != oldDelegate.backgroundColor ||
        majorGridInterval != oldDelegate.majorGridInterval ||
        majorGridColor != oldDelegate.majorGridColor;
  }
}