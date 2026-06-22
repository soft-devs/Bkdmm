import 'package:json_annotation/json_annotation.dart';

part 'entity.g.dart';

/// 数据表模型
@JsonSerializable()
class Entity {
  /// 表唯一标识
  final String id;

  /// 表代码（英文）
  final String title;

  /// 表中文名
  final String chnname;

  /// 表备注
  final String? remark;

  /// 字段列表
  final List<Field> fields;

  /// 索引列表
  final List<Index> indexes;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  Entity({
    required this.id,
    required this.title,
    required this.chnname,
    this.remark,
    this.fields = const [],
    this.indexes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);
  Map<String, dynamic> toJson() => _$EntityToJson(this);

  Entity copyWith({
    String? id,
    String? title,
    String? chnname,
    String? remark,
    List<Field>? fields,
    List<Index>? indexes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Entity(
      id: id ?? this.id,
      title: title ?? this.title,
      chnname: chnname ?? this.chnname,
      remark: remark ?? this.remark,
      fields: fields ?? this.fields,
      indexes: indexes ?? this.indexes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取主键字段
  List<Field> get primaryKeys => fields.where((f) => f.pk).toList();
}

/// 字段模型
@JsonSerializable()
class Field {
  /// 字段唯一标识
  final String id;

  /// 字段名
  final String name;

  /// 数据类型（抽象类型code）
  final String type;

  /// 字段中文名
  final String chnname;

  /// 字段备注
  final String? remark;

  /// 是否主键
  final bool pk;

  /// 是否非空
  final bool notNull;

  /// 是否自增
  final bool autoIncrement;

  /// 默认值
  final String? defaultValue;

  /// 长度
  final int? length;

  /// 小数位数
  final int? decimal;

  Field({
    required this.id,
    required this.name,
    required this.type,
    required this.chnname,
    this.remark,
    this.pk = false,
    this.notNull = false,
    this.autoIncrement = false,
    this.defaultValue,
    this.length,
    this.decimal,
  });

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);
  Map<String, dynamic> toJson() => _$FieldToJson(this);

  Field copyWith({
    String? id,
    String? name,
    String? type,
    String? chnname,
    String? remark,
    bool? pk,
    bool? notNull,
    bool? autoIncrement,
    String? defaultValue,
    int? length,
    int? decimal,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      chnname: chnname ?? this.chnname,
      remark: remark ?? this.remark,
      pk: pk ?? this.pk,
      notNull: notNull ?? this.notNull,
      autoIncrement: autoIncrement ?? this.autoIncrement,
      defaultValue: defaultValue ?? this.defaultValue,
      length: length ?? this.length,
      decimal: decimal ?? this.decimal,
    );
  }
}

/// 索引模型
@JsonSerializable()
class Index {
  /// 索引唯一标识
  final String id;

  /// 索引名称
  final String name;

  /// 索引字段列表
  final List<String> fields;

  /// 索引类型
  final IndexType type;

  /// 索引备注
  final String? remark;

  Index({
    required this.id,
    required this.name,
    required this.fields,
    this.type = IndexType.normal,
    this.remark,
  });

  factory Index.fromJson(Map<String, dynamic> json) => _$IndexFromJson(json);
  Map<String, dynamic> toJson() => _$IndexToJson(this);
}

/// 索引类型枚举
enum IndexType {
  @JsonValue('NORMAL')
  normal,
  @JsonValue('UNIQUE')
  unique,
  @JsonValue('FULLTEXT')
  fulltext,
}