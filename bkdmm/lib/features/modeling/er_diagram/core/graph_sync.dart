import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:graphview/graphview.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';
import '../models/er_diagram_models.dart';
import 'field_anchor_registry.dart';
import 'er_graph_edge.dart';

/// ER 图与 graphview Graph 的双向同步器
///
/// 负责在 ERDiagramState 和 Graph 之间转换数据：
/// - syncFromState: ERDiagramState -> Graph
/// - syncToState: Graph -> ERDiagramState
class ERDiagramGraphSync {
  /// graphview Graph 实例
  final Graph graph = Graph();

  /// 字段锚点注册表
  final FieldAnchorRegistry anchorRegistry = FieldAnchorRegistry();

  /// 节点 ID 到 Node 的映射
  final Map<String, Node> _nodeMap = {};

  /// 边 ID 到 Edge 的映射
  final Map<String, ERGraphEdge> _edgeMap = {};

  /// 获取所有 graphview 节点
  List<Node> get nodes => graph.nodes;

  /// 获取所有 graphview 边
  List<Edge> get edges => graph.edges;

  /// 从 ERDiagramState 同步到 Graph
  ///
  /// 将 ERDiagramState 中的节点和边转换为 graphview 的 Graph
  void syncFromState(ERDiagramState state) {
    // 调试：打印状态中的节点信息
    debugPrint('syncFromState: state.nodes.length = ${state.nodes.length}');
    for (final entry in state.nodes.entries) {
      final erNode = entry.value as ERNode;
      debugPrint('  - node key=${entry.key}, entity.id=${erNode.entity.id}, entity.title=${erNode.entity.title}');
    }

    // 清空现有数据
    graph.removeNodes(List.from(graph.nodes));
    _nodeMap.clear();
    _edgeMap.clear();
    anchorRegistry.clear();

    // 添加节点
    for (final entry in state.nodes.entries) {
      final erNode = entry.value as ERNode;
      final node = _createGraphNode(erNode);
      graph.addNode(node);
      _nodeMap[entry.key] = node;

      debugPrint('  Added node to graph: id=${erNode.id}, position=${erNode.position}');

      // 注册字段锚点
      anchorRegistry.registerFieldAnchors(
        entry.key,
        erNode.entity,
        erNode.position,
        nodeWidth: erNode.size.width,
      );
    }

    debugPrint('syncFromState: graph.nodeCount() = ${graph.nodeCount()}');

    // 添加边
    for (final entry in state.edges.entries) {
      final erEdge = entry.value as ERRelationEdge;
      final sourceNode = _nodeMap[erEdge.sourceNodeId];
      final targetNode = _nodeMap[erEdge.targetNodeId];

      if (sourceNode != null && targetNode != null) {
        final edge = ERGraphEdge.fromGraphEdge(
          sourceNode: sourceNode,
          targetNode: targetNode,
          graphEdge: erEdge.graphEdge,
        );
        graph.addEdge(edge.source, edge.destination);
        _edgeMap[entry.key] = edge;
      }
    }
  }

  /// 创建 graphview Node
  ///
  /// 使用 Node.Id() 创建节点，ID 作为 key 的 value。
  /// 注意：Node.Id(id) 创建的节点 hashCode 基于 id.hashCode，
  /// 相同 ID 的节点会被视为相等。
  Node _createGraphNode(ERNode erNode) {
    final node = Node.Id(erNode.id);
    node.position = erNode.position;
    node.size = erNode.size;
    return node;
  }

  /// 同步节点位置更新
  ///
  /// 当节点位置改变时调用，更新 graphview Node 和锚点位置
  void updateNodePosition(String nodeId, Offset newPosition) {
    final node = _nodeMap[nodeId];
    if (node != null) {
      node.position = newPosition;
    }
  }

  /// 同步节点尺寸更新
  void updateNodeSize(String nodeId, Size newSize) {
    final node = _nodeMap[nodeId];
    if (node != null) {
      node.size = newSize;
    }
  }

  /// 添加节点
  Node addNode(ERNode erNode) {
    final node = _createGraphNode(erNode);
    graph.addNode(node);
    _nodeMap[erNode.id] = node;

    // 注册锚点
    anchorRegistry.registerFieldAnchors(
      erNode.id,
      erNode.entity,
      erNode.position,
      nodeWidth: erNode.size.width,
    );

    return node;
  }

  /// 移除节点
  void removeNode(String nodeId) {
    final node = _nodeMap[nodeId];
    if (node != null) {
      graph.removeNode(node);
      _nodeMap.remove(nodeId);
      anchorRegistry.removeNodeAnchors(nodeId);
    }
  }

  /// 添加边（字段级连线）
  ERGraphEdge? addEdgeWithFields({
    required String sourceNodeId,
    required String targetNodeId,
    int? sourceFieldIndex,
    int? targetFieldIndex,
    String relationType = '1:N',
    String? label,
  }) {
    final sourceNode = _nodeMap[sourceNodeId];
    final targetNode = _nodeMap[targetNodeId];

    if (sourceNode == null || targetNode == null) return null;

    final edge = ERGraphEdge(
      source: sourceNode,
      destination: targetNode,
      sourceFieldIndex: sourceFieldIndex,
      targetFieldIndex: targetFieldIndex,
      relationType: relationType,
      label: label,
    );

    graph.addEdge(edge.source, edge.destination);
    final edgeId = '$sourceNodeId:$targetNodeId';
    _edgeMap[edgeId] = edge;

    return edge;
  }

  /// 移除边
  void removeEdge(String edgeId) {
    final edge = _edgeMap[edgeId];
    if (edge != null) {
      graph.removeEdge(edge);
      _edgeMap.remove(edgeId);
    }
  }

  /// 导出回 ERDiagramState（用于持久化）
  ///
  /// 将 graphview Graph 的数据导出回 ERDiagramState 格式
  ERDiagramState syncToState(ERDiagramState baseState) {
    final newNodes = <String, DiagramNode>{};
    final newEdges = <String, DiagramEdge>{};

    // 转换节点
    for (final entry in baseState.nodes.entries) {
      final erNode = entry.value as ERNode;
      final graphNode = _nodeMap[entry.key];

      if (graphNode != null) {
        // 更新位置
        newNodes[entry.key] = erNode.copyWith(
          graphNode: _copyGraphNode(erNode.graphNode, x: graphNode.x, y: graphNode.y),
        );
      } else {
        newNodes[entry.key] = erNode;
      }
    }

    // 转换边
    for (final entry in _edgeMap.entries) {
      final erGraphEdge = entry.value;
      final sourceId = erGraphEdge.source.key?.value.toString() ?? '';
      final targetId = erGraphEdge.destination.key?.value.toString() ?? '';

      // 创建 GraphEdge
      final graphEdge = GraphEdge(
        source: sourceId,
        target: targetId,
        sourceField: erGraphEdge.sourceFieldIndex?.toString(),
        targetField: erGraphEdge.targetFieldIndex?.toString(),
        relationType: erGraphEdge.relationType,
        label: erGraphEdge.label,
      );

      newEdges[entry.key] = ERRelationEdge(graphEdge: graphEdge);
    }

    return baseState.copyWith(
      nodes: newNodes,
      edges: newEdges,
    );
  }

  /// 复制 GraphNode
  GraphNode _copyGraphNode(GraphNode original, {double? x, double? y}) {
    return GraphNode(
      title: original.title,
      x: x ?? original.x,
      y: y ?? original.y,
    );
  }

  /// 获取节点
  Node? getNode(String nodeId) => _nodeMap[nodeId];

  /// 获取边
  ERGraphEdge? getEdge(String edgeId) => _edgeMap[edgeId];

  /// 获取节点数量
  int get nodeCount => graph.nodeCount();

  /// 获取边数量
  int get edgeCount => graph.edges.length;

  /// 清空所有数据
  void clear() {
    graph.removeNodes(List.from(graph.nodes));
    _nodeMap.clear();
    _edgeMap.clear();
    anchorRegistry.clear();
  }

  /// 更新锚点位置（节点移动后调用）
  void refreshAnchors(ERDiagramState state) {
    for (final entry in state.nodes.entries) {
      final erNode = entry.value as ERNode;
      anchorRegistry.updateNodeAnchors(
        entry.key,
        erNode.entity,
        erNode.position,
        nodeWidth: erNode.size.width,
      );
    }
  }
}