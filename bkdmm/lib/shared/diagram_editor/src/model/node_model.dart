import 'dart:ui';
import '../core/diagram_node.dart';

/// 节点模型基类
///
/// 提供节点的基础属性实现：位置、尺寸、状态
/// 具体图表类型的节点可继承此类并扩展自定义属性
class NodeModel implements DiagramNode {
  @override
  final String id;

  @override
  String type;

  @override
  String title;

  /// 节点位置 (场景坐标)
  @override
  Offset position;

  /// 节点尺寸
  @override
  Size size;

  /// 节点状态
  NodeState state;

  /// 是否可选中
  @override
  bool isSelectable;

  /// 是否可拖拽
  @override
  bool isDraggable;

  /// 是否可连线
  @override
  bool isConnectable;

  /// 自定义数据
  dynamic _data;

  /// 创建节点模型
  NodeModel({
    required this.id,
    required this.type,
    required this.title,
    Offset position = Offset.zero,
    Size size = const Size(100, 60),
    NodeState? state,
    this.isSelectable = true,
    this.isDraggable = true,
    this.isConnectable = true,
    dynamic data,
  })  : position = position,
        size = size,
        state = state ?? const NodeState(),
        _data = data;

  /// 节点边界矩形
  Rect get bounds => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  /// 节点中心点
  Offset get center => Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );

  /// 检测点是否在节点内
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  /// 移动节点到指定位置
  void moveTo(Offset newPosition) {
    position = newPosition;
  }

  /// 移动节点偏移量
  void moveBy(Offset delta) {
    position = position + delta;
  }

  /// 调整节点尺寸
  void resize(Size newSize) {
    size = newSize;
  }

  /// 更新节点状态
  void updateState(NodeState newState) {
    state = newState;
  }

  /// 设置选中状态
  void setSelected(bool selected) {
    state = state.copyWith(isSelected: selected);
  }

  /// 设置高亮状态
  void setHighlighted(bool highlighted) {
    state = state.copyWith(isHighlighted: highlighted);
  }

  /// 设置悬停状态
  void setHovered(bool hovered) {
    state = state.copyWith(isHovered: hovered);
  }

  /// 设置拖拽状态
  void setDragging(bool dragging) {
    state = state.copyWith(isDragging: dragging);
  }

  /// 设置编辑状态
  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing);
  }

  @override
  List<AnchorPoint> getAnchors() {
    // 默认返回四个方向的中点锚点
    return [
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.left),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.right),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.top),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.bottom),
    ];
  }

  @override
  AnchorPoint? getAnchor(String direction) {
    final anchors = getAnchors();
    for (final anchor in anchors) {
      if (anchor.direction.name == direction) {
        return anchor;
      }
    }
    return null;
  }

  @override
  dynamic getData() => _data;

  /// 设置自定义数据
  void setData(dynamic data) {
    _data = data;
  }

  /// 复制节点模型
  NodeModel copyWith({
    String? id,
    String? type,
    String? title,
    Offset? position,
    Size? size,
    NodeState? state,
    bool? isSelectable,
    bool? isDraggable,
    bool? isConnectable,
    dynamic data,
  }) {
    return NodeModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      position: position ?? this.position,
      size: size ?? this.size,
      state: state ?? this.state,
      isSelectable: isSelectable ?? this.isSelectable,
      isDraggable: isDraggable ?? this.isDraggable,
      isConnectable: isConnectable ?? this.isConnectable,
      data: data ?? _data,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'isSelectable': isSelectable,
      'isDraggable': isDraggable,
      'isConnectable': isConnectable,
      'data': _data,
    };
  }

  /// 从 JSON 创建
  factory NodeModel.fromJson(Map<String, dynamic> json) {
    final posJson = json['position'] as Map<String, dynamic>?;
    final sizeJson = json['size'] as Map<String, dynamic>?;

    return NodeModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      position: posJson != null
          ? Offset((posJson['x'] as num).toDouble(), (posJson['y'] as num).toDouble())
          : Offset.zero,
      size: sizeJson != null
          ? Size((sizeJson['width'] as num).toDouble(), (sizeJson['height'] as num).toDouble())
          : const Size(100, 60),
      isSelectable: json['isSelectable'] as bool? ?? true,
      isDraggable: json['isDraggable'] as bool? ?? true,
      isConnectable: json['isConnectable'] as bool? ?? true,
      data: json['data'],
    );
  }

  @override
  String toString() {
    return 'NodeModel(id: $id, type: $type, title: $title, position: $position, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NodeModel &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.position == position &&
        other.size == size;
  }

  @override
  int get hashCode {
    return Object.hash(id, type, title, position, size);
  }
}

/// 可观察的节点模型
///
/// 提供变更通知能力的节点模型，适合需要响应式更新的场景
class ObservableNodeModel extends NodeModel {
  /// 状态变更回调
  final void Function(ObservableNodeModel node)? onStateChanged;

  /// 位置变更回调
  final void Function(ObservableNodeModel node, Offset oldPosition)? onPositionChanged;

  /// 尺寸变更回调
  final void Function(ObservableNodeModel node, Size oldSize)? onSizeChanged;

  ObservableNodeModel({
    required super.id,
    required super.type,
    required super.title,
    super.position,
    super.size,
    super.state,
    super.isSelectable,
    super.isDraggable,
    super.isConnectable,
    super.data,
    this.onStateChanged,
    this.onPositionChanged,
    this.onSizeChanged,
  });

  @override
  void moveTo(Offset newPosition) {
    final oldPosition = position;
    super.moveTo(newPosition);
    onPositionChanged?.call(this, oldPosition);
  }

  @override
  void moveBy(Offset delta) {
    final oldPosition = position;
    super.moveBy(delta);
    onPositionChanged?.call(this, oldPosition);
  }

  @override
  void resize(Size newSize) {
    final oldSize = size;
    super.resize(newSize);
    onSizeChanged?.call(this, oldSize);
  }

  @override
  void updateState(NodeState newState) {
    super.updateState(newState);
    onStateChanged?.call(this);
  }

  @override
  ObservableNodeModel copyWith({
    String? id,
    String? type,
    String? title,
    Offset? position,
    Size? size,
    NodeState? state,
    bool? isSelectable,
    bool? isDraggable,
    bool? isConnectable,
    dynamic data,
  }) {
    return ObservableNodeModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      position: position ?? this.position,
      size: size ?? this.size,
      state: state ?? this.state,
      isSelectable: isSelectable ?? this.isSelectable,
      isDraggable: isDraggable ?? this.isDraggable,
      isConnectable: isConnectable ?? this.isConnectable,
      data: data ?? this.getData(),
      onStateChanged: onStateChanged,
      onPositionChanged: onPositionChanged,
      onSizeChanged: onSizeChanged,
    );
  }
}
