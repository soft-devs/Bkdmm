import 'dart:ui';

/// 图表节点抽象接口
///
/// 所有图表类型的节点都需要实现此接口
/// 提供通用的位置、尺寸、标识属性
abstract class DiagramNode {
  /// 节点唯一标识
  String get id;

  /// 节点位置 (场景坐标)
  Offset get position;
  set position(Offset value);

  /// 节点尺寸
  Size get size;

  /// 节点类型标识
  String get type;

  /// 节点标题（用于显示）
  String get title;

  /// 是否可选中
  bool get isSelectable;

  /// 是否可拖拽
  bool get isDraggable;

  /// 是否可连线
  bool get isConnectable;

  /// 获取所有锚点位置
  ///
  /// 锚点是边连接到节点的具体位置
  /// 默认返回节点四边中点
  /// 特殊类型（如 ER 图）可以返回字段级锚点
  List<AnchorPoint> getAnchors();

  /// 获取指定方向的锚点
  ///
  /// direction: 锚点方向 (left, right, top, bottom)
  AnchorPoint? getAnchor(String direction);

  /// 获取自定义数据
  ///
  /// 用于存储特定图表类型的数据
  /// 如 ER 图的 Entity，UML 类图的 ClassInfo
  dynamic getData();
}

/// 锚点类型
enum AnchorType {
  /// 节点级锚点（节点四边中点）
  node,

  /// 字段级锚点（如 ER 图的字段连接点）
  field,

  /// 端口锚点（如流程图的输入/输出端口）
  port,

  /// 自定义锚点
  custom,
}

/// 锚点方向
enum AnchorDirection {
  left,
  right,
  top,
  bottom,
}

/// 锚点配置
class AnchorConfig {
  /// 是否可作为连接起点
  final bool canConnectFrom;

  /// 是否可作为连接终点
  final bool canConnectTo;

  /// 最大连接数
  final int maxConnections;

  /// 接受的边类型列表（空表示接受所有）
  final List<String>? acceptedEdgeTypes;

  const AnchorConfig({
    this.canConnectFrom = true,
    this.canConnectTo = true,
    this.maxConnections = -1, // -1 表示无限制
    this.acceptedEdgeTypes,
  });
}

/// 锚点位置信息
class AnchorPoint {
  /// 锚点所属节点
  final DiagramNode node;

  /// 锚点 ID (格式: nodeId:anchorKey)
  final String id;

  /// 锚点在场景中的绝对位置
  final Offset position;

  /// 锚点类型
  final AnchorType type;

  /// 锚点方向
  final AnchorDirection direction;

  /// 锚点配置
  final AnchorConfig config;

  /// 锚点附加数据（如字段索引、端口名称等）
  final dynamic data;

  const AnchorPoint({
    required this.node,
    required this.id,
    required this.position,
    this.type = AnchorType.node,
    this.direction = AnchorDirection.right,
    this.config = const AnchorConfig(),
    this.data,
  });

  /// 创建节点级锚点
  factory AnchorPoint.nodeAnchor({
    required DiagramNode node,
    required AnchorDirection direction,
  }) {
    final rect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );

    Offset pos;
    switch (direction) {
      case AnchorDirection.left:
        pos = Offset(rect.left, rect.center.dy);
        break;
      case AnchorDirection.right:
        pos = Offset(rect.right, rect.center.dy);
        break;
      case AnchorDirection.top:
        pos = Offset(rect.center.dx, rect.top);
        break;
      case AnchorDirection.bottom:
        pos = Offset(rect.center.dx, rect.bottom);
        break;
    }

    return AnchorPoint(
      node: node,
      id: '${node.id}:${direction.name}',
      position: pos,
      type: AnchorType.node,
      direction: direction,
    );
  }

  /// 创建字段级锚点（用于 ER 图）
  factory AnchorPoint.fieldAnchor({
    required DiagramNode node,
    required int fieldIndex,
    required AnchorDirection direction,
    required Offset position,
    dynamic fieldData,
  }) {
    return AnchorPoint(
      node: node,
      id: '${node.id}:field:$fieldIndex:${direction.name}',
      position: position,
      type: AnchorType.field,
      direction: direction,
      data: {'fieldIndex': fieldIndex, 'fieldData': fieldData},
    );
  }

  /// 获取相对节点的位置
  Offset get relativePosition {
    return Offset(
      position.dx - node.position.dx,
      position.dy - node.position.dy,
    );
  }
}

/// 节点状态
class NodeState {
  /// 是否选中
  final bool isSelected;

  /// 是否高亮
  final bool isHighlighted;

  /// 是否悬停
  final bool isHovered;

  /// 是否正在拖拽
  final bool isDragging;

  /// 是否正在编辑
  final bool isEditing;

  const NodeState({
    this.isSelected = false,
    this.isHighlighted = false,
    this.isHovered = false,
    this.isDragging = false,
    this.isEditing = false,
  });

  NodeState copyWith({
    bool? isSelected,
    bool? isHighlighted,
    bool? isHovered,
    bool? isDragging,
    bool? isEditing,
  }) {
    return NodeState(
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isHovered: isHovered ?? this.isHovered,
      isDragging: isDragging ?? this.isDragging,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  bool get isInteractive => isDragging || isEditing;
}