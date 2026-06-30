import 'dart:ui';

import 'package:bkdmm/shared/models/entity.dart';
import '../model/node_model.dart';
import '../core/diagram_node.dart';

/// ER 表节点模型
///
/// 专门用于 ER 图的表节点模型，扩展自 [NodeModel]，
/// 封装 [Entity] 数据并提供字段级锚点支持。
///
/// 特性：
/// - 支持字段级锚点（每个字段左右两侧可连线）
/// - 自动计算节点尺寸（基于字段数量）
/// - 提供主键字段快速访问
class ERTableNodeModel extends NodeModel {
  /// 关联的实体数据
  Entity _entity;

  /// 字段锚点缓存
  List<AnchorPoint>? _cachedFieldAnchors;

  /// 布局常量
  static const double defaultWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double cornerRadius = 8.0;

  /// 创建 ER 表节点模型
  ERTableNodeModel({
    required String id,
    required Entity entity,
    super.position,
    super.state,
    super.isSelectable,
    super.isDraggable,
    super.isConnectable,
  })  : _entity = entity,
        super(
          id: id,
          type: 'er_table',
          title: entity.title,
          size: _calculateSize(entity.fields.length),
        );

  /// 获取关联的实体数据
  Entity get entity => _entity;

  /// 更新关联的实体数据
  ///
  /// 更新实体会自动重新计算节点尺寸
  set entity(Entity value) {
    _entity = value;
    title = value.title;
    size = _calculateSize(value.fields.length);
    _cachedFieldAnchors = null; // 清除锚点缓存
  }

  /// 获取主键字段列表
  List<Field> get primaryKeys => _entity.primaryKeys;

  /// 获取字段数量
  int get fieldCount => _entity.fields.length;

  /// 获取指定索引的字段
  Field? getField(int index) {
    if (index < 0 || index >= _entity.fields.length) return null;
    return _entity.fields[index];
  }

  /// 获取字段在节点中的 Y 偏移量
  double getFieldYOffset(int fieldIndex) {
    return headerHeight + (fieldIndex * fieldRowHeight) + (fieldRowHeight / 2);
  }

  @override
  List<AnchorPoint> getAnchors() {
    // 返回字段级锚点 + 节点级锚点
    return [...getFieldAnchors(), ...getNodeAnchors()];
  }

  /// 获取字段级锚点
  ///
  /// 每个字段左右两侧各一个锚点，用于连线
  List<AnchorPoint> getFieldAnchors() {
    if (_cachedFieldAnchors != null) {
      return _cachedFieldAnchors!;
    }

    final anchors = <AnchorPoint>[];
    for (var i = 0; i < _entity.fields.length; i++) {
      final field = _entity.fields[i];
      final yOffset = getFieldYOffset(i);

      // 左侧锚点
      anchors.add(AnchorPoint.fieldAnchor(
        node: this,
        fieldIndex: i,
        direction: AnchorDirection.left,
        position: Offset(position.dx, position.dy + yOffset),
        fieldData: field,
      ));

      // 右侧锚点
      anchors.add(AnchorPoint.fieldAnchor(
        node: this,
        fieldIndex: i,
        direction: AnchorDirection.right,
        position: Offset(position.dx + size.width, position.dy + yOffset),
        fieldData: field,
      ));
    }

    _cachedFieldAnchors = anchors;
    return anchors;
  }

  /// 获取节点级锚点
  ///
  /// 节点四边中点，用于一般连接
  List<AnchorPoint> getNodeAnchors() {
    return [
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.left),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.right),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.top),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.bottom),
    ];
  }

  @override
  AnchorPoint? getAnchor(String direction) {
    // 支持两种格式:
    // 1. 简单方向: "left", "right", "top", "bottom"
    // 2. 字段锚点: "field:0:left", "field:1:right"

    if (direction.startsWith('field:')) {
      final parts = direction.split(':');
      if (parts.length >= 3) {
        final fieldIndex = int.tryParse(parts[1]);
        final anchorDir = parts[2];
        if (fieldIndex != null && fieldIndex < _entity.fields.length) {
          return getFieldAnchor(fieldIndex, anchorDir);
        }
      }
      return null;
    }

    // 简单方向查询
    return super.getAnchor(direction);
  }

  /// 获取指定字段的锚点
  ///
  /// [fieldIndex] 字段索引
  /// [direction] 锚点方向: "left" 或 "right"
  AnchorPoint? getFieldAnchor(int fieldIndex, String direction) {
    if (fieldIndex < 0 || fieldIndex >= _entity.fields.length) return null;

    final yOffset = getFieldYOffset(fieldIndex);
    final isLeft = direction == 'left' || direction == AnchorDirection.left.name;

    return AnchorPoint.fieldAnchor(
      node: this,
      fieldIndex: fieldIndex,
      direction: isLeft ? AnchorDirection.left : AnchorDirection.right,
      position: Offset(
        isLeft ? position.dx : position.dx + size.width,
        position.dy + yOffset,
      ),
      fieldData: _entity.fields[fieldIndex],
    );
  }

  /// 更新节点位置并清除锚点缓存
  @override
  void moveTo(Offset newPosition) {
    super.moveTo(newPosition);
    _cachedFieldAnchors = null;
  }

  /// 更新节点位置并清除锚点缓存
  @override
  void moveBy(Offset delta) {
    super.moveBy(delta);
    _cachedFieldAnchors = null;
  }

  /// 更新实体数据
  ///
  /// [newEntity] 新的实体数据
  void updateEntity(Entity newEntity) {
    entity = newEntity;
  }

  /// 计算节点尺寸
  static Size _calculateSize(int fieldCount) {
    const minHeight = 80.0;
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return Size(defaultWidth, height < minHeight ? minHeight : height);
  }

  /// 计算节点高度
  static double calculateHeight(int fieldCount) {
    const minHeight = 80.0;
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return height < minHeight ? minHeight : height;
  }

  /// 复制节点模型
  @override
  ERTableNodeModel copyWith({
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
    Entity? entity,
  }) {
    return ERTableNodeModel(
      id: id ?? this.id,
      entity: entity ?? _entity,
      position: position ?? this.position,
      state: state ?? this.state,
      isSelectable: isSelectable ?? this.isSelectable,
      isDraggable: isDraggable ?? this.isDraggable,
      isConnectable: isConnectable ?? this.isConnectable,
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['entity'] = _entity.toJson();
    json['nodeType'] = 'er_table';
    return json;
  }

  /// 从 JSON 创建
  factory ERTableNodeModel.fromJson(Map<String, dynamic> json) {
    final posJson = json['position'] as Map<String, dynamic>?;
    final entityJson = json['entity'] as Map<String, dynamic>?;

    return ERTableNodeModel(
      id: json['id'] as String,
      entity: entityJson != null ? Entity.fromJson(entityJson) : Entity(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        chnname: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      position: posJson != null
          ? Offset((posJson['x'] as num).toDouble(), (posJson['y'] as num).toDouble())
          : Offset.zero,
      state: json['state'] != null
          ? NodeState(
              isSelected: (json['state'] as Map<String, dynamic>?)?['isSelected'] as bool? ?? false,
              isHighlighted: (json['state'] as Map<String, dynamic>?)?['isHighlighted'] as bool? ?? false,
              isHovered: (json['state'] as Map<String, dynamic>?)?['isHovered'] as bool? ?? false,
              isDragging: (json['state'] as Map<String, dynamic>?)?['isDragging'] as bool? ?? false,
              isEditing: (json['state'] as Map<String, dynamic>?)?['isEditing'] as bool? ?? false,
            )
          : null,
      isSelectable: json['isSelectable'] as bool? ?? true,
      isDraggable: json['isDraggable'] as bool? ?? true,
      isConnectable: json['isConnectable'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'ERTableNodeModel(id: $id, title: $title, entity: ${_entity.title}, fields: ${_entity.fields.length}, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ERTableNodeModel &&
        other.id == id &&
        other._entity.id == _entity.id &&
        other.position == position &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(id, _entity.id, position, size);
}