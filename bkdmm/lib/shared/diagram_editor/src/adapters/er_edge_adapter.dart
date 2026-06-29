/// ER 边适配器
///
/// 将 [GraphEdge] 数据转换为 [ERRelationEdgeModel],
/// 用于 diagram_editor 框架的 ER 图连线渲染。
library;

import '../../../models/module.dart';
import '../er/er_relation_edge_model.dart';

/// ER 边适配器
///
/// 提供从业务数据到图编辑器边模型的转换方法。
///
/// ## 锚点 ID 格式
///
/// ER 图使用字段级锚点，格式为: `nodeId:field:index:direction`
/// - `nodeId`: 实体 ID
/// - `field`: 固定标识符，表示这是字段锚点
/// - `index`: 字段索引（从 0 开始）
/// - `direction`: 锚点方向 (`left` 或 `right`)
///
/// ## 使用示例
///
/// ```dart
/// // 从 GraphEdge 创建边
/// final edge = EREdgeAdapter.fromGraphEdge(graphEdge, sourceId, targetId);
///
/// // 从整个 Module 创建所有边
/// final edges = EREdgeAdapter.fromModule(module);
/// ```
class EREdgeAdapter {
  /// 从 GraphEdge 创建 ERRelationEdgeModel
  ///
  /// [edge] 图边数据
  /// [sourceNodeId] 源实体 ID
  /// [targetNodeId] 目标实体 ID
  ///
  /// 返回可用于 diagram_editor 的边模型。
  static ERRelationEdgeModel fromGraphEdge(
    GraphEdge edge,
    String sourceNodeId,
    String targetNodeId,
  ) {
    // 解析字段索引
    final sourceFieldIndex = _parseFieldIndex(edge.sourceField);
    final targetFieldIndex = _parseFieldIndex(edge.targetField);

    // 构建锚点 ID
    final sourceAnchorId = _buildFieldAnchorId(
      sourceNodeId,
      sourceFieldIndex,
      AnchorDirection.right,
    );
    final targetAnchorId = _buildFieldAnchorId(
      targetNodeId,
      targetFieldIndex,
      AnchorDirection.left,
    );

    // 解析关系类型和基数
    final relationType = _parseRelationType(edge.relationType);
    final (sourceCardinality, targetCardinality) = _parseCardinality(
      edge.relationType,
    );

    // 构建边 ID
    final edgeId = _buildEdgeId(
      sourceNodeId,
      targetNodeId,
      sourceFieldIndex,
      targetFieldIndex,
    );

    return ERRelationEdgeModel(
      id: edgeId,
      sourceAnchorId: sourceAnchorId,
      targetAnchorId: targetAnchorId,
      relationType: relationType,
      sourceCardinality: sourceCardinality,
      targetCardinality: targetCardinality,
      label: edge.label,
    );
  }

  /// 从 Module 创建所有 ERRelationEdgeModel
  ///
  /// [module] 模块数据
  ///
  /// 返回模块中所有关系对应的边模型列表。
  static List<ERRelationEdgeModel> fromModule(Module module) {
    // 构建 Entity title -> Entity ID 映射
    // GraphEdge 使用 source/target 作为实体标识（可能是 title 或 ID）
    final titleToIdMap = <String, String>{};
    final idToEntityMap = <String, dynamic>{};

    for (final entity in module.entities) {
      titleToIdMap[entity.title] = entity.id;
      idToEntityMap[entity.id] = entity;
    }

    final edges = <ERRelationEdgeModel>[];

    for (final graphEdge in module.graphCanvas.edges) {
      // 解析源和目标实体 ID
      final sourceNodeId = _resolveNodeId(graphEdge.source, titleToIdMap);
      final targetNodeId = _resolveNodeId(graphEdge.target, titleToIdMap);

      if (sourceNodeId == null || targetNodeId == null) {
        // 无法解析实体 ID，跳过此边
        continue;
      }

      edges.add(fromGraphEdge(graphEdge, sourceNodeId, targetNodeId));
    }

    return edges;
  }

  /// 从 ERRelationEdgeModel 创建 GraphEdge（用于保存）
  ///
  /// [edge] ER 关系边模型
  /// [sourceEntityTitle] 源实体标题
  /// [targetEntityTitle] 目标实体标题
  static GraphEdge toGraphEdge(
    ERRelationEdgeModel edge,
    String sourceEntityTitle,
    String targetEntityTitle,
  ) {
    // 解析字段索引
    final sourceFieldIndex = _extractFieldIndex(edge.sourceAnchorId);
    final targetFieldIndex = _extractFieldIndex(edge.targetAnchorId);

    return GraphEdge(
      source: sourceEntityTitle,
      target: targetEntityTitle,
      sourceField: sourceFieldIndex?.toString(),
      targetField: targetFieldIndex?.toString(),
      label: edge.label ?? edge.relationName,
      relationType: _cardinalityToRelationType(
        edge.sourceCardinality,
        edge.targetCardinality,
      ),
    );
  }

  /// 批量转换 ERRelationEdgeModel 为 GraphEdge 列表
  ///
  /// [edges] ER 边模型列表
  /// [entityIdToTitleMap] 实体 ID -> 实体标题映射
  static List<GraphEdge> toGraphEdges(
    List<ERRelationEdgeModel> edges,
    Map<String, String> entityIdToTitleMap,
  ) {
    return edges.map((edge) {
      final sourceTitle = entityIdToTitleMap[edge.sourceEntityId] ?? '';
      final targetTitle = entityIdToTitleMap[edge.targetEntityId] ?? '';
      return toGraphEdge(edge, sourceTitle, targetTitle);
    }).toList();
  }

  // ===========================================================================
  // 私有辅助方法
  // ===========================================================================

  /// 构建字段锚点 ID
  ///
  /// 格式: `nodeId:field:index:direction`
  static String _buildFieldAnchorId(
    String nodeId,
    int? fieldIndex,
    AnchorDirection direction,
  ) {
    // 如果没有字段索引，使用节点级锚点
    if (fieldIndex == null) {
      return '$nodeId:${direction.name}';
    }

    return '$nodeId:field:$fieldIndex:${direction.name}';
  }

  /// 构建边 ID
  ///
  /// 格式: `sourceId_targetId_sourceFieldIndex_targetFieldIndex`
  static String _buildEdgeId(
    String sourceNodeId,
    String targetNodeId,
    int? sourceFieldIndex,
    int? targetFieldIndex,
  ) {
    final source = sourceFieldIndex ?? 'node';
    final target = targetFieldIndex ?? 'node';
    return '${sourceNodeId}_${targetNodeId}_${source}_${target}';
  }

  /// 解析字段索引
  ///
  /// GraphEdge 的 sourceField/targetField 可能是:
  /// - 数字字符串: "0", "1", "2"
  /// - 字段名: "id", "name" (需要查找对应的索引)
  /// - null (表示节点级连线)
  static int? _parseFieldIndex(String? field) {
    if (field == null || field.isEmpty) {
      return null;
    }

    // 尝试直接解析为数字
    final index = int.tryParse(field);
    if (index != null) {
      return index;
    }

    // 如果是字段名，返回 null（需要在具体上下文中查找索引）
    return null;
  }

  /// 从锚点 ID 提取字段索引
  ///
  /// 锚点 ID 格式: `nodeId:field:index:direction` 或 `nodeId:direction`
  static int? _extractFieldIndex(String anchorId) {
    final parts = anchorId.split(':');
    if (parts.length >= 3 && parts[1] == 'field') {
      return int.tryParse(parts[2]);
    }
    return null;
  }

  /// 解析实体 ID
  ///
  /// GraphEdge.source/target 可能是:
  /// - Entity ID (直接匹配)
  /// - Entity title (需要通过映射查找)
  /// - 格式: "表名:序号" (需要解析表名部分)
  static String? _resolveNodeId(
    String identifier,
    Map<String, String> titleToIdMap,
  ) {
    // 直接匹配 ID
    if (titleToIdMap.containsValue(identifier)) {
      return identifier;
    }

    // 通过 title 匹配
    if (titleToIdMap.containsKey(identifier)) {
      return titleToIdMap[identifier];
    }

    // 解析 "表名:序号" 格式
    if (identifier.contains(':')) {
      final titlePart = identifier.split(':').first;
      return titleToIdMap[titlePart];
    }

    return null;
  }

  /// 解析关系类型
  ///
  /// 关系类型格式: "1:1", "1:N", "N:1", "N:M", "identifying", "nonIdentifying"
  static ERRelationType _parseRelationType(String? relationType) {
    if (relationType == null || relationType.isEmpty) {
      return ERRelationType.nonIdentifying;
    }

    // 检查是否为标识关系
    if (relationType.toLowerCase().contains('identifying')) {
      return ERRelationType.identifying;
    }

    // 检查是否为非标识关系
    if (relationType.toLowerCase().contains('nonidentifying')) {
      return ERRelationType.nonIdentifying;
    }

    // 默认为非标识关系
    return ERRelationType.nonIdentifying;
  }

  /// 解析基数
  ///
  /// 从关系类型字符串解析源端和目标端基数
  static (ERCardinalityEnd, ERCardinalityEnd) _parseCardinality(
    String? relationType,
  ) {
    if (relationType == null || relationType.isEmpty) {
      return (ERCardinalityEnd.one, ERCardinalityEnd.many);
    }

    // 解析基数格式: "1:1", "1:N", "N:1", "N:M"
    final parts = relationType.split(':');
    if (parts.length == 2) {
      final source = _parseCardinalityEnd(parts[0].trim());
      final target = _parseCardinalityEnd(parts[1].trim());
      return (source, target);
    }

    // 默认 1:N
    return (ERCardinalityEnd.one, ERCardinalityEnd.many);
  }

  /// 解析单个基数端
  static ERCardinalityEnd _parseCardinalityEnd(String cardinality) {
    switch (cardinality.toUpperCase()) {
      case '1':
        return ERCardinalityEnd.one;
      case 'N':
      case 'M':
        return ERCardinalityEnd.many;
      case '0..1':
        return ERCardinalityEnd.zeroOrOne;
      case '0..N':
      case '0..M':
        return ERCardinalityEnd.zeroOrMany;
      default:
        // 尝试解析数字
        final value = int.tryParse(cardinality);
        if (value != null) {
          return ERCardinalityEnd.custom(value);
        }
        return ERCardinalityEnd.one;
    }
  }

  /// 将基数转换为关系类型字符串
  static String _cardinalityToRelationType(
    ERCardinalityEnd source,
    ERCardinalityEnd target,
  ) {
    return '${source.displayText}:${target.displayText}';
  }
}

/// 锚点方向枚举
enum AnchorDirection {
  left,
  right,
  top,
  bottom,
}