import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import '../core/er_graph_builder.dart';
import '../layout/layout_adapter.dart';
import '../models/er_diagram_ui_state.dart';
import '../providers/er_diagram_ui_provider.dart';
import 'er_field_anchor_widget.dart';
import 'er_table_node_widget.dart';

/// ER 图画布
///
/// 使用 graphview 库渲染 ER 图，提供：
/// - 预览模式：左键拖动画布，双击打开预览弹窗
/// - 编辑模式：左键框选/拖动节点，右键拖动画布，双击打开编辑弹窗
class ERDiagramCanvas extends ConsumerStatefulWidget {
  /// 模块 ID
  final String moduleId;

  /// 实体编辑回调（编辑模式双击）
  final void Function(Entity entity)? onEntityEdit;

  /// 实体预览回调（预览模式双击）
  final void Function(Entity entity)? onEntityPreview;

  /// 右键菜单回调
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramCanvas({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onEntityPreview,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramCanvas> createState() => _ERDiagramCanvasState();
}

class _ERDiagramCanvasState extends ConsumerState<ERDiagramCanvas> {
  /// graphview 控制器
  late GraphViewController _graphViewController;

  /// 变换控制器（用于缩放和平移）
  late TransformationController _transformationController;

  /// Graph 构建器
  final ERGraphBuilder _graphBuilder = ERGraphBuilder();

  /// 拖动状态
  String? _draggedNodeId;
  Offset _dragStartPos = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  /// 多选拖动时，其他节点的起始位置
  Map<String, Offset> _multiDragStartPositions = {};

  /// 鼠标位置（用于显示坐标）
  Offset _mousePosition = Offset.zero;

  /// 缓存的算法实例
  Algorithm? _cachedAlgorithm;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _graphViewController = GraphViewController(
      transformationController: _transformationController,
    );

    // 确保所有实体都有对应的图节点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).ensureGraphNodesForEntities(widget.moduleId);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 从 project 读取数据
    final project = ref.watch(projectNotifierProvider).project;
    final module = project?.modules.firstWhere(
      (m) => m.id == widget.moduleId,
      orElse: () => Module.empty,
    );

    // 从 UI provider 读取状态
    final uiState = ref.watch(erDiagramUIProvider(widget.moduleId));

    // 空状态
    if (module == null || module.entities.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // 构建 Graph
    final graph = _graphBuilder.buildGraph(module);

    // 更新缓存的算法
    _cachedAlgorithm ??= NoOpLayoutAlgorithm();

    return Stack(
      children: [
        // 主画布
        _buildMainCanvas(graph, module, uiState, isDark),

        // 工具栏
        Positioned(
          top: 16,
          right: 16,
          child: _buildToolbar(uiState, isDark),
        ),

        // 左下角坐标显示
        Positioned(
          left: 16,
          bottom: 16,
          child: _buildCoordinateDisplay(isDark),
        ),

        // 连线预览
        if (uiState.isConnecting && uiState.connection.sourceAnchor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConnectionPreviewPainter(
                  sourcePos: uiState.connection.sourceAnchor!.position,
                  targetPos: uiState.connection.previewEnd,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade500,
                ),
              ),
            ),
          ),

        // 框选预览
        if (uiState.isSelecting)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionRectPainter(
                  rect: uiState.selection.selectionRect,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建主画布
  Widget _buildMainCanvas(
    Graph graph,
    Module module,
    ERDiagramUIState uiState,
    bool isDark,
  ) {
    // 创建实体映射
    final entityMap = <String, Entity>{};
    final graphNodeMap = <String, GraphNode>{};

    for (final entity in module.entities) {
      entityMap[entity.id] = entity;
    }
    for (final gn in module.graphCanvas.nodes) {
      if (gn.moduleName != null) {
        graphNodeMap[gn.moduleName!] = gn;
      }
    }

    // 背景网格颜色
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Listener(
      onPointerDown: (event) => _onPointerDown(event, uiState),
      onPointerMove: (event) => _onPointerMove(event, uiState),
      onPointerUp: (event) => _onPointerUp(event, uiState, entityMap, graphNodeMap),
      onPointerSignal: (event) => _onPointerSignal(event, uiState),
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });

          // 更新连线预览
          if (uiState.isConnecting) {
            ref.read(erDiagramUIProvider(widget.moduleId).notifier)
                .updateConnectionPreview(event.localPosition);
          }
        },
        child: Stack(
          children: [
            // GraphView 层（包含网格和节点）
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 5.0,
              // 编辑模式下禁用 InteractiveViewer 的内置手势，我们自己处理
              panEnabled: uiState.isPreviewMode,
              scaleEnabled: true,
              child: _ERGraphView(
                graph: graph,
                algorithm: _cachedAlgorithm!,
                controller: _graphViewController,
                nodeBuilder: (node) => _buildNodeWidget(node, entityMap, graphNodeMap, uiState, isDark),
                gridColor: gridColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 指针按下事件
  void _onPointerDown(PointerDownEvent event, ERDiagramUIState uiState) {
    // 右键：编辑模式下拖动画布
    if (event.kind == PointerDeviceKind.mouse && event.buttons == kSecondaryMouseButton) {
      if (uiState.isEditMode) {
        // 编辑模式下右键拖动画布
        // InteractiveViewer 会自动处理，这里不需要额外处理
      }
      return;
    }

    // 左键
    if (event.kind == PointerDeviceKind.mouse && event.buttons == kPrimaryMouseButton) {
      if (uiState.isEditMode) {
        // 编辑模式：开始框选（如果不在节点上）
        // 框选会在节点拖动之后自动取消
        final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
        notifier.startSelection(event.localPosition);
      }
      // 预览模式：InteractiveViewer 自动处理平移
    }
  }

  /// 指针移动事件
  void _onPointerMove(PointerMoveEvent event, ERDiagramUIState uiState) {
    // 左键框选（编辑模式）
    if (event.buttons == kPrimaryMouseButton && uiState.isSelecting) {
      ref.read(erDiagramUIProvider(widget.moduleId).notifier)
          .updateSelection(event.localPosition);
    }

    // 更新连线预览
    if (uiState.isConnecting) {
      ref.read(erDiagramUIProvider(widget.moduleId).notifier)
          .updateConnectionPreview(event.localPosition);
    }
  }

  /// 指针释放事件
  void _onPointerUp(
    PointerUpEvent event,
    ERDiagramUIState uiState,
    Map<String, Entity> entityMap,
    Map<String, GraphNode> graphNodeMap,
  ) {
    // 完成框选
    if (uiState.isSelecting) {
      final nodeRects = _calculateNodeRects(entityMap, graphNodeMap);
      ref.read(erDiagramUIProvider(widget.moduleId).notifier)
          .completeSelection(nodeRects);
    }
  }

  /// 指针信号事件（滚轮缩放）
  void _onPointerSignal(PointerSignalEvent event, ERDiagramUIState uiState) {
    // 滚轮缩放由 InteractiveViewer 自动处理
  }

  /// 计算所有节点的边界矩形
  Map<String, Rect> _calculateNodeRects(
    Map<String, Entity> entityMap,
    Map<String, GraphNode> graphNodeMap,
  ) {
    final rects = <String, Rect>{};
    for (final entry in entityMap.entries) {
      final entity = entry.value;
      final graphNode = graphNodeMap[entity.id];
      if (graphNode != null) {
        final size = ERTableNodeWidget.calculateNodeSize(entity.fields.length);
        rects[entity.id] = Rect.fromLTWH(
          graphNode.x,
          graphNode.y,
          size.width,
          size.height,
        );
      }
    }
    return rects;
  }

  /// 构建节点 Widget
  Widget _buildNodeWidget(
    Node node,
    Map<String, Entity> entityMap,
    Map<String, GraphNode> graphNodeMap,
    ERDiagramUIState uiState,
    bool isDark,
  ) {
    final nodeId = node.key?.value.toString() ?? '';
    final entity = entityMap[nodeId];
    final graphNode = graphNodeMap[nodeId];

    if (entity == null) {
      return _buildPlaceholder(nodeId);
    }

    return ERTableNodeWidget(
      node: node,
      entity: entity,
      graphNode: graphNode ?? GraphNode(title: entity.title, x: 100, y: 100, moduleName: entity.id),
      isSelected: uiState.selectedNodeIds.contains(nodeId),
      interactionMode: uiState.interactionMode,
      isDarkMode: isDark,
      onTap: (isCtrlPressed) => _onNodeTap(nodeId, isCtrlPressed),
      onDoubleTap: () => _onNodeDoubleTap(entity, uiState.isEditMode),
      onDragStart: uiState.isEditMode ? (details) => _onNodeDragStart(nodeId, details, graphNode ?? GraphNode(title: entity.title, x: 100, y: 100, moduleName: entity.id)) : null,
      onDragUpdate: uiState.isEditMode ? (details) => _onNodeDragUpdate(nodeId, details) : null,
      onDragEnd: uiState.isEditMode ? () => _onNodeDragEnd(nodeId) : null,
      onAnchorTap: (anchor, gn) => _onAnchorTap(anchor, gn),
    );
  }

  /// 构建占位 Widget
  Widget _buildPlaceholder(String nodeId) {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Unknown: $nodeId',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(ERDiagramUIState uiState, bool isDark) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

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
          // 预览模式按钮
          TDButton(
            theme: uiState.isPreviewMode
                ? TDButtonTheme.primary
                : TDButtonTheme.defaultTheme,
            icon: Icons.pan_tool,
            onTap: () => notifier.enterPreviewMode(),
          ),
          const SizedBox(width: 4),
          // 编辑模式按钮
          TDButton(
            theme: uiState.isEditMode
                ? TDButtonTheme.primary
                : TDButtonTheme.defaultTheme,
            icon: TDIcons.edit,
            onTap: () => notifier.enterEditMode(),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(width: 8),
          // 缩放按钮
          TDButton(
            icon: TDIcons.zoom_in,
            onTap: _zoomIn,
          ),
          const SizedBox(width: 4),
          TDButton(
            icon: TDIcons.zoom_out,
            onTap: _zoomOut,
          ),
          const SizedBox(width: 4),
          TDButton(
            icon: TDIcons.fullscreen,
            onTap: _fitToScreen,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(width: 8),
          // 布局按钮
          TDButton(
            icon: TDIcons.view_module,
            onTap: () => _autoLayout(),
          ),
        ],
      ),
    );
  }

  /// 构建坐标显示
  Widget _buildCoordinateDisplay(bool isDark) {
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
        'X: ${_mousePosition.dx.toStringAsFixed(0)}  Y: ${_mousePosition.dy.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无实体表',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先创建实体表',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 事件处理
  // ═══════════════════════════════════════════════════════════════════

  /// 节点点击事件
  /// [isCtrlPressed] 是否按下 Ctrl 键（用于多选）
  void _onNodeTap(String nodeId, bool isCtrlPressed) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

    if (isCtrlPressed) {
      // Ctrl+点击：多选行为
      notifier.selectNodeMultiple(nodeId);
    } else {
      // 单击：单选行为
      notifier.selectNodeSingle(nodeId);
    }

    // 取消框选（如果在框选）
    final uiState = ref.read(erDiagramUIProvider(widget.moduleId));
    if (uiState.isSelecting) {
      notifier.cancelSelection();
    }
  }

  void _onNodeDoubleTap(Entity entity, bool isEditMode) {
    if (isEditMode) {
      widget.onEntityEdit?.call(entity);
    } else {
      widget.onEntityPreview?.call(entity);
    }
  }

  void _onNodeDragStart(String nodeId, DragStartDetails details, GraphNode graphNode) {
    // 取消框选
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
    final currentUiState = ref.read(erDiagramUIProvider(widget.moduleId));
    if (currentUiState.isSelecting) {
      notifier.cancelSelection();
    }

    // 记录拖动起始位置
    setState(() {
      _draggedNodeId = nodeId;
      _dragStartPos = details.localPosition;
      _nodeStartPos = Offset(graphNode.x, graphNode.y);
    });

    // 开始拖动（会处理多选情况）
    notifier.startDragging(nodeId);

    // 如果有多个选中节点，记录它们的起始位置
    final draggingNodes = ref.read(erDiagramUIProvider(widget.moduleId)).draggingNodeIds;
    if (draggingNodes.length > 1) {
      final project = ref.read(projectNotifierProvider).project;
      final module = project?.modules.firstWhere((m) => m.id == widget.moduleId, orElse: () => Module.empty);
      if (module != null) {
        _multiDragStartPositions = {};
        for (final gn in module.graphCanvas.nodes) {
          if (gn.moduleName != null && draggingNodes.contains(gn.moduleName!)) {
            _multiDragStartPositions[gn.moduleName!] = Offset(gn.x, gn.y);
          }
        }
      }
    } else {
      _multiDragStartPositions = {};
    }
  }

  ERDiagramUIState get uiState => ref.read(erDiagramUIProvider(widget.moduleId));

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    if (_draggedNodeId != nodeId) return;

    // 计算偏移量
    final delta = details.localPosition - _dragStartPos;

    // 获取当前拖动的节点集合
    final draggingNodes = ref.read(erDiagramUIProvider(widget.moduleId)).draggingNodeIds;

    if (draggingNodes.length > 1 && _multiDragStartPositions.isNotEmpty) {
      // 多选拖动：移动所有选中的节点
      for (final entry in _multiDragStartPositions.entries) {
        final newX = entry.value.dx + delta.dx;
        final newY = entry.value.dy + delta.dy;
        ref.read(projectNotifierProvider.notifier)
            .updateGraphNode(widget.moduleId, entry.key, newX, newY);
      }
    } else {
      // 单节点拖动
      final newX = _nodeStartPos.dx + delta.dx;
      final newY = _nodeStartPos.dy + delta.dy;
      ref.read(projectNotifierProvider.notifier)
          .updateGraphNode(widget.moduleId, nodeId, newX, newY);
    }
  }

  void _onNodeDragEnd(String nodeId) {
    if (_draggedNodeId != nodeId) return;

    setState(() {
      _draggedNodeId = null;
      _multiDragStartPositions = {};
    });

    ref.read(erDiagramUIProvider(widget.moduleId).notifier).endDragging();
  }

  void _onAnchorTap(ERFieldAnchor anchor, GraphNode graphNode) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

    // 计算锚点的实际位置（基于节点当前位置）
    final rowY = ERTableNodeWidget.headerHeight + (anchor.fieldIndex * ERTableNodeWidget.fieldRowHeight) + ERTableNodeWidget.fieldRowHeight / 2;
    final anchorPosition = Offset(
      anchor.direction == ERAnchorDirection.left
          ? graphNode.x - ERFieldAnchorWidget.anchorOffset
          : graphNode.x + ERTableNodeWidget.defaultWidth + ERFieldAnchorWidget.anchorOffset,
      graphNode.y + rowY,
    );

    // 更新锚点位置
    final updatedAnchor = ERFieldAnchor(
      nodeId: anchor.nodeId,
      fieldIndex: anchor.fieldIndex,
      direction: anchor.direction,
      position: anchorPosition,
    );

    if (!ref.read(erDiagramUIProvider(widget.moduleId)).isConnecting) {
      // 开始连线
      notifier.startConnection(updatedAnchor);
    } else {
      // 完成连线
      notifier.completeConnection(updatedAnchor);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 缩放和布局
  // ═══════════════════════════════════════════════════════════════════

  void _zoomIn() {
    final matrix = _transformationController.value;
    final newMatrix = matrix.clone()..scale(1.2);
    _transformationController.value = newMatrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value;
    final newMatrix = matrix.clone()..scale(1 / 1.2);
    _transformationController.value = newMatrix;
  }

  void _fitToScreen() {
    _graphViewController.zoomToFit();
  }

  void _autoLayout() {
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;

    final module = project.modules.firstWhere(
      (m) => m.id == widget.moduleId,
      orElse: () => Module.empty,
    );
    if (module.entities.isEmpty) return;

    // 使用 Sugiyama 布局
    final config = SugiyamaConfiguration()
      ..nodeSeparation = 200
      ..levelSeparation = 150
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..iterations = 24;

    final algorithm = SugiyamaAlgorithm(config);
    final graph = _graphBuilder.buildGraph(module);
    algorithm.run(graph, 500, 400);

    // 收集新位置
    final positions = <String, Offset>{};
    for (final node in graph.nodes) {
      final nodeId = node.key?.value.toString() ?? '';
      positions[nodeId] = Offset(node.x, node.y);
    }

    // 应用布局
    ref.read(erDiagramUIProvider(widget.moduleId).notifier).applyLayout(positions);
  }
}

/// 连线预览绘制器
class _ConnectionPreviewPainter extends CustomPainter {
  final Offset sourcePos;
  final Offset targetPos;
  final Color color;

  _ConnectionPreviewPainter({
    required this.sourcePos,
    required this.targetPos,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, sourcePos, targetPos, paint);
    _drawArrow(canvas, targetPos, sourcePos, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = dx * dx + dy * dy;

    if (distance == 0) return;

    final length = math.sqrt(distance);
    final unitX = dx / length;
    final unitY = dy / length;

    var currentDistance = 0.0;
    while (currentDistance < length) {
      final dashStartX = start.dx + unitX * currentDistance;
      final dashStartY = start.dy + unitY * currentDistance;
      final dashEndX = start.dx + unitX * (currentDistance + dashLength).clamp(0.0, length);
      final dashEndY = start.dy + unitY * (currentDistance + dashLength).clamp(0.0, length);

      canvas.drawLine(
        Offset(dashStartX, dashStartY),
        Offset(dashEndX, dashEndY),
        paint,
      );

      currentDistance += dashLength + gapLength;
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset base, Paint paint) {
    const arrowSize = 10.0;

    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final angle = math.atan2(dy, dx);

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - math.pi / 6),
      tip.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + math.pi / 6),
      tip.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ConnectionPreviewPainter oldDelegate) {
    return sourcePos != oldDelegate.sourcePos ||
        targetPos != oldDelegate.targetPos ||
        color != oldDelegate.color;
  }
}

/// 框选矩形绘制器
class _SelectionRectPainter extends CustomPainter {
  final Rect rect;
  final Color color;

  _SelectionRectPainter({
    required this.rect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 边框
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionRectPainter oldDelegate) {
    return rect != oldDelegate.rect || color != oldDelegate.color;
  }
}

/// 自定义 ER 图 GraphView
///
/// 解决 graphview 库的 bug: GraphChildDelegate.getVisibleGraphOnly()
/// 在没有边时只渲染第一个节点。
/// 这个自定义组件确保所有节点都被渲染。
class _ERGraphView extends StatelessWidget {
  final Graph graph;
  final Algorithm algorithm;
  final GraphViewController? controller;
  final Widget Function(Node node) nodeBuilder;
  final Color gridColor;
  final bool isDark;

  /// 虚拟画布的固定大小（足够大以支持平移和缩放）
  static const double virtualCanvasWidth = 2000.0;
  static const double virtualCanvasHeight = 1500.0;

  const _ERGraphView({
    required this.graph,
    required this.algorithm,
    this.controller,
    required this.nodeBuilder,
    required this.gridColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 运行布局算法
    algorithm.run(graph, 0, 0);

    // 直接渲染所有节点和边，使用固定大小的虚拟画布
    return SizedBox(
      width: virtualCanvasWidth,
      height: virtualCanvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景层（网格和底色）
          Positioned.fill(
            child: GridPaper(
              color: gridColor,
              divisions: 1,
              subdivisions: 1,
              interval: 20,
              child: Container(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA),
              ),
            ),
          ),
          // 边层
          CustomPaint(
            painter: _EdgePainter(
              graph: graph,
              algorithm: algorithm,
            ),
            size: const Size(virtualCanvasWidth, virtualCanvasHeight),
          ),
          // 节点层
          for (final node in graph.nodes)
            Positioned(
              left: node.x,
              top: node.y,
              child: nodeBuilder(node),
            ),
        ],
      ),
    );
  }
}

/// 边绘制器
class _EdgePainter extends CustomPainter {
  final Graph graph;
  final Algorithm algorithm;

  _EdgePainter({
    required this.graph,
    required this.algorithm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (final edge in graph.edges) {
      algorithm.renderer?.renderEdge(canvas, edge, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) {
    return graph != oldDelegate.graph;
  }
}
