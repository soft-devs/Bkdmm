import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/spatial/spatial_index.dart';
import 'package:bkdmm/shared/diagram_editor/spatial/simple_index.dart';

void main() {
  group('SimpleSpatialIndex', () {
    late SimpleSpatialIndex index;

    setUp(() {
      index = SimpleSpatialIndex();
    });

    tearDown(() {
      index.clear();
    });

    group('insert', () {
      test('should insert item', () {
        final item = BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        );

        index.insert(item);

        expect(index.count, 1);
        expect(index.contains('node1'), true);
      });

      test('should insert multiple items', () {
        for (var i = 0; i < 10; i++) {
          index.insert(BoundedItem(
            id: 'node$i',
            bounds: Rect.fromLTWH(i * 100.0, 0, 100, 50),
          ));
        }

        expect(index.count, 10);
      });

      test('should update existing item', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(200, 200, 200, 100),
        ));

        expect(index.count, 1);
        final item = index.get('node1');
        expect(item?.bounds, const Rect.fromLTWH(200, 200, 200, 100));
      });
    });

    group('remove', () {
      test('should remove item', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        index.remove('node1');

        expect(index.isEmpty, true);
        expect(index.contains('node1'), false);
      });

      test('should not throw when removing non-existent item', () {
        // 应该不抛出异常
        expect(() => index.remove('nonexistent'), returnsNormally);
      });
    });

    group('update', () {
      test('should update item bounds', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        index.update('node1', const Rect.fromLTWH(200, 200, 200, 100));

        final item = index.get('node1');
        expect(item?.bounds, const Rect.fromLTWH(200, 200, 200, 100));
      });

      test('should not throw when updating non-existent item', () {
        expect(
          () => index.update('nonexistent', const Rect.fromLTWH(0, 0, 100, 100)),
          returnsNormally,
        );
      });
    });

    group('queryPoint', () {
      test('should find item at point', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        final results = index.queryPoint(const Offset(150, 150));

        expect(results.length, 1);
        expect(results.first.id, 'node1');
      });

      test('should not find item outside bounds', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        final results = index.queryPoint(const Offset(50, 50));

        expect(results.isEmpty, true);
      });

      test('should find multiple items at overlapping point', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));
        index.insert(BoundedItem(
          id: 'node2',
          bounds: const Rect.fromLTWH(150, 100, 200, 100),
        ));

        final results = index.queryPoint(const Offset(180, 150));

        expect(results.length, 2);
      });
    });

    group('queryRect', () {
      test('should find intersecting items', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));
        index.insert(BoundedItem(
          id: 'node2',
          bounds: const Rect.fromLTWH(400, 100, 200, 100),
        ));

        final results = index.queryRect(const Rect.fromLTWH(0, 0, 300, 300));

        expect(results.length, 1);
        expect(results.first.id, 'node1');
      });

      test('should find all intersecting items', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));
        index.insert(BoundedItem(
          id: 'node2',
          bounds: const Rect.fromLTWH(150, 100, 200, 100),
        ));

        final results = index.queryRect(const Rect.fromLTWH(0, 0, 300, 300));

        expect(results.length, 2);
      });
    });

    group('queryTopmost', () {
      test('should return topmost item', () {
        index.insert(BoundedItem(
          id: 'node1',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));
        index.insert(BoundedItem(
          id: 'node2',
          bounds: const Rect.fromLTWH(100, 100, 200, 100),
        ));

        final result = index.queryTopmost(const Offset(150, 150));

        // 后插入的在最上层
        expect(result?.id, 'node2');
      });

      test('should return null when no item found', () {
        final result = index.queryTopmost(const Offset(100, 100));

        expect(result, null);
      });
    });

    group('performance', () {
      test('should handle 100 nodes efficiently', () {
        final stopwatch = Stopwatch()..start();

        // 插入 100 个节点
        for (var i = 0; i < 100; i++) {
          index.insert(BoundedItem(
            id: 'node$i',
            bounds: Rect.fromLTWH(i * 10.0, i * 10.0, 100, 50),
          ));
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        // 查询
        stopwatch.reset();
        stopwatch.start();

        for (var i = 0; i < 100; i++) {
          index.queryPoint(Offset(i * 10.0 + 50, i * 10.0 + 25));
        }

        stopwatch.stop();
        // 100 次查询应该在 50ms 内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('getStats', () {
      test('should return correct stats', () {
        for (var i = 0; i < 10; i++) {
          index.insert(BoundedItem(
            id: 'node$i',
            bounds: Rect.fromLTWH(i * 10.0, 0, 100, 50),
          ));
        }

        final stats = index.getStats();

        expect(stats.itemCount, 10);
      });
    });
  });

  group('DiagramSpatialIndex', () {
    late DiagramSpatialIndex index;

    setUp(() {
      index = DiagramSpatialIndex();
    });

    test('should hit test nodes', () {
      index.nodeIndex.insert(BoundedItem(
        id: 'node1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
      ));

      final result = index.hitTest(const Offset(150, 150));

      expect(result.isOnNode, true);
      expect(result.nodeId, 'node1');
    });

    test('should hit test anchors first', () {
      // 节点和锚点在同一位置
      index.nodeIndex.insert(BoundedItem(
        id: 'node1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
      ));
      index.anchorIndex.insert(BoundedItem(
        id: 'anchor1',
        bounds: const Rect.fromLTWH(95, 145, 10, 10),
      ));

      final result = index.hitTest(const Offset(100, 150));

      expect(result.isOnAnchor, true);
    });

    test('should return canvas hit when nothing found', () {
      final result = index.hitTest(const Offset(100, 100));

      expect(result.isOnCanvas, true);
    });

    test('should query nodes in rect', () {
      index.nodeIndex.insert(BoundedItem(
        id: 'node1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
      ));
      index.nodeIndex.insert(BoundedItem(
        id: 'node2',
        bounds: const Rect.fromLTWH(400, 100, 200, 100),
      ));

      final results = index.queryNodesInRect(const Rect.fromLTWH(0, 0, 300, 300));

      expect(results.length, 1);
      expect(results.first, 'node1');
    });

    test('should clear all indexes', () {
      index.nodeIndex.insert(BoundedItem(
        id: 'node1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
      ));
      index.anchorIndex.insert(BoundedItem(
        id: 'anchor1',
        bounds: const Rect.fromLTWH(95, 145, 10, 10),
      ));

      index.clear();

      expect(index.nodeIndex.isEmpty, true);
      expect(index.anchorIndex.isEmpty, true);
    });
  });
}