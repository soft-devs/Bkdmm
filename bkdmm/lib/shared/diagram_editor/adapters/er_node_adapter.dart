/// ER 节点适配器
///
/// 将 [Entity] 和 [GraphNode] 数据转换为 [ERTableNodeModel]，
/// 用于 diagram_editor 框架的 ER 图渲染。
library;

import 'dart:ui';

import 'package:bkdmm/shared/models/entity.dart';
import 'package:bkdmm/shared/models/module.dart';
import '../er/er_table_node_model.dart';

/// ER 节点适配器
///
/// 提供从业务数据到图编辑器节点模型的转换方法。
///
/// ## 使用示例
///
/// ```dart
/// // 从单个 Entity 创建节点
/// final node = ERNodeAdapter.fromEntity(entity, graphNode);
///
/// // 从整个 Module 创建所有节点
/// final nodes = ERNodeAdapter.fromModule(module);
/// ```
class ERNodeAdapter {
  /// 默认起始 X 坐标
  static const double defaultStartX = 100.0;

  /// 默认起始 Y 坐标
  static const double defaultStartY = 100.0;

  /// 节点水平间距
  static const double nodeHorizontalSpacing = 250.0;

  /// 节点垂直间距
  static const double nodeVerticalSpacing = 300.0;

  /// 每行最大节点数
  static const int maxNodesPerRow = 4;

  /// 从 Entity 和 GraphNode 创建 ERTableNodeModel
  ///
  /// [entity] 实体数据
  /// [graphNode] 图节点数据（包含位置信息）
  ///
  /// 返回可用于 diagram_editor 的节点模型。
  static ERTableNodeModel fromEntity(Entity entity, GraphNode graphNode) {
    return ERTableNodeModel(
      id: entity.id,
      entity: entity,
      position: Offset(graphNode.x, graphNode.y),
    );
  }

  /// 从 Entity 创建 ERTableNodeModel（使用指定位置）
  ///
  /// [entity] 实体数据
  /// [position] 节点位置
  static ERTableNodeModel fromEntityWithPosition(
    Entity entity,
    Offset position,
  ) {
    return ERTableNodeModel(
      id: entity.id,
      entity: entity,
      position: position,
    );
  }

  /// 从 Module 创建所有 ERTableNodeModel
  ///
  /// [module] 模块数据
  ///
  /// 返回模块中所有实体对应的节点模型列表。
  /// 对于没有 GraphNode 的实体，会自动分配网格位置。
  static List<ERTableNodeModel> fromModule(Module module) {
    // 构建 Entity ID -> GraphNode 映射
    final graphNodeMap = <String, GraphNode>{};
    for (final gn in module.graphCanvas.nodes) {
      if (gn.moduleName != null) {
        graphNodeMap[gn.moduleName!] = gn;
      }
    }

    final nodes = <ERTableNodeModel>[];
    final entitiesWithoutPosition = <Entity>[];

    // 为有位置的实体创建节点
    for (final entity in module.entities) {
      final graphNode = graphNodeMap[entity.id];
      if (graphNode != null) {
        nodes.add(fromEntity(entity, graphNode));
      } else {
        entitiesWithoutPosition.add(entity);
      }
    }

    // 为没有位置的实体分配网格位置
    if (entitiesWithoutPosition.isNotEmpty) {
      // 找到当前最大 Y 坐标
      double maxY = defaultStartY;
      for (final node in nodes) {
        if (node.position.dy > maxY) {
          maxY = node.position.dy;
        }
      }

      // 从最大 Y 下方开始放置新节点
      final startPosition = Offset(defaultStartX, maxY + nodeVerticalSpacing);
      final newPositions = _calculateGridPositions(
        entitiesWithoutPosition.length,
        startPosition,
      );

      for (var i = 0; i < entitiesWithoutPosition.length; i++) {
        nodes.add(fromEntityWithPosition(
          entitiesWithoutPosition[i],
          newPositions[i],
        ));
      }
    }

    return nodes;
  }

  /// 从 Entity 列表和 GraphNode 映射创建节点
  ///
  /// [entities] 实体列表
  /// [graphNodeMap] Entity ID -> GraphNode 映射
  /// [defaultPosition] 没有位置信息时的默认起始位置
  static List<ERTableNodeModel> fromEntitiesWithMap(
    List<Entity> entities,
    Map<String, GraphNode> graphNodeMap, {
    Offset defaultPosition = Offset.zero,
  }) {
    final nodes = <ERTableNodeModel>[];
    var nextPosition = defaultPosition;

    for (final entity in entities) {
      final graphNode = graphNodeMap[entity.id];
      if (graphNode != null) {
        nodes.add(fromEntity(entity, graphNode));
      } else {
        nodes.add(fromEntityWithPosition(entity, nextPosition));
        nextPosition = Offset(
          nextPosition.dx + nodeHorizontalSpacing,
          nextPosition.dy,
        );
      }
    }

    return nodes;
  }

  /// 计算网格布局位置
  ///
  /// [count] 节点数量
  /// [startPosition] 起始位置
  static List<Offset> _calculateGridPositions(
    int count,
    Offset startPosition,
  ) {
    final positions = <Offset>[];
    var currentX = startPosition.dx;
    var currentY = startPosition.dy;
    var nodesInCurrentRow = 0;

    for (var i = 0; i < count; i++) {
      positions.add(Offset(currentX, currentY));

      nodesInCurrentRow++;
      if (nodesInCurrentRow >= maxNodesPerRow) {
        // 换行
        currentX = defaultStartX;
        currentY += nodeVerticalSpacing;
        nodesInCurrentRow = 0;
      } else {
        // 同一行下一个位置
        currentX += nodeHorizontalSpacing;
      }
    }

    return positions;
  }

  /// 创建单个实体的默认 GraphNode
  ///
  /// [entity] 实体数据
  /// [existingNodes] 已有节点列表（用于计算新位置）
  static GraphNode createDefaultGraphNode(
    Entity entity,
    List<GraphNode> existingNodes,
  ) {
    // 找到最后一行
    double maxY = defaultStartY;
    double maxXInLastRow = defaultStartX;
    int nodesInLastRow = 0;

    for (final node in existingNodes) {
      if (node.y > maxY) {
        maxY = node.y;
        maxXInLastRow = node.x;
        nodesInLastRow = 1;
      } else if (node.y == maxY) {
        maxXInLastRow = node.x > maxXInLastRow ? node.x : maxXInLastRow;
        nodesInLastRow++;
      }
    }

    // 计算新位置
    double newX;
    double newY;

    if (nodesInLastRow >= maxNodesPerRow) {
      // 换行
      newX = defaultStartX;
      newY = maxY + nodeVerticalSpacing;
    } else {
      // 同一行
      newX = maxXInLastRow + nodeHorizontalSpacing;
      newY = maxY;
    }

    return GraphNode(
      title: '${entity.title}:0',
      x: newX,
      y: newY,
      moduleName: entity.id,
    );
  }

  /// 将 ERTableNodeModel 转换为 GraphNode（用于保存）
  ///
  /// [node] ER 节点模型
  static GraphNode toGraphNode(ERTableNodeModel node) {
    return GraphNode(
      title: '${node.entity.title}:0',
      x: node.position.dx,
      y: node.position.dy,
      moduleName: node.id,
    );
  }

  /// 批量转换 ERTableNodeModel 为 GraphNode 列表
  ///
  /// [nodes] ER 节点模型列表
  static List<GraphNode> toGraphNodes(List<ERTableNodeModel> nodes) {
    return nodes.map(toGraphNode).toList();
  }

  /// 更新现有 GraphNode 列表中的位置
  ///
  /// [existingNodes] 现有节点列表
  /// [nodeId] 要更新的节点 ID
  /// [newPosition] 新位置
  static List<GraphNode> updateNodePosition(
    List<GraphNode> existingNodes,
    String nodeId,
    Offset newPosition,
  ) {
    return existingNodes.map((node) {
      if (node.moduleName == nodeId) {
        return node.copyWith(
          x: newPosition.dx,
          y: newPosition.dy,
        );
      }
      return node;
    }).toList();
  }

  /// 批量更新节点位置
  ///
  /// [existingNodes] 现有节点列表
  /// [positions] 节点 ID -> 新位置映射
  static List<GraphNode> updateNodePositions(
    List<GraphNode> existingNodes,
    Map<String, Offset> positions,
  ) {
    return existingNodes.map((node) {
      if (node.moduleName != null && positions.containsKey(node.moduleName)) {
        final pos = positions[node.moduleName]!;
        return node.copyWith(
          x: pos.dx,
          y: pos.dy,
        );
      }
      return node;
    }).toList();
  }
}
