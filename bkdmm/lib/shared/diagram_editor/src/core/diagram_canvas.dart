import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_state.dart';

/// 图表画布抽象基类
///
/// 提供通用的画布功能：缩放、平移、选择、拖拽
/// 子类需要实现具体的节点和边渲染逻辑
abstract class DiagramCanvas extends ConsumerStatefulWidget {
  /// 图表 ID
  final String diagramId;

  /// 图表类型
  final String diagramType;

  /// 是否显示工具栏
  final bool showToolbar;

  /// 是否显示网格
  final bool showGrid;

  /// 是否启用选择
  final bool enableSelection;

  /// 是否启用拖拽
  final bool enableDrag;

  /// 是否启用连线
  final bool enableConnection;

  /// 节点双击回调
  final void Function(DiagramNode node)? onNodeDoubleTap;

  /// 节点右键菜单回调
  final void Function(DiagramNode? node, Offset position)? onNodeContextMenu;

  /// 边双击回调
  final void Function(DiagramEdge edge)? onEdgeDoubleTap;

  /// 空白区域右键菜单回调
  final void Function(Offset position)? onCanvasContextMenu;

  const DiagramCanvas({
    super.key,
    required this.diagramId,
    required this.diagramType,
    this.showToolbar = true,
    this.showGrid = true,
    this.enableSelection = true,
    this.enableDrag = true,
    this.enableConnection = true,
    this.onNodeDoubleTap,
    this.onNodeContextMenu,
    this.onEdgeDoubleTap,
    this.onCanvasContextMenu,
  });

  // Note: Concrete subclasses must override createState() and return
  // a concrete implementation of DiagramCanvasState
}

/// 图表画布状态基类
///
/// 管理通用的画布状态和交互逻辑
/// 子类需要实现 watchDiagramState, _createDiagramPainter, _calculateCanvasSize
abstract class DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  /// 变换控制器（用于 InteractiveViewer）
  final TransformationController transformController = TransformationController();

  /// 当前交互状态
  InteractionState interactionState = const InteractionState();

  /// 当前选择状态
  SelectionState selectionState = const SelectionState();

  /// 当前视口状态
  ViewportState viewportState = const ViewportState();

  /// 拖拽起始位置
  Offset dragStartPosition = Offset.zero;

  /// 节点拖拽起始位置
  Offset nodeDragStartPosition = Offset.zero;

  /// 双击检测
  String? lastTappedNodeId;
  DateTime? lastTapTime;
  static const Duration doubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    transformController.removeListener(_onTransformChanged);
    transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final matrix = transformController.value;
    final zoom = matrix.getMaxScaleOnAxis();
    final panOffset = MatrixUtils.transformPoint(matrix, Offset.zero);

    setState(() {
      viewportState = viewportState.copyWith(
        zoom: zoom,
        panOffset: panOffset,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset local) {
    final matrix = transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, local);
  }

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return MatrixUtils.transformPoint(transformController.value, scene);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 视口操作
  // ═══════════════════════════════════════════════════════════════════

  /// 放大
  void zoomIn() {
    final currentZoom = transformController.value.getMaxScaleOnAxis();
    final newZoom = (currentZoom * 1.2).clamp(0.1, 5.0);
    transformController.value = Matrix4.identity()..scale(newZoom);
  }

  /// 缩小
  void zoomOut() {
    final currentZoom = transformController.value.getMaxScaleOnAxis();
    final newZoom = (currentZoom / 1.2).clamp(0.1, 5.0);
    transformController.value = Matrix4.identity()..scale(newZoom);
  }

  /// 重置视口
  void resetViewport() {
    transformController.value = Matrix4.identity();
  }

  /// 适应内容到视口
  void fitContent(Rect contentBounds, Size viewportSize) {
    if (contentBounds == Rect.zero) return;

    final padding = 50.0;
    final contentWidth = contentBounds.width + padding * 2;
    final contentHeight = contentBounds.height + padding * 2;

    final scaleX = viewportSize.width / contentWidth;
    final scaleY = viewportSize.height / contentHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 2.0);

    final offsetX = (viewportSize.width - contentWidth * scale) / 2 -
        contentBounds.left * scale + padding * scale;
    final offsetY = (viewportSize.height - contentHeight * scale) / 2 -
        contentBounds.top * scale + padding * scale;

    transformController.value = Matrix4.identity()
      ..scale(scale)
      ..translate(offsetX / scale, offsetY / scale);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 选择操作
  // ═══════════════════════════════════════════════════════════════════

  /// 选择节点
  void selectNode(String nodeId, {bool addToSelection = false}) {
    Set<String> newSelection;
    if (addToSelection) {
      newSelection = Set<String>.from(selectionState.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
    } else {
      newSelection = {nodeId};
    }
    setState(() {
      selectionState = selectionState.copyWith(selectedNodeIds: newSelection);
    });
  }

  /// 取消选择
  void clearSelection() {
    setState(() {
      selectionState = selectionState.copyWith(
        selectedNodeIds: const {},
        selectedEdgeIds: const {},
      );
    });
  }

  /// 全选
  void selectAll(Map<String, DiagramNode> nodes) {
    setState(() {
      selectionState = selectionState.copyWith(
        selectedNodeIds: Set<String>.from(nodes.keys),
      );
    });
  }

  /// 设置悬停节点
  void setHoveredNode(String? nodeId) {
    if (selectionState.hoveredNodeId != nodeId) {
      setState(() {
        selectionState = selectionState.copyWith(hoveredNodeId: nodeId);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 交互模式
  // ═══════════════════════════════════════════════════════════════════

  /// 设置交互模式
  void setInteractionMode(InteractionMode mode) {
    setState(() {
      interactionState = interactionState.copyWith(mode: mode);
    });
  }

  /// 切换交互模式
  void toggleInteractionMode() {
    final newMode = interactionState.mode == InteractionMode.move
        ? InteractionMode.edit
        : InteractionMode.move;
    setInteractionMode(newMode);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 构建方法
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final diagramState = watchDiagramState();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 主画布
        SizedBox.expand(
          child: MouseRegion(
            cursor: _getCursor(diagramState),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: InteractiveViewer(
                transformationController: transformController,
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false,
                panEnabled: interactionState.isIdle && interactionState.mode == InteractionMode.move,
                scaleEnabled: true,
                child: CustomPaint(
                  size: _calculateCanvasSize(diagramState),
                  painter: _createDiagramPainter(diagramState, isDark),
                ),
              ),
            ),
          ),
        ),

        // 工具栏
        if (widget.showToolbar)
          Positioned(
            top: 12,
            right: 12,
            child: _buildToolbar(diagramState, isDark),
          ),

        // 连线预览
        if (interactionState.isConnecting && interactionState.connectionPreviewEnd != null)
          _buildConnectionPreview(isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 抽象方法（由子类实现）
  // ═══════════════════════════════════════════════════════════════════

  /// 获取图表状态（子类从 Provider 获取）
  DiagramState watchDiagramState();

  /// 创建图表绘制器
  CustomPainter _createDiagramPainter(DiagramState state, bool isDark);

  /// 计算画布尺寸
  Size _calculateCanvasSize(DiagramState state);

  /// 构建工具栏
  Widget _buildToolbar(DiagramState state, bool isDark) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 模式切换
            IconButton(
              icon: Icon(interactionState.mode == InteractionMode.edit
                  ? Icons.edit
                  : Icons.pan_tool),
              tooltip: interactionState.mode == InteractionMode.edit
                  ? 'Edit Mode'
                  : 'Move Mode',
              onPressed: toggleInteractionMode,
            ),

            const VerticalDivider(),

            // 缩放控制
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom In',
              onPressed: zoomIn,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom Out',
              onPressed: zoomOut,
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Fit to Screen',
              onPressed: resetViewport,
            ),

            const VerticalDivider(),

            // 布局
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Auto Layout',
              onPressed: () => _autoLayout(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建连线预览
  Widget _buildConnectionPreview(bool isDark) {
    // 子类可以覆盖此方法
    return const SizedBox.shrink();
  }

  /// 获取鼠标光标
  MouseCursor _getCursor(DiagramState state) {
    switch (interactionState.type) {
      case InteractionType.nodeDrag:
        return SystemMouseCursors.grabbing;
      case InteractionType.edgeCreate:
        return SystemMouseCursors.click;
      case InteractionType.pan:
        return SystemMouseCursors.grab;
      default:
        if (interactionState.mode == InteractionMode.move) {
          return SystemMouseCursors.grab;
        }
        return SystemMouseCursors.basic;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 手势处理
  // ═══════════════════════════════════════════════════════════════════

  void _onPointerDown(PointerDownEvent event) {
    // 子类覆盖实现具体逻辑
  }

  void _onPointerMove(PointerMoveEvent event) {
    // 子类覆盖实现具体逻辑
  }

  void _onPointerUp(PointerUpEvent event) {
    // 子类覆盖实现具体逻辑
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _resetInteraction();
  }

  void _resetInteraction() {
    setState(() {
      interactionState = const InteractionState();
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // 布局
  // ═══════════════════════════════════════════════════════════════════

  void _autoLayout() {
    // 子类覆盖实现具体布局逻辑
  }
}

/// 图表画布绘制器基类
///
/// 提供通用的绘制逻辑，子类需要实现具体节点和边的绘制
abstract class DiagramPainter extends CustomPainter {
  final DiagramState state;
  final bool isDarkMode;
  final bool showGrid;
  final bool showAnchors;

  DiagramPainter({
    required this.state,
    this.isDarkMode = false,
    this.showGrid = true,
    this.showAnchors = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // 应用变换
    canvas.save();
    canvas.scale(state.viewport.zoom, state.viewport.zoom);
    canvas.translate(
      state.viewport.panOffset.dx / state.viewport.zoom,
      state.viewport.panOffset.dy / state.viewport.zoom,
    );

    // 绘制边（在节点下方）
    drawEdges(canvas, size);

    // 绘制节点
    drawNodes(canvas, size);

    canvas.restore();
  }

  /// 绘制网格
  void _drawGrid(Canvas canvas, Size size) {
    const gridSize = 20.0;
    final gridPaint = Paint()
      ..color = isDarkMode
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    // 计算可见区域
    final visibleRect = Rect.fromLTWH(
      -state.viewport.panOffset.dx / state.viewport.zoom,
      -state.viewport.panOffset.dy / state.viewport.zoom,
      size.width / state.viewport.zoom,
      size.height / state.viewport.zoom,
    );

    // 绘制垂直线
    final startX = (visibleRect.left / gridSize).floor() * gridSize;
    for (var x = startX; x <= visibleRect.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, visibleRect.top),
        Offset(x, visibleRect.bottom),
        gridPaint,
      );
    }

    // 绘制水平线
    final startY = (visibleRect.top / gridSize).floor() * gridSize;
    for (var y = startY; y <= visibleRect.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(visibleRect.left, y),
        Offset(visibleRect.right, y),
        gridPaint,
      );
    }
  }

  /// 绘制所有节点（子类实现）
  void drawNodes(Canvas canvas, Size size);

  /// 绘制所有边（子类实现）
  void drawEdges(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant DiagramPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDarkMode != isDarkMode;
  }
}