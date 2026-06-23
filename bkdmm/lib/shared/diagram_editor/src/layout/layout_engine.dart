import 'dart:ui';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_state.dart';

/// 布局引擎抽象接口
///
/// 定义通用的布局计算接口，支持多种布局算法
/// 可以对接 graphview 或自定义实现
abstract class LayoutEngine {
  /// 布局引擎名称
  String get name;

  /// 布置节点位置
  ///
  /// 输入：当前图表状态
  /// 输出：节点 ID -> 新位置的映射
  Map<String, Offset> layout(DiagramState state);

  /// 异步布局（用于复杂算法）
  Future<Map<String, Offset>> layoutAsync(DiagramState state);

  /// 设置布局参数
  void setConfig(LayoutConfig config);

  /// 获取当前配置
  LayoutConfig getConfig();
}

/// 布局配置基类
abstract class LayoutConfig {
  /// 节点间距
  final double nodeSpacing;

  /// 层级间距（用于层次布局）
  final double rankSpacing;

  /// 边距
  final double margin;

  const LayoutConfig({
    this.nodeSpacing = 50.0,
    this.rankSpacing = 100.0,
    this.margin = 50.0,
  });
}

/// 布局类型
enum LayoutType {
  /// 无布局（手动排列）
  none,

  /// 层次布局（适合 ER 图、流程图）
  hierarchical,

  /// 树形布局（适合思维导图、组织架构）
  tree,

  /// 力导向布局（适合网络拓扑）
  forceDirected,

  /// 圆形布局（适合环形关系）
  circular,

  /// 网格布局
  grid,

  /// 随机布局
  random,
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
    super.nodeSpacing,
    super.rankSpacing,
    super.margin,
    this.direction = LayoutDirection.topToBottom,
    this.optimizeCrossings = true,
    this.maxIterations = 24,
  });
}

/// 布局方向
enum LayoutDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
}

/// 树形布局配置
class TreeLayoutConfig extends LayoutConfig {
  /// 树的方向
  final LayoutDirection direction;

  /// 是否启用紧凑模式
  final bool compact;

  /// 根节点 ID
  final String? rootNodeId;

  const TreeLayoutConfig({
    super.nodeSpacing,
    super.rankSpacing,
    super.margin,
    this.direction = LayoutDirection.topToBottom,
    this.compact = false,
    this.rootNodeId,
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

  /// 重力强度（防止节点飘离中心）
  final double gravityStrength;

  /// 最大迭代次数
  final int maxIterations;

  /// 每次迭代的时间步长
  final double timeStep;

  const ForceDirectedLayoutConfig({
    super.nodeSpacing,
    super.margin,
    this.idealEdgeLength = 100.0,
    this.springStrength = 0.1,
    this.repulsionStrength = 500.0,
    this.gravityStrength = 0.01,
    this.maxIterations = 300,
    this.timeStep = 0.1,
  });
}

/// 圆形布局配置
class CircularLayoutConfig extends LayoutConfig {
  /// 圆形半径
  final double radius;

  /// 是否按顺序排列（否则按角度均匀分布）
  final bool ordered;

  /// 排序依据（如节点 ID、连接数等）
  final CircularSortBy sortBy;

  const CircularLayoutConfig({
    super.margin,
    this.radius = 200.0,
    this.ordered = false,
    this.sortBy = CircularSortBy.none,
  });
}

/// 圆形布局排序依据
enum CircularSortBy {
  none,
  nodeId,
  title,
  connectionCount,
}

/// 网格布局配置
class GridLayoutConfig extends LayoutConfig {
  /// 列数
  final int columns;

  /// 行数
  final int rows;

  /// 是否自动计算行列
  final bool autoSize;

  /// 填充方向
  final GridFillDirection fillDirection;

  const GridLayoutConfig({
    super.nodeSpacing,
    super.margin,
    this.columns = 4,
    this.rows = 0,
    this.autoSize = true,
    this.fillDirection = GridFillDirection.rowFirst,
  });
}

/// 网格填充方向
enum GridFillDirection {
  rowFirst,
  columnFirst,
}

/// 布局计算辅助类
class LayoutHelper {
  /// 计算节点的连接数
  static int getConnectionCount(DiagramState state, String nodeId) {
    return state.edges.values.where((e) =>
      e.sourceNodeId == nodeId || e.targetNodeId == nodeId
    ).length;
  }

  /// 获取节点的入边
  static List<DiagramEdge> getIncomingEdges(DiagramState state, String nodeId) {
    return state.edges.values
        .where((e) => e.targetNodeId == nodeId)
        .toList();
  }

  /// 获取节点的出边
  static List<DiagramEdge> getOutgoingEdges(DiagramState state, String nodeId) {
    return state.edges.values
        .where((e) => e.sourceNodeId == nodeId)
        .toList();
  }

  /// 找到根节点（无入边的节点）
  static List<String> findRootNodes(DiagramState state) {
    final nodesWithIncoming = state.edges.values
        .map((e) => e.targetNodeId)
        .toSet();

    return state.nodes.keys
        .where((id) => !nodesWithIncoming.contains(id))
        .toList();
  }

  /// 计算图的层级结构（用于层次布局）
  static Map<String, int> calculateRanks(DiagramState state) {
    final ranks = <String, int>{};
    final visited = <String>{};
    final roots = findRootNodes(state);

    if (roots.isEmpty && state.nodes.isNotEmpty) {
      // 如果没有根节点（循环图），随机选一个起点
      roots.add(state.nodes.keys.first);
    }

    // BFS 分配层级
    final queue = <String>[...roots];
    for (final root in roots) {
      ranks[root] = 0;
      visited.add(root);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentRank = ranks[current] ?? 0;

      for (final edge in getOutgoingEdges(state, current)) {
        final target = edge.targetNodeId;
        if (!visited.contains(target)) {
          ranks[target] = currentRank + 1;
          visited.add(target);
          queue.add(target);
        }
      }
    }

    // 处理未访问的节点
    for (final nodeId in state.nodes.keys) {
      if (!ranks.containsKey(nodeId)) {
        ranks[nodeId] = 0;
      }
    }

    return ranks;
  }

  /// 计算节点尺寸
  static Size getNodeSize(DiagramNode node) {
    return node.size;
  }

  /// 计算内容边界
  static Rect calculateBounds(Map<String, Offset> positions, DiagramState state) {
    if (positions.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final entry in positions.entries) {
      final node = state.getNode(entry.key);
      if (node == null) continue;

      final size = node.size;
      final pos = entry.value;

      minX = minX < pos.dx ? minX : pos.dx;
      minY = minY < pos.dy ? minY : pos.dy;
      maxX = maxX > pos.dx + size.width ? maxX : pos.dx + size.width;
      maxY = maxY > pos.dy + size.height ? maxY : pos.dy + size.height;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 将布局居中
  static Map<String, Offset> centerLayout(
    Map<String, Offset> positions,
    DiagramState state,
    Offset center,
  ) {
    if (positions.isEmpty) return positions;

    final bounds = calculateBounds(positions, state);
    final currentCenter = bounds.center;

    final offset = center - currentCenter;

    return positions.map((key, value) => MapEntry(key, value + offset));
  }
}