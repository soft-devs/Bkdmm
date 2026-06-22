import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';
import '../../../project/providers/project_notifier.dart';
import '../export/image_export.dart';
import '../layout/dagre_layout.dart';
import '../painters/er_graph_painter.dart';
import '../painters/node_painter.dart';
import '../providers/graph_provider.dart';

/// Main ER Diagram visualization widget
///
/// Provides interactive visualization of entity-relationship diagrams with:
/// - Zoom and pan controls
/// - Node selection and dragging
/// - Double-click to open entity editor
/// - Auto-layout functionality
/// - Image export
class ERDiagramWidget extends ConsumerStatefulWidget {
  /// The module ID to display
  final String moduleId;

  /// Callback when an entity is selected for editing
  final void Function(Entity entity)? onEntityEdit;

  /// Callback when context menu is requested
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
  /// Key for the CustomPaint for image export
  final GlobalKey _paintKey = GlobalKey();

  /// Current transformation controller
  final TransformationController _transformController = TransformationController();

  /// Whether we're currently dragging a node
  bool _isDragging = false;

  /// The node being dragged
  String? _draggedNodeId;

  /// Drag start position
  Offset _dragStart = Offset.zero;

  /// Node position at drag start
  Offset _nodeStartPos = Offset.zero;

  /// Last tap position for context menu
  Offset _lastTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Initialize transform from saved viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromSavedViewport();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _initializeFromSavedViewport() {
    // Load viewport from project if available
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;

    try {
      final module = project.modules.firstWhere((m) => m.id == widget.moduleId);
      final viewport = module.graphCanvas.viewport;
      if (viewport != null) {
        _transformController.value = Matrix4.identity()
          ..translate(viewport.offsetX, viewport.offsetY)
          ..scale(viewport.scale);
      }
    } catch (_) {
      // Module not found or no viewport, use default
    }
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(erGraphProvider(widget.moduleId));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Main diagram area
        GestureDetector(
          onTapDown: _onTapDown,
          onTap: _onTap,
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: _onDoubleTap,
          onLongPressStart: _onLongPressStart,
          onSecondaryTapDown: _onSecondaryTapDown,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            color: isDarkMode ? const Color(0xFF1A202C) : Colors.grey.shade100,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.1,
                maxScale: 3.0,
                constrained: false,
                onInteractionUpdate: _onInteractionUpdate,
                child: CustomPaint(
                  key: _paintKey,
                  size: _calculateCanvasSize(graphState),
                  painter: ERGraphPainter(
                    graphState: graphState,
                    isDarkMode: isDarkMode,
                    hoveredNodeId: graphState.hoveredNodeId,
                    searchQuery: graphState.searchQuery,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Toolbar overlay
        Positioned(
          top: 16,
          right: 16,
          child: _buildToolbar(graphState, isDarkMode),
        ),

        // Empty state
        if (graphState.nodes.isEmpty) _buildEmptyState(isDarkMode),

        // Search overlay
        if (graphState.searchQuery.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: _buildSearchIndicator(graphState),
          ),

        // Zoom indicator
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildZoomIndicator(graphState),
        ),
      ],
    );
  }

  /// Build the toolbar
  Widget _buildToolbar(ERGraphState graphState, bool isDarkMode) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: isDarkMode ? const Color(0xFF2D3748) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom in
            _ToolbarButton(
              icon: Icons.zoom_in,
              tooltip: 'Zoom In',
              onPressed: () => _zoomIn(graphState),
            ),
            const SizedBox(width: 4),

            // Zoom out
            _ToolbarButton(
              icon: Icons.zoom_out,
              tooltip: 'Zoom Out',
              onPressed: () => _zoomOut(graphState),
            ),
            const SizedBox(width: 4),

            // Fit to screen
            _ToolbarButton(
              icon: Icons.fit_screen,
              tooltip: 'Fit to Screen',
              onPressed: () => _fitToScreen(graphState),
            ),
            const SizedBox(width: 8),

            // Divider
            Container(
              width: 1,
              height: 24,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(width: 8),

            // Search
            _ToolbarButton(
              icon: Icons.search,
              tooltip: 'Search Tables',
              onPressed: () => _showSearchDialog(graphState),
            ),
            const SizedBox(width: 4),

            // Auto layout
            _ToolbarButton(
              icon: Icons.account_tree,
              tooltip: 'Auto Layout',
              onPressed: graphState.isLayouting ? null : () => _autoLayout(graphState),
            ),
            const SizedBox(width: 4),

            // Export
            _ToolbarButton(
              icon: Icons.download,
              tooltip: 'Export Image',
              onPressed: () => _exportImage(graphState, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state indicator
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_chart,
            size: 64,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tables to display',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add entities to this module to see them here',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build search indicator
  Widget _buildSearchIndicator(ERGraphState graphState) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Search: ${graphState.searchQuery}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ref.read(erGraphProvider(widget.moduleId).notifier).clearSearch(),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Build zoom indicator
  Widget _buildZoomIndicator(ERGraphState graphState) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '${(graphState.zoom * 100).toInt()}%',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  /// Calculate canvas size based on content
  Size _calculateCanvasSize(ERGraphState graphState) {
    const minSize = Size(800, 600);
    if (graphState.nodes.isEmpty) return minSize;

    double maxX = 0;
    double maxY = 0;

    for (final node in graphState.nodes) {
      final entity = node.entity;
      final size = entity != null
          ? NodePainter.calculateNodeSize(entity)
          : const Size(NodePainter.defaultWidth, NodePainter.minHeight);

      maxX = maxX.clamp(node.x + size.width, node.x + size.width);
      maxY = maxY.clamp(node.y + size.height, node.y + size.height);
    }

    return Size(
      (maxX + 100).clamp(minSize.width, double.infinity),
      (maxY + 100).clamp(minSize.height, double.infinity),
    );
  }

  // Gesture handlers

  void _onTapDown(TapDownDetails details) {
    _lastTapPosition = details.localPosition;
  }

  void _onTap() {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Convert tap position to graph coordinates
    final graphPos = _transformController.toScene(_lastTapPosition);
    final hitNode = ERGraphPainter.hitTestNode(graphState, graphPos);

    if (hitNode != null) {
      // Select the node
      graphNotifier.selectNode(hitNode.id);
    } else {
      // Clear selection if clicking on empty space
      graphNotifier.clearSelection();
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _lastTapPosition = details.localPosition;
  }

  void _onDoubleTap() {
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Convert tap position to graph coordinates
    final graphPos = _transformController.toScene(_lastTapPosition);
    final hitNode = ERGraphPainter.hitTestNode(graphState, graphPos);

    if (hitNode != null && hitNode.entity != null) {
      // Open entity editor
      widget.onEntityEdit?.call(hitNode.entity!);
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Convert position to graph coordinates
    final graphPos = _transformController.toScene(details.localPosition);
    final hitNode = ERGraphPainter.hitTestNode(graphState, graphPos);

    // Show context menu
    widget.onContextMenu?.call(
      details.globalPosition,
      hitNode?.entity,
    );
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Convert position to graph coordinates
    final graphPos = _transformController.toScene(details.localPosition);
    final hitNode = ERGraphPainter.hitTestNode(graphState, graphPos);

    // Show context menu
    widget.onContextMenu?.call(
      details.globalPosition,
      hitNode?.entity,
    );
  }

  void _onPanStart(DragStartDetails details) {
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Convert position to graph coordinates
    final graphPos = _transformController.toScene(details.localPosition);
    final hitNode = ERGraphPainter.hitTestNode(graphState, graphPos);

    if (hitNode != null) {
      // Start dragging the node
      setState(() {
        _isDragging = true;
        _draggedNodeId = hitNode.id;
        _dragStart = graphPos;
        _nodeStartPos = Offset(hitNode.x, hitNode.y);
      });

      final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
      graphNotifier.selectNode(hitNode.id);
      graphNotifier.startDrag(hitNode.id);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _draggedNodeId == null) return;

    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    final graphState = ref.read(erGraphProvider(widget.moduleId));

    // Get current transform scale
    final scale = _transformController.value.getMaxScaleOnAxis();

    // Calculate new position
    final graphPos = _transformController.toScene(details.localPosition);
    final delta = graphPos - _dragStart;

    final newX = _nodeStartPos.dx + delta.dx;
    final newY = _nodeStartPos.dy + delta.dy;

    graphNotifier.moveNode(_draggedNodeId!, newX, newY);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDragging && _draggedNodeId != null) {
      final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
      graphNotifier.endDrag(_draggedNodeId!);
    }

    setState(() {
      _isDragging = false;
      _draggedNodeId = null;
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Save viewport state
    _saveViewport();
  }

  void _saveViewport() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final offsetX = matrix.getTranslation().x;
    final offsetY = matrix.getTranslation().y;

    // Update the graph notifier with viewport info
    // This will be saved to the project
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);

    // Update zoom in state
    if ((graphNotifier.state.zoom - scale).abs() > 0.01) {
      graphNotifier.setZoom(scale);
    }
  }

  // Toolbar actions

  void _zoomIn(ERGraphState graphState) {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    graphNotifier.zoomIn();

    final newScale = graphState.zoom * 1.2;
    _transformController.value = Matrix4.identity()
      ..scale(newScale);
  }

  void _zoomOut(ERGraphState graphState) {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    graphNotifier.zoomOut();

    final newScale = graphState.zoom / 1.2;
    _transformController.value = Matrix4.identity()
      ..scale(newScale);
  }

  void _fitToScreen(ERGraphState graphState) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportSize = renderBox.size;
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    graphNotifier.fitToView(viewportSize);

    // Update transform controller
    _transformController.value = Matrix4.identity()
      ..translate(graphNotifier.state.panOffset.dx, graphNotifier.state.panOffset.dy)
      ..scale(graphNotifier.state.zoom);
  }

  void _showSearchDialog(ERGraphState graphState) {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        onSearch: (query) {
          ref.read(erGraphProvider(widget.moduleId).notifier).setSearchQuery(query);
        },
      ),
    );
  }

  void _autoLayout(ERGraphState graphState) async {
    final graphNotifier = ref.read(erGraphProvider(widget.moduleId).notifier);
    graphNotifier.setLayouting(true);

    try {
      // Create layout algorithm
      final layout = DagreLayout();

      // Prepare node and edge data
      final nodeIds = graphState.nodes.map((n) => n.id).toList();
      final edges = graphState.edges.map((e) => LayoutEdge(
        source: e.source,
        target: e.target,
      )).toList();

      // Get node sizes
      Size getNodeSize(String nodeId) {
        final node = graphState.getNode(nodeId);
        if (node?.entity != null) {
          return NodePainter.calculateNodeSize(node!.entity!);
        }
        return const Size(NodePainter.defaultWidth, NodePainter.minHeight);
      }

      // Calculate layout
      final positions = layout.layout(
        nodes: nodeIds,
        edges: edges,
        nodeSize: getNodeSize,
      );

      // Apply layout
      graphNotifier.applyLayout(
        positions.map((key, value) => MapEntry(key, value)),
      );

      // Fit to screen after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToScreen(graphNotifier.state);
      });
    } finally {
      graphNotifier.setLayouting(false);
    }
  }

  void _exportImage(ERGraphState graphState, bool isDarkMode) async {
    final result = await ERDiagramExporter.exportToPNG(
      graphState: graphState,
      context: context,
      isDarkMode: isDarkMode,
      pixelRatio: 2,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${result.path}')),
        );
      } else if (!result.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Export failed')),
        );
      }
    }
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Search dialog widget
class _SearchDialog extends StatefulWidget {
  final void Function(String query) onSearch;

  const _SearchDialog({required this.onSearch});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Tables'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter table name...',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (_) => _search(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _search,
          child: const Text('Search'),
        ),
      ],
    );
  }

  void _search() {
    widget.onSearch(_controller.text);
    Navigator.pop(context);
  }
}
