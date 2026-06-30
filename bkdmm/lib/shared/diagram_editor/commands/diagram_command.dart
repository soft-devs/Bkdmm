/// 图表命令基类
///
/// 所有可撤销操作都需要实现此接口。
/// 使用命令模式支持撤销/重做功能。
library;

import 'dart:ui';

/// 图表命令接口
///
/// 所有图表操作都应该封装为命令对象，
/// 以支持撤销和重做功能。
abstract class DiagramCommand {
  /// 命令唯一标识
  final String id;

  /// 命令描述（用于 UI 显示）
  final String description;

  /// 创建时间
  final DateTime timestamp;

  /// 命令类型（用于分组）
  final String type;

  DiagramCommand({
    required this.id,
    required this.description,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 执行命令
  ///
  /// 调用此方法执行命令的操作。
  /// 返回执行结果（可选）。
  dynamic execute();

  /// 撤销命令
  ///
  /// 调用此方法撤销命令的操作。
  /// 必须恢复到 execute() 之前的状态。
  void undo();

  /// 重做命令
  ///
  /// 默认实现是再次调用 execute()。
  /// 如果需要不同的重做逻辑，可以覆盖此方法。
  dynamic redo() => execute();

  /// 是否可以与另一个命令合并
  ///
  /// 用于合并连续的相同类型操作（如连续拖动）。
  bool canMergeWith(DiagramCommand other) => false;

  /// 与另一个命令合并
  ///
  /// 返回合并后的新命令。
  /// 如果无法合并，抛出异常。
  DiagramCommand mergeWith(DiagramCommand other) {
    throw UnsupportedError('This command cannot be merged');
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson();

  /// 从 JSON 反序列化
  ///
  /// 子类需要实现此方法以支持持久化。
  static DiagramCommand fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }

  @override
  String toString() => 'DiagramCommand($type: $description)';
}

/// 移动节点命令
///
/// 记录节点位置的变更，支持撤销。
class MoveNodeCommand extends DiagramCommand {
  /// 节点 ID
  final String nodeId;

  /// 旧位置
  final Offset oldPosition;

  /// 新位置
  Offset newPosition;

  /// 执行移动的回调
  final void Function(String nodeId, Offset position) onMove;

  MoveNodeCommand({
    required this.nodeId,
    required this.oldPosition,
    required this.newPosition,
    required this.onMove,
    super.id = '',
    super.description = 'Move node',
    super.type = 'move_node',
  });

  @override
  dynamic execute() {
    onMove(nodeId, newPosition);
  }

  @override
  void undo() {
    onMove(nodeId, oldPosition);
  }

  @override
  bool canMergeWith(DiagramCommand other) {
    if (other is! MoveNodeCommand) return false;
    return other.nodeId == nodeId && other.type == type;
  }

  @override
  DiagramCommand mergeWith(DiagramCommand other) {
    if (other is! MoveNodeCommand) {
      throw ArgumentError('Cannot merge with non-MoveNodeCommand');
    }
    return MoveNodeCommand(
      nodeId: nodeId,
      oldPosition: oldPosition,
      newPosition: other.newPosition,
      onMove: onMove,
      id: id,
      description: description,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'nodeId': nodeId,
        'oldPosition': {'x': oldPosition.dx, 'y': oldPosition.dy},
        'newPosition': {'x': newPosition.dx, 'y': newPosition.dy},
      };
}

/// 添加边命令
///
/// 记录边的创建，支持撤销。
class AddEdgeCommand extends DiagramCommand {
  /// 边 ID
  final String edgeId;

  /// 源锚点 ID
  final String sourceAnchorId;

  /// 目标锚点 ID
  final String targetAnchorId;

  /// 执行添加的回调
  final void Function(String edgeId, String sourceAnchorId, String targetAnchorId) onAdd;

  /// 执行删除的回调
  final void Function(String edgeId) onRemove;

  AddEdgeCommand({
    required this.edgeId,
    required this.sourceAnchorId,
    required this.targetAnchorId,
    required this.onAdd,
    required this.onRemove,
    super.id = '',
    super.description = 'Add edge',
    super.type = 'add_edge',
  });

  @override
  dynamic execute() {
    onAdd(edgeId, sourceAnchorId, targetAnchorId);
  }

  @override
  void undo() {
    onRemove(edgeId);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'edgeId': edgeId,
        'sourceAnchorId': sourceAnchorId,
        'targetAnchorId': targetAnchorId,
      };
}

/// 删除元素命令
///
/// 记录元素（节点、边）的删除，支持撤销。
class DeleteElementsCommand extends DiagramCommand {
  /// 被删除的节点 ID 列表
  final List<String> nodeIds;

  /// 被删除的边 ID 列表
  final List<String> edgeIds;

  /// 节点数据（用于恢复）
  final Map<String, dynamic> nodesData;

  /// 边数据（用于恢复）
  final Map<String, dynamic> edgesData;

  /// 执行删除的回调
  final void Function(List<String> nodeIds, List<String> edgeIds) onDelete;

  /// 执行恢复的回调
  final void Function(Map<String, dynamic> nodesData, Map<String, dynamic> edgesData) onRestore;

  DeleteElementsCommand({
    required this.nodeIds,
    required this.edgeIds,
    required this.nodesData,
    required this.edgesData,
    required this.onDelete,
    required this.onRestore,
    super.id = '',
    super.description = 'Delete elements',
    super.type = 'delete_elements',
  });

  @override
  dynamic execute() {
    onDelete(nodeIds, edgeIds);
  }

  @override
  void undo() {
    onRestore(nodesData, edgesData);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'nodeIds': nodeIds,
        'edgeIds': edgeIds,
        'nodesData': nodesData,
        'edgesData': edgesData,
      };
}

/// 复合命令
///
/// 将多个命令组合为一个原子操作。
class CompositeCommand extends DiagramCommand {
  /// 子命令列表
  final List<DiagramCommand> commands;

  CompositeCommand({
    required this.commands,
    super.id = '',
    super.description = 'Composite operation',
    super.type = 'composite',
  });

  @override
  dynamic execute() {
    for (final command in commands) {
      command.execute();
    }
  }

  @override
  void undo() {
    // 按相反顺序撤销
    for (final command in commands.reversed) {
      command.undo();
    }
  }

  @override
  dynamic redo() {
    for (final command in commands) {
      command.redo();
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'commands': commands.map((c) => c.toJson()).toList(),
      };
}
