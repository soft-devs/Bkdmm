import 'dart:math' as math;
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
import 'er_node_widget_new.dart';

/// ER 图画布（重构版）
///
/// 使用 graphview 库渲染 ER 图，提供：
/// - 节点拖拽（编辑模式）
/// - 字段级连线（编辑模式）
/// - 自动布局
/// - 缩放/平移
class ERDiagramCanvasNew extends ConsumerStatefulWidget {
  /// 模块 ID
  final String moduleId;

  /// 实体编辑回调
  final void Function(Entity entity)? onEntityEdit;

  /// 右键菜单回调
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramCanvasNew({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramCanvasNew> createState() => _ERDiagramCanvasNewState();
}

class _ERDiagramCanvasNewState extends ConsumerState<ERDiagramCanvasNew> {
  /// graphview 控制器
  late GraphViewController _graphViewController;

  /// Graph 构建器
  final ERGraphBuilder _graphBuilder = ERGraphBuilder();

  /// 拖动状态
  String? _draggedNodeId;
  Offset _dragStartPos = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  /// 鼠标位置（用于显示坐标）
  Offset _mousePosition = Offset.zero;

  /// 缓存的算法实例
  Algorithm? _cachedAlgorithm;

  @override
  void initState() {
    super.initState();
    _graphViewController = GraphViewController();
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
    _cachedAlgorithm ??= NoOpLayoutAlgorithm(
      anchorRegistry: null,
      isDarkMode: isDark,
    );

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

    return MouseRegion(
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
          // 背景网格层
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
          // GraphView 层
          GraphView.builder(
            graph: graph,
            algorithm: _cachedAlgorithm!,
            controller: _graphViewController,
            builder: (node) => _buildNodeWidget(node, entityMap, graphNodeMap, uiState, isDark),
            animated: false,
          ),
        ],
      ),
    );
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

    return ERTableNodeWidgetNew(
      node: node,
      entity: entity,
      graphNode: graphNode ?? GraphNode(title: entity.title, x: 100, y: 100, moduleName: entity.id),
      isSelected: uiState.selectedNodeIds.contains(nodeId),
      showAnchors: uiState.isEditMode,
      isDraggable: uiState.isEditMode,
      isDarkMode: isDark,
      onTap: () => _onNodeTap(nodeId),
      onDoubleTap: () => _onNodeDoubleTap(entity),
      onDragStart: uiState.isEditMode ? (details) => _onNodeDragStart(nodeId, details, graphNode!) : null,
      onDragUpdate: uiState.isEditMode ? (details) => _onNodeDragUpdate(nodeId, details) : null,
      onDragEnd: uiState.isEditMode ? () => _onNodeDragEnd(nodeId) : null,
      onAnchorTap: (anchor) => _onAnchorTap(anchor, entity, graphNode!),
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
          // 移动模式按钮
          TDButton(
            theme: uiState.isMoveMode
                ? TDButtonTheme.primary
                : TDButtonTheme.defaultTheme,
            icon: Icons.pan_tool,
            onTap: () => notifier.enterMoveMode(),
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

  void _onNodeTap(String nodeId) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
    notifier.selectNode(nodeId, addToSelection: true);
  }

  void _onNodeDoubleTap(Entity entity) {
    widget.onEntityEdit?.call(entity);
  }

  void _onNodeDragStart(String nodeId, DragStartDetails details, GraphNode graphNode) {
    setState(() {
      _draggedNodeId = nodeId;
      _dragStartPos = details.localPosition;
      _nodeStartPos = Offset(graphNode.x, graphNode.y);
    });

    ref.read(erDiagramUIProvider(widget.moduleId).notifier).startDragging(nodeId);
  }

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    if (_draggedNodeId != nodeId) return;

    // 计算新位置
    final delta = details.localPosition - _dragStartPos;
    final newX = _nodeStartPos.dx + delta.dx;
    final newY = _nodeStartPos.dy + delta.dy;

    // 直接更新到 Project
    ref.read(projectNotifierProvider.notifier)
        .updateGraphNode(widget.moduleId, nodeId, newX, newY);
  }

  void _onNodeDragEnd(String nodeId) {
    if (_draggedNodeId != nodeId) return;

    setState(() {
      _draggedNodeId = null;
    });

    ref.read(erDiagramUIProvider(widget.moduleId).notifier).endDragging();
  }

  void _onAnchorTap(ERFieldAnchor anchor, Entity entity, GraphNode graphNode) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

    if (!ref.read(erDiagramUIProvider(widget.moduleId)).isConnecting) {
      // 开始连线
      notifier.startConnection(anchor);
    } else {
      // 完成连线
      notifier.completeConnection(anchor);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 缩放和布局
  // ═══════════════════════════════════════════════════════════════════

  void _zoomIn() {
    _graphViewController.zoomToFit();
  }

  void _zoomOut() {
    _graphViewController.zoomToFit();
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
