/// 图数据模型
///
/// 提供节点和边的统一管理，包括增删改查、批量操作、事件通知等。
/// 作为图表编辑器的核心数据层，与 UI 层解耦。
library;

import 'dart:ui';
import 'dart:async';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';

/// 图数据模型
///
/// 管理图表中的所有节点和边，提供：
/// - 增删改查操作
/// - 批量操作支持
/// - 变更事件流
/// - 连接关系查询
/// - 数据验证
class GraphModel {
  /// 节点存储
  final Map<String, DiagramNode> _nodes = {};

  /// 边存储
  final Map<String, DiagramEdge> _edges = {};

  /// 节点连接索引：nodeId -> 连接的边 ID 列表
  final Map<String, Set<String>> _nodeEdgeIndex = {};

  /// 锚点连接索引：anchorId -> 连接的边 ID 列表
  final Map<String, Set<String>> _anchorEdgeIndex = {};

  /// 变更控制器
  final StreamController<GraphChangeEvent> _changeController =
      StreamController<GraphChangeEvent>.broadcast();

  /// 变更事件流
  Stream<GraphChangeEvent> get onChange => _changeController.stream;

  /// 是否禁用事件通知（批量操作时使用）
  bool _suppressEvents = false;

  /// 累积的变更事件（批量操作时使用）
  final List<GraphChangeEvent> _pendingEvents = [];

  // ========== 节点操作 ==========

  /// 获取所有节点
  Iterable<DiagramNode> get nodes => _nodes.values;

  /// 获取节点数量
  int get nodeCount => _nodes.length;

  /// 检查节点是否存在
  bool hasNode(String id) => _nodes.containsKey(id);

  /// 获取节点
  DiagramNode? getNode(String id) => _nodes[id];

  /// 添加节点
  ///
  /// 如果节点 ID 已存在，将抛出 [ArgumentError]。
  /// 使用 [overwrite: true] 可以覆盖已有节点。
  void addNode(DiagramNode node, {bool overwrite = false}) {
    if (!overwrite && _nodes.containsKey(node.id)) {
      throw ArgumentError('Node with id "${node.id}" already exists');
    }

    final oldNode = _nodes[node.id];
    _nodes[node.id] = node;
    _nodeEdgeIndex.putIfAbsent(node.id, () => {});

    _emitEvent(NodeAddedEvent(node, oldNode: oldNode));
  }

  /// 更新节点
  ///
  /// 如果节点不存在，返回 false。
  bool updateNode(String id, DiagramNode Function(DiagramNode) updater) {
    final oldNode = _nodes[id];
    if (oldNode == null) return false;

    final newNode = updater(oldNode);
    _nodes[id] = newNode;

    _emitEvent(NodeUpdatedEvent(id, oldNode, newNode));
    return true;
  }

  /// 移除节点
  ///
  /// 同时移除与该节点相连的所有边。
  /// 返回被移除的节点和边。
  RemoveNodeResult removeNode(String id) {
    final node = _nodes.remove(id);
    if (node == null) {
      return RemoveNodeResult.notFound();
    }

    // 移除连接的边
    final connectedEdgeIds = _nodeEdgeIndex[id] ?? {};
    final removedEdges = <DiagramEdge>[];

    for (final edgeId in connectedEdgeIds.toList()) {
      final edge = _edges.remove(edgeId);
      if (edge != null) {
        removedEdges.add(edge);
        _removeFromAnchorIndex(edge);
      }
    }

    _nodeEdgeIndex.remove(id);

    _emitEvent(NodeRemovedEvent(node, removedEdges));
    return RemoveNodeResult(node: node, removedEdges: removedEdges);
  }

  /// 批量添加节点
  void addNodes(Iterable<DiagramNode> nodes, {bool overwrite = false}) {
    _withBatchEvents(() {
      for (final node in nodes) {
        addNode(node, overwrite: overwrite);
      }
    });
  }

  /// 批量移除节点
  ///
  /// 返回被移除的节点和边。
  BatchRemoveResult removeNodes(Iterable<String> ids) {
    final removedNodes = <DiagramNode>[];
    final removedEdges = <DiagramEdge>[];

    _withBatchEvents(() {
      for (final id in ids) {
        final result = removeNode(id);
        if (result.node != null) {
          removedNodes.add(result.node!);
          removedEdges.addAll(result.removedEdges);
        }
      }
    });

    return BatchRemoveResult(nodes: removedNodes, edges: removedEdges);
  }

  // ========== 边操作 ==========

  /// 获取所有边
  Iterable<DiagramEdge> get edges => _edges.values;

  /// 获取边数量
  int get edgeCount => _edges.length;

  /// 检查边是否存在
  bool hasEdge(String id) => _edges.containsKey(id);

  /// 获取边
  DiagramEdge? getEdge(String id) => _edges[id];

  /// 添加边
  ///
  /// 如果边 ID 已存在，将抛出 [ArgumentError]。
  /// 使用 [overwrite: true] 可以覆盖已有边。
  ///
  /// 如果源节点或目标节点不存在，将抛出 [ArgumentError]。
  /// 使用 [validateNodes: false] 可以跳过节点验证。
  void addEdge(DiagramEdge edge,
      {bool overwrite = false, bool validateNodes = true}) {
    if (!overwrite && _edges.containsKey(edge.id)) {
      throw ArgumentError('Edge with id "${edge.id}" already exists');
    }

    if (validateNodes) {
      if (!hasNode(edge.sourceNodeId)) {
        throw ArgumentError(
            'Source node "${edge.sourceNodeId}" does not exist');
      }
      if (!hasNode(edge.targetNodeId)) {
        throw ArgumentError(
            'Target node "${edge.targetNodeId}" does not exist');
      }
    }

    final oldEdge = _edges[edge.id];
    _edges[edge.id] = edge;

    // 更新索引
    _addToNodeIndex(edge);
    _addToAnchorIndex(edge);

    _emitEvent(EdgeAddedEvent(edge, oldEdge: oldEdge));
  }

  /// 更新边
  ///
  /// 如果边不存在，返回 false。
  bool updateEdge(String id, DiagramEdge Function(DiagramEdge) updater) {
    final oldEdge = _edges[id];
    if (oldEdge == null) return false;

    // 从索引中移除旧边
    _removeFromNodeIndex(oldEdge);
    _removeFromAnchorIndex(oldEdge);

    final newEdge = updater(oldEdge);
    _edges[id] = newEdge;

    // 添加新边到索引
    _addToNodeIndex(newEdge);
    _addToAnchorIndex(newEdge);

    _emitEvent(EdgeUpdatedEvent(id, oldEdge, newEdge));
    return true;
  }

  /// 移除边
  ///
  /// 返回被移除的边，如果不存在则返回 null。
  DiagramEdge? removeEdge(String id) {
    final edge = _edges.remove(id);
    if (edge == null) return null;

    // 更新索引
    _removeFromNodeIndex(edge);
    _removeFromAnchorIndex(edge);

    _emitEvent(EdgeRemovedEvent(edge));
    return edge;
  }

  /// 批量添加边
  void addEdges(Iterable<DiagramEdge> edges,
      {bool overwrite = false, bool validateNodes = true}) {
    _withBatchEvents(() {
      for (final edge in edges) {
        addEdge(edge, overwrite: overwrite, validateNodes: validateNodes);
      }
    });
  }

  /// 批量移除边
  List<DiagramEdge> removeEdges(Iterable<String> ids) {
    final removed = <DiagramEdge>[];

    _withBatchEvents(() {
      for (final id in ids) {
        final edge = removeEdge(id);
        if (edge != null) {
          removed.add(edge);
        }
      }
    });

    return removed;
  }

  // ========== 连接查询 ==========

  /// 获取连接到指定节点的所有边
  List<DiagramEdge> getEdgesForNode(String nodeId) {
    final edgeIds = _nodeEdgeIndex[nodeId];
    if (edgeIds == null || edgeIds.isEmpty) return [];

    return edgeIds.map((id) => _edges[id]).whereType<DiagramEdge>().toList();
  }

  /// 获取从指定节点出发的边（作为源节点）
  List<DiagramEdge> getOutgoingEdges(String nodeId) {
    return getEdgesForNode(nodeId)
        .where((e) => e.sourceNodeId == nodeId)
        .toList();
  }

  /// 获取进入指定节点的边（作为目标节点）
  List<DiagramEdge> getIncomingEdges(String nodeId) {
    return getEdgesForNode(nodeId)
        .where((e) => e.targetNodeId == nodeId)
        .toList();
  }

  /// 获取连接到指定锚点的所有边
  List<DiagramEdge> getEdgesForAnchor(String anchorId) {
    final edgeIds = _anchorEdgeIndex[anchorId];
    if (edgeIds == null || edgeIds.isEmpty) return [];

    return edgeIds.map((id) => _edges[id]).whereType<DiagramEdge>().toList();
  }

  /// 获取两个节点之间的边
  List<DiagramEdge> getEdgesBetween(String sourceNodeId, String targetNodeId) {
    return getEdgesForNode(sourceNodeId)
        .where((e) => e.targetNodeId == targetNodeId)
        .toList();
  }

  /// 检查两个节点是否直接相连
  bool areNodesConnected(String sourceNodeId, String targetNodeId) {
    return getEdgesBetween(sourceNodeId, targetNodeId).isNotEmpty;
  }

  /// 获取节点的邻居节点
  List<DiagramNode> getNeighbors(String nodeId) {
    final neighbors = <String>{};

    for (final edge in getEdgesForNode(nodeId)) {
      if (edge.sourceNodeId == nodeId) {
        neighbors.add(edge.targetNodeId);
      } else {
        neighbors.add(edge.sourceNodeId);
      }
    }

    return neighbors.map((id) => _nodes[id]).whereType<DiagramNode>().toList();
  }

  /// 获取锚点的连接数
  int getAnchorConnectionCount(String anchorId) {
    return _anchorEdgeIndex[anchorId]?.length ?? 0;
  }

  // ========== 批量操作 ==========

  /// 在批量操作中禁用事件通知
  ///
  /// 所有变更将在操作完成后合并为单个 [BatchChangeEvent] 发送。
  T withBatchEvents<T>(T Function() operation) {
    return _withBatchEvents(operation);
  }

  T _withBatchEvents<T>(T Function() operation) {
    final wasSuppressing = _suppressEvents;
    _suppressEvents = true;
    _pendingEvents.clear();

    try {
      final result = operation();

      // 发送批量事件
      if (_pendingEvents.isNotEmpty) {
        _changeController.add(BatchChangeEvent(List.unmodifiable(_pendingEvents)));
        _pendingEvents.clear();
      }

      return result;
    } finally {
      _suppressEvents = wasSuppressing;
    }
  }

  /// 清空所有数据
  void clear() {
    _withBatchEvents(() {
      // 移除所有边
      for (final edgeId in _edges.keys.toList()) {
        removeEdge(edgeId);
      }
      // 移除所有节点
      for (final nodeId in _nodes.keys.toList()) {
        removeNode(nodeId);
      }
    });
  }

  // ========== 数据导入导出 ==========

  /// 导出所有数据
  GraphData export() {
    return GraphData(
      nodes: Map.unmodifiable(_nodes),
      edges: Map.unmodifiable(_edges),
    );
  }

  /// 导入数据
  ///
  /// 使用 [clear: true] 在导入前清空现有数据。
  void import(GraphData data, {bool clear = true}) {
    _withBatchEvents(() {
      if (clear) {
        this.clear();
      }

      for (final node in data.nodes.values) {
        addNode(node);
      }

      for (final edge in data.edges.values) {
        addEdge(edge, validateNodes: false);
      }
    });
  }

  /// 从另一个模型复制数据
  void copyFrom(GraphModel other, {bool clear = true}) {
    import(other.export(), clear: clear);
  }

  // ========== 内部方法 ==========

  void _emitEvent(GraphChangeEvent event) {
    if (_suppressEvents) {
      _pendingEvents.add(event);
    } else {
      _changeController.add(event);
    }
  }

  void _addToNodeIndex(DiagramEdge edge) {
    _nodeEdgeIndex.putIfAbsent(edge.sourceNodeId, () => {}).add(edge.id);
    _nodeEdgeIndex.putIfAbsent(edge.targetNodeId, () => {}).add(edge.id);
  }

  void _removeFromNodeIndex(DiagramEdge edge) {
    _nodeEdgeIndex[edge.sourceNodeId]?.remove(edge.id);
    _nodeEdgeIndex[edge.targetNodeId]?.remove(edge.id);
  }

  void _addToAnchorIndex(DiagramEdge edge) {
    _anchorEdgeIndex.putIfAbsent(edge.sourceAnchorId, () => {}).add(edge.id);
    _anchorEdgeIndex.putIfAbsent(edge.targetAnchorId, () => {}).add(edge.id);
  }

  void _removeFromAnchorIndex(DiagramEdge edge) {
    _anchorEdgeIndex[edge.sourceAnchorId]?.remove(edge.id);
    _anchorEdgeIndex[edge.targetAnchorId]?.remove(edge.id);
  }

  // ========== 资源清理 ==========

  /// 释放资源
  void dispose() {
    _changeController.close();
  }
}

// ========== 变更事件 ==========

/// 图变更事件基类
sealed class GraphChangeEvent {
  /// 事件时间戳
  final DateTime timestamp;

  GraphChangeEvent() : timestamp = DateTime.now();
}

/// 节点添加事件
class NodeAddedEvent extends GraphChangeEvent {
  final DiagramNode node;
  final DiagramNode? oldNode;

  NodeAddedEvent(this.node, {this.oldNode});
}

/// 节点更新事件
class NodeUpdatedEvent extends GraphChangeEvent {
  final String nodeId;
  final DiagramNode oldNode;
  final DiagramNode newNode;

  NodeUpdatedEvent(this.nodeId, this.oldNode, this.newNode);
}

/// 节点移除事件
class NodeRemovedEvent extends GraphChangeEvent {
  final DiagramNode node;
  final List<DiagramEdge> removedEdges;

  NodeRemovedEvent(this.node, this.removedEdges);
}

/// 边添加事件
class EdgeAddedEvent extends GraphChangeEvent {
  final DiagramEdge edge;
  final DiagramEdge? oldEdge;

  EdgeAddedEvent(this.edge, {this.oldEdge});
}

/// 边更新事件
class EdgeUpdatedEvent extends GraphChangeEvent {
  final String edgeId;
  final DiagramEdge oldEdge;
  final DiagramEdge newEdge;

  EdgeUpdatedEvent(this.edgeId, this.oldEdge, this.newEdge);
}

/// 边移除事件
class EdgeRemovedEvent extends GraphChangeEvent {
  final DiagramEdge edge;

  EdgeRemovedEvent(this.edge);
}

/// 批量变更事件
class BatchChangeEvent extends GraphChangeEvent {
  final List<GraphChangeEvent> events;

  BatchChangeEvent(this.events);
}

// ========== 结果类型 ==========

/// 移除节点结果
class RemoveNodeResult {
  final DiagramNode? node;
  final List<DiagramEdge> removedEdges;

  const RemoveNodeResult({this.node, this.removedEdges = const []});

  const RemoveNodeResult.notFound() : node = null, removedEdges = const [];

  bool get found => node != null;
}

/// 批量移除结果
class BatchRemoveResult {
  final List<DiagramNode> nodes;
  final List<DiagramEdge> edges;

  const BatchRemoveResult({this.nodes = const [], this.edges = const []});
}

// ========== 数据容器 ==========

/// 图数据容器
///
/// 用于导入导出操作的数据载体。
class GraphData {
  final Map<String, DiagramNode> nodes;
  final Map<String, DiagramEdge> edges;

  const GraphData({required this.nodes, required this.edges});

  /// 空数据
  static const GraphData empty = GraphData(nodes: {}, edges: {});

  /// 是否为空
  bool get isEmpty => nodes.isEmpty && edges.isEmpty;

  /// 是否不为空
  bool get isNotEmpty => nodes.isNotEmpty || edges.isNotEmpty;
}

// ========== 扩展方法 ==========

/// GraphModel 扩展
extension GraphModelExtension on GraphModel {
  /// 查找满足条件的节点
  List<DiagramNode> findNodes(bool Function(DiagramNode) predicate) {
    return nodes.where(predicate).toList();
  }

  /// 查找满足条件的边
  List<DiagramEdge> findEdges(bool Function(DiagramEdge) predicate) {
    return edges.where(predicate).toList();
  }

  /// 获取所有节点 ID
  Set<String> get nodeIds => _nodes.keys.toSet();

  /// 获取所有边 ID
  Set<String> get edgeIds => _edges.keys.toSet();

  /// 计算内容边界
  Rect calculateContentBounds({double padding = 50.0}) {
    if (nodeCount == 0) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      final rect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );
      minX = minX < rect.left ? minX : rect.left;
      minY = minY < rect.top ? minY : rect.top;
      maxX = maxX > rect.right ? maxX : rect.right;
      maxY = maxY > rect.bottom ? maxY : rect.bottom;
    }

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// 获取图的统计信息
  GraphStats get stats => GraphStats(
        nodeCount: nodeCount,
        edgeCount: edgeCount,
        anchorConnectionCounts: _anchorEdgeIndex.map(
          (key, value) => MapEntry(key, value.length),
        ),
      );
}

/// 图统计信息
class GraphStats {
  final int nodeCount;
  final int edgeCount;
  final Map<String, int> anchorConnectionCounts;

  const GraphStats({
    required this.nodeCount,
    required this.edgeCount,
    required this.anchorConnectionCounts,
  });

  /// 平均每个节点的连接数
  double get avgConnectionsPerNode =>
      nodeCount > 0 ? (edgeCount * 2) / nodeCount : 0;

  /// 最大锚点连接数
  int get maxAnchorConnections =>
      anchorConnectionCounts.values.fold(0, (a, b) => a > b ? a : b);
}
