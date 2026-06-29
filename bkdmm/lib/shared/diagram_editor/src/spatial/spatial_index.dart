/// 空间索引接口
///
/// 定义空间索引的标准接口，用于 O(log n) 命中测试
library;

import 'dart:ui';

/// 有边界项
///
/// 表示一个有边界矩形的空间对象
class BoundedItem {
  /// 对象唯一标识
  final String id;

  /// 边界矩形
  final Rect bounds;

  /// 附加数据（可选）
  final dynamic data;

  const BoundedItem({
    required this.id,
    required this.bounds,
    this.data,
  });

  /// 检查点是否在边界内
  bool containsPoint(Offset point) => bounds.contains(point);

  /// 检查矩形是否相交
  bool intersectsRect(Rect rect) => bounds.overlaps(rect);

  /// 讽刺复制
  BoundedItem copyWith({
    String? id,
    Rect? bounds,
    dynamic data,
  }) {
    return BoundedItem(
      id: id ?? this.id,
      bounds: bounds ?? this.bounds,
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'BoundedItem($id, bounds=$bounds)';
}

/// 空间索引接口
///
/// 定义空间索引的标准操作，用于高效的命中测试和区域查询
abstract class SpatialIndex {
  /// 索引边界
  final Rect bounds;

  SpatialIndex({required this.bounds});

  /// 插入项
  void insert(BoundedItem item);

  /// 移除项
  void remove(String id);

  /// 更新项的位置
  ///
  /// [id] - 项 ID
  /// [newBounds] - 新边界
  void update(String id, Rect newBounds);

  /// 清空索引
  void clear();

  /// 点查询
  ///
  /// 返回包含指定点的所有项
  List<BoundedItem> queryPoint(Offset point);

  /// 矩形查询
  ///
  /// 返回与指定矩形相交的所有项
  List<BoundedItem> queryRect(Rect rect);

  /// 获取最上层项
  ///
  /// 在多个项重叠时，返回最上层的一个。
  /// 默认返回查询结果中的最后一个。
  BoundedItem? queryTopmost(Offset point);

  /// 检查项是否存在
  bool contains(String id);

  /// 获取项
  BoundedItem? get(String id);

  /// 获取所有项
  List<BoundedItem> getAll();

  /// 获取项数量
  int get count;

  /// 检查是否为空
  bool get isEmpty;

  /// 检查是否不为空
  bool get isNotEmpty;

  /// 获取索引统计信息
  SpatialIndexStats getStats();
}

/// 空间索引统计信息
class SpatialIndexStats {
  /// 总项数
  final int itemCount;

  /// 平均查询时间（毫秒）
  final double avgQueryTimeMs;

  /// 最大查询时间（毫秒）
  final double maxQueryTimeMs;

  /// 最小查询时间（毫秒）
  final double minQueryTimeMs;

  /// 查询次数
  final int queryCount;

  /// 内存使用估算（字节）
  final int estimatedMemoryBytes;

  const SpatialIndexStats({
    required this.itemCount,
    this.avgQueryTimeMs = 0.0,
    this.maxQueryTimeMs = 0.0,
    this.minQueryTimeMs = 0.0,
    this.queryCount = 0,
    this.estimatedMemoryBytes = 0,
  });

  @override
  String toString() {
    return 'SpatialIndexStats(count=$itemCount, avgQuery=${avgQueryTimeMs.toStringAsFixed(2)}ms)';
  }
}

/// 空间索引类型
enum SpatialIndexType {
  /// 简单列表索引（O(n)）
  simple,

  /// 四叉树索引（O(log n)）
  quadtree,

  /// R-树索引（O(log n)）
  rtree,
}

/// 空间索引配置
class SpatialIndexConfig {
  /// 索引类型
  final SpatialIndexType type;

  /// 索引边界
  final Rect bounds;

  /// 四叉树最大深度
  final int maxDepth;

  /// 四叉树节点最大容量
  final int maxNodeCapacity;

  /// 是否启用性能统计
  final bool enableStats;

  const SpatialIndexConfig({
    this.type = SpatialIndexType.simple,
    this.bounds = const Rect.fromLTWH(0, 0, 50000, 50000),
    this.maxDepth = 8,
    this.maxNodeCapacity = 4,
    this.enableStats = false,
  });

  /// 默认配置
  static const SpatialIndexConfig defaultConfig = SpatialIndexConfig();

  /// 四叉树配置
  static const SpatialIndexConfig quadtreeConfig = SpatialIndexConfig(
    type: SpatialIndexType.quadtree,
    maxDepth: 8,
    maxNodeCapacity: 4,
  );

  /// 简单索引配置
  static const SpatialIndexConfig simpleConfig = SpatialIndexConfig(
    type: SpatialIndexType.simple,
  );
}