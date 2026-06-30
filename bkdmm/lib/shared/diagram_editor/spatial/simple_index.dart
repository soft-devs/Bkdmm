/// 简单空间索引实现
///
/// 使用列表存储项，提供 O(n) 的查询性能
/// 适合小型图表（< 100 个节点）
library;

import 'dart:ui';
import 'spatial_index.dart';

/// 简单空间索引
///
/// 使用列表存储所有项，遍历查询。
/// 优点：实现简单、内存占用小、插入/删除快。
/// 缺点：查询性能 O(n)，不适合大量节点。
class SimpleSpatialIndex extends SpatialIndex {
  /// 存储所有项的列表
  final List<BoundedItem> _items = [];

  /// 按 ID 索引的项
  final Map<String, BoundedItem> _itemMap = {};

  SimpleSpatialIndex({super.bounds = const Rect.fromLTWH(0, 0, 50000, 50000)});

  @override
  void insert(BoundedItem item) {
    if (_itemMap.containsKey(item.id)) {
      // 已存在，更新
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
      }
    } else {
      // 新增
      _items.add(item);
    }
    _itemMap[item.id] = item;
  }

  @override
  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
    _itemMap.remove(id);
  }

  @override
  void update(String id, Rect newBounds) {
    final item = _itemMap[id];
    if (item != null) {
      final updated = item.copyWith(bounds: newBounds);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = updated;
      }
      _itemMap[id] = updated;
    }
  }

  @override
  void clear() {
    _items.clear();
    _itemMap.clear();
  }

  @override
  List<BoundedItem> queryPoint(Offset point) {
    final results = <BoundedItem>[];

    for (final item in _items) {
      if (item.containsPoint(point)) {
        results.add(item);
      }
    }

    return results;
  }

  @override
  List<BoundedItem> queryRect(Rect rect) {
    final results = <BoundedItem>[];

    for (final item in _items) {
      if (item.intersectsRect(rect)) {
        results.add(item);
      }
    }

    return results;
  }

  @override
  BoundedItem? queryTopmost(Offset point) {
    // 从后往前找，返回第一个匹配的（最后添加的在最上层）
    for (var i = _items.length - 1; i >= 0; i--) {
      if (_items[i].containsPoint(point)) {
        return _items[i];
      }
    }
    return null;
  }

  @override
  bool contains(String id) {
    return _itemMap.containsKey(id);
  }

  @override
  BoundedItem? get(String id) {
    return _itemMap[id];
  }

  @override
  List<BoundedItem> getAll() {
    return List.unmodifiable(_items);
  }

  @override
  int get count => _items.length;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  SpatialIndexStats getStats() {
    return SpatialIndexStats(
      itemCount: _items.length,
      estimatedMemoryBytes: _items.length * 64, // 估算：每项约 64 字节
    );
  }

  /// 批量插入
  void insertAll(List<BoundedItem> items) {
    for (final item in items) {
      insert(item);
    }
  }

  /// 获取所有边界
  List<Rect> getAllBounds() {
    return _items.map((item) => item.bounds).toList();
  }

  /// 计算所有项的总边界
  Rect calculateTotalBounds() {
    if (_items.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final item in _items) {
      final bounds = item.bounds;
      if (bounds.left < minX) minX = bounds.left;
      if (bounds.top < minY) minY = bounds.top;
      if (bounds.right > maxX) maxX = bounds.right;
      if (bounds.bottom > maxY) maxY = bounds.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// 带有命中测试扩展的简单空间索引
///
/// 支持节点和锚点的分层命中测试
class DiagramSpatialIndex {
  /// 节点索引
  final SimpleSpatialIndex nodeIndex;

  /// 锚点索引
  final SimpleSpatialIndex anchorIndex;

  /// 边索引
  final SimpleSpatialIndex edgeIndex;

  DiagramSpatialIndex({
    Rect bounds = const Rect.fromLTWH(0, 0, 50000, 50000),
  })  : nodeIndex = SimpleSpatialIndex(bounds: bounds),
        anchorIndex = SimpleSpatialIndex(bounds: bounds),
        edgeIndex = SimpleSpatialIndex(bounds: bounds);

  /// 综合命中测试
  ///
  /// 按优先级测试：锚点 > 节点 > 边
  SpatialHitTestResult hitTest(Offset point) {
    // 1. 先测试锚点（最高优先级）
    final anchorHit = anchorIndex.queryTopmost(point);
    if (anchorHit != null) {
      // 从 data 中恢复锚点信息
      // 实际使用时需要存储完整的 AnchorPoint
      return SpatialHitTestResult(
        nodeId: anchorHit.data?['nodeId'],
        anchor: anchorHit.data?['anchor'],
        hitPosition: point,
        type: SpatialHitTestType.anchor,
      );
    }

    // 2. 测试节点
    final nodeHit = nodeIndex.queryTopmost(point);
    if (nodeHit != null) {
      return SpatialHitTestResult(
        nodeId: nodeHit.id,
        node: nodeHit.data,
        hitPosition: point,
        type: SpatialHitTestType.node,
      );
    }

    // 3. 测试边
    final edgeHit = edgeIndex.queryTopmost(point);
    if (edgeHit != null) {
      return SpatialHitTestResult(
        edgeId: edgeHit.id,
        edge: edgeHit.data,
        hitPosition: point,
        type: SpatialHitTestType.edge,
      );
    }

    // 4. 没有命中任何元素
    return SpatialHitTestResult.canvas(point);
  }

  /// 框选测试
  ///
  /// 返回与矩形相交的所有节点
  List<String> queryNodesInRect(Rect rect) {
    final items = nodeIndex.queryRect(rect);
    return items.map((item) => item.id).toList();
  }

  /// 清空所有索引
  void clear() {
    nodeIndex.clear();
    anchorIndex.clear();
    edgeIndex.clear();
  }

  /// 获取统计信息
  Map<String, int> getStats() {
    return {
      'nodes': nodeIndex.count,
      'anchors': anchorIndex.count,
      'edges': edgeIndex.count,
    };
  }
}

/// 空间索引命中测试类型
enum SpatialHitTestType {
  node,
  anchor,
  edge,
  canvas,
}

/// 空间索引命中测试结果
class SpatialHitTestResult {
  final String? nodeId;
  final dynamic node;
  final dynamic anchor;
  final String? edgeId;
  final dynamic edge;
  final Offset hitPosition;
  final SpatialHitTestType type;

  const SpatialHitTestResult({
    this.nodeId,
    this.node,
    this.anchor,
    this.edgeId,
    this.edge,
    required this.hitPosition,
    required this.type,
  });

  factory SpatialHitTestResult.canvas(Offset position) {
    return SpatialHitTestResult(hitPosition: position, type: SpatialHitTestType.canvas);
  }

  bool get isOnNode => type == SpatialHitTestType.node;
  bool get isOnAnchor => type == SpatialHitTestType.anchor;
  bool get isOnEdge => type == SpatialHitTestType.edge;
  bool get isOnCanvas => type == SpatialHitTestType.canvas;
}