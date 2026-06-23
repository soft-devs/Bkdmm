import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';
import '../../../project/providers/project_notifier.dart';
import '../layout/dagre_layout.dart';
import '../painters/er_graph_painter.dart';
import '../painters/node_painter.dart';
import '../providers/graph_provider.dart';

/// Interaction state machine for ER diagram
///
/// States:
/// - IDLE: No active interaction, InteractiveViewer handles pan/zoom
/// - DRAG_NODE: Dragging a node, pan disabled
/// - DRAG_EDGE: Creating edge from anchor, pan disabled
/// - PAN_CANVAS: Panning canvas (handled by InteractiveViewer)
enum InteractionState {
  idle,
  dragNode,
  dragEdge,
  panCanvas,
}

/// Main ER Diagram visualization widget.
///
/// PDManER-style interaction with explicit state machine:
/// - Move Mode: pan/zoom canvas, click to select nodes (default)
/// - Edit Mode: drag nodes, create edges from anchors
///
/// Interactions:
/// - Single click: select node
/// - Double click: edit entity (opens dialog)
/// - Right click: context menu
class ERDiagramWidget extends ConsumerStatefulWidget {
  final String moduleId;
  final void Function(Entity entity)? onEntityEdit;
  final void Function(Offset position, Entity? entity)? onContextMenu;

  const ERDiagramWidget({
    super.key,
    required this.moduleId,
    this.onEntityEdit,
    this.onContextMenu,
  });

  @override
  ConsumerState<ERDiagramWidget> createState() => _ERDiagramWidgetState();
}

class _ERDiagramWidgetState extends ConsumerState<ERDiagramWidget> {
  final GlobalKey _paintKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  // State machine
  InteractionState _interactionState = InteractionState.idle;

  // Node drag state
  String? _draggedNodeId;
  Offset _dragStart = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  // Edge creation state
  Offset? _edgeDragStart;
  String? _edgeSourceNodeId;
  int? _edgeSourceFieldIndex; // Which field was hit
  Offset _edgeCurrentPos = Offset.zero;

  // Track if we've started a definite gesture
  bool _gestureClaimed = false;
  Offset _pointerDownPos = Offset.zero;

  // Double click detection
  String? _lastClickedNodeId;
  DateTime? _lastClickTime;
  static const _doubleClickThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(erGraphProvider(widget.moduleId).notifier).postInit();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // ── Graph ↔ screen coordinate helpers ──

  Offset _toScene(Offset local) {
    final matrix = _transformController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, local);
  }

  Offset _toScreen(Offset scene) {
    final matrix = _transformController.value;
    return MatrixUtils.transformPoint(matrix, scene);
  }

  // ── State Machine Helpers ──

  /// Check if pan should be enabled (only in IDLE state)
  bool get _panEnabled => _interactionState == InteractionState.idle;

  /// Transition to a new state
  void _transitionTo(InteractionState newState) {
    if (_interactionState != newState) {
      debugPrint('State transition: $_interactionState -> $newState');
      _interactionState = newState;
      // Trigger rebuild to update panEnabled
      setState(() {});
    }
  }


  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(erGraphProvider(widget.moduleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // React to project changes (e.g. entity added from tree)
    // This listener triggers when any project data changes
    ref.listen(projectNotifierProvider, (prev, next) {
      if (next.project != null) {
        try {
          final module = next.project!.modules.firstWhere((m) => m.id == widget.moduleId);
          final prevModule = prev?.project?.modules.where((m) => m.id == widget.moduleId).firstOrNull;

          // Reload if:
          // 1. Module is new (prevModule is null)
          // 2. Entity count changed
          // 3. Entity content changed (compare by title)
          bool shouldReload = false;

          if (prevModule == null) {
            shouldReload = true;
          } else if (module.entities.length != prevModule.entities.length) {
            shouldReload = true;
          } else {
            // Check if any entity was modified
            for (int i = 0; i < module.entities.length; i++) {
              if (i >= prevModule.entities.length ||
                  module.entities[i].title != prevModule.entities[i].title ||
                  module.entities[i].fields.length != prevModule.entities[i].fields.length) {
                shouldReload = true;
                break;
              }
            }
          }

          if (shouldReload) {
            ref.read(erGraphProvider(widget.moduleId).notifier).reload();
          }
        } catch (_) {
          // Module not found, ignore
        }
      }
    });

    return Stack(
      children: [
        // Canvas with InteractiveViewer
        SizedBox.expand(
          child: MouseRegion(
            cursor: _getCursor(graphState),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: _onPointerSignal,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false,
                panEnabled: _panEnabled, // Dynamic based on state machine
                scaleEnabled: true,
                child: CustomPaint(
                  key: _paintKey,
                  size: _canvasSize(graphState),
                  painter: ERGraphPainter(
                    graphState: graphState,
                    isDarkMode: isDark,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Toolbar
        Positioned(top: 12, right: 12, child: _toolbar(graphState, isDark)),

        // Empty state hint
        if (graphState.nodes.isEmpty)
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

        // Edge preview overlay (only when in DRAG_EDGE state)
        if (_interactionState == InteractionState.dragEdge && _edgeDragStart != null)
          _EdgePreviewLine(
            start: _toScreen(_edgeDragStart!),
            end: _toScreen(_edgeCurrentPos),
            isDark: isDark,
          ),
      ],
    );
  }

  Size _canvasSize(ERGraphState s) {
    if (s.nodes.isEmpty) return const Size(4000, 4000);
    double maxX = 0, maxY = 0;
    for (final n in s.nodes) {
      final sz = n.entity != null
          ? NodePainter.calculateNodeSize(n.entity!)
          : const Size(NodePainter.defaultWidth, NodePainter.minHeight);
      maxX = math.max(maxX, n.x + sz.width);
      maxY = math.max(maxY, n.y + sz.height);
    }
    return Size(
      (maxX + 200).clamp(2000, 10000),
      (maxY + 200).clamp(2000, 10000),
    );
  }

  // ── Pointer handling with State Machine ──

  void _onPointerSignal(PointerSignalEvent event) {
    // Scroll events are handled by InteractiveViewer for zoom
  }

  void _onPointerDown(PointerDownEvent event) {
    final graphState = ref.read(erGraphProvider(widget.moduleId));
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    // Store initial position for gesture disambiguation
    _pointerDownPos = event.localPosition;
    _gestureClaimed = false;

    // Only handle interactions in edit mode
    if (graphState.interactionMode == InteractionMode.edit) {
      // Priority 1: Field anchor hit → start edge creation (field-to-field)
      final fieldAnchorHit = ERGraphPainter.hitTestFieldAnchor(graphState, scenePos);
      if (fieldAnchorHit != null) {
        final (node, fieldIndex, isLeft) = fieldAnchorHit;

        // Get the exact anchor position
        final anchorPos = ERGraphPainter.getFieldAnchorPosition(node, fieldIndex, isLeft);

        _edgeSourceNodeId = node.id;
        _edgeSourceFieldIndex = fieldIndex;
        _edgeDragStart = anchorPos ?? scenePos;
        _edgeCurrentPos = scenePos;
        _gestureClaimed = true;
        _transitionTo(InteractionState.dragEdge);
        graphNotifier.startEdgeCreation(node.id);
        return;
      }

      // Priority 2: Node body hit → potential node drag (excludes anchors)
      final hitNode = ERGraphPainter.hitTestNode(graphState, scenePos);
      if (hitNode != null) {
        _draggedNodeId = hitNode.id;
        _dragStart = scenePos;
        _nodeStartPos = Offset(hitNode.x, hitNode.y);
        _gestureClaimed = true;
        _transitionTo(InteractionState.dragNode);
        graphNotifier.selectNode(hitNode.id);
        graphNotifier.startDrag(hitNode.id);
        return;
      }
    }

    // No hit or move mode → let InteractiveViewer handle pan
    // State stays IDLE, panEnabled is true
  }

  void _onPointerMove(PointerMoveEvent event) {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    // Handle based on current state
    switch (_interactionState) {
      case InteractionState.dragEdge:
        // Update edge preview position
        _edgeCurrentPos = scenePos;
        graphNotifier.updateEdgePreview(scenePos);
        // Force rebuild to update overlay
        setState(() {});
        break;

      case InteractionState.dragNode:
        // Move the node
        if (_draggedNodeId != null) {
          final delta = scenePos - _dragStart;
          final newX = _nodeStartPos.dx + delta.dx;
          final newY = _nodeStartPos.dy + delta.dy;
          graphNotifier.moveNode(_draggedNodeId!, newX, newY);
        }
        break;

      case InteractionState.idle:
        // Check if we should start panning (movement threshold)
        if (!_gestureClaimed) {
          final delta = event.localPosition - _pointerDownPos;
          if (delta.distance > 5) {
            // InteractiveViewer will handle this
            // We just stay idle and let it pan
          }
        }
        break;

      case InteractionState.panCanvas:
        // InteractiveViewer handles this
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final graphState = ref.read(erGraphProvider(widget.moduleId));
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final scenePos = _toScene(event.localPosition);

    // Handle based on current state
    switch (_interactionState) {
      case InteractionState.dragEdge:
        // Try to complete edge creation
        // Check if we hit a field anchor on another node
        final targetFieldAnchor = ERGraphPainter.hitTestFieldAnchor(graphState, scenePos);

        if (targetFieldAnchor != null) {
          final (targetNode, targetFieldIndex, targetIsLeft) = targetFieldAnchor;

          // Don't connect to same node
          if (targetNode.id != _edgeSourceNodeId) {
            // Get source and target field names
            final sourceNode = graphState.getNode(_edgeSourceNodeId!);
            final sourceFieldName = _getFieldName(sourceNode, _edgeSourceFieldIndex!);
            final targetFieldName = _getFieldName(targetNode, targetFieldIndex);

            // Show relationship dialog with field info
            _showRelationDialogWithFields(
              _edgeSourceNodeId!,
              sourceFieldName,
              targetNode.id,
              targetFieldName,
            );
          } else {
            graphNotifier.cancelEdgeCreation();
          }
        } else {
          // No valid target, cancel
          graphNotifier.cancelEdgeCreation();
        }
        break;

      case InteractionState.dragNode:
        // Finish node drag
        if (_draggedNodeId != null) {
          // Check if it was a click vs drag
          final delta = scenePos - _dragStart;
          if (delta.distance < 5) {
            // It was a click, not a drag - clear selection if clicking empty space
            final hitNode = ERGraphPainter.hitTestNode(graphState, scenePos);
            if (hitNode == null) {
              graphNotifier.clearSelection();
            }
          }
          graphNotifier.endDrag(_draggedNodeId!);
        }
        break;

      case InteractionState.idle:
        // Handle click (no movement)
        if (!_gestureClaimed) {
          final delta = event.localPosition - _pointerDownPos;
          if (delta.distance < 5) {
            // It was a click
            final hitNode = ERGraphPainter.hitTestNode(graphState, scenePos);
            if (hitNode == null) {
              graphNotifier.clearSelection();
            } else {
              // Check for double click
              final now = DateTime.now();
              final isDoubleClick = _lastClickedNodeId == hitNode.id &&
                  _lastClickTime != null &&
                  now.difference(_lastClickTime!) < _doubleClickThreshold;

              if (isDoubleClick) {
                // Double click - open edit dialog
                if (hitNode.entity != null) {
                  widget.onEntityEdit?.call(hitNode.entity!);
                }
                _lastClickedNodeId = null;
                _lastClickTime = null;
              } else {
                // Single click - select node
                _lastClickedNodeId = hitNode.id;
                _lastClickTime = now;
                if (graphState.interactionMode == InteractionMode.move) {
                  graphNotifier.selectNode(hitNode.id);
                }
              }
            }
          }
        }
        break;

      case InteractionState.panCanvas:
        // InteractiveViewer finished panning
        break;
    }

    // Always reset to idle after pointer up
    _resetToIdle();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    // Cancel any ongoing operation
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);

    if (_interactionState == InteractionState.dragEdge) {
      graphNotifier.cancelEdgeCreation();
    } else if (_interactionState == InteractionState.dragNode && _draggedNodeId != null) {
      graphNotifier.endDrag(_draggedNodeId!);
    }

    _resetToIdle();
  }

  /// Get field name from node and field index
  String? _getFieldName(ERGraphNode? node, int fieldIndex) {
    if (node == null || node.entity == null) return null;
    if (fieldIndex < 0 || fieldIndex >= node.entity!.fields.length) return null;
    return node.entity!.fields[fieldIndex].name;
  }

  /// Reset to idle state
  void _resetToIdle() {
    _draggedNodeId = null;
    _edgeSourceNodeId = null;
    _edgeSourceFieldIndex = null;
    _edgeDragStart = null;
    _edgeCurrentPos = Offset.zero;
    _gestureClaimed = false;
    _transitionTo(InteractionState.idle);
  }

  void _showRelationDialogWithFields(
    String sourceId,
    String? sourceFieldName,
    String targetId,
    String? targetFieldName,
  ) {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    final sourceNode = graphState.getNode(sourceId);
    final targetNode = graphState.getNode(targetId);

    final sourceTableName = sourceNode?.data.title.split(':').first ?? sourceId;
    final targetTableName = targetNode?.data.title.split(':').first ?? targetId;

    final sourceFieldDisplay = sourceFieldName ?? 'Unknown';
    final targetFieldDisplay = targetFieldName ?? 'Unknown';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Relation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection info
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
                      Icon(Icons.table_chart, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$sourceTableName.$sourceFieldDisplay',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 16),
                      const SizedBox(width: 8),
                      Text('relation'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.table_chart, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$targetTableName.$targetFieldDisplay',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Relation type selection
            const Text('Relation type:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('1:1'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('1:N'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('N:1'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('N:M'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              graphNotifier.addEdgeWithFields(
                sourceId,
                targetId,
                sourceField: sourceFieldName,
                targetField: targetFieldName,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  MouseCursor _getCursor(ERGraphState graphState) {
    switch (_interactionState) {
      case InteractionState.dragNode:
        return SystemMouseCursors.grabbing;
      case InteractionState.dragEdge:
        return SystemMouseCursors.click;
      case InteractionState.panCanvas:
        return SystemMouseCursors.grab;
      case InteractionState.idle:
        if (graphState.interactionMode == InteractionMode.move) {
          return SystemMouseCursors.grab;
        }
        return SystemMouseCursors.basic;
    }
  }

  // ── Toolbar ──

  Widget _toolbar(ERGraphState graphState, bool isDark) {
    final notifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final editMode = graphState.interactionMode == InteractionMode.edit;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode toggle
            _ToolBtn(
              icon: editMode ? Icons.edit : Icons.pan_tool,
              tooltip: editMode ? 'Edit Mode' : 'Move Mode',
              active: true,
              onTap: () => notifier.toggleInteractionMode(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: (editMode ? Colors.green : Colors.blue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(editMode ? 'EDIT' : 'MOVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: editMode ? Colors.green.shade700 : Colors.blue.shade700)),
            ),

            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
            const SizedBox(width: 8),

            // Zoom
            _ToolBtn(icon: Icons.zoom_in, tooltip: 'Zoom in', onTap: _zoomIn),
            _ToolBtn(icon: Icons.zoom_out, tooltip: 'Zoom out', onTap: _zoomOut),
            _ToolBtn(icon: Icons.fit_screen, tooltip: 'Fit to screen', onTap: _fitToScreen),

            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
            const SizedBox(width: 8),

            // Layout & export
            _ToolBtn(icon: Icons.auto_fix_high, tooltip: 'Auto layout', onTap: _autoLayout),
            _ToolBtn(icon: Icons.image, tooltip: 'Export image', onTap: () {}),
          ],
        ),
      ),
    );
  }

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
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final graphState = ref.read(erGraphProvider(widget.moduleId));
    if (graphState.nodes.isEmpty) return;

    graphNotifier.setLayouting(true);
    final layout = DagreLayout();
    final nodeIds = graphState.nodes.map((n) => n.id).toList();
    final edges = graphState.edges.map((e) => LayoutEdge(source: e.source, target: e.target)).toList();

    Size getSize(String id) {
      final node = graphState.getNode(id);
      if (node?.entity != null) return NodePainter.calculateNodeSize(node!.entity!);
      return const Size(NodePainter.defaultWidth, NodePainter.minHeight);
    }

    final positions = layout.layout(nodes: nodeIds, edges: edges, nodeSize: getSize);
    graphNotifier.applyLayout(positions.map((k, v) => MapEntry(k, v)));
    graphNotifier.setLayouting(false);

    _transformController.value = Matrix4.identity();
  }
}

// ── Toolbar button ──

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const _ToolBtn({required this.icon, required this.tooltip, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

// ── Edge preview overlay ──

class _EdgePreviewLine extends StatelessWidget {
  final Offset start;
  final Offset end;
  final bool isDark;

  const _EdgePreviewLine({required this.start, required this.end, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _EdgePreviewPainter(start: start, end: end, isDark: isDark),
    );
  }
}

class _EdgePreviewPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isDark;

  _EdgePreviewPainter({required this.start, required this.end, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.blue.shade300 : Colors.blue.shade500).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dashed line
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

    // Arrow
    final angle = dir.direction;
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 10 * math.cos(angle - math.pi / 6), end.dy - 10 * math.sin(angle - math.pi / 6))
      ..lineTo(end.dx - 10 * math.cos(angle + math.pi / 6), end.dy - 10 * math.sin(angle + math.pi / 6))
      ..close();
    canvas.drawPath(arrow, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _EdgePreviewPainter old) => old.start != start || old.end != end;
}
