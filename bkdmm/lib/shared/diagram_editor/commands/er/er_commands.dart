/// ER 图专用命令
///
/// 扩展 DiagramCommand 以支持 ER 图特有的操作，
/// 如关系创建、实体删除等。
library;

import 'dart:ui';

import '../diagram_command.dart';
import '../../er/er_relation_edge_model.dart';

/// 创建 ER 关系命令
///
/// 封装关系的创建操作，支持撤销/重做。
class CreateERRelationCommand extends DiagramCommand {
  /// 关系模型
  final ERRelationEdgeModel relation;

  /// 添加关系的回调
  final void Function(ERRelationEdgeModel relation) onAdd;

  /// 移除关系的回调
  final void Function(String edgeId) onRemove;

  CreateERRelationCommand({
    required this.relation,
    required this.onAdd,
    required this.onRemove,
  }) : super(
          id: relation.id,
          description: 'Create relation: ${relation.cardinalityDisplayText}',
          type: 'create_er_relation',
        );

  @override
  dynamic execute() {
    onAdd(relation);
  }

  @override
  void undo() {
    onRemove(relation.id);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'relation': relation.toJson(),
    };
  }
}

/// 删除 ER 关系命令
///
/// 封装关系的删除操作，支持撤销/重做。
class DeleteERRelationCommand extends DiagramCommand {
  /// 关系 ID
  final String edgeId;

  /// 关系数据（用于恢复）
  final ERRelationEdgeModel relationData;

  /// 删除关系的回调
  final void Function(String edgeId) onRemove;

  /// 恢复关系的回调
  final void Function(ERRelationEdgeModel relation) onRestore;

  DeleteERRelationCommand({
    required this.edgeId,
    required this.relationData,
    required this.onRemove,
    required this.onRestore,
  }) : super(
          id: edgeId,
          description: 'Delete relation: ${relationData.cardinalityDisplayText}',
          type: 'delete_er_relation',
        );

  @override
  dynamic execute() {
    onRemove(edgeId);
  }

  @override
  void undo() {
    onRestore(relationData);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'edgeId': edgeId,
      'relationData': relationData.toJson(),
    };
  }
}

/// 批量移动 ER 节点命令
///
/// 将多个节点的移动操作合并为单个命令，
/// 支持合并连续的移动操作。
class BatchMoveERNodesCommand extends DiagramCommand {
  /// 节点 ID -> 旧位置映射
  final Map<String, Offset> oldPositions;

  /// 节点 ID -> 新位置映射
  final Map<String, Offset> newPositions;

  /// 移动节点的回调
  final void Function(String nodeId, Offset position) onMove;

  BatchMoveERNodesCommand({
    required this.oldPositions,
    required this.newPositions,
    required this.onMove,
    String? id,
  }) : super(
          id: id ?? 'batch_move_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Move ${oldPositions.length} nodes',
          type: 'batch_move_er_nodes',
        );

  @override
  dynamic execute() {
    for (final entry in newPositions.entries) {
      onMove(entry.key, entry.value);
    }
  }

  @override
  void undo() {
    for (final entry in oldPositions.entries) {
      onMove(entry.key, entry.value);
    }
  }

  @override
  bool canMergeWith(DiagramCommand other) {
    if (other is! BatchMoveERNodesCommand) return false;
    // 检查是否移动相同的节点
    final myNodeIds = oldPositions.keys.toSet();
    final otherNodeIds = other.oldPositions.keys.toSet();
    return myNodeIds.containsAll(otherNodeIds) ||
        otherNodeIds.containsAll(myNodeIds);
  }

  @override
  DiagramCommand mergeWith(DiagramCommand other) {
    if (other is! BatchMoveERNodesCommand) {
      throw ArgumentError('Cannot merge with non-BatchMoveERNodesCommand');
    }
    return BatchMoveERNodesCommand(
      oldPositions: oldPositions,
      newPositions: other.newPositions,
      onMove: onMove,
      id: id,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'oldPositions': oldPositions.map(
        (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
      ),
      'newPositions': newPositions.map(
        (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
      ),
    };
  }
}

/// 应用 ER 布局命令
///
/// 将自动布局的结果应用到图，支持撤销。
class ApplyERLayoutCommand extends DiagramCommand {
  /// 节点 ID -> 旧位置映射
  final Map<String, Offset> oldPositions;

  /// 节点 ID -> 新位置映射
  final Map<String, Offset> newPositions;

  /// 应用位置的回调
  final void Function(Map<String, Offset> positions) onApplyLayout;

  ApplyERLayoutCommand({
    required this.oldPositions,
    required this.newPositions,
    required this.onApplyLayout,
  }) : super(
          id: 'apply_layout_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Apply auto layout',
          type: 'apply_er_layout',
        );

  @override
  dynamic execute() {
    onApplyLayout(newPositions);
  }

  @override
  void undo() {
    onApplyLayout(oldPositions);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'oldPositions': oldPositions.map(
        (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
      ),
      'newPositions': newPositions.map(
        (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
      ),
    };
  }
}
