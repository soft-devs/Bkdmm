import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../../../../shared/models/models.dart';
import '../../../project/providers/project_notifier.dart';
import '../providers/er_diagram_provider.dart';
import '../models/er_diagram_models.dart';
import '../renderers/er_renderers.dart';

/// ER 图画布 Widget
///
/// 使用混合架构实现：
/// - DiagramCanvas 基类提供通用画布功能
/// - ERNodeRenderer/EREdgeRenderer 提供自定义渲染
/// - GraphViewLayoutEngine 提供布局算法
class ERDiagramCanvas extends ConsumerStatefulWidget {
  /// 模块 ID
  final String moduleId;

  /// 实体编辑回调
  final void Function(Entity entity)? onEntityEdit;

  /// 右键菜单回调
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramCanvas({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramCanvas> createState() => _ERDiagramCanvasState();
}

class _ERDiagramCanvasState extends ConsumerState<ERDiagramCanvas> {
  final TransformationController _transformController = TransformationController();
  final ERNodeRenderer _nodeRenderer = ERNodeRenderer();
  final EREdgeRenderer _edgeRenderer = EREdgeRenderer();
  final GraphViewLayoutEngine _layoutEngine = GraphViewLayoutEngine();

  // 手势状态
  InteractionState _interactionState = const InteractionState();
  Offset _pointerDownPos = Offset.zero;
  bool _gestureClaimed = false;

  // 拖拽状态
  String? _draggedNodeId;
  Offset _dragStartPos = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  // 连线状态
  String? _sourceAnchorId;
  Offset _connectionStartPos = Offset.zero;
  Offset _connectionCurrentPos = Offset.zero;

  // 双击检测
  String? _lastTappedNodeId;
  DateTime? _lastTapTime;
  static const _doubleClickThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final matrix = _transformController.value;
    final zoom = matrix.getMaxScaleOnAxis();
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    notifier.setZoom(zoom);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  Offset _toScene(Offset local) {
    final matrix = _transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, local);
  }

  Offset _toScreen(Offset scene) {
    return MatrixUtils.transformPoint(_transformController.value, scene);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 交互状态
  // ═══════════════════════════════════════════════════════════════════

  bool get _panEnabled =>
      _interactionState.isIdle &&
      _interactionState.mode == InteractionMode.move;

  void _transitionTo(InteractionType type) {
    setState(() {
      _interactionState = _interactionState.copyWith(type: type);
    });
  }

  void _resetInteraction() {
    setState(() {
      _interactionState = const InteractionState();
      _gestureClaimed = false;
      _draggedNodeId = null;
      _sourceAnchorId = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // 构建
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final diagramState = ref.watch(erDiagramProvider(widget.moduleId));
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 监听项目变化
    ref.listen<ProjectState>(projectNotifierProvider, (prev, next) {
      final project = next.project;
      if (project != null) {
        try {
          final module = project.modules.firstWhere((m) => m.id == widget.moduleId);
          final prevModule = prev?.project?.modules.where((m) => m.id == widget.moduleId).firstOrNull;

          if (prevModule == null ||
              module.entities.length != prevModule.entities.length) {
            notifier.reload();
          }
        } catch (_) {}
      }
    });

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
                transformationController: _transformController,
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false,
                panEnabled: _panEnabled,
                scaleEnabled: true,
                child: CustomPaint(
                  size: _calculateCanvasSize(diagramState),
                  painter: ERDiagramPainter(
                    state: diagramState,
                    isDarkMode: isDark,
                    nodeRenderer: _nodeRenderer,
                    edgeRenderer: _edgeRenderer,
                    interactionState: _interactionState,
                    connectionStartPos: _sourceAnchorId != null ? _connectionStartPos : null,
                    connectionCurrentPos: _connectionCurrentPos,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 工具栏
        Positioned(top: 12, right: 12, child: _buildToolbar(diagramState, isDark)),

        // 空状态提示
        if (diagramState.nodes.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_chart, size: 56, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No tables yet', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entity'),
                  onPressed: () => widget.onContextMenu?.call(Offset.zero, null),
                ),
              ],
            ),
          ),

        // 连线预览（在 InteractiveViewer 外部，使用屏幕坐标）
        if (_sourceAnchorId != null && _interactionState.isConnecting)
          CustomPaint(
            size: Size.infinite,
            painter: ConnectionPreviewPainter(
              start: _toScreen(_connectionStartPos),
              end: _toScreen(_connectionCurrentPos),
              isDark: isDark,
            ),
          ),
      ],
    );
  }

  Size _calculateCanvasSize(ERDiagramState state) {
    if (state.nodes.isEmpty) return const Size(4000, 4000);

    double maxX = 0, maxY = 0;
    for (final node in state.nodes.values) {
      maxX = math.max(maxX, node.position.dx + node.size.width);
      maxY = math.max(maxY, node.position.dy + node.size.height);
    }

    return Size(
      (maxX + 200).clamp(2000.0, 10000.0),
      (maxY + 200).clamp(2000.0, 10000.0),
    );
  }

  Widget _buildToolbar(ERDiagramState state, bool isDark) {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final editMode = state.interaction.mode == InteractionMode.edit;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 模式切换
            IconButton(
              icon: Icon(editMode ? Icons.edit : Icons.pan_tool),
              tooltip: editMode ? 'Edit Mode' : 'Move Mode',
              onPressed: () => notifier.toggleInteractionMode(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: (editMode ? Colors.green : Colors.blue).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                editMode ? 'EDIT' : 'MOVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: editMode ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
            ),

            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
            const SizedBox(width: 8),

            // 缩放
            IconButton(icon: const Icon(Icons.zoom_in), tooltip: 'Zoom In', onPressed: _zoomIn),
            IconButton(icon: const Icon(Icons.zoom_out), tooltip: 'Zoom Out', onPressed: _zoomOut),
            IconButton(icon: const Icon(Icons.fit_screen), tooltip: 'Fit to Screen', onPressed: _fitToScreen),

            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
            const SizedBox(width: 8),

            // 布局
            IconButton(icon: const Icon(Icons.auto_fix_high), tooltip: 'Auto Layout', onPressed: _autoLayout),
          ],
        ),
      ),
    );
  }

  MouseCursor _getCursor(ERDiagramState state) {
    switch (_interactionState.type) {
      case InteractionType.nodeDrag:
        return SystemMouseCursors.grabbing;
      case InteractionType.edgeCreate:
        return SystemMouseCursors.click;
      case InteractionType.pan:
        return SystemMouseCursors.grab;
      default:
        if (state.interaction.mode == InteractionMode.move) {
          return SystemMouseCursors.grab;
        }
        return SystemMouseCursors.basic;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 视口操作
  // ═══════════════════════════════════════════════════════════════════

  void _zoomIn() {
    final scale = _transformController.value.getMaxScaleOnAxis() * 1.2;
    _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
  }

  void _zoomOut() {
    final scale = _transformController.value.getMaxScaleOnAxis() / 1.2;
    _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
  }

  void _fitToScreen() {
    _transformController.value = Matrix4.identity();
  }

  void _autoLayout() async {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final state = ref.read(erDiagramProvider(widget.moduleId));
    if (state.nodes.isEmpty) return;

    // 配置层次布局
    _layoutEngine.setConfig(const HierarchicalLayoutConfig(
      nodeSpacing: 60,
      rankSpacing: 120,
      direction: LayoutDirection.topToBottom,
    ));

    final positions = _layoutEngine.layout(state);
    notifier.applyLayout(positions);
    _fitToScreen();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 手势处理
  // ═══════════════════════════════════════════════════════════════════

  void _onPointerDown(PointerDownEvent event) {
    final diagramState = ref.read(erDiagramProvider(widget.moduleId));
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    _pointerDownPos = event.localPosition;
    _gestureClaimed = false;

    // 编辑模式下的交互
    if (diagramState.interaction.mode == InteractionMode.edit) {
      // 优先级 1: 字段锚点
      for (final node in diagramState.nodes.values) {
        final anchor = _nodeRenderer.hitTestAnchor(node, scenePos, 10.0);
        if (anchor != null && anchor.type == AnchorType.field) {
          _sourceAnchorId = anchor.id;
          _connectionStartPos = anchor.position;
          _connectionCurrentPos = scenePos;
          _gestureClaimed = true;
          _transitionTo(InteractionType.edgeCreate);
          notifier.startConnection(anchor.id);
          return;
        }
      }

      // 优先级 2: 节点主体
      for (final node in diagramState.nodes.values) {
        if (_nodeRenderer.hitTest(node, scenePos)) {
          // 检查是否点击锚点（排除）
          final anchorHit = _nodeRenderer.hitTestAnchor(node, scenePos, 10.0);
          if (anchorHit != null) continue;

          _draggedNodeId = node.id;
          _dragStartPos = scenePos;
          _nodeStartPos = node.position;
          _gestureClaimed = true;
          _transitionTo(InteractionType.nodeDrag);
          notifier.selectNode(node.id);
          notifier.startDrag(node.id);
          return;
        }
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    switch (_interactionState.type) {
      case InteractionType.edgeCreate:
        _connectionCurrentPos = scenePos;
        notifier.updateConnectionPreview(scenePos);
        setState(() {});
        break;

      case InteractionType.nodeDrag:
        if (_draggedNodeId != null) {
          final delta = scenePos - _dragStartPos;
          final newX = _nodeStartPos.dx + delta.dx;
          final newY = _nodeStartPos.dy + delta.dy;
          notifier.moveNode(_draggedNodeId!, newX, newY);
        }
        break;

      default:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final diagramState = ref.read(erDiagramProvider(widget.moduleId));
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    switch (_interactionState.type) {
      case InteractionType.edgeCreate:
        // 查找目标锚点
        for (final node in diagramState.nodes.values) {
          final anchor = _nodeRenderer.hitTestAnchor(node, scenePos, 10.0);
          if (anchor != null && anchor.id != _sourceAnchorId) {
            // 显示关系对话框
            _showRelationDialog(anchor);
            break;
          }
        }
        notifier.cancelConnection();
        break;

      case InteractionType.nodeDrag:
        if (_draggedNodeId != null) {
          notifier.endDrag(_draggedNodeId!);
        }
        break;

      default:
        // 处理点击
        if (!_gestureClaimed) {
          final delta = event.localPosition - _pointerDownPos;
          if (delta.distance < 5) {
            // 点击空白区域取消选择
            notifier.clearSelection();

            // 或点击节点（移动模式）
            if (diagramState.interaction.mode == InteractionMode.move) {
              for (final node in diagramState.nodes.values) {
                if (_nodeRenderer.hitTest(node, scenePos)) {
                  // 检测双击
                  final now = DateTime.now();
                  final isDoubleClick = _lastTappedNodeId == node.id &&
                      _lastTapTime != null &&
                      now.difference(_lastTapTime!) < _doubleClickThreshold;

                  if (isDoubleClick) {
                    final erNode = node as ERNode;
                    widget.onEntityEdit?.call(erNode.entity);
                    _lastTappedNodeId = null;
                    _lastTapTime = null;
                  } else {
                    notifier.selectNode(node.id);
                    _lastTappedNodeId = node.id;
                    _lastTapTime = now;
                  }
                  break;
                }
              }
            }
          }
        }
        break;
    }

    _resetInteraction();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    if (_interactionState.isConnecting) {
      notifier.cancelConnection();
    } else if (_draggedNodeId != null) {
      notifier.endDrag(_draggedNodeId!);
    }
    _resetInteraction();
  }

  void _showRelationDialog(AnchorPoint targetAnchor) {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    final diagramState = ref.read(erDiagramProvider(widget.moduleId));

    // 解析锚点信息
    final sourceParts = _sourceAnchorId!.split(':');
    final targetParts = targetAnchor.id.split(':');

    String? sourceField;
    String? targetField;

    for (var i = 0; i < sourceParts.length; i++) {
      if (sourceParts[i] == 'field' && i + 1 < sourceParts.length) {
        sourceField = sourceParts[i + 1];
        break;
      }
    }

    for (var i = 0; i < targetParts.length; i++) {
      if (targetParts[i] == 'field' && i + 1 < targetParts.length) {
        targetField = targetParts[i + 1];
        break;
      }
    }

    final sourceNode = diagramState.nodes[sourceParts.first] as ERNode?;
    final targetNode = diagramState.nodes[targetParts.first] as ERNode?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Relation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${sourceNode?.entity.title}.${sourceField ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(children: [Icon(Icons.arrow_downward, size: 16), SizedBox(width: 8), Text('relation')]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${targetNode?.entity.title}.${targetField ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Relation type:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('1:1'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('1:N'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('N:1'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('N:M'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              notifier.addEdgeWithFields(
                sourceParts.first,
                targetParts.first,
                sourceField: sourceField,
                targetField: targetField,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// ER 图绘制器
class ERDiagramPainter extends CustomPainter {
  final ERDiagramState state;
  final bool isDarkMode;
  final ERNodeRenderer nodeRenderer;
  final EREdgeRenderer edgeRenderer;
  final InteractionState interactionState;
  final Offset? connectionStartPos;
  final Offset connectionCurrentPos;

  ERDiagramPainter({
    required this.state,
    required this.isDarkMode,
    required this.nodeRenderer,
    required this.edgeRenderer,
    required this.interactionState,
    this.connectionStartPos,
    required this.connectionCurrentPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    _drawGrid(canvas, size);

    // 应用变换
    canvas.save();
    canvas.scale(state.viewport.zoom, state.viewport.zoom);
    canvas.translate(
      state.viewport.panOffset.dx / state.viewport.zoom,
      state.viewport.panOffset.dy / state.viewport.zoom,
    );

    final renderContext = RenderContext(
      scale: state.viewport.zoom,
      isDarkMode: isDarkMode,
      showAnchors: state.interaction.mode == InteractionMode.edit,
      interactionMode: state.interaction.mode,
    );

    // 绘制边（在节点下方）
    for (final edge in state.edges.values) {
      final erEdge = edge as ERRelationEdge;
      final sourceAnchor = state.getAnchor(erEdge.sourceAnchorId);
      final targetAnchor = state.getAnchor(erEdge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      final edgeState = state.getEdgeState(edge.id);
      edgeRenderer.paint(
        canvas: canvas,
        edge: erEdge,
        sourceAnchor: sourceAnchor,
        targetAnchor: targetAnchor,
        state: edgeState,
        context: renderContext,
      );
    }

    // 绘制节点（排序，选中的在最后）
    final sortedNodes = state.nodes.values.toList();
    sortedNodes.sort((a, b) {
      final aSelected = state.selection.isNodeSelected(a.id);
      final bSelected = state.selection.isNodeSelected(b.id);
      if (aSelected && !bSelected) return 1;
      if (!aSelected && bSelected) return -1;
      return 0;
    });

    for (final node in sortedNodes) {
      final nodeState = state.getNodeState(node.id);
      nodeRenderer.paint(
        canvas: canvas,
        node: node,
        state: nodeState.copyWith(
          isSelected: state.selection.isNodeSelected(node.id),
          isHovered: state.selection.hoveredNodeId == node.id,
        ),
        context: renderContext,
      );
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridSize = 20.0;
    final gridPaint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;

    final visibleRect = Rect.fromLTWH(
      -state.viewport.panOffset.dx / state.viewport.zoom,
      -state.viewport.panOffset.dy / state.viewport.zoom,
      size.width / state.viewport.zoom,
      size.height / state.viewport.zoom,
    );

    final startX = (visibleRect.left / gridSize).floor() * gridSize;
    for (var x = startX; x <= visibleRect.right; x += gridSize) {
      canvas.drawLine(Offset(x, visibleRect.top), Offset(x, visibleRect.bottom), gridPaint);
    }

    final startY = (visibleRect.top / gridSize).floor() * gridSize;
    for (var y = startY; y <= visibleRect.bottom; y += gridSize) {
      canvas.drawLine(Offset(visibleRect.left, y), Offset(visibleRect.right, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ERDiagramPainter old) {
    return old.state != state ||
        old.isDarkMode != isDarkMode ||
        old.interactionState != interactionState ||
        old.connectionCurrentPos != connectionCurrentPos;
  }
}

/// 连线预览绘制器
class ConnectionPreviewPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isDark;

  ConnectionPreviewPainter({required this.start, required this.end, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.blue.shade300 : Colors.blue.shade500).withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 虚线
    final d = (end - start).distance;
    final dir = (end - start) / d;
    const dash = 10.0, gap = 6.0;
    double t = 0;
    bool draw = true;

    while (t < d) {
      final seg = draw ? dash : gap;
      final next = math.min(t + seg, d);
      if (draw) canvas.drawLine(start + dir * t, start + dir * next, paint);
      t = next;
      draw = !draw;
    }

    // 箭头
    final angle = dir.direction;
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 10 * math.cos(angle - math.pi / 6), end.dy - 10 * math.sin(angle - math.pi / 6))
      ..lineTo(end.dx - 10 * math.cos(angle + math.pi / 6), end.dy - 10 * math.sin(angle + math.pi / 6))
      ..close();
    canvas.drawPath(arrow, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ConnectionPreviewPainter old) => old.start != start || old.end != end;
}