import 'dart:ui';
import 'diagram_node.dart';

/// 图表边抽象接口
///
/// 所有图表类型的边都需要实现此接口
/// 提供通用的连接、样式、标记属性
abstract class DiagramEdge {
  /// 边唯一标识
  String get id;

  /// 源锚点 ID (格式: nodeId:anchorKey)
  String get sourceAnchorId;

  /// 目标锚点 ID
  String get targetAnchorId;

  /// 边类型标识
  String get type;

  /// 边标签
  String? get label;

  /// 是否可选
  bool get isSelectable;

  /// 获取源节点 ID
  String get sourceNodeId {
    return sourceAnchorId.split(':').first;
  }

  /// 获取目标节点 ID
  String get targetNodeId {
    return targetAnchorId.split(':').first;
  }

  /// 获取自定义数据
  dynamic getData();

  /// 获取边样式
  EdgeStyle getStyle();

  /// 获取源端标记（如 ER 图的 1, N, M）
  EdgeMarker? getSourceMarker();

  /// 获取目标端标记
  EdgeMarker? getTargetMarker();
}

/// 边样式配置
class EdgeStyle {
  /// 线条颜色
  final Color color;

  /// 线条宽度
  final double width;

  /// 线条类型
  final EdgeLineType lineType;

  /// 线条形状
  final EdgeShape shape;

  /// 是否显示箭头
  final bool showArrow;

  /// 箭头大小
  final double arrowSize;

  /// 曲线弯曲程度（仅对 curved 生效）
  final double curveFactor;

  /// 虚线配置
  final DashConfig? dashConfig;

  const EdgeStyle({
    this.color = const Color(0xFF666666),
    this.width = 2.0,
    this.lineType = EdgeLineType.solid,
    this.shape = EdgeShape.straight,
    this.showArrow = false,
    this.arrowSize = 10.0,
    this.curveFactor = 0.3,
    this.dashConfig,
  });

  EdgeStyle copyWith({
    Color? color,
    double? width,
    EdgeLineType? lineType,
    EdgeShape? shape,
    bool? showArrow,
    double? arrowSize,
    double? curveFactor,
    DashConfig? dashConfig,
  }) {
    return EdgeStyle(
      color: color ?? this.color,
      width: width ?? this.width,
      lineType: lineType ?? this.lineType,
      shape: shape ?? this.shape,
      showArrow: showArrow ?? this.showArrow,
      arrowSize: arrowSize ?? this.arrowSize,
      curveFactor: curveFactor ?? this.curveFactor,
      dashConfig: dashConfig ?? this.dashConfig,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'width': width,
      'lineType': lineType.name,
      'shape': shape.name,
      'showArrow': showArrow,
      'arrowSize': arrowSize,
      'curveFactor': curveFactor,
      'dashConfig': dashConfig?.pattern,
    };
  }

  /// Create from JSON map
  factory EdgeStyle.fromJson(Map<String, dynamic> json) {
    return EdgeStyle(
      color: Color(json['color'] as int? ?? 0xFF666666),
      width: (json['width'] as num?)?.toDouble() ?? 2.0,
      lineType: EdgeLineType.values.firstWhere(
        (e) => e.name == json['lineType'],
        orElse: () => EdgeLineType.solid,
      ),
      shape: EdgeShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => EdgeShape.straight,
      ),
      showArrow: json['showArrow'] as bool? ?? false,
      arrowSize: (json['arrowSize'] as num?)?.toDouble() ?? 10.0,
      curveFactor: (json['curveFactor'] as num?)?.toDouble() ?? 0.3,
      dashConfig: json['dashConfig'] != null
          ? DashConfig(
              pattern: (json['dashConfig'] as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList(),
            )
          : null,
    );
  }
}

/// 线条类型
enum EdgeLineType {
  /// 实线
  solid,

  /// 虚线
  dashed,

  /// 点线
  dotted,
}

/// 线条形状
enum EdgeShape {
  /// 直线
  straight,

  /// 曲线
  curved,

  /// 正交线（折线）
  orthogonal,

  /// 贝塞尔曲线
  bezier,
}

/// 虚线配置
class DashConfig {
  final List<double> pattern;
  final double startOffset;

  const DashConfig({
    required this.pattern,
    this.startOffset = 0.0,
  });

  /// 标准虚线
  static const DashConfig dashed = DashConfig(pattern: [10.0, 5.0]);

  /// 点线
  static const DashConfig dotted = DashConfig(pattern: [3.0, 3.0]);

  /// 点划线
  static const DashConfig dashDot = DashConfig(pattern: [10.0, 3.0, 3.0, 3.0]);
}

/// 边端点标记
///
/// 用于表示关系的基数（如 ER 图的 1:1, 1:N, N:M）
class EdgeMarker {
  /// 标记类型
  final EdgeMarkerType type;

  /// 标记文本（如 "1", "N", "M"）
  final String? text;

  /// 标记颜色
  final Color? color;

  /// 标记大小
  final double size;

  const EdgeMarker({
    required this.type,
    this.text,
    this.color,
    this.size = 12.0,
  });

  /// 创建 "1" 标记
  factory EdgeMarker.one({Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.one,
      text: '1',
      color: color,
    );
  }

  /// 创建 "N" 标记（鸦脚）
  factory EdgeMarker.many({Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.many,
      text: 'N',
      color: color,
    );
  }

  /// 创建 "M" 标记（多对多）
  factory EdgeMarker.multiple({Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.multiple,
      text: 'M',
      color: color,
    );
  }

  /// 创建箭头标记
  factory EdgeMarker.arrow({double size = 10.0, Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.arrow,
      color: color,
      size: size,
    );
  }

  /// 创建圆点标记
  factory EdgeMarker.circle({double size = 8.0, Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.circle,
      color: color,
      size: size,
    );
  }

  /// 创建菱形标记（用于聚合/组合）
  factory EdgeMarker.diamond({double size = 10.0, Color? color}) {
    return EdgeMarker(
      type: EdgeMarkerType.diamond,
      color: color,
      size: size,
    );
  }
}

/// 边端点标记类型
enum EdgeMarkerType {
  /// 无标记
  none,

  /// 单线标记（表示 "一"）
  one,

  /// 鸦脚标记（表示 "多"）
  many,

  /// 多对多标记
  multiple,

  /// 箭头
  arrow,

  /// 圆点
  circle,

  /// 菱形
  diamond,

  /// 自定义文本
  custom,
}

/// 边状态
class EdgeState {
  /// 是否选中
  final bool isSelected;

  /// 是否高亮
  final bool isHighlighted;

  /// 是否悬停
  final bool isHovered;

  /// 是否正在创建中
  final bool isCreating;

  const EdgeState({
    this.isSelected = false,
    this.isHighlighted = false,
    this.isHovered = false,
    this.isCreating = false,
  });

  EdgeState copyWith({
    bool? isSelected,
    bool? isHighlighted,
    bool? isHovered,
    bool? isCreating,
  }) {
    return EdgeState(
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isHovered: isHovered ?? this.isHovered,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

/// 边连接约束
///
/// 定义哪些节点类型可以连接
class EdgeConnectionRule {
  /// 允许的源节点类型
  final List<String>? allowedSourceTypes;

  /// 允许的目标节点类型
  final List<String>? allowedTargetTypes;

  /// 是否允许自连接
  final bool allowSelfConnection;

  /// 是否允许重复连接
  final bool allowDuplicate;

  /// 自定义验证函数
  final bool Function(DiagramNode source, DiagramNode target)? customValidator;

  const EdgeConnectionRule({
    this.allowedSourceTypes,
    this.allowedTargetTypes,
    this.allowSelfConnection = false,
    this.allowDuplicate = false,
    this.customValidator,
  });

  /// 验证连接是否有效
  bool validate(DiagramNode source, DiagramNode target) {
    // 检查自连接
    if (!allowSelfConnection && source.id == target.id) {
      return false;
    }

    // 检查源节点类型
    if (allowedSourceTypes != null &&
        !allowedSourceTypes!.contains(source.type)) {
      return false;
    }

    // 检查目标节点类型
    if (allowedTargetTypes != null &&
        !allowedTargetTypes!.contains(target.type)) {
      return false;
    }

    // 执行自定义验证
    if (customValidator != null) {
      return customValidator!(source, target);
    }

    return true;
  }
}