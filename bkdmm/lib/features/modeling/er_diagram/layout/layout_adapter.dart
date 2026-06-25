import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:graphview/graphview.dart';
import '../core/field_anchor_registry.dart';
import '../renderers/er_edge_renderer.dart';

/// 无操作布局算法（保持节点现有位置）
class NoOpLayoutAlgorithm extends Algorithm {
  @override
  EdgeRenderer? renderer;

  NoOpLayoutAlgorithm({FieldAnchorRegistry? anchorRegistry, bool isDarkMode = false}) {
    // 使用自定义边渲染器
    if (anchorRegistry != null) {
      renderer = ERRelationEdgeRenderer(
        anchorRegistry: anchorRegistry,
        isDarkMode: isDarkMode,
      );
    } else {
      // 使用默认的箭头渲染器
      renderer = ArrowEdgeRenderer(noArrow: true);
    }
  }

  @override
  void init(Graph? graph) {
    // 不需要初始化
  }

  @override
  void setDimensions(double width, double height) {
    // 不需要设置尺寸
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    // 不进行任何布局计算，保持节点现有位置
    if (graph == null) return const Size(2000, 2000);

    // 调试：打印所有节点位置
    debugPrint('NoOpLayoutAlgorithm.run() called with shiftX=$shiftX, shiftY=$shiftY');
    for (final node in graph.nodes) {
      debugPrint('  - node: key=${node.key?.value}, x=${node.x}, y=${node.y}, width=${node.width}, height=${node.height}');
    }

    // 计算图的大小
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      if (node.x < minX) minX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.x + node.width > maxX) maxX = node.x + node.width;
      if (node.y + node.height > maxY) maxY = node.y + node.height;
    }

    if (minX == double.infinity) {
      debugPrint('NoOpLayoutAlgorithm: returning default size');
      return const Size(2000, 2000);
    }

    final width = maxX - minX + 100;  // 添加一些边距
    final height = maxY - minY + 100;
    debugPrint('NoOpLayoutAlgorithm: calculated size = ${width}x$height');

    return Size(width, height);
  }
}

/// graphview 布局算法适配器
///
/// 将 graphview 的布局算法适配到统一的接口，
/// 支持多种布局策略的切换
class GraphViewLayoutAdapter {
  /// 当前布局算法
  Algorithm? _algorithm;

  /// 当前布局配置
  LayoutConfig _config = const HierarchicalLayoutConfig();

  /// 字段锚点注册表（用于边渲染）
  FieldAnchorRegistry? anchorRegistry;

  /// 是否暗色模式
  bool isDarkMode = false;

  /// 是否使用固定位置布局（不自动布局）
  bool useFixedLayout = true;

  /// 获取当前算法
  Algorithm? get algorithm {
    // 如果使用固定布局，返回 NoOp 算法
    if (useFixedLayout && anchorRegistry != null) {
      return NoOpLayoutAlgorithm(
        anchorRegistry: anchorRegistry!,
        isDarkMode: isDarkMode,
      );
    }
    return _algorithm;
  }

  /// 获取当前配置
  LayoutConfig get config => _config;

  /// 设置布局配置
  void setConfig(LayoutConfig config) {
    _config = config;
    useFixedLayout = false; // 用户明确设置了布局配置，启用自动布局
    _updateAlgorithm();
  }

  /// 使用固定位置布局（保持节点现有位置）
  void useFixedPositionLayout() {
    useFixedLayout = true;
  }

  /// 更新布局算法
  void _updateAlgorithm() {
    if (_config is HierarchicalLayoutConfig) {
      _algorithm = _createSugiyamaAlgorithm(_config as HierarchicalLayoutConfig);
    } else if (_config is ForceDirectedLayoutConfig) {
      _algorithm = _createFruchtermanReingoldAlgorithm(
          _config as ForceDirectedLayoutConfig);
    } else if (_config is CircularLayoutConfig) {
      _algorithm = _createCircleLayoutAlgorithm(_config as CircularLayoutConfig);
    }
  }

  /// 创建 Sugiyama 层次布局算法
  Algorithm _createSugiyamaAlgorithm(HierarchicalLayoutConfig config) {
    final sugiyamaConfig = SugiyamaConfiguration()
      ..nodeSeparation = config.nodeSpacing.toInt()
      ..levelSeparation = config.rankSpacing.toInt()
      ..orientation = _mapOrientation(config.direction)
      ..iterations = config.maxIterations;

    final algorithm = SugiyamaAlgorithm(sugiyamaConfig);

    // 使用自定义边渲染器
    if (anchorRegistry != null) {
      algorithm.renderer = ERRelationEdgeRenderer(
        anchorRegistry: anchorRegistry!,
        isDarkMode: isDarkMode,
      );
    }

    return algorithm;
  }

  /// 创建 Fruchterman-Reingold 力导向布局算法
  Algorithm _createFruchtermanReingoldAlgorithm(ForceDirectedLayoutConfig config) {
    return FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(
        iterations: config.maxIterations,
      ),
    );
  }

  /// 创建圆形布局算法
  Algorithm _createCircleLayoutAlgorithm(CircularLayoutConfig config) {
    return CircleLayoutAlgorithm(
      CircleLayoutConfiguration(radius: config.radius),
      null,
    );
  }

  /// 映射布局方向
  int _mapOrientation(LayoutDirection direction) {
    switch (direction) {
      case LayoutDirection.topToBottom:
        return SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
      case LayoutDirection.bottomToTop:
        return SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;
      case LayoutDirection.leftToRight:
        return SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
      case LayoutDirection.rightToLeft:
        return SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;
    }
  }

  /// 运行布局
  void runLayout(Graph graph) {
    if (_algorithm == null) return;

    // 默认居中布局
    const centerX = 100000.0;
    const centerY = 100000.0;
    _algorithm!.run(graph, centerX, centerY);
  }

  /// 获取布局后的节点位置
  Map<String, Offset> getNodePositions(Graph graph) {
    final positions = <String, Offset>{};

    for (final node in graph.nodes) {
      final nodeId = node.key?.value.toString() ?? '';
      positions[nodeId] = Offset(node.x, node.y);
    }

    return positions;
  }
}

/// 布局配置基类
abstract class LayoutConfig {
  /// 节点间距
  final double nodeSpacing;

  /// 层级间距
  final double rankSpacing;

  const LayoutConfig({
    this.nodeSpacing = 50.0,
    this.rankSpacing = 100.0,
  });
}

/// 层次布局配置
class HierarchicalLayoutConfig extends LayoutConfig {
  /// 布局方向
  final LayoutDirection direction;

  /// 是否优化边交叉
  final bool optimizeCrossings;

  /// 最大迭代次数
  final int maxIterations;

  const HierarchicalLayoutConfig({
    super.nodeSpacing = 60,
    super.rankSpacing = 120,
    this.direction = LayoutDirection.topToBottom,
    this.optimizeCrossings = true,
    this.maxIterations = 24,
  });
}

/// 力导向布局配置
class ForceDirectedLayoutConfig extends LayoutConfig {
  /// 理想边长度
  final double idealEdgeLength;

  /// 弹簧强度
  final double springStrength;

  /// 排斥强度
  final double repulsionStrength;

  /// 重力强度
  final double gravityStrength;

  /// 最大迭代次数
  final int maxIterations;

  const ForceDirectedLayoutConfig({
    this.idealEdgeLength = 100.0,
    this.springStrength = 0.1,
    this.repulsionStrength = 500.0,
    this.gravityStrength = 0.01,
    this.maxIterations = 300,
  });
}

/// 圆形布局配置
class CircularLayoutConfig extends LayoutConfig {
  /// 圆形半径
  final double radius;

  const CircularLayoutConfig({
    this.radius = 200.0,
  });
}

/// 布局方向
enum LayoutDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
}