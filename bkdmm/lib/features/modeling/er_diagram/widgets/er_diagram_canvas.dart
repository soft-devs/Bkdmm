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

  /// 是否正在右键拖动画布
  bool _isRightDragging = false;

  /// 右键拖动起始位置
  Offset _rightDragStart = Offset.zero;

  /// 右键拖动起始变换
  Matrix4 _rightDragTransformStart = Matrix4.identity();

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
      behavior: HitTestBehavior.translucent,
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
            // 无限网格背景层（在 InteractiveViewer 外部，使用屏幕坐标绘制）
            // 使用 ListenableBuilder 监听变换控制器变化以重绘网格
            Positioned.fill(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _transformationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _InfiniteGridPainter(
                        transformationController: _transformationController,
                        gridColor: gridColor,
                        gridSize: 20.0,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
            // GraphView 层（节点和边）
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 指针按下事件（右键拖动画布 + 编辑模式框选）
  void _onPointerDown(PointerDownEvent event, ERDiagramUIState uiState) {
    debugPrint('[ERCanvas] _onPointerDown: localPosition=${event.localPosition}, buttons=${event.buttons}, kind=${event.kind}');

    // 右键：编辑模式下拖动画布
    if (event.kind == PointerDeviceKind.mouse && event.buttons == kSecondaryMouseButton) {
      debugPrint('[ERCanvas] 右键按下，编辑模式=${uiState.isEditMode}');
      if (uiState.isEditMode) {
        // 编辑模式下手动处理右键拖动画布
        _isRightDragging = true;
        _rightDragStart = event.localPosition;
        _rightDragTransformStart = _transformationController.value.clone();
      }
      return;
    }

    // 左键：编辑模式下开始框选（仅当点击在空白区域时）
    if (event.kind == PointerDeviceKind.mouse && event.buttons == kPrimaryMouseButton) {
      debugPrint('[ERCanvas] 左键按下，编辑模式=${uiState.isEditMode}');
      if (uiState.isEditMode) {
        // 检查是否点击在节点上
        final project = ref.read(projectNotifierProvider).project;
        final module = project?.modules.firstWhere(
          (m) => m.id == widget.moduleId,
          orElse: () => Module.empty,
        );

        bool clickedOnNode = false;
        if (module != null) {
          // 将屏幕坐标转换为画布坐标
          // InteractiveViewer 的变换矩阵：canvas_pos = transform * screen_pos
          // 我们需要：canvas_pos = inverse(transform) * screen_pos
          final transform = _transformationController.value;
          final inverseTransform = Matrix4.inverted(transform);
          final canvasPos = MatrixUtils.transformPoint(inverseTransform, event.localPosition);

          debugPrint('[ERCanvas] 屏幕坐标=${event.localPosition}, 画布坐标=$canvasPos, 变换矩阵=$transform');

          // 检查每个节点
          for (final entity in module.entities) {
            final graphNode = module.graphCanvas.nodes.firstWhere(
              (gn) => gn.moduleName == entity.id,
              orElse: () => GraphNode(title: '', x: 0, y: 0),
            );
            if (graphNode.moduleName == null) continue;

            final nodeSize = ERTableNodeWidget.calculateNodeSize(entity.fields.length);
            final nodeRect = Rect.fromLTWH(
              graphNode.x,
              graphNode.y,
              nodeSize.width,
              nodeSize.height,
            );

            debugPrint('[ERCanvas] 节点 ${entity.title}: 位置=(${graphNode.x}, ${graphNode.y}), rect=$nodeRect');

            // 扩大点击区域以包含锚点
            final expandedRect = nodeRect.inflate(ERFieldAnchorWidget.hitSize);
            if (expandedRect.contains(canvasPos)) {
              debugPrint('[ERCanvas] 点击在节点 ${entity.title} 上');
              clickedOnNode = true;
              break;
            }
          }

          debugPrint('[ERCanvas] clickedOnNode=$clickedOnNode');
        }

        // 仅当点击在空白区域时启动框选
        if (!clickedOnNode) {
          final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
          notifier.startSelection(event.localPosition);
        }
      }
    }
  }

  /// 指针移动事件（右键拖动画布 + 编辑模式框选）
  void _onPointerMove(PointerMoveEvent event, ERDiagramUIState uiState) {
    // 右键拖动画布（编辑模式）
    if (event.buttons == kSecondaryMouseButton && _isRightDragging) {
      final delta = event.localPosition - _rightDragStart;
      final newMatrix = _rightDragTransformStart.clone();
      newMatrix.translate(delta.dx, delta.dy);
      _transformationController.value = newMatrix;
      return;
    }

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
    // 结束右键拖动
    if (_isRightDragging) {
      _isRightDragging = false;
      return;
    }

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

  /// 虚拟画布大小（足够大以支持无限画布效果）
  /// 配合 InteractiveViewer 的 boundaryMargin: EdgeInsets.all(double.infinity) 使用
  static const double virtualCanvasSize = 50000.0;

  const _ERGraphView({
    required this.graph,
    required this.algorithm,
    this.controller,
    required this.nodeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 运行布局算法
    algorithm.run(graph, 0, 0);

    // 使用超大虚拟画布，配合 InteractiveViewer 的 boundaryMargin 实现无限画布效果
    // 注意：背景色由外部的 _InfiniteGridPainter 绘制，这里不绘制背景
    return SizedBox(
      width: virtualCanvasSize,
      height: virtualCanvasSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 边层
          CustomPaint(
            painter: _EdgePainter(
              graph: graph,
              algorithm: algorithm,
            ),
            size: const Size(virtualCanvasSize, virtualCanvasSize),
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

/// 无限网格绘制器
///
/// 在 InteractiveViewer 外部绘制网格，根据变换矩阵计算可见区域，
/// 实现真正的无限网格效果。
class _InfiniteGridPainter extends CustomPainter {
  final TransformationController transformationController;
  final Color gridColor;
  final double gridSize;
  final bool isDark;

  _InfiniteGridPainter({
    required this.transformationController,
    required this.gridColor,
    required this.gridSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 获取变换矩阵
    final matrix = transformationController.value;

    // 计算缩放比例
    final scale = matrix.getMaxScaleOnAxis();

    // 计算平移偏移（屏幕坐标 -> 场景坐标的逆变换）
    final inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();

    // 可见区域在场景坐标系中的范围
    // 屏幕左上角对应场景坐标
    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    // 屏幕右下角对应场景坐标
    final bottomRight = MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height));

    // 绘制背景色
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 绘制网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 / scale // 保持网格线宽度在视觉上一致
      ..style = PaintingStyle.stroke;

    // 计算网格起始位置（对齐到网格）
    final startX = (topLeft.dx / gridSize).floor() * gridSize;
    final endX = (bottomRight.dx / gridSize).ceil() * gridSize;
    final startY = (topLeft.dy / gridSize).floor() * gridSize;
    final endY = (bottomRight.dy / gridSize).ceil() * gridSize;

    // 绘制垂直网格线
    for (var x = startX; x <= endX; x += gridSize) {
      // 将场景坐标转换为屏幕坐标
      final screenX = MatrixUtils.transformPoint(matrix, Offset(x, 0)).dx;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, size.height),
        gridPaint,
      );
    }

    // 绘制水平网格线
    for (var y = startY; y <= endY; y += gridSize) {
      // 将场景坐标转换为屏幕坐标
      final screenY = MatrixUtils.transformPoint(matrix, Offset(0, y)).dy;
      canvas.drawLine(
        Offset(0, screenY),
        Offset(size.width, screenY),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteGridPainter oldDelegate) {
    // 当变换矩阵、网格颜色、网格大小或暗色模式变化时重绘
    return transformationController.value != oldDelegate.transformationController.value ||
        gridColor != oldDelegate.gridColor ||
        gridSize != oldDelegate.gridSize ||
        isDark != oldDelegate.isDark;
  }
}
