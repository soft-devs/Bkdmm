/// ER 图视图
///
/// 新的 ER 图主画布组件，使用 diagram_editor 框架。
/// 替代旧的 ERDiagramCanvas。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/pointer_handler.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/features/project/providers/project_notifier.dart';
import 'package:bkdmm/utils/logging/logging_service.dart';
import '../controllers/er_diagram_controller.dart';
import '../models/er_diagram_ui_state.dart' show ERInteractionMode, ERFieldAnchor, ERAnchorDirection;
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

  /// 指针处理器（框架事件分发）
  PointerHandler? _pointerHandler;

  /// 变换控制器
  late TransformationController _transformationController;

  /// 鼠标位置
  Offset _mousePosition = Offset.zero;

  /// 是否正在框选
  bool _isSelecting = false;
  Offset _selectionStart = Offset.zero;
  Offset _selectionEnd = Offset.zero;

  /// 是否正在连线
  bool _isConnecting = false;
  String? _connectionSourceAnchorId;
  Offset? _connectionSourcePosition;

  /// 状态变更订阅
  VoidCallback? _stateSubscription;

  /// 是否正在交互（避免状态同步循环）
  bool _isInteracting = false;

  /// 节点拖动状态（GestureDetector 方式）
  String? _draggedNodeId;
  Offset _dragStartScreenPos = Offset.zero;
  Offset _nodeStartCanvasPos = Offset.zero;

  /// 手动节点拖动状态（Listener 方式，用于缩放后的拖动）
  bool _isManualDraggingNode = false;
  String? _manualDragNodeId;
  Offset _manualDragStartScreenPos = Offset.zero;
  Offset _manualDragStartCanvasPos = Offset.zero;
  Map<String, Offset> _multiDragStartPositions = {};  // 多选拖动时其他节点的起始位置

  /// 右键拖动画布状态
  bool _isRightDragging = false;
  Offset _rightDragStart = Offset.zero;
  Matrix4 _rightDragTransformStart = Matrix4.identity();

  /// 左键按下状态（用于区分单击和拖动）
  bool _isLeftButtonDown = false;
  Offset _leftButtonDownPos = Offset.zero;
  String? _leftButtonDownNodeId;  // 按下时点击的节点ID
  bool _isPotentialSelection = false;  // 是否可能启动框选（拖动距离超过阈值）

  /// 双击检测状态
  String? _lastTapNodeId;  // 上次点击的节点ID
  DateTime? _lastTapTime;  // 上次点击的时间

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

    // 创建指针处理器（使用框架事件系统）
    _pointerHandler = PointerHandler(
      registry: _controller!.editor.handlerRegistry,
      spatialIndex: _controller!.editor.spatialIndex,
      diagramId: widget.moduleId,
      diagramType: 'er-diagram',
      interactionMode: _controller!.interactionMode == ERInteractionMode.edit
          ? InteractionMode.edit
          : InteractionMode.move,
      onStateUpdate: _handleHandlerUpdate,
    );

    // 订阅状态变更
    _stateSubscription = _controller!.subscribeToStateChanges(_onStateChanged);
  }

  /// 处理 Handler 状态更新
  void _handleHandlerUpdate(HandlerUpdate update) {
    final controller = _controller;
    if (controller == null) return;

    logging.d('[ERDiagramView] HandlerUpdate: ${update.type}', tag: 'ERCanvas');

    switch (update.type) {
      case HandlerUpdateType.startConnection:
        // 开始连线
        setState(() {
          _isConnecting = true;
          _connectionSourceAnchorId = update.data['anchorId'];
          _connectionSourcePosition = update.data['position'];
        });
        // 通知 ConnectionHandler 开始连线
        final connectionHandler = controller.editor.handlerRegistry.handlers
            .whereType<ConnectionHandler>()
            .firstOrNull;
        connectionHandler?.startConnection(
          update.data['anchorId'],
          update.data['position'],
        );

      case HandlerUpdateType.updateConnectionPreview:
        // 更新连线预览
        setState(() {
          // 预览位置在 ERInteractionOverlay 中处理
        });

      case HandlerUpdateType.completeConnection:
        // 完成连线
        final targetAnchorId = update.data['targetAnchorId'] as String;
        if (_connectionSourceAnchorId != null) {
          controller.completeConnection(targetAnchorId, _extractNodeId(targetAnchorId));
        }
        setState(() {
          _isConnecting = false;
          _connectionSourceAnchorId = null;
          _connectionSourcePosition = null;
        });

      case HandlerUpdateType.cancelConnection:
        // 取消连线
        setState(() {
          _isConnecting = false;
          _connectionSourceAnchorId = null;
          _connectionSourcePosition = null;
        });

      case HandlerUpdateType.selectNode:
        // 选中节点
        controller.selectNode(
          update.data['nodeId'],
          addToSelection: update.data['addToSelection'] ?? false,
        );

      case HandlerUpdateType.startDrag:
        // 开始拖动（记录起始位置）
        // 框架会处理

      case HandlerUpdateType.updateDrag:
        // 更新拖动位置
        final nodeId = update.data['nodeId'] as String;
        final position = update.data['position'] as Offset;
        controller.editor.updateNode(nodeId, (node) {
          if (node is ERTableNodeModel) {
            return node.copyWith(position: position);
          }
          return node;
        });

      case HandlerUpdateType.endDrag:
        // 结束拖动，同步位置到项目
        final nodeId = update.data['nodeId'] as String;
        controller.editor.eventCenter.emit(DragEndedEvent(nodeId));

      case HandlerUpdateType.startBoxSelection:
        // 开始框选
        setState(() {
          _isSelecting = true;
          _selectionStart = update.data['start'];
          _selectionEnd = _selectionStart;
        });

      case HandlerUpdateType.updateBoxSelection:
        // 更新框选区域
        setState(() {
          _selectionEnd = update.data['end'];
        });

      case HandlerUpdateType.completeBoxSelection:
        // 完成框选
        final rect = Rect.fromPoints(_selectionStart, _selectionEnd);
        final transform = _transformationController.value;
        final inverseTransform = Matrix4.inverted(transform);
        final canvasStart = MatrixUtils.transformPoint(inverseTransform, rect.topLeft);
        final canvasEnd = MatrixUtils.transformPoint(inverseTransform, rect.bottomRight);
        final canvasRect = Rect.fromPoints(canvasStart, canvasEnd);

        // 选中框选区域内的所有节点
        for (final node in controller.state.nodes.values) {
          if (canvasRect.overlaps(Rect.fromLTWH(
            node.position.dx,
            node.position.dy,
            node.size.width,
            node.size.height,
          ))) {
            controller.selectNode(node.id, addToSelection: true);
          }
        }

        setState(() {
          _isSelecting = false;
        });

      case HandlerUpdateType.openNodeEditor:
        // 打开节点编辑器
        controller.editor.eventCenter.emit(
          NodeEditorRequestedEvent(update.data['nodeId']),
        );

      case HandlerUpdateType.showContextMenu:
        // 显示上下文菜单
        controller.editor.eventCenter.emit(
          ContextMenuRequestedEvent(
            update.data['position'],
            update.data['nodeId'],
          ),
        );
    }
  }

  /// 从锚点 ID 提取节点 ID
  String _extractNodeId(String anchorId) {
    final parts = anchorId.split(':');
    return parts.first;
  }

  /// 状态变更处理
  void _onStateChanged() {
    if (_controller == null || _isInteracting) return;

    // 不同步变换控制器，因为 InteractiveViewer 管理自己的变换状态
    // InteractiveViewer 的缩放和平移由用户交互直接控制
    // DiagramEditor 的 viewport 状态用于内部计算，不需要同步到视图

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
    final tdTheme = TDTheme.of(context);

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = _controller!.state;

    return Stack(
      children: [
        // 主画布
        _buildMainCanvas(isDark, state, tdTheme),

        // 交互覆盖层
        Positioned.fill(
          child: IgnorePointer(
            child: ERInteractionOverlay(
              state: state,
              transform: _transformationController.value,
              isDarkMode: isDark,
              selectionRectScreen: _isSelecting ? Rect.fromPoints(_selectionStart, _selectionEnd) : null,
              connectionPreviewEndScreen: null, // TODO: 连线预览位置
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
  Widget _buildMainCanvas(bool isDark, DiagramState state, TDThemeData tdTheme) {
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
        child: Stack(
          children: [
            // 背景网格层（在 InteractiveViewer 外部，使用屏幕坐标绘制）
            Positioned.fill(
              child: IgnorePointer(
                child: _buildGridBackground(isDark, tdTheme),
              ),
            ),

            // InteractiveViewer 层（节点和边）
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 5.0,
              panEnabled: _controller?.interactionMode == ERInteractionMode.preview,
              scaleEnabled: true,
              // 不设置 clipBehavior，使用默认 Clip.hardEdge
              onInteractionStart: (details) {
                _isInteracting = true;
              },
              onInteractionUpdate: (details) {
                // 不调用 zoomTo，避免重置画布位置
              },
              onInteractionEnd: (details) {
                _isInteracting = false;
              },
              child: SizedBox(
                width: 50000,
                height: 50000,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 透明背景层（确保整个虚拟画布区域都能响应事件）
                    Positioned.fill(
                      child: const ColoredBox(color: Colors.transparent),
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
          ],
        ),
      ),
    );
  }

  /// 构建网格背景
  Widget _buildGridBackground(bool isDark, TDThemeData tdTheme) {
    return ListenableBuilder(
      listenable: _transformationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _InfiniteGridPainter(
            transformationController: _transformationController,
            gridColor: tdTheme.brandNormalColor.withValues(alpha: isDark ? 0.15 : 0.2),
            gridSize: 20.0,
            backgroundColor: tdTheme.bgColorPage,
            majorGridInterval: 5,
            majorGridColor: tdTheme.brandNormalColor.withValues(alpha: isDark ? 0.25 : 0.3),
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
                    ? Icons.visibility  // 编辑模式时显示预览图标（点击切换到预览）
                    : Icons.edit,        // 预览模式时显示编辑图标（点击切换到编辑）
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
    logging.d('[ERDiagramView] onPointerDown: ${event.localPosition}, buttons=${event.buttons}', tag: 'ERCanvas');

    // 右键在编辑模式下用于平移画布
    if (event.buttons == kSecondaryMouseButton &&
        _controller?.interactionMode == ERInteractionMode.edit) {
      _isRightDragging = true;
      _rightDragStart = event.localPosition;
      _rightDragTransformStart = _transformationController.value.clone();
      return;
    }

    // 左键：编辑模式下记录按下状态，等待拖动或释放
    if (event.buttons == kPrimaryMouseButton &&
        _controller?.interactionMode == ERInteractionMode.edit) {
      _isLeftButtonDown = true;
      _leftButtonDownPos = event.localPosition;
      _isPotentialSelection = false;

      // 检查是否点击在节点上
      _leftButtonDownNodeId = _checkClickedOnNode(event.localPosition);

      if (_leftButtonDownNodeId != null) {
        logging.d('[ERDiagramView] 左键按下在节点上: ${_leftButtonDownNodeId}', tag: 'ERCanvas');
      } else {
        logging.d('[ERDiagramView] 左键按下在空白区域', tag: 'ERCanvas');
      }
    }
  }

  /// 检查点击位置是否在某个节点上
  /// 返回节点ID，如果不在任何节点上则返回 null
  String? _checkClickedOnNode(Offset screenPos) {
    final controller = _controller;
    if (controller == null) return null;

    // 将屏幕坐标转换为画布坐标
    final transform = _transformationController.value;
    final inverseTransform = Matrix4.inverted(transform);
    final canvasPos = MatrixUtils.transformPoint(inverseTransform, screenPos);

    logging.d('[ERDiagramView] 屏幕坐标=$screenPos, 画布坐标=$canvasPos', tag: 'ERCanvas');

    // 检查每个节点
    for (final node in controller.state.nodes.values) {
      final nodeRect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );

      // 扩大点击区域以包含锚点（如果有）
      const anchorHitSize = 16.0;
      final expandedRect = nodeRect.inflate(anchorHitSize);

      if (expandedRect.contains(canvasPos)) {
        logging.d('[ERDiagramView] 节点 ${node.id}: rect=$nodeRect, contains=true', tag: 'ERCanvas');
        return node.id;
      }
    }

    return null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    // 右键拖动画布（编辑模式）
    if (event.buttons == kSecondaryMouseButton && _isRightDragging) {
      final delta = event.localPosition - _rightDragStart;
      final newMatrix = _rightDragTransformStart.clone();
      newMatrix.translate(delta.dx, delta.dy);
      _transformationController.value = newMatrix;
      return;
    }

    // 左键拖动（编辑模式）
    if (event.buttons == kPrimaryMouseButton && _isLeftButtonDown) {
      final delta = event.localPosition - _leftButtonDownPos;

      // 检查是否超过拖动阈值（启动拖动或框选）
      const dragThreshold = 5.0;  // 5像素阈值
      if (delta.distance > dragThreshold && !_isPotentialSelection && !_isManualDraggingNode) {
        // 超过阈值，判断是节点拖动还是框选
        if (_leftButtonDownNodeId != null) {
          // 拖动节点
          _startNodeDrag(_leftButtonDownNodeId!, _leftButtonDownPos);
        } else {
          // 启动框选
          _startSelection(_leftButtonDownPos);
          _isPotentialSelection = true;
        }
      }

      // 处理节点拖动更新
      if (_isManualDraggingNode && _manualDragNodeId != null) {
        _handleManualNodeDrag(event.localPosition);
        return;
      }

      // 处理框选更新
      if (_isSelecting) {
        _updateSelection(event.localPosition);
      }
    }
  }

  /// 启动节点拖动
  void _startNodeDrag(String nodeId, Offset screenPos) {
    final controller = _controller;
    if (controller == null) return;

    final node = controller.editor.getNode(nodeId);
    if (node == null) return;

    // 检查是否按下 Ctrl 键
    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlRight);

    // 如果节点未被选中，先选中它
    final selectedNodes = controller.state.selection.selectedNodeIds;
    if (!selectedNodes.contains(nodeId)) {
      _onNodeTap(nodeId, isCtrlPressed);
    }

    // 启动拖动
    _isManualDraggingNode = true;
    _manualDragNodeId = nodeId;
    _manualDragStartScreenPos = screenPos;
    _manualDragStartCanvasPos = node.position;

    // 如果有多个选中节点，记录它们的起始位置
    _multiDragStartPositions = {};
    final currentSelectedNodes = controller.state.selection.selectedNodeIds;
    if (currentSelectedNodes.length > 1) {
      for (final n in controller.state.nodes.values) {
        if (currentSelectedNodes.contains(n.id)) {
          _multiDragStartPositions[n.id] = n.position;
        }
      }
    }

    logging.d('[ERDiagramView] 启动节点拖动: nodeId=$nodeId, selectedCount=${currentSelectedNodes.length}', tag: 'ERCanvas');
  }

  /// 处理手动节点拖动
  void _handleManualNodeDrag(Offset screenPos) {
    final controller = _controller;
    if (controller == null) return;

    // 计算从起始位置到当前位置的总偏移（屏幕坐标）
    final screenDelta = screenPos - _manualDragStartScreenPos;

    // 将屏幕偏移转换为画布偏移
    final zoom = _transformationController.value.getMaxScaleOnAxis();
    final canvasDelta = screenDelta / zoom;

    // 移动所有选中的节点
    if (_multiDragStartPositions.isNotEmpty) {
      // 多选拖动：移动所有选中节点
      for (final entry in _multiDragStartPositions.entries) {
        final newPosition = entry.value + canvasDelta;
        controller.moveNode(entry.key, newPosition);
      }
    } else if (_manualDragNodeId != null) {
      // 单节点拖动
      final newPosition = _manualDragStartCanvasPos + canvasDelta;
      controller.moveNode(_manualDragNodeId!, newPosition);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    // 结束右键拖动
    if (_isRightDragging) {
      _isRightDragging = false;
      return;
    }

    // 结束手动节点拖动
    if (_isManualDraggingNode) {
      _isManualDraggingNode = false;
      _manualDragNodeId = null;
      _multiDragStartPositions = {};
      logging.d('[ERDiagramView] 结束手动节点拖动', tag: 'ERCanvas');
      _isLeftButtonDown = false;
      return;
    }

    // 完成框选
    if (_isSelecting) {
      _completeSelection();
      _isLeftButtonDown = false;
      return;
    }

    // 处理左键单击（未拖动）
    if (_isLeftButtonDown && !_isPotentialSelection) {
      final controller = _controller;
      if (controller != null) {
        // 检查是否按下 Ctrl 键
        final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight);

        if (_leftButtonDownNodeId != null) {
          // 检测双击：同一节点、间隔小于300ms
          const doubleTapInterval = Duration(milliseconds: 300);
          final now = DateTime.now();
          final isDoubleTap = _lastTapNodeId == _leftButtonDownNodeId &&
              _lastTapTime != null &&
              now.difference(_lastTapTime!) < doubleTapInterval;

          if (isDoubleTap) {
            // 双击节点：打开编辑弹窗
            logging.d('[ERDiagramView] 双击节点: ${_leftButtonDownNodeId}', tag: 'ERCanvas');
            final node = controller.editor.getNode(_leftButtonDownNodeId!);
            if (node != null) {
              _onNodeDoubleTap(node);
            }
            // 清除双击状态
            _lastTapNodeId = null;
            _lastTapTime = null;
          } else {
            // 单击节点：选中或取消选中
            _onNodeTap(_leftButtonDownNodeId!, isCtrlPressed);
            // 记录单击状态（用于下次检测双击）
            _lastTapNodeId = _leftButtonDownNodeId;
            _lastTapTime = now;
          }
        } else {
          // 单击空白区域：取消所有选中
          if (!isCtrlPressed && controller.state.selection.selectedNodeIds.isNotEmpty) {
            controller.clearSelection();
          }
          // 清除双击状态
          _lastTapNodeId = null;
          _lastTapTime = null;
        }
      }
    }

    _isLeftButtonDown = false;
    _leftButtonDownNodeId = null;
    _isPotentialSelection = false;
  }

  void _startSelection(Offset position) {
    setState(() {
      _isSelecting = true;
      _selectionStart = position;
      _selectionEnd = position;
    });
  }

  void _updateSelection(Offset position) {
    if (!_isSelecting) return;

    setState(() {
      _selectionEnd = position;
    });
  }

  void _completeSelection() {
    if (_controller == null) {
      setState(() {
        _isSelecting = false;
      });
      return;
    }

    // 计算框选矩形
    final rect = Rect.fromPoints(_selectionStart, _selectionEnd);

    // 获取当前变换矩阵
    final transform = _transformationController.value;
    final inverseTransform = Matrix4.inverted(transform);

    // 将屏幕坐标的框选矩形转换为画布坐标
    final canvasTopLeft = MatrixUtils.transformPoint(inverseTransform, rect.topLeft);
    final canvasBottomRight = MatrixUtils.transformPoint(inverseTransform, rect.bottomRight);
    final canvasSelectionRect = Rect.fromPoints(canvasTopLeft, canvasBottomRight);

    // 查询框选区域内的节点（使用画布坐标）
    final selectedIds = <String>{};
    for (final node in _controller!.state.nodes.values) {
      final nodeRect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );
      if (canvasSelectionRect.overlaps(nodeRect)) {
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

    setState(() {
      _isSelecting = false;
    });
  }

  void _onAnchorTap(DiagramNode node, ERFieldAnchor anchor) {
    logging.d('[ERDiagramView] onAnchorTap: ${anchor.nodeId}, field=${anchor.fieldIndex}', tag: 'ERCanvas');

    if (_isConnecting) {
      // 完成连线
      _controller?.completeConnection(
        _buildAnchorId(node.id, anchor.fieldIndex, anchor.direction),
        node.id,
      );
      setState(() {
        _isConnecting = false;
        _connectionSourceAnchorId = null;
        _connectionSourcePosition = null;
      });
    } else {
      // 开始连线
      setState(() {
        _isConnecting = true;
        _connectionSourceAnchorId = _buildAnchorId(node.id, anchor.fieldIndex, anchor.direction);
        _connectionSourcePosition = node.position;
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

    final controller = _controller;
    if (controller == null) return;

    final node = controller.editor.getNode(nodeId);
    if (node == null) return;

    // 记录拖动起始位置
    _draggedNodeId = nodeId;
    _dragStartScreenPos = details.localPosition;
    _nodeStartCanvasPos = node.position;

    _controller?.editor.eventCenter.emit(DragStartedEvent(
      nodeId: nodeId,
      startPosition: node.position,
    ));
  }

  void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
    if (_draggedNodeId != nodeId) return;

    final controller = _controller;
    if (controller == null) return;

    // 计算从起始位置到当前位置的总偏移（屏幕坐标）
    final screenDelta = details.localPosition - _dragStartScreenPos;

    // 将屏幕偏移转换为画布偏移
    final zoom = _transformationController.value.getMaxScaleOnAxis();
    final canvasDelta = screenDelta / zoom;

    // 基于起始位置计算新位置
    final newPosition = _nodeStartCanvasPos + canvasDelta;

    controller.moveNode(nodeId, newPosition);
  }

  void _onNodeDragEnd(String nodeId) {
    if (_draggedNodeId != nodeId) return;

    logging.d('[ERDiagramView] onNodeDragEnd: $nodeId', tag: 'ERCanvas');

    _draggedNodeId = null;

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