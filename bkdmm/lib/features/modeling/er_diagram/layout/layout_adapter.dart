import 'dart:ui';
import 'package:graphview/graphview.dart';

/// graphview 布局算法适配器
///
/// 将 graphview 的布局算法适配到统一的接口，
/// 支持多种布局策略的切换
class GraphViewLayoutAdapter {
  /// 当前布局算法
  Algorithm? _algorithm;

  /// 当前布局配置
  LayoutConfig _config = const HierarchicalLayoutConfig();

  /// 获取当前算法
  Algorithm? get algorithm => _algorithm;

  /// 获取当前配置
  LayoutConfig get config => _config;

  /// 设置布局配置
  void setConfig(LayoutConfig config) {
    _config = config;
    _updateAlgorithm();
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

    return SugiyamaAlgorithm(sugiyamaConfig);
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