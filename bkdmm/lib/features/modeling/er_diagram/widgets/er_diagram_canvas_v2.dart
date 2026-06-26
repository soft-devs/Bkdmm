/// ER 图画布 V2
///
/// 使用新的 DiagramEditor 框架重构的 ER 图画布。
/// 通过 ERInteractionManager 统一管理所有交互事件。
library;

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/utils/logging/logging_service.dart';
import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';
import '../core/er_graph_builder.dart';
import '../layout/layout_adapter.dart';
import '../models/er_diagram_ui_state.dart';
import '../providers/er_diagram_ui_provider.dart';
import 'er_field_anchor_widget.dart';
import 'er_table_node_widget.dart';

/// ER 图画布 V2
///
/// 使用 ERInteractionManager 处理所有交互事件：
/// - 预览模式：左键拖动画布，双击打开预览弹窗
/// - 编辑模式：左键框选/拖动节点，右键拖动画布，双击打开编辑弹窗
class ERDiagramCanvasV2 extends ConsumerStatefulWidget {
  /// 模块 ID
  final String moduleId;

  /// 实体编辑回调（编辑模式双击）
  final void Function(Entity entity)? onEntityEdit;

  /// 实体预览回调（预览模式双击）
  final void Function(Entity entity)? onEntityPreview;

  /// 右键菜单回调
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramCanvasV2({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onEntityPreview,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramCanvasV2> createState() => _ERDiagramCanvasV2State();
}

class _ERDiagramCanvasV2State extends ConsumerState<ERDiagramCanvasV2> {
  /// graphview 控制器
  late GraphViewController _graphViewController;

  /// 变换控制器（用于缩放和平移）
  late TransformationController _transformationController;

  /// Graph 构建器
  final ERGraphBuilder _graphBuilder = ERGraphBuilder();

  /// 交互管理器
  late ERInteractionManager _interactionManager;

  /// 缓存的算法实例
  Algorithm? _cachedAlgorithm;

  /// 鼠标位置（用于显示坐标）
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _graphViewController = GraphViewController(
      transformationController: _transformationController,
    );
    _interactionManager = ERInteractionManager(
      transformController: _transformationController,
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

    // 同步交互模式
    _syncInteractionMode(uiState);

    // 更新空间索引
    _updateSpatialIndex(module);

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

  /// 同步交互模式
  void _syncInteractionMode(ERDiagramUIState uiState) {
    if (uiState.isEditMode && _interactionManager.state.isPreviewMode) {
      _interactionManager.enterEditMode();
    } else if (uiState.isPreviewMode && _interactionManager.state.isEditMode) {
      _interactionManager.enterPreviewMode();
    }
  }

  /// 更新空间索引
  void _updateSpatialIndex(Module module) {
    _interactionManager.clearIndex();

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

      // 添加节点到索引
      _interactionManager.updateNodeInIndex(entity.id, nodeRect);

      // 添加锚点到索引
      for (var i = 0; i < entity.fields.length; i++) {
        final rowY = ERTableNodeWidget.headerHeight +
            (i * ERTableNodeWidget.fieldRowHeight) +
            ERTableNodeWidget.fieldRowHeight / 2;

        // 左锚点
        final leftAnchorRect = Rect.fromLTWH(
          graphNode.x - ERFieldAnchorWidget.anchorOffset - ERFieldAnchorWidget.hitSize / 2,
          graphNode.y + rowY - ERFieldAnchorWidget.hitSize / 2,
          ERFieldAnchorWidget.hitSize,
          ERFieldAnchorWidget.hitSize,
        );
        _interactionManager.updateAnchorInIndex(
          '${entity.id}:field:$i:left',
          leftAnchorRect,
          nodeId: entity.id,
          anchor: ERFieldAnchor(
            nodeId: entity.id,
            fieldIndex: i,
            direction: ERAnchorDirection.left,
            position: Offset(graphNode.x - ERFieldAnchorWidget.anchorOffset, graphNode.y + rowY),
          ),
        );

        // 右锚点
        final rightAnchorRect = Rect.fromLTWH(
          graphNode.x + nodeSize.width + ERFieldAnchorWidget.anchorOffset - ERFieldAnchorWidget.hitSize / 2,
          graphNode.y + rowY - ERFieldAnchorWidget.hitSize / 2,
          ERFieldAnchorWidget.hitSize,
          ERFieldAnchorWidget.hitSize,
        );
        _interactionManager.updateAnchorInIndex(
          '${entity.id}:field:$i:right',
          rightAnchorRect,
          nodeId: entity.id,
          anchor: ERFieldAnchor(
            nodeId: entity.id,
            fieldIndex: i,
            direction: ERAnchorDirection.right,
            position: Offset(graphNode.x + nodeSize.width + ERFieldAnchorWidget.anchorOffset, graphNode.y + rowY),
          ),
        );
      }
    }
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
      onPointerDown: (event) => _onPointerDown(event, uiState, module),
      onPointerMove: (event) => _onPointerMove(event, uiState, module),
      onPointerUp: (event) => _onPointerUp(event, uiState, entityMap, graphNodeMap),
      onPointerSignal: (event) => _onPointerSignal(event, uiState),
      child: MouseRegion(
        cursor: _interactionManager.getCursor(),
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
            // 无限网格背景层
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
            // GraphView 层
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 5.0,
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

  /// 指针按下事件
  void _onPointerDown(PointerDownEvent event, ERDiagramUIState uiState, Module module) {
    logging.d('[ERCanvasV2] onPointerDown: localPosition=${event.localPosition}, buttons=${event.buttons}', tag: 'ERCanvasV2');

    // 使用交互管理器处理
    final scenePos = _interactionManager.toScene(event.localPosition);
    final hitResult = _interactionManager.spatialIndex.hitTest(scenePos);

    // 右键：编辑模式下开始平移
    if (event.buttons == kSecondaryMouseButton && uiState.isEditMode) {
      // 平移由 CanvasPanHandler 处理
      return;
    }

    // 左键处理
    if (event.buttons == kPrimaryMouseButton) {
      if (uiState.isEditMode) {
        if (hitResult.isOnAnchor) {
          // 点击锚点：开始连线
          final anchor = hitResult.anchor;
          if (anchor != null && anchor is ERFieldAnchor) {
            final graphNode = module.graphCanvas.nodes.firstWhere(
              (gn) => gn.moduleName == anchor.nodeId,
              orElse: () => GraphNode(title: '', x: 0, y: 0),
            );

            // 计算锚点的实际位置
            final rowY = ERTableNodeWidget.headerHeight +
                (anchor.fieldIndex * ERTableNodeWidget.fieldRowHeight) +
                ERTableNodeWidget.fieldRowHeight / 2;
            final anchorPosition = Offset(
              anchor.direction == ERAnchorDirection.left
                  ? graphNode.x - ERFieldAnchorWidget.anchorOffset
                  : graphNode.x + ERTableNodeWidget.defaultWidth + ERFieldAnchorWidget.anchorOffset,
              graphNode.y + rowY,
            );

            final updatedAnchor = ERFieldAnchor(
              nodeId: anchor.nodeId,
              fieldIndex: anchor.fieldIndex,
              direction: anchor.direction,
              position: anchorPosition,
            );

            ref.read(erDiagramUIProvider(widget.moduleId).notifier).startConnection(updatedAnchor);
          }
        } else if (hitResult.isOnNode) {
          // 点击节点：选择并可能开始拖动
          final nodeId = hitResult.nodeId;
          if (nodeId != null) {
            final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight);

            final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
            if (isCtrlPressed) {
              notifier.selectNodeMultiple(nodeId);
            } else {
              notifier.selectNodeSingle(nodeId);
            }
          }
        } else {
          // 点击空白区域：开始框选
          ref.read(erDiagramUIProvider(widget.moduleId).notifier).startSelection(event.localPosition);
        }
      }
    }
  }

  /// 指针移动事件
  void _onPointerMove(PointerMoveEvent event, ERDiagramUIState uiState, Module module) {
    // 右键拖动画布（编辑模式）
    if (event.buttons == kSecondaryMouseButton && uiState.isEditMode) {
      // 平移由 Listener 的 onPointerDown 启动，这里处理更新
      // InteractiveViewer 会处理这个，但我们可能需要手动处理
      return;
    }

    // 更新连线预览
    if (uiState.isConnecting) {
      ref.read(erDiagramUIProvider(widget.moduleId).notifier)
          .updateConnectionPreview(event.localPosition);
    }

    // 更新框选
    if (uiState.isSelecting) {
      ref.read(erDiagramUIProvider(widget.moduleId).notifier)
          .updateSelection(event.localPosition);
    }
  }

  /// 指针释放事件
  void _onPointerUp(
    PointerUpEvent event,
    ERDiagramUIState uiState,
    Map<String, Entity> entityMap,
    Map<String, GraphNode> graphNodeMap,
  ) {
    // 完成连线
    if (uiState.isConnecting) {
      final scenePos = _interactionManager.toScene(event.localPosition);
      final hitResult = _interactionManager.spatialIndex.hitTest(scenePos);

      if (hitResult.isOnAnchor) {
        final anchor = hitResult.anchor;
        if (anchor != null && anchor is ERFieldAnchor) {
          final graphNode = graphNodeMap[anchor.nodeId] ??
              GraphNode(title: '', x: 0, y: 0);

          // 计算锚点的实际位置
          final rowY = ERTableNodeWidget.headerHeight +
              (anchor.fieldIndex * ERTableNodeWidget.fieldRowHeight) +
              ERTableNodeWidget.fieldRowHeight / 2;
          final anchorPosition = Offset(
            anchor.direction == ERAnchorDirection.left
                ? graphNode.x - ERFieldAnchorWidget.anchorOffset
                : graphNode.x + ERTableNodeWidget.defaultWidth + ERFieldAnchorWidget.anchorOffset,
            graphNode.y + rowY,
          );

          final updatedAnchor = ERFieldAnchor(
            nodeId: anchor.nodeId,
            fieldIndex: anchor.fieldIndex,
            direction: anchor.direction,
            position: anchorPosition,
          );

          ref.read(erDiagramUIProvider(widget.moduleId).notifier).completeConnection(updatedAnchor);
        }
      } else {
        ref.read(erDiagramUIProvider(widget.moduleId).notifier).cancelConnection();
      }
    }

    // 完成框选
    if (uiState.isSelecting) {
      final nodeRects = _calculateNodeRects(entityMap, graphNodeMap);
      ref.read(erDiagramUIProvider(widget.moduleId).notifier).completeSelection(nodeRects);
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
  void _onNodeTap(String nodeId, bool isCtrlPressed) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

    if (isCtrlPressed) {
      notifier.selectNodeMultiple(nodeId);
    } else {
      notifier.selectNodeSingle(nodeId);
    }

    // 取消框选
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
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);
    final currentUiState = ref.read(erDiagramUIProvider(widget.moduleId));

    if (currentUiState.isSelecting) {
      notifier.cancelSelection();
    }

    notifier.startDragging(nodeId);
  }

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    // 拖动更新由原有的 ERTableNodeWidget 处理
  }

  void _onNodeDragEnd(String nodeId) {
    ref.read(erDiagramUIProvider(widget.moduleId).notifier).endDragging();
  }

  void _onAnchorTap(ERFieldAnchor anchor, GraphNode graphNode) {
    final notifier = ref.read(erDiagramUIProvider(widget.moduleId).notifier);

    // 计算锚点的实际位置
    final rowY = ERTableNodeWidget.headerHeight +
        (anchor.fieldIndex * ERTableNodeWidget.fieldRowHeight) +
        ERTableNodeWidget.fieldRowHeight / 2;
    final anchorPosition = Offset(
      anchor.direction == ERAnchorDirection.left
          ? graphNode.x - ERFieldAnchorWidget.anchorOffset
          : graphNode.x + ERTableNodeWidget.defaultWidth + ERFieldAnchorWidget.anchorOffset,
      graphNode.y + rowY,
    );

    final updatedAnchor = ERFieldAnchor(
      nodeId: anchor.nodeId,
      fieldIndex: anchor.fieldIndex,
      direction: anchor.direction,
      position: anchorPosition,
    );

    if (!ref.read(erDiagramUIProvider(widget.moduleId)).isConnecting) {
      notifier.startConnection(updatedAnchor);
    } else {
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
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

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
class _ERGraphView extends StatelessWidget {
  final Graph graph;
  final Algorithm algorithm;
  final GraphViewController? controller;
  final Widget Function(Node node) nodeBuilder;

  static const double virtualCanvasSize = 50000.0;

  const _ERGraphView({
    required this.graph,
    required this.algorithm,
    this.controller,
    required this.nodeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    algorithm.run(graph, 0, 0);

    return SizedBox(
      width: virtualCanvasSize,
      height: virtualCanvasSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: const ColoredBox(color: Colors.transparent),
          ),
          CustomPaint(
            painter: _EdgePainter(
              graph: graph,
              algorithm: algorithm,
            ),
            size: const Size(virtualCanvasSize, virtualCanvasSize),
          ),
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
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();

    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height));

    // 绘制背景色
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 绘制网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 / scale
      ..style = PaintingStyle.stroke;

    final startX = (topLeft.dx / gridSize).floor() * gridSize;
    final endX = (bottomRight.dx / gridSize).ceil() * gridSize;
    final startY = (topLeft.dy / gridSize).floor() * gridSize;
    final endY = (bottomRight.dy / gridSize).ceil() * gridSize;

    for (var x = startX; x <= endX; x += gridSize) {
      final screenX = MatrixUtils.transformPoint(matrix, Offset(x, 0)).dx;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, size.height),
        gridPaint,
      );
    }

    for (var y = startY; y <= endY; y += gridSize) {
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
    return transformationController.value != oldDelegate.transformationController.value ||
        gridColor != oldDelegate.gridColor ||
        gridSize != oldDelegate.gridSize ||
        isDark != oldDelegate.isDark;
  }
}