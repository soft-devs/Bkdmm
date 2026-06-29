/// ER 图视图
///
/// 新的 ER 图主画布组件，使用 diagram_editor 框架。
/// 替代旧的 ERDiagramCanvas。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../../../../shared/models/models.dart';
import '../../../../utils/logging/logging_service.dart';
import '../../../project/providers/project_notifier.dart';
import '../controllers/er_diagram_controller.dart';
import '../models/er_diagram_ui_state.dart';
import '../painters/er_relation_painter_adapter.dart';
import 'er_interaction_overlay.dart';
import '../widgets/er_table_node_widget_v2.dart';

/// ER 图视图
///
/// 使用 GraphView (diagram_editor) 渲染 ER 图。
///
/// 功能：
/// - 节点渲染（ERTableNodeWidget）
/// - 连线渲染（ERRelationPainterAdapter）
/// - 交互覆盖（连线预览、框选）
/// - 工具栏（缩放、适应、布局）
/// - 坐标显示
class ERDiagramView extends ConsumerStatefulWidget {
  /// 模块 ID
  final String moduleId;

  /// 实体编辑回调
  final void Function(Entity entity)? onEntityEdit;

  /// 实体预览回调
  final void Function(Entity entity)? onEntityPreview;

  /// 右键菜单回调
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramView({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onEntityPreview,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramView> createState() => _ERDiagramViewState();
}

class _ERDiagramViewState extends ConsumerState<ERDiagramView> {
  /// 控制器
  ERDiagramController? _controller;

  /// 变换控制器
  late TransformationController _transformationController;

  /// 鼠标位置
  Offset _mousePosition = Offset.zero;

  /// 交互扩展状态
  ERInteractionExtension _interactionExtension = ERInteractionExtension.empty;

  /// 状态变更订阅
  VoidCallback? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeController();
  }

  /// 初始化控制器
  void _initializeController() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    final project = ref.read(projectNotifierProvider).project;

    if (project == null) return;

    final module = project.modules.firstWhere(
      (m) => m.id == widget.moduleId,
      orElse: () => Module.empty,
    );

    if (module == Module.empty) return;

    // 创建控制器
    _controller = ERDiagramController(
      editor: DiagramEditor(diagramType: 'er-diagram'),
      projectNotifier: projectNotifier,
      moduleId: widget.moduleId,
    );

    // 设置回调
    _controller!.onEntityEditRequest = (entityId) {
      final entity = module.entities.firstWhere(
        (e) => e.id == entityId,
        orElse: () => throw StateError('Entity not found'),
      );
      widget.onEntityEdit?.call(entity);
    };

    _controller!.onContextMenuRequest = (position, entityId) {
      Entity? entity;
      if (entityId != null) {
        entity = module.entities.firstWhere(
          (e) => e.id == entityId,
          orElse: () => throw StateError('Entity not found'),
        );
      }
      widget.onContextMenu?.call(position, entity);
    };

    // 初始化数据
    _controller!.initialize(module);

    // 订阅状态变更
    _stateSubscription = _controller!.subscribeToStateChanges(_onStateChanged);
  }

  /// 状态变更处理
  void _onStateChanged() {
    if (_controller == null) return;

    // 同步变换控制器
    final viewport = _controller!.state.viewport;
    final matrix = Matrix4.identity()
      ..translate(viewport.panOffset.dx, viewport.panOffset.dy)
      ..scale(viewport.zoom);
    _transformationController.value = matrix;

    setState(() {});
  }

  @override
  void dispose() {
    _stateSubscription?.call();
    _controller?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = _controller!.state;

    return Stack(
      children: [
        // 主画布
        _buildMainCanvas(isDark, state),

        // 交互覆盖层
        Positioned.fill(
          child: IgnorePointer(
            child: ERInteractionOverlay(
              state: state,
              transform: _transformationController.value,
              isDarkMode: isDark,
            ),
          ),
        ),

        // 工具栏
        _buildToolbar(isDark),

        // 坐标显示
        _buildCoordinateDisplay(isDark),
      ],
    );
  }

  /// 构建主画布
  Widget _buildMainCanvas(bool isDark, DiagramState state) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 5.0,
          panEnabled: _controller?.interactionMode == ERInteractionMode.preview,
          scaleEnabled: true,
          clipBehavior: Clip.none,
          onInteractionUpdate: (details) {
            // 通知控制器视口变更
            _controller?.zoomTo(_transformationController.value.getMaxScaleOnAxis());
          },
          child: SizedBox(
            width: 50000,
            height: 50000,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 背景网格
                Positioned.fill(
                  child: _buildGridBackground(isDark),
                ),

                // 边层
                if (state.edges.isNotEmpty)
                  CustomPaint(
                    painter: _buildEdgePainter(state, isDark),
                    size: const Size(50000, 50000),
                  ),

                // 节点层
                ...state.nodes.values.map((node) {
                  final nodeState = state.getNodeState(node.id);
                  return Positioned(
                    left: node.position.dx,
                    top: node.position.dy,
                    child: ERTableNodeWidgetV2.builder(
                      node,
                      nodeState,
                      isDarkMode: isDark,
                      interactionMode: _getInteractionMode(),
                      onAnchorTap: (anchor) => _onAnchorTap(node, anchor),
                      onTap: (isCtrlPressed) => _onNodeTap(node.id, isCtrlPressed),
                      onDoubleTap: () => _onNodeDoubleTap(node),
                      onDragStart: (details) => _onNodeDragStart(node.id, details),
                      onDragUpdate: (details) => _onNodeDragUpdate(node.id, details),
                      onDragEnd: () => _onNodeDragEnd(node.id),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建网格背景
  Widget _buildGridBackground(bool isDark) {
    return ListenableBuilder(
      listenable: _transformationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _InfiniteGridPainter(
            transformationController: _transformationController,
            gridColor: isDark ? const Color(0x14FFFFFF) : const Color(0x14000000),
            gridSize: 20.0,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA),
            majorGridInterval: 5,
            majorGridColor:
                isDark ? const Color(0x28FFFFFF) : const Color(0x28000000),
          ),
        );
      },
    );
  }

  /// 构建边绘制器
  CustomPainter _buildEdgePainter(DiagramState state, bool isDark) {
    return _ERDiagramEdgePainter(
      state: state,
      transform: _transformationController.value,
      isDark: isDark,
      edgePainter: ERRelationPainterAdapter(isDarkMode: isDark),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(bool isDark) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
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
              onPressed: () => _controller?.zoomIn(),
              tooltip: '放大',
            ),
            const SizedBox(width: 4),
            // 缩小
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              onPressed: () => _controller?.zoomOut(),
              tooltip: '缩小',
            ),
            const SizedBox(width: 4),
            // 适应
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20),
              onPressed: () => _controller?.fitContent(),
              tooltip: '适应内容',
            ),
            const SizedBox(width: 4),
            // 重置
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _controller?.resetViewport(),
              tooltip: '重置视口',
            ),
            const SizedBox(width: 8),
            // 分隔线
            Container(
              width: 1,
              height: 24,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 8),
            // 模式切换
            IconButton(
              icon: Icon(
                _controller?.interactionMode == ERInteractionMode.edit
                    ? Icons.edit
                    : Icons.visibility,
                size: 20,
              ),
              onPressed: () => _controller?.toggleMode(),
              tooltip: _controller?.interactionMode == ERInteractionMode.edit
                  ? '切换到预览模式'
                  : '切换到编辑模式',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建坐标显示
  Widget _buildCoordinateDisplay(bool isDark) {
    final scenePos = _controller?.toScene(_mousePosition) ?? Offset.zero;
    final zoom = _transformationController.value.getMaxScaleOnAxis();

    return Positioned(
      left: 16,
      bottom: 16,
      child: Container(
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
      ),
    );
  }

  // ===========================================================================
  // 事件处理
  // ===========================================================================

  void _onPointerDown(PointerDownEvent event) {
    logging.d('[ERDiagramView] onPointerDown: ${event.localPosition}', tag: 'ERCanvas');

    // 右键在编辑模式下用于平移
    if (event.buttons == kSecondaryMouseButton &&
        _controller?.interactionMode == ERInteractionMode.edit) {
      // 开始框选或平移
      _startSelection(event.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_interactionExtension.isSelecting) {
      _updateSelection(event.localPosition);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_interactionExtension.isSelecting) {
      _completeSelection();
    }
  }

  void _startSelection(Offset position) {
    setState(() {
      _interactionExtension = ERInteractionExtension(
        isSelecting: true,
        selectionStartPoint: position,
        selectionEndPoint: position,
        selectionRect: Rect.fromPoints(position, position),
      );
    });
  }

  void _updateSelection(Offset position) {
    if (!_interactionExtension.isSelecting) return;

    final start = _interactionExtension.selectionStartPoint ?? position;
    setState(() {
      _interactionExtension = _interactionExtension.copyWith(
        selectionEndPoint: position,
        selectionRect: ERInteractionExtension.calculateSelectionRect(start, position),
      );
    });
  }

  void _completeSelection() {
    final rect = _interactionExtension.selectionRect;
    if (rect != null && _controller != null) {
      // 查询框选区域内的节点
      final selectedIds = <String>{};
      for (final node in _controller!.state.nodes.values) {
        final nodeRect = Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        );
        if (rect.overlaps(nodeRect)) {
          selectedIds.add(node.id);
        }
      }

      // 选择节点
      if (selectedIds.isNotEmpty) {
        _controller!.selectNode(selectedIds.first);
        for (final id in selectedIds.skip(1)) {
          _controller!.selectNode(id, addToSelection: true);
        }
      }
    }

    setState(() {
      _interactionExtension = ERInteractionExtension.empty;
    });
  }

  void _onAnchorTap(DiagramNode node, ERFieldAnchor anchor) {
    logging.d('[ERDiagramView] onAnchorTap: ${anchor.nodeId}, field=${anchor.fieldIndex}', tag: 'ERCanvas');

    if (_interactionExtension.isConnecting) {
      // 完成连线
      _controller?.completeConnection(
        _buildAnchorId(node.id, anchor.fieldIndex, anchor.direction),
        node.id,
      );
      setState(() {
        _interactionExtension = ERInteractionExtension.empty;
      });
    } else {
      // 开始连线
      setState(() {
        _interactionExtension = ERInteractionExtension(
          isConnecting: true,
          connectionSourceAnchorId: _buildAnchorId(node.id, anchor.fieldIndex, anchor.direction),
          connectionSourcePosition: node.position,
        );
      });
    }
  }

  String _buildAnchorId(String nodeId, int fieldIndex, ERAnchorDirection direction) {
    return '$nodeId:field:$fieldIndex:${direction.name}';
  }

  void _onNodeTap(String nodeId, bool isCtrlPressed) {
    logging.d('[ERDiagramView] onNodeTap: $nodeId, ctrl=$isCtrlPressed', tag: 'ERCanvas');
    _controller?.selectNode(nodeId, addToSelection: isCtrlPressed);
  }

  void _onNodeDoubleTap(DiagramNode node) {
    logging.d('[ERDiagramView] onNodeDoubleTap: ${node.id}', tag: 'ERCanvas');

    if (_controller?.interactionMode == ERInteractionMode.edit) {
      _controller?.editor.eventCenter.emit(NodeEditorRequestedEvent(node.id));
    } else {
      // 预览模式
      final erNode = node as ERTableNodeModel;
      widget.onEntityPreview?.call(erNode.entity);
    }
  }

  void _onNodeDragStart(String nodeId, DragStartDetails details) {
    logging.d('[ERDiagramView] onNodeDragStart: $nodeId', tag: 'ERCanvas');
    _controller?.editor.eventCenter.emit(DragStartedEvent(
      nodeId: nodeId,
      startPosition: _controller?.toScene(details.localPosition) ?? Offset.zero,
    ));
  }

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    final controller = _controller;
    if (controller == null) return;

    final node = controller.editor.getNode(nodeId);
    if (node == null) return;

    final zoom = _transformationController.value.getMaxScaleOnAxis();
    final delta = details.delta / zoom;
    final newPosition = node.position + delta;

    controller.moveNode(nodeId, newPosition);
  }

  void _onNodeDragEnd(String nodeId) {
    logging.d('[ERDiagramView] onNodeDragEnd: $nodeId', tag: 'ERCanvas');
    final node = _controller?.editor.getNode(nodeId);
    if (node != null) {
      _controller?.editor.eventCenter.emit(DragEndedEvent(
        nodeId: nodeId,
        endPosition: node.position,
      ));
    }
  }

  ERInteractionMode _getInteractionMode() {
    return _controller?.interactionMode ?? ERInteractionMode.preview;
  }
}

/// 边绘制器
class _ERDiagramEdgePainter extends CustomPainter {
  final DiagramState state;
  final Matrix4 transform;
  final bool isDark;
  final GraphEdgePainter? edgePainter;

  _ERDiagramEdgePainter({
    required this.state,
    required this.transform,
    required this.isDark,
    this.edgePainter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in state.edges.values) {
      final sourceAnchor = state.getAnchor(edge.sourceAnchorId);
      final targetAnchor = state.getAnchor(edge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      final edgeState = state.getEdgeState(edge.id);

      edgePainter?.paint(
        canvas,
        edge,
        edgeState,
        sourceAnchor.position,
        targetAnchor.position,
        transform,
        isDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ERDiagramEdgePainter oldDelegate) {
    return state != oldDelegate.state ||
        transform != oldDelegate.transform ||
        isDark != oldDelegate.isDark;
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
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();

    final inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();

    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height));

    // 背景
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 / scale
      ..style = PaintingStyle.stroke;

    final majorGridPaint = Paint()
      ..color = majorGridColor
      ..strokeWidth = 1.0 / scale
      ..style = PaintingStyle.stroke;

    final majorGridStep = gridSize * majorGridInterval;

    // 垂直线
    var startX = (topLeft.dx / gridSize).floor() * gridSize;
    var endX = (bottomRight.dx / gridSize).ceil() * gridSize;

    for (var x = startX; x <= endX; x += gridSize) {
      final canvasX = MatrixUtils.transformPoint(matrix, Offset(x, 0)).dx;
      final isMajor = (x % majorGridStep).abs() < 0.001;
      canvas.drawLine(
        Offset(canvasX, 0),
        Offset(canvasX, size.height),
        isMajor ? majorGridPaint : gridPaint,
      );
    }

    // 水平线
    var startY = (topLeft.dy / gridSize).floor() * gridSize;
    var endY = (bottomRight.dy / gridSize).ceil() * gridSize;

    for (var y = startY; y <= endY; y += gridSize) {
      final canvasY = MatrixUtils.transformPoint(matrix, Offset(0, y)).dy;
      final isMajor = (y % majorGridStep).abs() < 0.001;
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
        backgroundColor != oldDelegate.backgroundColor;
  }
}