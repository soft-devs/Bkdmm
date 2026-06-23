import 'dart:ui';
import '../core/diagram_state.dart';
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import 'layout_engine.dart';

/// graphview 布局引擎适配器
///
/// 将 graphview 的布局算法适配到我们的布局接口
/// 使用 graphview 的 SugiyamaLayout、TreeLayout、ForceLayout 等
///
/// 注意：需要添加 graphview 依赖
/// dependencies:
///   graphview: ^1.2.0
class GraphViewLayoutEngine implements LayoutEngine {
  @override
  String get name => 'graphview';

  LayoutConfig _config = const HierarchicalLayoutConfig();

  @override
  void setConfig(LayoutConfig config) {
    _config = config;
  }

  @override
  LayoutConfig getConfig() => _config;

  @override
  Map<String, Offset> layout(DiagramState state) {
    if (state.nodes.isEmpty) return {};

    // 根据配置类型选择布局算法
    if (_config is HierarchicalLayoutConfig) {
      return _hierarchicalLayout(state, _config as HierarchicalLayoutConfig);
    } else if (_config is TreeLayoutConfig) {
      return _treeLayout(state, _config as TreeLayoutConfig);
    } else if (_config is ForceDirectedLayoutConfig) {
      return _forceDirectedLayout(state, _config as ForceDirectedLayoutConfig);
    } else if (_config is CircularLayoutConfig) {
      return _circularLayout(state, _config as CircularLayoutConfig);
    } else if (_config is GridLayoutConfig) {
      return _gridLayout(state, _config as GridLayoutConfig);
    }

    // 默认使用层次布局
    return _hierarchicalLayout(state, const HierarchicalLayoutConfig());
  }

  @override
  Future<Map<String, Offset>> layoutAsync(DiagramState state) async {
    // 对于复杂布局（如力导向），可以异步计算
    return layout(state);
  }

  /// 层次布局 (Sugiyama 算法)
  Map<String, Offset> _hierarchicalLayout(
    DiagramState state,
    HierarchicalLayoutConfig config,
  ) {
    // 1. 计算层级
    final ranks = LayoutHelper.calculateRanks(state);

    // 2. 按层级分组
    final rankGroups = <int, List<String>>{};
    for (final entry in ranks.entries) {
      rankGroups.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    // 3. 在每个层级内排序（优化边交叉）
    if (config.optimizeCrossings) {
      _optimizeCrossings(state, rankGroups);
    }

    // 4. 计算位置
    final positions = <String, Offset>{};
    final direction = config.direction;

    for (final entry in rankGroups.entries) {
      final rank = entry.key;
      final nodes = entry.value;

      // 计算该层级的总宽度
      double totalWidth = 0;
      for (final nodeId in nodes) {
        final node = state.getNode(nodeId);
        if (node != null) {
          totalWidth += node.size.width;
        }
      }
      totalWidth += (nodes.length - 1) * config.nodeSpacing;

      // 当前 X 位置（居中）
      double currentX = -totalWidth / 2;

      for (var i = 0; i < nodes.length; i++) {
        final nodeId = nodes[i];
        final node = state.getNode(nodeId);
        if (node == null) continue;

        final size = node.size;

        // 根据方向计算位置
        Offset position;
        switch (direction) {
          case LayoutDirection.topToBottom:
            position = Offset(currentX + size.width / 2, rank * config.rankSpacing);
            break;
          case LayoutDirection.bottomToTop:
            position = Offset(currentX + size.width / 2, -rank * config.rankSpacing);
            break;
          case LayoutDirection.leftToRight:
            position = Offset(rank * config.rankSpacing, currentX + size.width / 2);
            break;
          case LayoutDirection.rightToLeft:
            position = Offset(-rank * config.rankSpacing, currentX + size.width / 2);
            break;
        }

        positions[nodeId] = position;
        currentX += size.width + config.nodeSpacing;
      }
    }

    // 5. 居中布局
    return LayoutHelper.centerLayout(positions, state, Offset.zero);
  }

  /// 优化边交叉
  void _optimizeCrossings(DiagramState state, Map<int, List<String>> rankGroups) {
    // 简化的交叉优化：按连接数排序
    for (final entry in rankGroups.entries) {
      final nodes = entry.value;
      nodes.sort((a, b) {
        final countA = LayoutHelper.getConnectionCount(state, a);
        final countB = LayoutHelper.getConnectionCount(state, b);
        return countB.compareTo(countA);
      });
    }
  }

  /// 树形布局
  Map<String, Offset> _treeLayout(
    DiagramState state,
    TreeLayoutConfig config,
  ) {
    // 找到根节点
    String? rootId = config.rootNodeId;
    if (rootId == null) {
      final roots = LayoutHelper.findRootNodes(state);
      rootId = roots.isNotEmpty ? roots.first : state.nodes.keys.first;
    }

    final positions = <String, Offset>{};

    // 递归布局
    _layoutTreeRecursive(
      state,
      rootId,
      Offset.zero,
      0,
      config,
      positions,
    );

    return LayoutHelper.centerLayout(positions, state, Offset.zero);
  }

  void _layoutTreeRecursive(
    DiagramState state,
    String nodeId,
    Offset position,
    int depth,
    TreeLayoutConfig config,
    Map<String, Offset> positions,
  ) {
    positions[nodeId] = position;

    // 获取子节点
    final children = LayoutHelper.getOutgoingEdges(state, nodeId)
        .map((e) => e.targetNodeId)
        .toList();

    if (children.isEmpty) return;

    // 计算子节点位置
    final node = state.getNode(nodeId);
    final spacing = config.nodeSpacing;
    final rankSpacing = config.rankSpacing;

    // 子节点起始位置
    double startX = position.dx - (children.length - 1) * spacing / 2;

    for (var i = 0; i < children.length; i++) {
      final childId = children[i];
      final childPos = Offset(
        startX + i * spacing,
        position.dy + rankSpacing,
      );
      _layoutTreeRecursive(state, childId, childPos, depth + 1, config, positions);
    }
  }

  /// 力导向布局
  Map<String, Offset> _forceDirectedLayout(
    DiagramState state,
    ForceDirectedLayoutConfig config,
  ) {
    // 初始位置（随机或网格）
    final positions = <String, Offset>{};
    var index = 0;
    for (final nodeId in state.nodes.keys) {
      positions[nodeId] = Offset(
        (index % 5) * config.idealEdgeLength,
        (index ~/ 5) * config.idealEdgeLength,
      );
      index++;
    }

    // 简化的力导向模拟
    for (var iter = 0; iter < config.maxIterations; iter++) {
      final forces = <String, Offset>{};

      // 计算每个节点的力
      for (final nodeId in state.nodes.keys) {
        final pos = positions[nodeId]!;
        var force = Offset.zero;

        // 排斥力（与其他所有节点）
        for (final otherId in state.nodes.keys) {
          if (otherId == nodeId) continue;
          final otherPos = positions[otherId]!;
          final delta = pos - otherPos;
          final distance = delta.distance;
          if (distance > 0) {
            final repulsion = config.repulsionStrength / (distance * distance);
            force += Offset(
              delta.dx / distance * repulsion,
              delta.dy / distance * repulsion,
            );
          }
        }

        // 弹簧力（连接的节点）
        for (final edge in state.edges.values) {
          String? connectedId;
          if (edge.sourceNodeId == nodeId) {
            connectedId = edge.targetNodeId;
          } else if (edge.targetNodeId == nodeId) {
            connectedId = edge.sourceNodeId;
          }

          if (connectedId != null) {
            final connectedPos = positions[connectedId]!;
            final delta = connectedPos - pos;
            final distance = delta.distance;
            final displacement = distance - config.idealEdgeLength;
            force += Offset(
              delta.dx / distance * displacement * config.springStrength,
              delta.dy / distance * displacement * config.springStrength,
            );
          }
        }

        // 重力（向中心）
        force -= pos * config.gravityStrength;

        forces[nodeId] = force;
      }

      // 应用力
      for (final nodeId in state.nodes.keys) {
        final pos = positions[nodeId]!;
        final force = forces[nodeId]!;
        positions[nodeId] = pos + Offset(
          force.dx * config.timeStep,
          force.dy * config.timeStep,
        );
      }
    }

    return LayoutHelper.centerLayout(positions, state, Offset.zero);
  }

  /// 圆形布局
  Map<String, Offset> _circularLayout(
    DiagramState state,
    CircularLayoutConfig config,
  ) {
    final nodes = state.nodes.keys.toList();

    // 排序
    if (config.sortBy != CircularSortBy.none) {
      nodes.sort((a, b) {
        final nodeA = state.getNode(a);
        final nodeB = state.getNode(b);
        if (nodeA == null || nodeB == null) return 0;

        switch (config.sortBy) {
          case CircularSortBy.nodeId:
            return a.compareTo(b);
          case CircularSortBy.title:
            return nodeA.title.compareTo(nodeB.title);
          case CircularSortBy.connectionCount:
            final countA = LayoutHelper.getConnectionCount(state, a);
            final countB = LayoutHelper.getConnectionCount(state, b);
            return countB.compareTo(countA);
          default:
            return 0;
        }
      });
    }

    final positions = <String, Offset>{};
    final angleStep = 2 * 3.14159265359 / nodes.length;

    for (var i = 0; i < nodes.length; i++) {
      final angle = i * angleStep;
      final nodeId = nodes[i];
      positions[nodeId] = Offset(
        config.radius * (angle).cos(),
        config.radius * (angle).sin(),
      );
    }

    return positions;
  }

  /// 网格布局
  Map<String, Offset> _gridLayout(
    DiagramState state,
    GridLayoutConfig config,
  ) {
    final nodes = state.nodes.keys.toList();
    final positions = <String, Offset>{};

    int cols = config.columns;
    if (config.autoSize) {
      cols = (nodes.length / 4).ceil().clamp(1, 10);
    }

    for (var i = 0; i < nodes.length; i++) {
      final nodeId = nodes[i];
      int row, col;

      switch (config.fillDirection) {
        case GridFillDirection.rowFirst:
          row = i ~/ cols;
          col = i % cols;
          break;
        case GridFillDirection.columnFirst:
          col = i ~/ cols;
          row = i % cols;
          break;
      }

      final node = state.getNode(nodeId);
      final spacing = config.nodeSpacing;

      positions[nodeId] = Offset(
        col * (node?.size.width ?? 100) + col * spacing,
        row * (node?.size.height ?? 100) + row * spacing,
      );
    }

    return LayoutHelper.centerLayout(positions, state, Offset.zero);
  }
}

/// 数学扩展
extension DoubleExtension on double {
  double cos() => _cos(this);
  double sin() => _sin(this);

  static double _cos(double x) {
    // Taylor series approximation (简化版)
    return 1 - x * x / 2 + x * x * x * x / 24;
  }

  static double _sin(double x) {
    // Taylor series approximation (简化版)
    return x - x * x * x / 6 + x * x * x * x * x / 120;
  }
}