import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../models/flowchart_models.dart';
import '../renderers/flowchart_renderers.dart';

/// 流程图状态 Provider
final flowDiagramProvider = StateProvider<FlowDiagramState>((ref) {
  return FlowDiagramState.createSample();
});

/// 流程图画布 Widget
///
/// 使用混合架构实现：
/// - DiagramCanvas 基类提供通用画布功能
/// - FlowNodeRenderer/FlowEdgeRenderer 提供自定义渲染
/// - TreeLayout 提供树形布局
class FlowchartCanvas extends ConsumerStatefulWidget {
  const FlowchartCanvas({super.key});

  @override
  ConsumerState<FlowchartCanvas> createState() => _FlowchartCanvasState();
}

class _FlowchartCanvasState extends ConsumerState<FlowchartCanvas> {
  final TransformationController _transformController = TransformationController();
  final FlowNodeRenderer _nodeRenderer = FlowNodeRenderer();
  final FlowEdgeRenderer _edgeRenderer = FlowEdgeRenderer();
  final GraphViewLayoutEngine _layoutEngine = GraphViewLayoutEngine();

  InteractionState _interactionState = const InteractionState();
  String? _draggedNodeId;
  Offset _dragStartPos = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Offset _toScene(Offset local) {
    final matrix = _transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, local);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flowDiagramProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        SizedBox.expand(
          child: MouseRegion(
            cursor: _getCursor(state),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false,
                panEnabled: _interactionState.isIdle,
                scaleEnabled: true,
                child: CustomPaint(
                  size: const Size(2000, 2000),
                  painter: FlowchartPainter(
                    state: state,
                    isDarkMode: isDark,
                    nodeRenderer: _nodeRenderer,
                    edgeRenderer: _edgeRenderer,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 工具栏
        Positioned(
          top: 12,
          right: 12,
          child: _buildToolbar(state, isDark),
        ),
      ],
    );
  }

  Widget _buildToolbar(FlowDiagramState state, bool isDark) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom In',
              onPressed: () {
                final scale = _transformController.value.getMaxScaleOnAxis() * 1.2;
                _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom Out',
              onPressed: () {
                final scale = _transformController.value.getMaxScaleOnAxis() / 1.2;
                _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
              },
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Fit to Screen',
              onPressed: () => _transformController.value = Matrix4.identity(),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'Auto Layout (Tree)',
              onPressed: _autoLayout,
            ),
          ],
        ),
      ),
    );
  }

  MouseCursor _getCursor(FlowDiagramState state) {
    if (_interactionState.isNodeDrag) {
      return SystemMouseCursors.grabbing;
    }
    return SystemMouseCursors.basic;
  }

  void _onPointerDown(PointerDownEvent event) {
    final state = ref.read(flowDiagramProvider);
    final scenePos = _toScene(event.localPosition);

    // 检查是否点击节点
    for (final node in state.nodes.values) {
      final flowNode = node as FlowNode;
      if (_nodeRenderer.hitTest(flowNode, scenePos)) {
        setState(() {
          _draggedNodeId = node.id;
          _dragStartPos = scenePos;
          _nodeStartPos = node.position;
          _interactionState = _interactionState.copyWith(type: InteractionType.nodeDrag);
        });

        // 更新选择
        ref.read(flowDiagramProvider.notifier).state = state.copyWith(
          selection: state.selection.copyWith(selectedNodeIds: {node.id}),
        );
        return;
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_interactionState.isNodeDrag && _draggedNodeId != null) {
      final state = ref.read(flowDiagramProvider);
      final scenePos = _toScene(event.localPosition);
      final delta = scenePos - _dragStartPos;
      final newX = _nodeStartPos.dx + delta.dx;
      final newY = _nodeStartPos.dy + delta.dy;

      // 更新节点位置
      final node = state.nodes[_draggedNodeId!] as FlowNode;
      final newNodes = Map<String, DiagramNode>.from(state.nodes);
      newNodes[_draggedNodeId!] = node.copyWith(position: Offset(newX, newY));

      ref.read(flowDiagramProvider.notifier).state = state.copyWith(nodes: newNodes);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _interactionState = const InteractionState();
      _draggedNodeId = null;
    });
  }

  void _autoLayout() {
    final state = ref.read(flowDiagramProvider);

    // 配置树形布局
    _layoutEngine.setConfig(const TreeLayoutConfig(
      nodeSpacing: 80,
      rankSpacing: 100,
      direction: LayoutDirection.topToBottom,
    ));

    final positions = _layoutEngine.layout(state);

    // 应用布局
    final newNodes = <String, DiagramNode>{};
    for (final entry in state.nodes.entries) {
      final node = entry.value as FlowNode;
      final position = positions[entry.key];
      if (position != null) {
        newNodes[entry.key] = node.copyWith(position: position);
      } else {
        newNodes[entry.key] = node;
      }
    }

    ref.read(flowDiagramProvider.notifier).state = state.copyWith(nodes: newNodes);
    _transformController.value = Matrix4.identity();
  }
}

/// 流程图绘制器
class FlowchartPainter extends CustomPainter {
  final FlowDiagramState state;
  final bool isDarkMode;
  final FlowNodeRenderer nodeRenderer;
  final FlowEdgeRenderer edgeRenderer;

  FlowchartPainter({
    required this.state,
    required this.isDarkMode,
    required this.nodeRenderer,
    required this.edgeRenderer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    _drawGrid(canvas, size);

    // 应用变换
    canvas.save();
    canvas.scale(state.viewport.zoom, state.viewport.zoom);

    final renderContext = RenderContext(
      scale: state.viewport.zoom,
      isDarkMode: isDarkMode,
      showAnchors: false,
      interactionMode: state.interaction.mode,
    );

    // 绘制边
    for (final edge in state.edges.values) {
      final flowEdge = edge as FlowEdge;
      final sourceAnchor = state.getAnchor(flowEdge.sourceAnchorId);
      final targetAnchor = state.getAnchor(flowEdge.targetAnchorId);

      if (sourceAnchor == null || targetAnchor == null) continue;

      edgeRenderer.paint(
        canvas: canvas,
        edge: flowEdge,
        sourceAnchor: sourceAnchor,
        targetAnchor: targetAnchor,
        state: state.getEdgeState(edge.id),
        context: renderContext,
      );
    }

    // 绘制节点
    for (final node in state.nodes.values) {
      final flowNode = node as FlowNode;
      nodeRenderer.paint(
        canvas: canvas,
        node: flowNode,
        state: state.getNodeState(node.id).copyWith(
          isSelected: state.selection.isNodeSelected(node.id),
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
  bool shouldRepaint(covariant FlowchartPainter old) {
    return old.state != state || old.isDarkMode != isDarkMode;
  }
}