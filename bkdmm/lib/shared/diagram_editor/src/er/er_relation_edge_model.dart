/// ER 关系边模型
///
/// ER 图中实体之间的关系边，支持：
/// - 基数标注（1:1, 1:N, N:M）
/// - 关系类型（标识关系、非标识关系）
/// - 鸦脚标记和连线样式
library;

import 'dart:ui';
import '../model/edge_model.dart';
import '../core/diagram_edge.dart';

/// ER 关系类型
enum ERRelationType {
  /// 标识关系 - 子实体依赖父实体，子实体的主键包含外键
  /// 外键是主键的一部分，用实线表示
  identifying,

  /// 非标识关系 - 子实体独立于父实体
  /// 外键不是主键的一部分，用虚线表示
  nonIdentifying,

  /// 非特定关系 - 传统 ER 图关系，不区分标识性
  unspecified,
}

/// ER 基数类型
enum ERCardinality {
  /// 一对一 (1:1)
  oneToOne,

  /// 一对多 (1:N)
  oneToMany,

  /// 多对多 (N:M)
  manyToMany,
}

/// ER 基数类型枚举
enum ERCardinalityType {
  /// 一
  one,

  /// 多（鸦脚）
  many,

  /// 自定义值
  custom,
}

/// ER 关系端点基数
///
/// 描述关系一端的基数约束
class ERCardinalityEnd {
  /// 基数类型
  final ERCardinalityType type;

  /// 是否可选（可为空）
  final bool isOptional;

  /// 具体基数（当 type 为 custom 时使用）
  final int? customValue;

  const ERCardinalityEnd({
    required this.type,
    this.isOptional = false,
    this.customValue,
  });

  /// "一" 基数常量
  static const ERCardinalityEnd one = ERCardinalityEnd(type: ERCardinalityType.one);

  /// "多" 基数常量（鸦脚）
  static const ERCardinalityEnd many = ERCardinalityEnd(type: ERCardinalityType.many);

  /// "零或一" 基数常量
  static const ERCardinalityEnd zeroOrOne = ERCardinalityEnd(
    type: ERCardinalityType.one,
    isOptional: true,
  );

  /// "零或多" 基数常量
  static const ERCardinalityEnd zeroOrMany = ERCardinalityEnd(
    type: ERCardinalityType.many,
    isOptional: true,
  );

  /// 创建带可选性的 "一" 基数
  const ERCardinalityEnd.oneOf({bool isOptional = false})
      : type = ERCardinalityType.one,
        isOptional = isOptional,
        customValue = null;

  /// 创建带可选性的 "多" 基数
  const ERCardinalityEnd.manyOf({bool isOptional = false})
      : type = ERCardinalityType.many,
        isOptional = isOptional,
        customValue = null;

  /// 创建自定义基数
  const ERCardinalityEnd.custom(int value, {bool isOptional = false})
      : type = ERCardinalityType.custom,
        isOptional = isOptional,
        customValue = value;

  /// 获取显示文本
  String get displayText {
    switch (type) {
      case ERCardinalityType.one:
        return '1';
      case ERCardinalityType.many:
        return 'N';
      case ERCardinalityType.custom:
        return customValue?.toString() ?? '?';
    }
  }

  /// 获取 UML 风格的显示文本
  String get umlText {
    final prefix = isOptional ? '0..' : '';
    switch (type) {
      case ERCardinalityType.one:
        return '${prefix}1';
      case ERCardinalityType.many:
        return '$prefix*';
      case ERCardinalityType.custom:
        return '$prefix${customValue ?? '?'}';
    }
  }

  /// 获取对应的边标记
  EdgeMarker toEdgeMarker({Color? color}) {
    switch (type) {
      case ERCardinalityType.one:
        return EdgeMarker.one(color: color);
      case ERCardinalityType.many:
        return EdgeMarker.many(color: color);
      case ERCardinalityType.custom:
        return EdgeMarker(
          type: EdgeMarkerType.custom,
          text: customValue?.toString() ?? '?',
          color: color,
        );
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'isOptional': isOptional,
      'customValue': customValue,
    };
  }

  /// 从 JSON 创建
  factory ERCardinalityEnd.fromJson(Map<String, dynamic> json) {
    return ERCardinalityEnd(
      type: ERCardinalityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ERCardinalityType.one,
      ),
      isOptional: json['isOptional'] as bool? ?? false,
      customValue: json['customValue'] as int?,
    );
  }

  @override
  String toString() => displayText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ERCardinalityEnd &&
        other.type == type &&
        other.isOptional == isOptional &&
        other.customValue == customValue;
  }

  @override
  int get hashCode => Object.hash(type, isOptional, customValue);
}

/// ER 关系边模型
///
/// 表示 ER 图中实体之间的关系连接
class ERRelationEdgeModel extends EdgeModel {
  /// 关系类型
  final ERRelationType relationType;

  /// 源端基数
  final ERCardinalityEnd sourceCardinality;

  /// 目标端基数
  final ERCardinalityEnd targetCardinality;

  /// 关系名称
  final String? relationName;

  /// 外键约束名称
  final String? foreignKeyName;

  /// 是否允许级联删除
  final bool cascadeDelete;

  /// 是否允许级联更新
  final bool cascadeUpdate;

  /// 关系描述/注释
  final String? description;

  /// 创建时间
  final DateTime _createdAt;

  /// 最后修改时间
  DateTime _modifiedAt;

  ERRelationEdgeModel({
    required super.id,
    required super.sourceAnchorId,
    required super.targetAnchorId,
    this.relationType = ERRelationType.nonIdentifying,
    this.sourceCardinality = ERCardinalityEnd.one,
    this.targetCardinality = ERCardinalityEnd.many,
    this.relationName,
    this.foreignKeyName,
    this.cascadeDelete = false,
    this.cascadeUpdate = false,
    this.description,
    super.label,
    super.isSelectable,
    super.data,
    super.controlPoints,
    EdgeStyle? style,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : _createdAt = createdAt ?? DateTime.now(),
        _modifiedAt = modifiedAt ?? DateTime.now(),
        super(
          type: 'er_relation',
          style: style ?? _getDefaultStyle(relationType),
          sourceMarker: sourceCardinality.toEdgeMarker(),
          targetMarker: targetCardinality.toEdgeMarker(),
        );

  /// 根据关系类型获取默认样式
  static EdgeStyle _getDefaultStyle(ERRelationType type) {
    switch (type) {
      case ERRelationType.identifying:
        return const EdgeStyle(
          lineType: EdgeLineType.solid,
          width: 2.0,
        );
      case ERRelationType.nonIdentifying:
        return const EdgeStyle(
          lineType: EdgeLineType.dashed,
          width: 1.5,
          dashConfig: DashConfig.dashed,
        );
      case ERRelationType.unspecified:
        return const EdgeStyle(
          lineType: EdgeLineType.solid,
          width: 1.5,
        );
    }
  }

  /// 获取创建时间
  @override
  DateTime get createdAt => _createdAt;

  /// 获取/设置修改时间
  @override
  DateTime get modifiedAt => _modifiedAt;
  @override
  set modifiedAt(DateTime value) => _modifiedAt = value;

  /// 获取整体基数类型
  ERCardinality get cardinality {
    if (sourceCardinality.type == ERCardinalityType.one &&
        targetCardinality.type == ERCardinalityType.one) {
      return ERCardinality.oneToOne;
    }
    if ((sourceCardinality.type == ERCardinalityType.one &&
            targetCardinality.type == ERCardinalityType.many) ||
        (sourceCardinality.type == ERCardinalityType.many &&
            targetCardinality.type == ERCardinalityType.one)) {
      return ERCardinality.oneToMany;
    }
    return ERCardinality.manyToMany;
  }

  /// 是否为标识关系
  bool get isIdentifying => relationType == ERRelationType.identifying;

  /// 是否为非标识关系
  bool get isNonIdentifying => relationType == ERRelationType.nonIdentifying;

  /// 是否为弱实体关系（标识关系的子实体为弱实体）
  bool get isWeakEntityRelation => isIdentifying;

  /// 获取源实体 ID
  String get sourceEntityId => sourceNodeId;

  /// 获取目标实体 ID
  String get targetEntityId => targetNodeId;

  /// 获取关系的显示标签
  String get displayLabel {
    if (relationName != null && relationName!.isNotEmpty) {
      return relationName!;
    }
    return '${sourceCardinality.displayText}:${targetCardinality.displayText}';
  }

  /// 获取完整的基数显示文本
  String get cardinalityDisplayText {
    return '${sourceCardinality.displayText} : ${targetCardinality.displayText}';
  }

  /// 获取 UML 风格的基数显示文本
  String get cardinalityUmlText {
    return '${sourceCardinality.umlText} .. ${targetCardinality.umlText}';
  }

  /// 获取样式（考虑关系类型）
  @override
  EdgeStyle getStyle() {
    return super.getStyle().copyWith(
          lineType: isIdentifying ? EdgeLineType.solid : EdgeLineType.dashed,
          dashConfig: isNonIdentifying ? DashConfig.dashed : null,
        );
  }

  /// 获取源端标记
  @override
  EdgeMarker? getSourceMarker() {
    return sourceCardinality.toEdgeMarker();
  }

  /// 获取目标端标记
  @override
  EdgeMarker? getTargetMarker() {
    return targetCardinality.toEdgeMarker();
  }

  /// 判断是否为自引用关系
  bool get isSelfReferencing => isSelfLoop;

  /// 验证关系是否有效
  bool validate() {
    // 检查源和目标锚点是否有效
    if (sourceAnchorId.isEmpty || targetAnchorId.isEmpty) {
      return false;
    }

    // 检查关系名称（可选）
    // 如果需要强制关系名称，可以在这里添加验证

    return true;
  }

  /// 创建反向关系
  @override
  ERRelationEdgeModel reversed() {
    return ERRelationEdgeModel(
      id: id,
      sourceAnchorId: targetAnchorId,
      targetAnchorId: sourceAnchorId,
      relationType: relationType,
      sourceCardinality: targetCardinality,
      targetCardinality: sourceCardinality,
      relationName: relationName,
      foreignKeyName: foreignKeyName,
      cascadeDelete: cascadeDelete,
      cascadeUpdate: cascadeUpdate,
      description: description,
      label: label,
      isSelectable: isSelectable,
      data: getData(),
      controlPoints: controlPoints.reversed.toList(),
      createdAt: _createdAt,
    );
  }

  /// 复制并修改属性
  ERRelationEdgeModel copyWithER({
    String? id,
    String? sourceAnchorId,
    String? targetAnchorId,
    ERRelationType? relationType,
    ERCardinalityEnd? sourceCardinality,
    ERCardinalityEnd? targetCardinality,
    String? relationName,
    String? foreignKeyName,
    bool? cascadeDelete,
    bool? cascadeUpdate,
    String? description,
    String? label,
    bool? isSelectable,
    dynamic data,
    EdgeStyle? style,
    List<Offset>? controlPoints,
  }) {
    return ERRelationEdgeModel(
      id: id ?? this.id,
      sourceAnchorId: sourceAnchorId ?? this.sourceAnchorId,
      targetAnchorId: targetAnchorId ?? this.targetAnchorId,
      relationType: relationType ?? this.relationType,
      sourceCardinality: sourceCardinality ?? this.sourceCardinality,
      targetCardinality: targetCardinality ?? this.targetCardinality,
      relationName: relationName ?? this.relationName,
      foreignKeyName: foreignKeyName ?? this.foreignKeyName,
      cascadeDelete: cascadeDelete ?? this.cascadeDelete,
      cascadeUpdate: cascadeUpdate ?? this.cascadeUpdate,
      description: description ?? this.description,
      label: label ?? this.label,
      isSelectable: isSelectable ?? this.isSelectable,
      data: data ?? getData(),
      style: style ?? super.getStyle(),
      controlPoints: controlPoints ?? this.controlPoints,
      createdAt: _createdAt,
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'relationType': relationType.name,
      'sourceCardinality': sourceCardinality.toJson(),
      'targetCardinality': targetCardinality.toJson(),
      'relationName': relationName,
      'foreignKeyName': foreignKeyName,
      'cascadeDelete': cascadeDelete,
      'cascadeUpdate': cascadeUpdate,
      'description': description,
    };
  }

  /// 从 JSON 创建
  factory ERRelationEdgeModel.fromJson(Map<String, dynamic> json) {
    return ERRelationEdgeModel(
      id: json['id'] as String,
      sourceAnchorId: json['sourceAnchorId'] as String,
      targetAnchorId: json['targetAnchorId'] as String,
      relationType: ERRelationType.values.firstWhere(
        (e) => e.name == json['relationType'],
        orElse: () => ERRelationType.nonIdentifying,
      ),
      sourceCardinality: json['sourceCardinality'] != null
          ? ERCardinalityEnd.fromJson(
              json['sourceCardinality'] as Map<String, dynamic>)
          : ERCardinalityEnd.one,
      targetCardinality: json['targetCardinality'] != null
          ? ERCardinalityEnd.fromJson(
              json['targetCardinality'] as Map<String, dynamic>)
          : ERCardinalityEnd.many,
      relationName: json['relationName'] as String?,
      foreignKeyName: json['foreignKeyName'] as String?,
      cascadeDelete: json['cascadeDelete'] as bool? ?? false,
      cascadeUpdate: json['cascadeUpdate'] as bool? ?? false,
      description: json['description'] as String?,
      label: json['label'] as String?,
      isSelectable: json['isSelectable'] as bool? ?? true,
      data: json['data'],
      style: json['style'] != null
          ? EdgeStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      controlPoints: (json['controlPoints'] as List<dynamic>?)
              ?.map((p) => Offset(
                    (p as Map<String, dynamic>)['x'] as double,
                    p['y'] as double,
                  ))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'ERRelationEdgeModel(id: $id, $cardinalityDisplayText, type: $relationType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ERRelationEdgeModel &&
        other.id == id &&
        other.sourceAnchorId == sourceAnchorId &&
        other.targetAnchorId == targetAnchorId &&
        other.relationType == relationType &&
        other.sourceCardinality == sourceCardinality &&
        other.targetCardinality == targetCardinality;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sourceAnchorId,
        targetAnchorId,
        relationType,
        sourceCardinality,
        targetCardinality,
      );
}

/// ER 关系边构建器
///
/// 提供流畅的 API 来创建 ER 关系边
class ERRelationEdgeBuilder {
  String? _id;
  String? _sourceAnchorId;
  String? _targetAnchorId;
  ERRelationType _relationType = ERRelationType.nonIdentifying;
  ERCardinalityEnd _sourceCardinality = ERCardinalityEnd.one;
  ERCardinalityEnd _targetCardinality = ERCardinalityEnd.many;
  String? _relationName;
  String? _foreignKeyName;
  bool _cascadeDelete = false;
  bool _cascadeUpdate = false;
  String? _description;
  String? _label;
  List<Offset> _controlPoints = [];

  ERRelationEdgeBuilder();

  /// 设置 ID
  ERRelationEdgeBuilder id(String id) {
    _id = id;
    return this;
  }

  /// 设置源锚点
  ERRelationEdgeBuilder source(String anchorId) {
    _sourceAnchorId = anchorId;
    return this;
  }

  /// 设置目标锚点
  ERRelationEdgeBuilder target(String anchorId) {
    _targetAnchorId = anchorId;
    return this;
  }

  /// 设置关系类型
  ERRelationEdgeBuilder relationType(ERRelationType type) {
    _relationType = type;
    return this;
  }

  /// 设置为标识关系
  ERRelationEdgeBuilder identifying() {
    _relationType = ERRelationType.identifying;
    return this;
  }

  /// 设置为非标识关系
  ERRelationEdgeBuilder nonIdentifying() {
    _relationType = ERRelationType.nonIdentifying;
    return this;
  }

  /// 设置源端基数
  ERRelationEdgeBuilder sourceCardinality(ERCardinalityEnd cardinality) {
    _sourceCardinality = cardinality;
    return this;
  }

  /// 设置目标端基数
  ERRelationEdgeBuilder targetCardinality(ERCardinalityEnd cardinality) {
    _targetCardinality = cardinality;
    return this;
  }

  /// 设置为一对一关系
  ERRelationEdgeBuilder oneToOne() {
    _sourceCardinality = ERCardinalityEnd.one;
    _targetCardinality = ERCardinalityEnd.one;
    return this;
  }

  /// 设置为一对多关系
  ERRelationEdgeBuilder oneToMany() {
    _sourceCardinality = ERCardinalityEnd.one;
    _targetCardinality = ERCardinalityEnd.many;
    return this;
  }

  /// 设置为多对多关系
  ERRelationEdgeBuilder manyToMany() {
    _sourceCardinality = ERCardinalityEnd.many;
    _targetCardinality = ERCardinalityEnd.many;
    return this;
  }

  /// 设置关系名称
  ERRelationEdgeBuilder name(String name) {
    _relationName = name;
    return this;
  }

  /// 设置外键名称
  ERRelationEdgeBuilder foreignKey(String name) {
    _foreignKeyName = name;
    return this;
  }

  /// 启用级联删除
  ERRelationEdgeBuilder cascadeOnDelete() {
    _cascadeDelete = true;
    return this;
  }

  /// 启用级联更新
  ERRelationEdgeBuilder cascadeOnUpdate() {
    _cascadeUpdate = true;
    return this;
  }

  /// 设置描述
  ERRelationEdgeBuilder description(String desc) {
    _description = desc;
    return this;
  }

  /// 设置标签
  ERRelationEdgeBuilder label(String label) {
    _label = label;
    return this;
  }

  /// 设置控制点
  ERRelationEdgeBuilder controlPoints(List<Offset> points) {
    _controlPoints = points;
    return this;
  }

  /// 构建 ER 关系边
  ERRelationEdgeModel build() {
    if (_id == null || _sourceAnchorId == null || _targetAnchorId == null) {
      throw StateError(
          'ERRelationEdgeModel requires id, sourceAnchorId, and targetAnchorId');
    }

    return ERRelationEdgeModel(
      id: _id!,
      sourceAnchorId: _sourceAnchorId!,
      targetAnchorId: _targetAnchorId!,
      relationType: _relationType,
      sourceCardinality: _sourceCardinality,
      targetCardinality: _targetCardinality,
      relationName: _relationName,
      foreignKeyName: _foreignKeyName,
      cascadeDelete: _cascadeDelete,
      cascadeUpdate: _cascadeUpdate,
      description: _description,
      label: _label,
      controlPoints: _controlPoints,
    );
  }
}
