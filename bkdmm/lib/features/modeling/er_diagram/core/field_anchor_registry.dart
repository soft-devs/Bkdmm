import 'dart:ui';
import 'package:bkdmm/shared/models/models.dart';

/// 字段锚点方向
enum FieldAnchorDirection {
  left,
  right,
}

/// 字段锚点信息
///
/// 用于 ER 图的字段级连接点管理
class FieldAnchor {
  /// 锚点所属节点 ID
  final String nodeId;

  /// 字段索引
  final int fieldIndex;

  /// 锚点在场景中的绝对位置
  Offset position;

  /// 锚点方向（左/右）
  final FieldAnchorDirection direction;

  /// 字段数据
  final Field field;

  /// 锚点 ID
  String get id => '$nodeId:field:$fieldIndex:${direction.name}';

  FieldAnchor({
    required this.nodeId,
    required this.fieldIndex,
    required this.position,
    required this.direction,
    required this.field,
  });

  /// 复制并更新位置
  FieldAnchor copyWithPosition(Offset newPosition) {
    return FieldAnchor(
      nodeId: nodeId,
      fieldIndex: fieldIndex,
      position: newPosition,
      direction: direction,
      field: field,
    );
  }
}

/// 字段锚点注册表
///
/// 管理 ER 图所有节点的字段级锚点
/// 支持注册、查询、命中测试等功能
class FieldAnchorRegistry {
  /// 左锚点存储：nodeId -> (fieldIndex -> FieldAnchor)
  final Map<String, Map<int, FieldAnchor>> _leftAnchors = {};

  /// 右锚点存储：nodeId -> (fieldIndex -> FieldAnchor)
  final Map<String, Map<int, FieldAnchor>> _rightAnchors = {};

  /// 常量配置（与 ERNodeRenderer 保持一致）
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double anchorOffset = 8.0;
  static const double defaultWidth = 200.0;

  /// 注册节点所有字段的锚点
  ///
  /// [nodeId] 节点 ID
  /// [entity] 实体数据
  /// [nodePosition] 节点左上角位置
  /// [nodeWidth] 节点宽度（默认 200）
  void registerFieldAnchors(
    String nodeId,
    Entity entity,
    Offset nodePosition, {
    double nodeWidth = defaultWidth,
  }) {
    _leftAnchors[nodeId] = {};
    _rightAnchors[nodeId] = {};

    for (var i = 0; i < entity.fields.length; i++) {
      final field = entity.fields[i];
      final rowY = nodePosition.dy + headerHeight + (i * fieldRowHeight) + fieldRowHeight / 2;

      // 左锚点（出边连接点）
      _leftAnchors[nodeId]![i] = FieldAnchor(
        nodeId: nodeId,
        fieldIndex: i,
        position: Offset(nodePosition.dx - anchorOffset, rowY),
        direction: FieldAnchorDirection.left,
        field: field,
      );

      // 右锚点（入边连接点）
      _rightAnchors[nodeId]![i] = FieldAnchor(
        nodeId: nodeId,
        fieldIndex: i,
        position: Offset(nodePosition.dx + nodeWidth + anchorOffset, rowY),
        direction: FieldAnchorDirection.right,
        field: field,
      );
    }
  }

  /// 更新节点锚点位置（节点移动后调用）
  void updateNodeAnchors(
    String nodeId,
    Entity entity,
    Offset newPosition, {
    double nodeWidth = defaultWidth,
  }) {
    registerFieldAnchors(nodeId, entity, newPosition, nodeWidth: nodeWidth);
  }

  /// 获取指定锚点
  FieldAnchor? getAnchor(
    String nodeId,
    int fieldIndex,
    FieldAnchorDirection direction,
  ) {
    if (direction == FieldAnchorDirection.left) {
      return _leftAnchors[nodeId]?[fieldIndex];
    } else {
      return _rightAnchors[nodeId]?[fieldIndex];
    }
  }

  /// 通过锚点 ID 获取锚点
  FieldAnchor? getAnchorById(String anchorId) {
    final parts = anchorId.split(':');
    if (parts.length != 4 || parts[1] != 'field') return null;

    final nodeId = parts[0];
    final fieldIndex = int.tryParse(parts[2]);
    final directionStr = parts[3];

    if (fieldIndex == null) return null;

    final direction = directionStr == 'left'
        ? FieldAnchorDirection.left
        : FieldAnchorDirection.right;

    return getAnchor(nodeId, fieldIndex, direction);
  }

  /// 获取节点所有锚点
  List<FieldAnchor> getNodeAnchors(String nodeId) {
    final anchors = <FieldAnchor>[];

    final leftAnchors = _leftAnchors[nodeId];
    if (leftAnchors != null) {
      anchors.addAll(leftAnchors.values);
    }

    final rightAnchors = _rightAnchors[nodeId];
    if (rightAnchors != null) {
      anchors.addAll(rightAnchors.values);
    }

    return anchors;
  }

  /// 锚点命中测试
  ///
  /// [point] 测试点（场景坐标）
  /// [threshold] 命中阈值（像素）
  FieldAnchor? hitTest(Offset point, double threshold) {
    // 检查所有锚点
    for (final nodeAnchors in _leftAnchors.values) {
      for (final anchor in nodeAnchors.values) {
        if ((point - anchor.position).distance < threshold) {
          return anchor;
        }
      }
    }

    for (final nodeAnchors in _rightAnchors.values) {
      for (final anchor in nodeAnchors.values) {
        if ((point - anchor.position).distance < threshold) {
          return anchor;
        }
      }
    }

    return null;
  }

  /// 获取指定节点附近的所有锚点（用于连线预览）
  List<FieldAnchor> getAnchorsNearNode(
    String nodeId,
    Offset position,
    double radius,
  ) {
    final anchors = <FieldAnchor>[];

    final nodeLeftAnchors = _leftAnchors[nodeId];
    if (nodeLeftAnchors != null) {
      for (final anchor in nodeLeftAnchors.values) {
        if ((position - anchor.position).distance < radius) {
          anchors.add(anchor);
        }
      }
    }

    final nodeRightAnchors = _rightAnchors[nodeId];
    if (nodeRightAnchors != null) {
      for (final anchor in nodeRightAnchors.values) {
        if ((position - anchor.position).distance < radius) {
          anchors.add(anchor);
        }
      }
    }

    return anchors;
  }

  /// 移除节点锚点
  void removeNodeAnchors(String nodeId) {
    _leftAnchors.remove(nodeId);
    _rightAnchors.remove(nodeId);
  }

  /// 清空所有锚点
  void clear() {
    _leftAnchors.clear();
    _rightAnchors.clear();
  }

  /// 获取所有锚点数量
  int get totalAnchorCount {
    var count = 0;
    for (final nodeAnchors in _leftAnchors.values) {
      count += nodeAnchors.length;
    }
    for (final nodeAnchors in _rightAnchors.values) {
      count += nodeAnchors.length;
    }
    return count;
  }

  /// 获取节点数量
  int get nodeCount {
    return _leftAnchors.length;
  }

  /// 计算字段锚点位置（用于动态计算）
  static Offset calculateFieldAnchorPosition(
    Offset nodePosition,
    int fieldIndex,
    FieldAnchorDirection direction, {
    double nodeWidth = defaultWidth,
  }) {
    final rowY = nodePosition.dy + headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;

    if (direction == FieldAnchorDirection.left) {
      return Offset(nodePosition.dx - anchorOffset, rowY);
    } else {
      return Offset(nodePosition.dx + nodeWidth + anchorOffset, rowY);
    }
  }

  /// 计算节点高度
  static double calculateNodeHeight(int fieldCount) {
    const minHeight = 80.0;
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return height < minHeight ? minHeight : height;
  }
}