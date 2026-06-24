import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import '../core/er_graph_edge.dart';
import '../core/field_anchor_registry.dart';
import '../core/graph_sync.dart';
import '../layout/layout_adapter.dart';
import '../models/er_diagram_models.dart';
import '../providers/er_diagram_provider.dart';
import 'er_node_builder.dart';

/// ER 图画布（基于 graphview）
///
/// 使用 graphview 库渲染 ER 图，提供：
/// - 节点拖拽
/// - 字段级连线
/// - 自动布局
/// - 缩放/平移
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
  /// graphview 控制器
  late GraphViewController _graphViewController;

  /// graphview 同步器
  late ERDiagramGraphSync _graphSync;

  /// 布局适配器
  late GraphViewLayoutAdapter _layoutAdapter;

  /// 变换控制器
  late TransformationController _transformController;

  /// 当前选中的节点 ID
  final Set<String> _selectedNodeIds = {};

  /// 当前悬停的节点 ID
  String? _hoveredNodeId;

  /// 连线预览状态
  FieldAnchor? _sourceAnchor;
  Offset _connectionPreviewEnd = Offset.zero;
  bool _isConnecting = false;

  /// 交互模式
  InteractionMode _interactionMode = InteractionMode.move;

  @override
  void initState() {
    super.initState();

    _graphViewController = GraphViewController();
    _transformController = TransformationController();
    _graphSync = ERDiagramGraphSync();
    _layoutAdapter = GraphViewLayoutAdapter();

    // 延迟初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromState();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// 从状态同步到 graphview
  void _syncFromState() {
    final state = ref.read(erDiagramProvider(widget.moduleId));
    if (state is ERDiagramState) {
      _graphSync.syncFromState(state);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(erDiagramProvider(widget.moduleId));

    if (state is! ERDiagramState) {
      return const Center(child: Text('无法加载 ER 图'));
    }

    // 同步状态
    _graphSync.syncFromState(state);

    return Stack(
      children: [
        // 主画布
        _buildGraphView(state, isDark),

        // 工具栏
        Positioned(
          top: 16,
          right: 16,
          child: _buildToolbar(isDark),
        ),

        // 连线预览
        if (_isConnecting && _sourceAnchor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConnectionPreviewPainter(
                  sourcePos: _sourceAnchor!.position,
                  targetPos: _connectionPreviewEnd,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade500,
                ),
              ),
            ),
          ),

        // 空状态提示
        if (_graphSync.nodeCount == 0) _buildEmptyState(isDark),
      ],
    );
  }

  /// 构建 GraphView
  Widget _buildGraphView(ERDiagramState state, bool isDark) {
    // 创建节点构建器
    final entityMap = <String, Entity>{};
    for (final entry in state.nodes.entries) {
      final erNode = entry.value as ERNode;
      entityMap[entry.key] = erNode.entity;
    }

    final builder = ERNodeWidgetBuilderState(
      selectedNodeIds: _selectedNodeIds,
      hoveredNodeId: _hoveredNodeId,
      interactionMode: _interactionMode,
      isDarkMode: isDark,
    ).createBuilder(
      entityMap: entityMap,
      onAnchorTap: _onAnchorTap,
      onNodeTap: _onNodeTap,
      onNodeDoubleTap: _onNodeDoubleTap,
    );

    // 设置布局算法
    _layoutAdapter.setConfig(const HierarchicalLayoutConfig(
      nodeSpacing: 60,
      rankSpacing: 120,
    ));

    return GraphView.builder(
      graph: _graphSync.graph,
      algorithm: _layoutAdapter.algorithm ?? SugiyamaAlgorithm(SugiyamaConfiguration()),
      controller: _graphViewController,
      builder: builder.build(),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(bool isDark) {
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
          // 模式切换
          TDButton(
            theme: _interactionMode == InteractionMode.edit
                ? TDButtonTheme.primary
                : TDButtonTheme.defaultTheme,
            icon: _interactionMode == InteractionMode.edit
                ? TDIcons.edit
                : TDIcons.unfold_more,
            onTap: () => setState(() {
              _interactionMode = _interactionMode == InteractionMode.edit
                  ? InteractionMode.move
                  : InteractionMode.edit;
            }),
          ),
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
          // 布局按钮
          TDButton(
            icon: TDIcons.view_module,
            onTap: _autoLayout,
          ),
        ],
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

  /// 锚点点击处理
  void _onAnchorTap(FieldAnchor anchor) {
    if (_interactionMode != InteractionMode.edit) return;

    if (!_isConnecting) {
      // 开始连线
      setState(() {
        _sourceAnchor = anchor;
        _isConnecting = true;
        _connectionPreviewEnd = anchor.position;
      });
    } else {
      // 完成连线
      if (_sourceAnchor != null &&
          _sourceAnchor!.nodeId != anchor.nodeId) {
        _createRelation(_sourceAnchor!, anchor);
      }

      setState(() {
        _sourceAnchor = null;
        _isConnecting = false;
      });
    }
  }

  /// 创建关系
  void _createRelation(FieldAnchor source, FieldAnchor target) {
    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);

    // 获取源节点和目标节点
    final sourceNode = _graphSync.getNode(source.nodeId);
    final targetNode = _graphSync.getNode(target.nodeId);

    if (sourceNode == null || targetNode == null) return;

    // 显示关系对话框
    _showRelationDialog(source, target, notifier);
  }

  /// 显示关系对话框
  void _showRelationDialog(
    FieldAnchor source,
    FieldAnchor target,
    ERDiagramNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => _RelationDialog(
        sourceField: source.field,
        targetField: target.field,
        onConfirm: (relationType, label) {
          notifier.addEdgeWithFields(
            source.nodeId,
            target.nodeId,
            sourceField: source.field.name,
            targetField: target.field.name,
            relationType: relationType,
            label: label,
          );
        },
      ),
    );
  }

  /// 节点点击处理
  void _onNodeTap(String nodeId) {
    setState(() {
      if (_selectedNodeIds.contains(nodeId)) {
        _selectedNodeIds.remove(nodeId);
      } else {
        _selectedNodeIds.add(nodeId);
      }
    });
  }

  /// 节点双击处理
  void _onNodeDoubleTap(String nodeId) {
    final state = ref.read(erDiagramProvider(widget.moduleId));
    if (state is ERDiagramState) {
      final erNode = state.getERNode(nodeId);
      if (erNode != null) {
        widget.onEntityEdit?.call(erNode.entity);
      }
    }
  }

  /// 放大
  void _zoomIn() {
    final scale = _transformController.value.getMaxScaleOnAxis() * 1.2;
    _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
  }

  /// 缩小
  void _zoomOut() {
    final scale = _transformController.value.getMaxScaleOnAxis() / 1.2;
    _transformController.value = Matrix4.identity()..scale(scale.clamp(0.1, 5.0));
  }

  /// 适应屏幕
  void _fitToScreen() {
    _graphViewController.zoomToFit();
  }

  /// 自动布局
  void _autoLayout() {
    _layoutAdapter.runLayout(_graphSync.graph);

    // 获取布局后的位置并更新状态
    final positions = _layoutAdapter.getNodePositions(_graphSync.graph);

    final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
    notifier.applyLayout(positions);

    setState(() {});
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

    // 绘制虚线
    _drawDashedLine(canvas, sourcePos, targetPos, paint);

    // 绘制箭头
    _drawArrow(canvas, targetPos, sourcePos, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (dx * dx + dy * dy);

    if (distance == 0) return;

    final length = math.sqrt(distance);
    final unitX = dx / length;
    final unitY = dy / length;

    var currentDistance = 0.0;
    while (currentDistance < length) {
      final dashStartX = start.dx + unitX * currentDistance;
      final dashStartY = start.dy + unitY * currentDistance;
      final dashEndX = start.dx + unitX * (currentDistance + dashLength).clamp(0, length);
      final dashEndY = start.dy + unitY * (currentDistance + dashLength).clamp(0, length);

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

/// 关系对话框
class _RelationDialog extends StatefulWidget {
  final Field sourceField;
  final Field targetField;
  final void Function(String relationType, String? label) onConfirm;

  const _RelationDialog({
    required this.sourceField,
    required this.targetField,
    required this.onConfirm,
  });

  @override
  State<_RelationDialog> createState() => _RelationDialogState();
}

class _RelationDialogState extends State<_RelationDialog> {
  String _relationType = '1:N';
  String? _label;

  @override
  Widget build(BuildContext context) {
    return TDAlertDialog(
      title: '创建关系',
      content: '源字段: ${widget.sourceField.name} → 目标字段: ${widget.targetField.name}\n\n关系类型: 1:N',
      leftBtn: TDDialogButtonOptions(
        title: '取消',
        action: () => Navigator.of(context).pop(),
      ),
      rightBtn: TDDialogButtonOptions(
        title: '确定',
        action: () {
          widget.onConfirm('1:N', null);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}