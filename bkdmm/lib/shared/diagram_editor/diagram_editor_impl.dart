/// Diagram Editor - Main Entry Class
///
/// Provides a unified facade for the diagram editor framework,
/// integrating graph model, spatial index, handlers, behaviors,
/// commands, and view components.
library;

import 'dart:async';
import 'package:flutter/material.dart';

import 'core/diagram_node.dart';
import 'core/diagram_edge.dart';
import 'core/diagram_state.dart';
import 'model/graph_model.dart';
import 'spatial/spatial_index.dart';
import 'spatial/simple_index.dart' show DiagramSpatialIndex;
import 'handlers/diagram_event.dart';
import 'handlers/diagram_context.dart';
import 'handlers/diagram_handler.dart';
import 'handlers/handler_registry.dart';
import 'commands/diagram_command.dart';
import 'commands/history_controller.dart';
import 'behavior/behavior_registry.dart';
import 'event/event_center.dart';
import 'integration/er_interaction_manager.dart' as er show InteractionMode;
import 'view/graph_view.dart' show ViewportConfig;

/// Diagram Editor Controller
///
/// The main entry point for the diagram editor framework.
/// Provides a unified API for:
/// - Graph data management (nodes, edges)
/// - Viewport control (zoom, pan)
/// - Selection management
/// - Command execution (undo/redo)
/// - Event handling and dispatch
/// - Spatial indexing for hit testing
///
/// ## Architecture
///
/// The controller follows a layered architecture:
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │                    DiagramEditor                        │
/// │  (Facade - Unified API)                                 │
/// ├─────────────────────────────────────────────────────────┤
/// │  GraphModel    │  SpatialIndex  │  EventCenter          │
/// │  (Data Layer)  │  (Query Layer) │  (Event Layer)        │
/// ├─────────────────────────────────────────────────────────┤
/// │  HandlerRegistry  │  BehaviorRegistry  │  HistoryCtrl   │
/// │  (Event Handling) │  (Behavior Mods)    │  (Commands)   │
/// └─────────────────────────────────────────────────────────┘
/// ```
///
/// ## Usage
///
/// ```dart
/// // Create editor with default configuration
/// final editor = DiagramEditor();
///
/// // Add nodes
/// editor.addNode(MyNode(id: 'node-1', position: Offset(100, 100)));
///
/// // Add edges
/// editor.addEdge(MyEdge(
///   id: 'edge-1',
///   sourceNodeId: 'node-1',
///   targetNodeId: 'node-2',
/// ));
///
/// // Selection
/// editor.selectNode('node-1');
/// final selected = editor.selectedNodes;
///
/// // Undo/Redo
/// editor.executeCommand(MyCommand());
/// if (editor.canUndo) editor.undo();
///
/// // Events
/// editor.eventCenter.on<NodeSelectedEvent>((e) {
///   print('Node selected: ${e.nodeId}');
/// });
///
/// // Cleanup
/// editor.dispose();
/// ```
class DiagramEditor {
  /// Unique identifier for this editor instance
  final String id;

  /// Diagram type (e.g., 'er-diagram', 'flowchart')
  final String diagramType;

  /// Graph data model
  final GraphModel _graphModel;

  /// Spatial index for efficient hit testing
  final DiagramSpatialIndex _spatialIndex;

  /// Event handler registry
  final HandlerRegistry _handlerRegistry;

  /// Behavior registry
  final BehaviorRegistry _behaviorRegistry;

  /// History controller for undo/redo
  final HistoryController _historyController;

  /// Event center for pub/sub
  final EventCenter _eventCenter;

  /// Transformation controller for viewport
  final TransformationController _transformController;

  /// Current interaction mode
  er.InteractionMode _interactionMode;

  /// Current selection
  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedEdgeIds = {};

  /// Current hover state
  String? _hoveredNodeId;
  String? _hoveredEdgeId;

  /// Viewport configuration
  ViewportConfig _viewportConfig;

  /// State change listeners
  final List<VoidCallback> _stateListeners = [];

  /// Creates a new DiagramEditor instance
  ///
  /// Parameters:
  /// - [id]: Unique identifier (auto-generated if not provided)
  /// - [diagramType]: Type of diagram ('er-diagram', 'flowchart', etc.)
  /// - [viewportConfig]: Viewport configuration
  /// - [interactionMode]: Initial interaction mode
  DiagramEditor({
    String? id,
    this.diagramType = 'default',
    ViewportConfig? viewportConfig,
    er.InteractionMode interactionMode = er.InteractionMode.edit,
  })  : id = id ?? 'diagram-${DateTime.now().millisecondsSinceEpoch}',
        _graphModel = GraphModel(),
        _spatialIndex = DiagramSpatialIndex(),
        _handlerRegistry = HandlerRegistry(),
        _behaviorRegistry = BehaviorRegistry(),
        _historyController = HistoryController(),
        _eventCenter = EventCenter(),
        _transformController = TransformationController(),
        _interactionMode = interactionMode,
        _viewportConfig = viewportConfig ?? const ViewportConfig();

  // ===========================================================================
  // Properties
  // ===========================================================================

  /// Current interaction mode
  er.InteractionMode get interactionMode => _interactionMode;

  /// Graph model (read-only access)
  GraphModel get graphModel => _graphModel;

  /// Spatial index (read-only access)
  DiagramSpatialIndex get spatialIndex => _spatialIndex;

  /// Handler registry (read-only access)
  HandlerRegistry get handlerRegistry => _handlerRegistry;

  /// Behavior registry (read-only access)
  BehaviorRegistry get behaviorRegistry => _behaviorRegistry;

  /// History controller (read-only access)
  HistoryController get historyController => _historyController;

  /// Event center (read-only access)
  EventCenter get eventCenter => _eventCenter;

  /// Transformation controller (read-only access)
  TransformationController get transformController => _transformController;

  /// Viewport configuration
  ViewportConfig get viewportConfig => _viewportConfig;

  /// Current zoom level
  double get zoom => _transformController.value.getMaxScaleOnAxis();

  /// Current pan offset
  Offset get panOffset {
    final matrix = _transformController.value;
    return Offset(matrix.entry(0, 3), matrix.entry(1, 3));
  }

  /// Whether the editor has selection
  bool get hasSelection =>
      _selectedNodeIds.isNotEmpty || _selectedEdgeIds.isNotEmpty;

  /// Whether multiple items are selected
  bool get hasMultiSelection =>
      _selectedNodeIds.length > 1 || _selectedEdgeIds.length > 1;

  /// Selected node IDs
  Set<String> get selectedNodeIds => Set.unmodifiable(_selectedNodeIds);

  /// Selected edge IDs
  Set<String> get selectedEdgeIds => Set.unmodifiable(_selectedEdgeIds);

  /// Selected nodes
  List<DiagramNode> get selectedNodes =>
      _selectedNodeIds.map((id) => _graphModel.getNode(id)).whereType<DiagramNode>().toList();

  /// Selected edges
  List<DiagramEdge> get selectedEdges =>
      _selectedEdgeIds.map((id) => _graphModel.getEdge(id)).whereType<DiagramEdge>().toList();

  /// Hovered node ID
  String? get hoveredNodeId => _hoveredNodeId;

  /// Hovered edge ID
  String? get hoveredEdgeId => _hoveredEdgeId;

  /// Node count
  int get nodeCount => _graphModel.nodeCount;

  /// Edge count
  int get edgeCount => _graphModel.edgeCount;

  /// Whether the editor is empty
  bool get isEmpty => nodeCount == 0 && edgeCount == 0;

  /// Whether undo is available
  bool get canUndo => _historyController.canUndo;

  /// Whether redo is available
  bool get canRedo => _historyController.canRedo;

  /// Whether the editor is in edit mode
  bool get isEditMode => _interactionMode == er.InteractionMode.edit;

  /// Whether the editor is in move mode
  bool get isMoveMode => _interactionMode == er.InteractionMode.move;

  /// Whether the editor is in readonly mode
  bool get isReadonlyMode => _interactionMode == er.InteractionMode.readonly;

  // ===========================================================================
  // Node Operations
  // ===========================================================================

  /// Adds a node to the diagram
  ///
  /// If a node with the same ID exists, throws [ArgumentError]
  /// unless [overwrite] is true.
  void addNode(DiagramNode node, {bool overwrite = false}) {
    _graphModel.addNode(node, overwrite: overwrite);
    _spatialIndex.nodeIndex.insert(BoundedItem(
      id: node.id,
      bounds: Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      ),
    ));
    _notifyStateChange();
  }

  /// Adds multiple nodes at once
  void addNodes(Iterable<DiagramNode> nodes, {bool overwrite = false}) {
    _graphModel.withBatchEvents(() {
      for (final node in nodes) {
        addNode(node, overwrite: overwrite);
      }
    });
  }

  /// Updates a node
  ///
  /// Returns true if the node was updated, false if not found.
  bool updateNode(String id, DiagramNode Function(DiagramNode) updater) {
    final result = _graphModel.updateNode(id, (node) {
      final updated = updater(node);
      _spatialIndex.nodeIndex.update(id, Rect.fromLTWH(
        updated.position.dx,
        updated.position.dy,
        updated.size.width,
        updated.size.height,
      ));
      return updated;
    });
    if (result) _notifyStateChange();
    return result;
  }

  /// Removes a node
  ///
  /// Also removes connected edges and clears selection.
  /// Returns the removed node, or null if not found.
  DiagramNode? removeNode(String id) {
    final result = _graphModel.removeNode(id);
    if (result.node != null) {
      _spatialIndex.nodeIndex.remove(id);
      _selectedNodeIds.remove(id);
      _selectedEdgeIds.removeAll(result.removedEdges.map((e) => e.id));
      _notifyStateChange();
    }
    return result.node;
  }

  /// Removes multiple nodes
  void removeNodes(Iterable<String> ids) {
    for (final id in ids) {
      removeNode(id);
    }
  }

  /// Gets a node by ID
  DiagramNode? getNode(String id) => _graphModel.getNode(id);

  /// Checks if a node exists
  bool hasNode(String id) => _graphModel.hasNode(id);

  /// Gets all nodes
  Iterable<DiagramNode> get nodes => _graphModel.nodes;

  /// Finds nodes matching a predicate
  List<DiagramNode> findNodes(bool Function(DiagramNode) predicate) =>
      _graphModel.findNodes(predicate);

  /// Gets the bounding box of all nodes
  Rect calculateContentBounds({double padding = 50.0}) =>
      _graphModel.calculateContentBounds(padding: padding);

  // ===========================================================================
  // Edge Operations
  // ===========================================================================

  /// Adds an edge to the diagram
  ///
  /// If an edge with the same ID exists, throws [ArgumentError]
  /// unless [overwrite] is true.
  void addEdge(DiagramEdge edge, {bool overwrite = false, bool validateNodes = true}) {
    _graphModel.addEdge(edge, overwrite: overwrite, validateNodes: validateNodes);
    _notifyStateChange();
  }

  /// Adds multiple edges at once
  void addEdges(Iterable<DiagramEdge> edges, {bool overwrite = false, bool validateNodes = true}) {
    _graphModel.withBatchEvents(() {
      for (final edge in edges) {
        addEdge(edge, overwrite: overwrite, validateNodes: validateNodes);
      }
    });
  }

  /// Updates an edge
  bool updateEdge(String id, DiagramEdge Function(DiagramEdge) updater) {
    final result = _graphModel.updateEdge(id, updater);
    if (result) _notifyStateChange();
    return result;
  }

  /// Removes an edge
  DiagramEdge? removeEdge(String id) {
    final edge = _graphModel.removeEdge(id);
    if (edge != null) {
      _selectedEdgeIds.remove(id);
      _notifyStateChange();
    }
    return edge;
  }

  /// Removes multiple edges
  void removeEdges(Iterable<String> ids) {
    for (final id in ids) {
      removeEdge(id);
    }
  }

  /// Gets an edge by ID
  DiagramEdge? getEdge(String id) => _graphModel.getEdge(id);

  /// Checks if an edge exists
  bool hasEdge(String id) => _graphModel.hasEdge(id);

  /// Gets all edges
  Iterable<DiagramEdge> get edges => _graphModel.edges;

  /// Finds edges matching a predicate
  List<DiagramEdge> findEdges(bool Function(DiagramEdge) predicate) =>
      _graphModel.findEdges(predicate);

  /// Gets edges connected to a node
  List<DiagramEdge> getEdgesForNode(String nodeId) =>
      _graphModel.getEdgesForNode(nodeId);

  /// Gets outgoing edges from a node
  List<DiagramEdge> getOutgoingEdges(String nodeId) =>
      _graphModel.getOutgoingEdges(nodeId);

  /// Gets incoming edges to a node
  List<DiagramEdge> getIncomingEdges(String nodeId) =>
      _graphModel.getIncomingEdges(nodeId);

  /// Gets edges between two nodes
  List<DiagramEdge> getEdgesBetween(String sourceId, String targetId) =>
      _graphModel.getEdgesBetween(sourceId, targetId);

  /// Checks if two nodes are connected
  bool areNodesConnected(String sourceId, String targetId) =>
      _graphModel.areNodesConnected(sourceId, targetId);

  /// Gets neighbor nodes
  List<DiagramNode> getNeighbors(String nodeId) =>
      _graphModel.getNeighbors(nodeId);

  // ===========================================================================
  // Selection Operations
  // ===========================================================================

  /// Selects a node
  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (!_graphModel.hasNode(nodeId)) return;

    if (addToSelection) {
      if (_selectedNodeIds.contains(nodeId)) {
        _selectedNodeIds.remove(nodeId);
      } else {
        _selectedNodeIds.add(nodeId);
      }
    } else {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
      _selectedNodeIds.add(nodeId);
    }

    _eventCenter.emit(NodeSelectedEvent(
      nodeId: nodeId,
      addToSelection: addToSelection,
    ));
    _notifyStateChange();
  }

  /// Selects an edge
  void selectEdge(String edgeId, {bool addToSelection = false}) {
    if (!_graphModel.hasEdge(edgeId)) return;

    if (addToSelection) {
      if (_selectedEdgeIds.contains(edgeId)) {
        _selectedEdgeIds.remove(edgeId);
      } else {
        _selectedEdgeIds.add(edgeId);
      }
    } else {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
      _selectedEdgeIds.add(edgeId);
    }

    _notifyStateChange();
  }

  /// Selects multiple nodes
  void selectNodes(Set<String> nodeIds) {
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    for (final id in nodeIds) {
      if (_graphModel.hasNode(id)) {
        _selectedNodeIds.add(id);
      }
    }
    _notifyStateChange();
  }

  /// Selects multiple edges
  void selectEdges(Set<String> edgeIds) {
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    for (final id in edgeIds) {
      if (_graphModel.hasEdge(id)) {
        _selectedEdgeIds.add(id);
      }
    }
    _notifyStateChange();
  }

  /// Selects all nodes and edges
  void selectAll() {
    _selectedNodeIds.addAll(_graphModel.nodeIds);
    _selectedEdgeIds.addAll(_graphModel.edgeIds);
    _notifyStateChange();
  }

  /// Deselects a node
  void deselectNode(String nodeId) {
    if (_selectedNodeIds.remove(nodeId)) {
      _eventCenter.emit(NodeDeselectedEvent(nodeId));
      _notifyStateChange();
    }
  }

  /// Deselects an edge
  void deselectEdge(String edgeId) {
    if (_selectedEdgeIds.remove(edgeId)) {
      _notifyStateChange();
    }
  }

  /// Clears all selection
  void clearSelection() {
    if (_selectedNodeIds.isNotEmpty || _selectedEdgeIds.isNotEmpty) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
      _eventCenter.emit(const SelectionClearedEvent());
      _notifyStateChange();
    }
  }

  /// Checks if a node is selected
  bool isNodeSelected(String nodeId) => _selectedNodeIds.contains(nodeId);

  /// Checks if an edge is selected
  bool isEdgeSelected(String edgeId) => _selectedEdgeIds.contains(edgeId);

  // ===========================================================================
  // Hover Operations
  // ===========================================================================

  /// Sets the hovered node
  void setHoveredNode(String? nodeId) {
    if (_hoveredNodeId != nodeId) {
      final previous = _hoveredNodeId;
      _hoveredNodeId = nodeId;
      _eventCenter.emit(HoveredNodeChangedEvent(
        nodeId: nodeId,
        previousNodeId: previous,
      ));
      _notifyStateChange();
    }
  }

  /// Sets the hovered edge
  void setHoveredEdge(String? edgeId) {
    if (_hoveredEdgeId != edgeId) {
      _hoveredEdgeId = edgeId;
      _notifyStateChange();
    }
  }

  // ===========================================================================
  // Viewport Operations
  // ===========================================================================

  /// Zooms to a specific level
  void zoomTo(double newZoom, {Offset? center}) {
    final targetCenter = center ?? Offset.zero;
    final clampedZoom = newZoom.clamp(
      _viewportConfig.minZoom,
      _viewportConfig.maxZoom,
    );

    final matrix = Matrix4.identity();
    matrix.translate(targetCenter.dx, targetCenter.dy);
    matrix.scale(clampedZoom);
    matrix.translate(-targetCenter.dx, -targetCenter.dy);

    _transformController.value = matrix;
    _eventCenter.emit(CanvasZoomedEvent(
      zoom: clampedZoom,
      center: targetCenter,
      previousZoom: zoom,
    ));
    _notifyStateChange();
  }

  /// Zooms in by one step
  void zoomIn({Offset? center}) {
    zoomTo(zoom * _viewportConfig.zoomStep, center: center);
  }

  /// Zooms out by one step
  void zoomOut({Offset? center}) {
    zoomTo(zoom / _viewportConfig.zoomStep, center: center);
  }

  /// Pans the canvas
  void pan(Offset delta) {
    final matrix = _transformController.value.clone();
    matrix.translate(delta.dx, delta.dy);
    _transformController.value = matrix;
    _eventCenter.emit(CanvasPannedEvent(
      delta: delta,
      newOffset: panOffset,
    ));
    _notifyStateChange();
  }

  /// Pans to a specific offset
  void panTo(Offset offset) {
    final matrix = Matrix4.identity();
    matrix.translate(offset.dx, offset.dy);
    matrix.scale(zoom);
    _transformController.value = matrix;
    _notifyStateChange();
  }

  /// Fits all content in the viewport
  void fitContent({double padding = 50.0, Size? viewportSize}) {
    if (_graphModel.nodeCount == 0) return;

    final bounds = _graphModel.calculateContentBounds(padding: padding);
    if (bounds == Rect.zero) return;

    final size = viewportSize ?? Size(800, 600);
    final contentWidth = bounds.width + padding * 2;
    final contentHeight = bounds.height + padding * 2;

    final scaleX = size.width / contentWidth;
    final scaleY = size.height / contentHeight;
    final newZoom = (scaleX < scaleY ? scaleX : scaleY)
        .clamp(_viewportConfig.minZoom, _viewportConfig.maxZoom);

    final offsetX = (size.width - contentWidth * newZoom) / 2 -
        bounds.left * newZoom + padding * newZoom;
    final offsetY = (size.height - contentHeight * newZoom) / 2 -
        bounds.top * newZoom + padding * newZoom;

    final matrix = Matrix4.identity();
    matrix.translate(offsetX, offsetY);
    matrix.scale(newZoom);

    _transformController.value = matrix;
    _notifyStateChange();
  }

  /// Resets the viewport to default
  void resetViewport() {
    _transformController.value = Matrix4.identity();
    _notifyStateChange();
  }

  /// Sets viewport configuration
  void setViewportConfig(ViewportConfig config) {
    _viewportConfig = config;
    _notifyStateChange();
  }

  /// Converts screen coordinates to scene coordinates
  Offset toScene(Offset screen) {
    final inverse = Matrix4.tryInvert(_transformController.value) ??
        Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screen);
  }

  /// Converts scene coordinates to screen coordinates
  Offset toScreen(Offset scene) {
    return MatrixUtils.transformPoint(_transformController.value, scene);
  }

  // ===========================================================================
  // Interaction Mode
  // ===========================================================================

  /// Sets the interaction mode
  void setInteractionMode(er.InteractionMode mode) {
    if (_interactionMode != mode) {
      _interactionMode = mode;
      _notifyStateChange();
    }
  }

  /// Enters edit mode
  void enterEditMode() => setInteractionMode(er.InteractionMode.edit);

  /// Enters move mode
  void enterMoveMode() => setInteractionMode(er.InteractionMode.move);

  /// Enters readonly mode
  void enterReadonlyMode() => setInteractionMode(er.InteractionMode.readonly);

  /// Toggles between edit and move mode
  void toggleMode() {
    if (_interactionMode == er.InteractionMode.edit) {
      enterMoveMode();
    } else if (_interactionMode == er.InteractionMode.move) {
      enterEditMode();
    }
  }

  // ===========================================================================
  // Command Execution
  // ===========================================================================

  /// Executes a command
  dynamic executeCommand(DiagramCommand command) {
    return _historyController.execute(command);
  }

  /// Undoes the last command
  void undo() {
    _historyController.undo();
    _notifyStateChange();
  }

  /// Redoes the last undone command
  void redo() {
    _historyController.redo();
    _notifyStateChange();
  }

  /// Clears command history
  void clearHistory() {
    _historyController.clear();
    _notifyStateChange();
  }

  /// Gets undo history descriptions
  List<String> get undoHistory => _historyController.undoHistory;

  /// Gets redo history descriptions
  List<String> get redoHistory => _historyController.redoHistory;

  // ===========================================================================
  // Hit Testing
  // ===========================================================================

  /// Performs hit testing at a scene position
  HitTestResult hitTest(Offset scenePosition) {
    // Check anchors first (higher priority)
    final anchorItems = _spatialIndex.anchorIndex.queryPoint(scenePosition);
    if (anchorItems.isNotEmpty) {
      final item = anchorItems.last;
      final data = item.data as Map<String, dynamic>?;
      if (data != null) {
        final node = _graphModel.getNode(data['nodeId'] as String);
        if (node != null) {
          // Find the anchor in the node
          for (final anchor in node.getAnchors()) {
            if (anchor.id == item.id) {
              return HitTestResult.anchor(anchor, scenePosition);
            }
          }
        }
      }
    }

    // Check nodes
    final nodeItems = _spatialIndex.nodeIndex.queryPoint(scenePosition);
    if (nodeItems.isNotEmpty) {
      final item = nodeItems.last;
      final node = _graphModel.getNode(item.id);
      if (node != null) {
        return HitTestResult.node(node, scenePosition);
      }
    }

    // Check edges (more complex hit testing needed)
    // For now, return canvas
    return HitTestResult.canvas(scenePosition);
  }

  /// Queries nodes within a rectangle
  List<DiagramNode> queryNodesInRect(Rect rect) {
    final items = _spatialIndex.nodeIndex.queryRect(rect);
    return items
        .map((item) => _graphModel.getNode(item.id))
        .whereType<DiagramNode>()
        .toList();
  }

  // ===========================================================================
  // Event Dispatch
  // ===========================================================================

  /// Dispatches an event through the handler registry
  Future<bool> dispatchEvent(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    return _handlerRegistry.dispatch(event, context, updateState);
  }

  /// Gets the current cursor based on context
  MouseCursor getCursor(DiagramContext context) {
    return _handlerRegistry.getCursor(context);
  }

  /// Resets all handlers
  void resetHandlers() {
    _handlerRegistry.resetAll();
    _behaviorRegistry.resetAll();
  }

  // ===========================================================================
  // Handler Registration
  // ===========================================================================

  /// Registers an event handler
  void registerHandler(DiagramEventHandler handler) {
    _handlerRegistry.register(handler);
  }

  /// Registers multiple handlers
  void registerHandlers(List<DiagramEventHandler> handlers) {
    _handlerRegistry.registerAll(handlers);
  }

  /// Removes a handler
  void removeHandler(DiagramEventHandler handler) {
    _handlerRegistry.remove(handler);
  }

  // ===========================================================================
  // Behavior Registration
  // ===========================================================================

  /// Registers a behavior
  void registerBehavior(Behavior behavior) {
    _behaviorRegistry.register(behavior);
  }

  /// Registers multiple behaviors
  void registerBehaviors(List<Behavior> behaviors) {
    _behaviorRegistry.registerAll(behaviors);
  }

  /// Removes a behavior
  Behavior? removeBehavior(String id) {
    return _behaviorRegistry.remove(id);
  }

  /// Enables a behavior
  void enableBehavior(String id) {
    _behaviorRegistry.enable(id);
    _notifyStateChange();
  }

  /// Disables a behavior
  void disableBehavior(String id) {
    _behaviorRegistry.disable(id);
    _notifyStateChange();
  }

  /// Toggles a behavior
  void toggleBehavior(String id) {
    _behaviorRegistry.toggle(id);
    _notifyStateChange();
  }

  // ===========================================================================
  // State Management
  // ===========================================================================

  /// Gets the current diagram state
  DiagramState get state => DiagramState(
    diagramId: id,
    diagramType: diagramType,
    nodes: Map.fromEntries(
      _graphModel.nodes.map((n) => MapEntry(n.id, n)),
    ),
    edges: Map.fromEntries(
      _graphModel.edges.map((e) => MapEntry(e.id, e)),
    ),
    nodeStates: Map.fromEntries(
      _graphModel.nodes.map((n) => MapEntry(
        n.id,
        NodeState(
          isSelected: _selectedNodeIds.contains(n.id),
          isHovered: _hoveredNodeId == n.id,
        ),
      )),
    ),
    edgeStates: Map.fromEntries(
      _graphModel.edges.map((e) => MapEntry(
        e.id,
        EdgeState(
          isSelected: _selectedEdgeIds.contains(e.id),
          isHovered: _hoveredEdgeId == e.id,
        ),
      )),
    ),
    viewport: ViewportState(
      zoom: zoom,
      panOffset: panOffset,
      minZoom: _viewportConfig.minZoom,
      maxZoom: _viewportConfig.maxZoom,
    ),
    interaction: InteractionState(
      mode: _convertInteractionMode(_interactionMode),
    ),
    selection: SelectionState(
      selectedNodeIds: Set.from(_selectedNodeIds),
      selectedEdgeIds: Set.from(_selectedEdgeIds),
      hoveredNodeId: _hoveredNodeId,
      hoveredEdgeId: _hoveredEdgeId,
    ),
  );

  /// Converts InteractionMode from er_interaction_manager to diagram_state
  InteractionMode _convertInteractionMode(er.InteractionMode mode) {
    switch (mode) {
      case er.InteractionMode.move:
        return InteractionMode.move;
      case er.InteractionMode.edit:
        return InteractionMode.edit;
      case er.InteractionMode.readonly:
        return InteractionMode.readonly;
    }
  }

  /// Subscribes to state changes
  VoidCallback subscribeToStateChanges(VoidCallback listener) {
    _stateListeners.add(listener);
    return () => _stateListeners.remove(listener);
  }

  /// Notifies state listeners
  void _notifyStateChange() {
    for (final listener in _stateListeners) {
      listener();
    }
  }

  // ===========================================================================
  // Data Import/Export
  // ===========================================================================

  /// Exports graph data
  GraphData exportData() => _graphModel.export();

  /// Imports graph data
  void importData(GraphData data, {bool clear = true}) {
    _graphModel.import(data, clear: clear);

    // Rebuild spatial index
    _spatialIndex.clear();
    for (final node in _graphModel.nodes) {
      _spatialIndex.nodeIndex.insert(BoundedItem(
        id: node.id,
        bounds: Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        ),
      ));
    }

    // Clear selection
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    _hoveredNodeId = null;
    _hoveredEdgeId = null;

    _notifyStateChange();
  }

  /// Clears all data
  void clearAll() {
    _graphModel.clear();
    _spatialIndex.clear();
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    _hoveredNodeId = null;
    _hoveredEdgeId = null;
    _historyController.clear();
    _notifyStateChange();
  }

  // ===========================================================================
  // Graph Model Events
  // ===========================================================================

  /// Subscribes to graph changes
  StreamSubscription<GraphChangeEvent> subscribeToGraphChanges(
    void Function(GraphChangeEvent) listener,
  ) {
    return _graphModel.onChange.listen(listener);
  }

  // ===========================================================================
  // Cleanup
  // ===========================================================================

  /// Disposes the editor and releases all resources
  void dispose() {
    _graphModel.dispose();
    _eventCenter.dispose();
    _transformController.dispose();
    _handlerRegistry.clear();
    _behaviorRegistry.clear();
    _stateListeners.clear();
  }
}
