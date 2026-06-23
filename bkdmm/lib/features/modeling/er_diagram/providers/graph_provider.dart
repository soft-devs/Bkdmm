import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';

/// ER 图交互模式
enum InteractionMode {
  /// 移动模式 - 平移/缩放画布，仅查看节点
  move,
  /// 编辑模式 - 拖拽节点、创建连线、编辑属性
  edit,
}

/// Graph node UI state - extends GraphNode with UI-specific properties
class ERGraphNode {
  /// The underlying graph node data
  final GraphNode data;

  /// The entity this node represents
  final Entity? entity;

  /// Whether the node is selected
  final bool isSelected;

  /// Whether the node is being dragged
  final bool isDragging;

  /// Whether the node is highlighted (e.g., during search)
  final bool isHighlighted;

  const ERGraphNode({
    required this.data,
    this.entity,
    this.isSelected = false,
    this.isDragging = false,
    this.isHighlighted = false,
  });

  ERGraphNode copyWith({
    GraphNode? data,
    Entity? entity,
    bool? isSelected,
    bool? isDragging,
    bool? isHighlighted,
  }) {
    return ERGraphNode(
      data: data ?? this.data,
      entity: entity ?? this.entity,
      isSelected: isSelected ?? this.isSelected,
      isDragging: isDragging ?? this.isDragging,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  String get id => data.title;
  double get x => data.x;
  double get y => data.y;
}

/// Graph edge UI state - extends GraphEdge with UI-specific properties
class ERGraphEdge {
  /// The underlying graph edge data
  final GraphEdge data;

  /// Whether the edge is highlighted
  final bool isHighlighted;

  const ERGraphEdge({
    required this.data,
    this.isHighlighted = false,
  });

  ERGraphEdge copyWith({
    GraphEdge? data,
    bool? isHighlighted,
  }) {
    return ERGraphEdge(
      data: data ?? this.data,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  String get source => data.source;
  String get target => data.target;
  String? get label => data.label;
}

/// ER Diagram graph state
class ERGraphState {
  /// The module ID this graph represents
  final String moduleId;

  /// Current interaction mode
  final InteractionMode interactionMode;

  /// Whether we're creating a new edge
  final bool isCreatingEdge;

  /// The source node ID when creating an edge
  final String? edgeStartNodeId;

  /// The current end position for edge preview
  final Offset edgePreviewEnd;

  /// All nodes in the graph
  final List<ERGraphNode> nodes;

  /// All edges in the graph
  final List<ERGraphEdge> edges;

  /// Currently selected node IDs
  final Set<String> selectedNodeIds;

  /// Currently hovered node ID
  final String? hoveredNodeId;

  /// Search query for filtering nodes
  final String searchQuery;

  /// Zoom level
  final double zoom;

  /// Pan offset
  final Offset panOffset;

  /// Whether auto-layout is in progress
  final bool isLayouting;

  /// Viewport bounds for fitting content
  final Rect? contentBounds;

  const ERGraphState({
    required this.moduleId,
    this.interactionMode = InteractionMode.edit, // 默认编辑模式
    this.isCreatingEdge = false,
    this.edgeStartNodeId,
    this.edgePreviewEnd = Offset.zero,
    this.nodes = const [],
    this.edges = const [],
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.searchQuery = '',
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.isLayouting = false,
    this.contentBounds,
  });

  ERGraphState copyWith({
    String? moduleId,
    InteractionMode? interactionMode,
    bool? isCreatingEdge,
    String? edgeStartNodeId,
    Offset? edgePreviewEnd,
    List<ERGraphNode>? nodes,
    List<ERGraphEdge>? edges,
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    String? searchQuery,
    double? zoom,
    Offset? panOffset,
    bool? isLayouting,
    Rect? contentBounds,
  }) {
    return ERGraphState(
      moduleId: moduleId ?? this.moduleId,
      interactionMode: interactionMode ?? this.interactionMode,
      isCreatingEdge: isCreatingEdge ?? this.isCreatingEdge,
      edgeStartNodeId: edgeStartNodeId ?? this.edgeStartNodeId,
      edgePreviewEnd: edgePreviewEnd ?? this.edgePreviewEnd,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: hoveredNodeId ?? this.hoveredNodeId,
      searchQuery: searchQuery ?? this.searchQuery,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      isLayouting: isLayouting ?? this.isLayouting,
      contentBounds: contentBounds ?? this.contentBounds,
    );
  }

  /// Get filtered nodes based on search query
  List<ERGraphNode> get filteredNodes {
    if (searchQuery.isEmpty) return nodes;
    final query = searchQuery.toLowerCase();
    return nodes.where((node) {
      final entity = node.entity;
      if (entity == null) return false;
      return entity.title.toLowerCase().contains(query) ||
          entity.chnname.toLowerCase().contains(query);
    }).toList();
  }

  /// Get selected nodes
  List<ERGraphNode> get selectedNodes {
    return nodes.where((n) => selectedNodeIds.contains(n.id)).toList();
  }

  /// Check if a node is selected
  bool isNodeSelected(String nodeId) => selectedNodeIds.contains(nodeId);

  /// Get node by ID
  ERGraphNode? getNode(String nodeId) {
    try {
      return nodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// Get edges connected to a node
  List<ERGraphEdge> getEdgesForNode(String nodeId) {
    return edges.where((e) => e.source == nodeId || e.target == nodeId).toList();
  }
}

/// Notifier for managing ER diagram graph state
class ERGraphNotifier extends StateNotifier<ERGraphState> {
  final Ref ref;
  bool _needsSync = false; // Flag for delayed sync

  ERGraphNotifier(this.ref, String moduleId) : super(ERGraphState(moduleId: moduleId)) {
    _loadFromModule();
  }

  /// Called after initialization to sync if needed
  void postInit() {
    if (_needsSync) {
      _syncToProject();
      _needsSync = false;
    }
  }

  /// Load graph data from the module
  void _loadFromModule() {
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;

    try {
      final module = project.modules.firstWhere((m) => m.id == state.moduleId);
      final graphCanvas = module.graphCanvas;

      // Create entity map for quick lookup
      final entityMap = <String, Entity>{};
      for (final entity in module.entities) {
        entityMap[entity.title] = entity;
      }

      // Create a map of existing nodes by entity title
      final existingNodeMap = <String, GraphNode>{};
      for (final node in graphCanvas.nodes) {
        // Extract entity title from node title (format: "tableName:index")
        final entityTitle = node.title.split(':').first;
        existingNodeMap[entityTitle] = node;
      }

      // Build nodes list: sync with current entities
      final graphNodes = <GraphNode>[];
      bool shouldSync = false;

      for (int i = 0; i < module.entities.length; i++) {
        final entity = module.entities[i];

        // Check if node already exists for this entity
        if (existingNodeMap.containsKey(entity.title)) {
          // Use existing node with its position
          graphNodes.add(existingNodeMap[entity.title]!);
        } else {
          // Create new node with default position
          final col = i % 3;
          final row = i ~/ 3;
          graphNodes.add(GraphNode(
            title: '${entity.title}:1',
            x: 50.0 + col * 280.0,
            y: 50.0 + row * 220.0,
          ));
          shouldSync = true;
        }
      }

      // Check if any entities were removed (need sync)
      if (graphNodes.length != graphCanvas.nodes.length) {
        shouldSync = true;
      }

      // Convert GraphNodes to ERGraphNodes
      final nodes = graphNodes.map((node) {
        // Extract entity title from node title (format: "tableName:index")
        final entityTitle = node.title.split(':').first;
        return ERGraphNode(
          data: node,
          entity: entityMap[entityTitle],
        );
      }).toList();

      // Convert GraphEdges to ERGraphEdges
      final edges = graphCanvas.edges.map((edge) {
        return ERGraphEdge(data: edge);
      }).toList();

      state = state.copyWith(
        nodes: nodes,
        edges: edges,
        contentBounds: _calculateBounds(nodes),
      );

      // Mark for delayed sync instead of calling immediately
      if (shouldSync) {
        _needsSync = true;
      }
    } catch (_) {
      // Module not found, keep empty state
    }
  }

  /// Reload graph from module (call when module data changes)
  void reload() {
    _loadFromModule();
  }

  /// Select a node
  void selectNode(String nodeId, {bool addToSelection = false}) {
    Set<String> newSelection;
    if (addToSelection) {
      newSelection = Set<String>.from(state.selectedNodeIds);
      if (newSelection.contains(nodeId)) {
        newSelection.remove(nodeId);
      } else {
        newSelection.add(nodeId);
      }
    } else {
      newSelection = {nodeId};
    }
    state = state.copyWith(selectedNodeIds: newSelection);
  }

  /// Deselect all nodes
  void clearSelection() {
    state = state.copyWith(selectedNodeIds: {});
  }

  /// Select all nodes
  void selectAll() {
    state = state.copyWith(
      selectedNodeIds: Set<String>.from(state.nodes.map((n) => n.id)),
    );
  }

  /// Set hovered node
  void setHoveredNode(String? nodeId) {
    if (state.hoveredNodeId != nodeId) {
      state = state.copyWith(hoveredNodeId: nodeId);
    }
  }

  /// Move a node to a new position
  void moveNode(String nodeId, double x, double y) {
    final nodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(
          data: node.data.copyWith(x: x, y: y),
        );
      }
      return node;
    }).toList();

    state = state.copyWith(
      nodes: nodes,
      contentBounds: _calculateBounds(nodes),
    );
    _syncToProject();
  }

  /// Start dragging a node
  void startDrag(String nodeId) {
    final nodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(isDragging: true);
      }
      return node;
    }).toList();
    state = state.copyWith(nodes: nodes);
  }

  /// End dragging a node
  void endDrag(String nodeId) {
    final nodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(isDragging: false);
      }
      return node;
    }).toList();
    state = state.copyWith(nodes: nodes);
  }

  /// Set zoom level
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(0.1, 3.0);
    state = state.copyWith(zoom: clampedZoom);
  }

  /// Zoom in
  void zoomIn() {
    setZoom(state.zoom * 1.2);
  }

  /// Zoom out
  void zoomOut() {
    setZoom(state.zoom / 1.2);
  }

  /// Reset zoom to 1.0
  void resetZoom() {
    state = state.copyWith(zoom: 1.0);
  }

  /// Set pan offset
  void setPanOffset(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  /// Fit all nodes to the viewport
  void fitToView(Size viewportSize, {double padding = 50}) {
    if (state.nodes.isEmpty) return;

    final bounds = state.contentBounds;
    if (bounds == null) return;

    final contentWidth = bounds.width + padding * 2;
    final contentHeight = bounds.height + padding * 2;

    final scaleX = viewportSize.width / contentWidth;
    final scaleY = viewportSize.height / contentHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final clampedScale = scale.clamp(0.1, 2.0);

    // Center the content
    final offsetX = (viewportSize.width - contentWidth * clampedScale) / 2 - bounds.left * clampedScale + padding * clampedScale;
    final offsetY = (viewportSize.height - contentHeight * clampedScale) / 2 - bounds.top * clampedScale + padding * clampedScale;

    state = state.copyWith(
      zoom: clampedScale,
      panOffset: Offset(offsetX, offsetY),
    );
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Set layouting state
  void setLayouting(bool isLayouting) {
    state = state.copyWith(isLayouting: isLayouting);
  }

  // ============ Interaction Mode Methods ============

  /// Set interaction mode
  void setInteractionMode(InteractionMode mode) {
    state = state.copyWith(interactionMode: mode);
  }

  /// Toggle between move and edit modes
  void toggleInteractionMode() {
    final newMode = state.interactionMode == InteractionMode.move
        ? InteractionMode.edit
        : InteractionMode.move;
    setInteractionMode(newMode);
  }

  // ============ Edge Creation Methods ============

  /// Start creating a new edge from a node
  void startEdgeCreation(String nodeId) {
    state = state.copyWith(
      isCreatingEdge: true,
      edgeStartNodeId: nodeId,
    );
  }

  /// Update the edge preview end position
  void updateEdgePreview(Offset position) {
    if (state.isCreatingEdge) {
      state = state.copyWith(edgePreviewEnd: position);
    }
  }

  /// Cancel edge creation
  void cancelEdgeCreation() {
    state = state.copyWith(
      isCreatingEdge: false,
      edgeStartNodeId: null,
      edgePreviewEnd: Offset.zero,
    );
  }

  /// Complete edge creation by connecting to target node
  void completeEdgeCreation(String targetNodeId) {
    if (!state.isCreatingEdge || state.edgeStartNodeId == null) {
      return;
    }

    // Don't create edge to self
    if (state.edgeStartNodeId == targetNodeId) {
      cancelEdgeCreation();
      return;
    }

    // Check if edge already exists
    final existingEdge = state.edges.any((e) =>
        (e.source == state.edgeStartNodeId && e.target == targetNodeId) ||
        (e.source == targetNodeId && e.target == state.edgeStartNodeId));

    if (!existingEdge) {
      addEdge(state.edgeStartNodeId!, targetNodeId);
    }

    cancelEdgeCreation();
  }

  /// Apply auto-layout positions
  void applyLayout(Map<String, Offset> positions) {
    final nodes = state.nodes.map((node) {
      final position = positions[node.id];
      if (position != null) {
        return node.copyWith(
          data: node.data.copyWith(x: position.dx, y: position.dy),
        );
      }
      return node;
    }).toList();

    state = state.copyWith(
      nodes: nodes,
      contentBounds: _calculateBounds(nodes),
    );
    _syncToProject();
  }

  /// Add a new edge
  void addEdge(String source, String target, {String? label}) {
    final newEdge = ERGraphEdge(
      data: GraphEdge(source: source, target: target, label: label),
    );
    state = state.copyWith(edges: [...state.edges, newEdge]);
    _syncToProject();
  }

  /// Remove an edge
  void removeEdge(String source, String target) {
    final edges = state.edges.where((e) {
      return !(e.source == source && e.target == target);
    }).toList();
    state = state.copyWith(edges: edges);
    _syncToProject();
  }

  /// Calculate content bounds
  Rect? _calculateBounds(List<ERGraphNode> nodes) {
    if (nodes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // Default node size for bounds calculation
    const nodeWidth = 200.0;
    const nodeHeight = 150.0;

    for (final node in nodes) {
      if (node.x < minX) minX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.x + nodeWidth > maxX) maxX = node.x + nodeWidth;
      if (node.y + nodeHeight > maxY) maxY = node.y + nodeHeight;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Sync changes to the project provider
  void _syncToProject() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    final project = ref.read(projectNotifierProvider).project;

    if (project == null) return;

    // Convert back to GraphNode and GraphEdge
    final graphNodes = state.nodes.map((n) => n.data).toList();
    final graphEdges = state.edges.map((e) => e.data).toList();

    // Update the module's graphCanvas
    final modules = project.modules.map((m) {
      if (m.id == state.moduleId) {
        return m.copyWith(
          graphCanvas: m.graphCanvas.copyWith(
            nodes: graphNodes,
            edges: graphEdges,
          ),
          updatedAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    final updatedProject = project.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );

    projectNotifier.updateProject(updatedProject);
  }
}

/// Provider family for ER graph - one provider per module
final erGraphProvider = StateNotifierProvider.family<ERGraphNotifier, ERGraphState, String>(
  (ref, moduleId) {
    return ERGraphNotifier(ref, moduleId);
  },
);

/// Provider for checking if a module has entities to display
final hasEntitiesProvider = Provider.family<bool, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return false;

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.entities.isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// Provider for getting entity count in a module
final entityCountProvider = Provider.family<int, String>((ref, moduleId) {
  final project = ref.watch(projectNotifierProvider).project;
  if (project == null) return 0;

  try {
    final module = project.modules.firstWhere((m) => m.id == moduleId);
    return module.entities.length;
  } catch (_) {
    return 0;
  }
});
