import 'package:graphview/graphview.dart';
import '../../../shared/models/models.dart';
import 'field_anchor_registry.dart';

/// ER 图关系边
///
/// 扩展 graphview 的 Edge 类，添加 ER 图特定的属性：
/// - 字段级连接信息
/// - 关系类型 (1:1, 1:N, N:M)
/// - 关系标记
class ERGraphEdge extends Edge {
  /// 源字段索引（字段级连线时使用）
  final int? sourceFieldIndex;

  /// 目标字段索引（字段级连线时使用）
  final int? targetFieldIndex;

  /// 关系类型：'1:1', '1:N', 'N:1', 'N:M'
  final String relationType;

  /// 关系名称/标签
  final String? label;

  /// 关联的 GraphEdge 数据（用于持久化）
  final GraphEdge? graphEdge;

  ERGraphEdge({
    required Node source,
    required Node destination,
    this.sourceFieldIndex,
    this.targetFieldIndex,
    this.relationType = '1:N',
    this.label,
    this.graphEdge,
    Paint? paint,
  }) : super(source, destination, paint: paint);

  /// 从 GraphEdge 创建 ERGraphEdge
  factory ERGraphEdge.fromGraphEdge({
    required Node sourceNode,
    required Node targetNode,
    required GraphEdge graphEdge,
  }) {
    return ERGraphEdge(
      source: sourceNode,
      destination: targetNode,
      sourceFieldIndex: graphEdge.sourceField != null
          ? _parseFieldIndex(graphEdge.sourceField)
          : null,
      targetFieldIndex: graphEdge.targetField != null
          ? _parseFieldIndex(graphEdge.targetField)
          : null,
      relationType: graphEdge.relationType ?? '1:N',
      label: graphEdge.label,
      graphEdge: graphEdge,
    );
  }

  /// 解析字段索引
  static int? _parseFieldIndex(String? fieldName) {
    if (fieldName == null) return null;
    // 如果 fieldName 是索引数字，直接解析
    final index = int.tryParse(fieldName);
    if (index != null) return index;
    // 否则返回 null（需要通过字段名查找索引）
    return null;
  }

  /// 获取源端关系标记
  String? get sourceMarker {
    final parts = relationType.split(':');
    if (parts.length != 2) return null;
    return parts[0]; // '1', 'N', 'M'
  }

  /// 获取目标端关系标记
  String? get targetMarker {
    final parts = relationType.split(':');
    if (parts.length != 2) return null;
    return parts[1]; // '1', 'N', 'M'
  }

  /// 是否为字段级连线
  bool get isFieldConnection => sourceFieldIndex != null || targetFieldIndex != null;

  /// 获取源锚点 ID
  String get sourceAnchorId {
    final nodeId = source.key?.value.toString() ?? '';
    if (sourceFieldIndex != null) {
      return '$nodeId:field:$sourceFieldIndex:left';
    }
    return '$nodeId:right';
  }

  /// 获取目标锚点 ID
  String get targetAnchorId {
    final nodeId = destination.key?.value.toString() ?? '';
    if (targetFieldIndex != null) {
      return '$nodeId:field:$targetFieldIndex:right';
    }
    return '$nodeId:left';
  }

  /// 复制并更新关系类型
  ERGraphEdge copyWith({
    String? relationType,
    String? label,
    int? sourceFieldIndex,
    int? targetFieldIndex,
  }) {
    return ERGraphEdge(
      source: source,
      destination: destination,
      sourceFieldIndex: sourceFieldIndex ?? this.sourceFieldIndex,
      targetFieldIndex: targetFieldIndex ?? this.targetFieldIndex,
      relationType: relationType ?? this.relationType,
      label: label ?? this.label,
      graphEdge: graphEdge,
      paint: paint,
    );
  }

  @override
  String toString() {
    return 'ERGraphEdge(${source.key} -> ${destination.key}, '
        'relation: $relationType, '
        'sourceField: $sourceFieldIndex, '
        'targetField: $targetFieldIndex)';
  }
}

/// 关系标记类型
enum RelationMarkerType {
  one,    // 1
  many,   // N
  multiple, // M
}

/// 关系标记工具类
class RelationMarkerHelper {
  /// 从字符串解析关系标记类型
  static RelationMarkerType? parseMarker(String? marker) {
    if (marker == null) return null;

    switch (marker.toUpperCase()) {
      case '1':
        return RelationMarkerType.one;
      case 'N':
        return RelationMarkerType.many;
      case 'M':
        return RelationMarkerType.multiple;
      default:
        return null;
    }
  }

  /// 判断是否需要绘制鸦脚
  static bool shouldDrawCrowsFoot(RelationMarkerType? type) {
    return type == RelationMarkerType.many || type == RelationMarkerType.multiple;
  }

  /// 获取标记显示文本
  static String? getMarkerText(RelationMarkerType? type) {
    if (type == null) return null;

    switch (type) {
      case RelationMarkerType.one:
        return '1';
      case RelationMarkerType.many:
        return 'N';
      case RelationMarkerType.multiple:
        return 'M';
    }
  }
}