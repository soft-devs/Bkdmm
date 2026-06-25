import 'dart:ui';
import 'package:graphview/graphview.dart';
import '../../../../shared/models/models.dart';
import '../models/er_diagram_ui_state.dart';

/// ER 图 Graph 构建器
///
/// 从 Module 数据构建 graphview 的 Graph 对象。
/// 单向转换，每次 build 时重新构建。
class ERGraphBuilder {
  /// 节点默认宽度
  static const double nodeWidth = 200.0;

  /// 表头高度
  static const double headerHeight = 40.0;

  /// 字段行高度
  static const double fieldRowHeight = 28.0;

  /// 节点最小高度
  static const double minNodeHeight = 80.0;

  /// 节点 ID 到 Node 的映射
  final Map<String, Node> _nodeMap = {};

  /// 从 Module 构建 Graph
  Graph buildGraph(Module module) {
    final graph = Graph();
    _nodeMap.clear();

    // 创建节点 ID 到 GraphNode 的映射
    final graphNodeMap = <String, GraphNode>{};
    for (final gn in module.graphCanvas.nodes) {
      if (gn.moduleName != null) {
        graphNodeMap[gn.moduleName!] = gn;
      }
    }

    // 添加节点
    for (final entity in module.entities) {
      final graphNode = graphNodeMap[entity.id] ?? _createDefaultGraphNode(entity, module);
      final node = _createNode(entity, graphNode);
      graph.addNode(node);
      _nodeMap[entity.id] = node;
    }

    // 添加边
    for (final edge in module.graphCanvas.edges) {
      final sourceNode = _nodeMap[edge.source];
      final targetNode = _nodeMap[edge.target];

      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }

    return graph;
  }

  /// 创建 graphview Node
  Node _createNode(Entity entity, GraphNode graphNode) {
    final node = Node.Id(entity.id);
    node.position = Offset(graphNode.x, graphNode.y);
    node.size = _calculateNodeSize(entity);
    return node;
  }

  /// 计算节点尺寸
  Size _calculateNodeSize(Entity entity) {
    final fieldCount = entity.fields.length;
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return Size(nodeWidth, height < minNodeHeight ? minNodeHeight : height);
  }

  /// 为新实体创建默认 GraphNode
  GraphNode _createDefaultGraphNode(Entity entity, Module module) {
    final position = _calculateNewNodePosition(module);
    return GraphNode(
      title: '${entity.title}:0',
      x: position.dx,
      y: position.dy,
      moduleName: entity.id,
    );
  }

  /// 计算新节点的位置
  Offset _calculateNewNodePosition(Module module) {
    const startX = 100.0;
    const startY = 100.0;
    const offsetX = 250.0;
    const offsetY = 300.0;
    const maxCols = 4;

    final existingNodes = module.graphCanvas.nodes
        .where((n) => n.moduleName != null)
        .toList();

    if (existingNodes.isEmpty) {
      return const Offset(startX, startY);
    }

    // 找到已有节点的最大 X 和 Y
    double maxX = 0;
    double maxY = 0;
    int lastRowNodeCount = 0;

    for (final node in existingNodes) {
      if (node.x > maxX) maxX = node.x;
      if (node.y > maxY) maxY = node.y;
    }

    // 计算最后一行的节点数量
    for (final node in existingNodes) {
      if ((node.y - startY).abs() < offsetY / 2) {
        lastRowNodeCount++;
      }
    }

    // 如果最后一行已满，开启新行
    if (lastRowNodeCount >= maxCols) {
      return Offset(startX, maxY + offsetY);
    }

    // 否则添加到当前行末尾
    return Offset(maxX + offsetX, maxY);
  }

  /// 计算字段锚点位置
  ///
  /// [nodePosition] 节点位置
  /// [entity] 实体数据
  /// [fieldIndex] 字段索引
  /// [direction] 锚点方向
  static Offset calculateAnchorPosition(
    Offset nodePosition,
    Entity entity,
    int fieldIndex,
    ERAnchorDirection direction,
  ) {
    const anchorOffset = 8.0;
    final rowY = headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;

    if (direction == ERAnchorDirection.left) {
      return Offset(nodePosition.dx - anchorOffset, nodePosition.dy + rowY);
    } else {
      return Offset(nodePosition.dx + nodeWidth + anchorOffset, nodePosition.dy + rowY);
    }
  }

  /// 获取节点的所有字段锚点
  static List<ERFieldAnchor> getFieldAnchors(
    String nodeId,
    Entity entity,
    Offset nodePosition,
  ) {
    final anchors = <ERFieldAnchor>[];

    for (var i = 0; i < entity.fields.length; i++) {
      // 左锚点
      anchors.add(ERFieldAnchor(
        nodeId: nodeId,
        fieldIndex: i,
        direction: ERAnchorDirection.left,
        position: calculateAnchorPosition(nodePosition, entity, i, ERAnchorDirection.left),
      ));

      // 右锚点
      anchors.add(ERFieldAnchor(
        nodeId: nodeId,
        fieldIndex: i,
        direction: ERAnchorDirection.right,
        position: calculateAnchorPosition(nodePosition, entity, i, ERAnchorDirection.right),
      ));
    }

    return anchors;
  }

  /// 获取节点
  Node? getNode(String nodeId) => _nodeMap[nodeId];
}

/// ER 图边数据
///
/// 扩展 graphview 的 Edge，存储字段级连线信息
class EREdgeData {
  final int? sourceFieldIndex;
  final int? targetFieldIndex;
  final String? relationType;
  final String? label;

  const EREdgeData({
    this.sourceFieldIndex,
    this.targetFieldIndex,
    this.relationType,
    this.label,
  });
}
