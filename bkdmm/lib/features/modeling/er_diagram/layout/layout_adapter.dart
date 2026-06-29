import 'dart:ui';
import 'package:graphview/graphview.dart';

/// 无操作布局算法
///
/// 保持节点现有位置，不做任何布局计算
class NoOpLayoutAlgorithm extends Algorithm {
  @override
  EdgeRenderer? renderer;

  NoOpLayoutAlgorithm() {
    // 使用默认的箭头渲染器
    renderer = ArrowEdgeRenderer(noArrow: true);
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
      return const Size(2000, 2000);
    }

    final width = maxX - minX + 100;
    final height = maxY - minY + 100;

    return Size(width, height);
  }
}
