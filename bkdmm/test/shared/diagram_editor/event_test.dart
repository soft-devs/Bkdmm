import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bkdmm/shared/diagram_editor/event/event_center.dart';

void main() {
  group('EventCenter', () {
    late EventCenter eventCenter;

    setUp(() {
      eventCenter = EventCenter();
    });

    tearDown(() {
      eventCenter.dispose();
    });

    group('基本订阅和发布', () {
      test('on() 应该注册监听器并返回订阅器', () {
        var called = false;
        final subscription = eventCenter.on<NodeSelectedEvent>((event) {
          called = true;
        });

        expect(subscription, isNotNull);
        expect(subscription.isUnsubscribed, false);

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));
        expect(called, true);
      });

      test('emit() 应该调用所有注册的监听器', () {
        final receivedIds = <String>[];

        eventCenter.on<NodeSelectedEvent>((event) {
          receivedIds.add(event.nodeId);
        });
        eventCenter.on<NodeSelectedEvent>((event) {
          receivedIds.add('${event.nodeId}_2');
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'node1'));
        eventCenter.emit(const NodeSelectedEvent(nodeId: 'node2'));

        expect(receivedIds, ['node1', 'node1_2', 'node2', 'node2_2']);
      });

      test('不同类型的事件应该独立触发', () {
        var nodeSelectedCalled = false;
        var nodeDeselectedCalled = false;

        eventCenter.on<NodeSelectedEvent>((event) {
          nodeSelectedCalled = true;
        });
        eventCenter.on<NodeDeselectedEvent>((event) {
          nodeDeselectedCalled = true;
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));

        expect(nodeSelectedCalled, true);
        expect(nodeDeselectedCalled, false);
      });
    });

    group('EventSubscription', () {
      test('unsubscribe() 应该取消订阅', () {
        var callCount = 0;
        final subscription = eventCenter.on<NodeSelectedEvent>((event) {
          callCount++;
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test1'));
        expect(callCount, 1);

        subscription.unsubscribe();
        expect(subscription.isUnsubscribed, true);

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test2'));
        expect(callCount, 1); // 不应该再增加
      });

      test('多次调用 unsubscribe() 应该是幂等的', () {
        final subscription = eventCenter.on<NodeSelectedEvent>((_) {});

        subscription.unsubscribe();
        expect(subscription.isUnsubscribed, true);

        subscription.unsubscribe(); // 不应该抛出异常
        expect(subscription.isUnsubscribed, true);
      });
    });

    group('off()', () {
      test('off() 应该移除指定监听器', () {
        var callCount = 0;
        void listener(NodeSelectedEvent event) {
          callCount++;
        }

        eventCenter.on<NodeSelectedEvent>(listener);

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test1'));
        expect(callCount, 1);

        eventCenter.off<NodeSelectedEvent>(listener);

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test2'));
        expect(callCount, 1); // 不应该再增加
      });

      test('off() 未注册的监听器应该不报错', () {
        // 不应该抛出异常
        eventCenter.off<NodeSelectedEvent>((_) {});
      });
    });

    group('once()', () {
      test('once() 应该只触发一次', () {
        var callCount = 0;
        final receivedIds = <String>[];

        eventCenter.once<NodeSelectedEvent>((event) {
          callCount++;
          receivedIds.add(event.nodeId);
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test1'));
        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test2'));
        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test3'));

        expect(callCount, 1);
        expect(receivedIds, ['test1']);
      });

      test('once() 返回的订阅器应该可以提前取消', () {
        var callCount = 0;
        final subscription = eventCenter.once<NodeSelectedEvent>((event) {
          callCount++;
        });

        subscription.unsubscribe();

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));
        expect(callCount, 0); // 取消后不应该触发
      });
    });

    group('emitAsync()', () {
      test('emitAsync() 应该异步发布事件', () async {
        var called = false;
        eventCenter.on<NodeSelectedEvent>((event) {
          called = true;
        });

        expect(called, false);

        await eventCenter.emitAsync(const NodeSelectedEvent(nodeId: 'test'));

        expect(called, true);
      });
    });

    group('hasListeners() 和 listenerCount()', () {
      test('hasListeners() 应该正确报告监听器状态', () {
        expect(eventCenter.hasListeners<NodeSelectedEvent>(), false);

        final subscription = eventCenter.on<NodeSelectedEvent>((_) {});
        expect(eventCenter.hasListeners<NodeSelectedEvent>(), true);

        subscription.unsubscribe();
        expect(eventCenter.hasListeners<NodeSelectedEvent>(), false);
      });

      test('listenerCount() 应该返回正确的监听器数量', () {
        expect(eventCenter.listenerCount<NodeSelectedEvent>(), 0);

        final sub1 = eventCenter.on<NodeSelectedEvent>((_) {});
        final sub2 = eventCenter.on<NodeSelectedEvent>((_) {});
        expect(eventCenter.listenerCount<NodeSelectedEvent>(), 2);

        sub1.unsubscribe();
        expect(eventCenter.listenerCount<NodeSelectedEvent>(), 1);

        sub2.unsubscribe();
        expect(eventCenter.listenerCount<NodeSelectedEvent>(), 0);
      });
    });

    group('clear() 和 clearAll()', () {
      test('clear<T>() 应该清除指定类型的所有监听器', () {
        var nodeSelectedCalled = false;
        var nodeDeselectedCalled = false;

        eventCenter.on<NodeSelectedEvent>((_) {
          nodeSelectedCalled = true;
        });
        eventCenter.on<NodeDeselectedEvent>((_) {
          nodeDeselectedCalled = true;
        });

        eventCenter.clear<NodeSelectedEvent>();

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));
        eventCenter.emit(const NodeDeselectedEvent('test'));

        expect(nodeSelectedCalled, false);
        expect(nodeDeselectedCalled, true);
      });

      test('clearAll() 应该清除所有监听器', () {
        var called1 = false;
        var called2 = false;

        eventCenter.on<NodeSelectedEvent>((_) {
          called1 = true;
        });
        eventCenter.on<NodeDeselectedEvent>((_) {
          called2 = true;
        });

        eventCenter.clearAll();

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));
        eventCenter.emit(const NodeDeselectedEvent('test'));

        expect(called1, false);
        expect(called2, false);
      });
    });

    group('getStream()', () {
      test('getStream() 应该返回事件流', () async {
        final receivedIds = <String>[];
        final stream = eventCenter.getStream<NodeSelectedEvent>();

        final subscription = stream.listen((event) {
          receivedIds.add(event.nodeId);
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test1'));
        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test2'));

        // 等待事件处理
        await Future.delayed(Duration.zero);

        expect(receivedIds, ['test1', 'test2']);

        await subscription.cancel();
      });

      test('流应该是广播流', () {
        final stream = eventCenter.getStream<NodeSelectedEvent>();
        expect(stream.isBroadcast, true);
      });
    });

    group('错误处理', () {
      test('监听器抛出异常时应该继续执行其他监听器', () {
        var firstCalled = false;
        var thirdCalled = false;

        eventCenter.on<NodeSelectedEvent>((event) {
          firstCalled = true;
        });
        eventCenter.on<NodeSelectedEvent>((event) {
          throw Exception('Test error');
        });
        eventCenter.on<NodeSelectedEvent>((event) {
          thirdCalled = true;
        });

        eventCenter.emit(const NodeSelectedEvent(nodeId: 'test'));

        expect(firstCalled, true);
        expect(thirdCalled, true);
      });
    });

    group('dispose()', () {
      test('dispose() 应该清除所有资源', () {
        eventCenter.on<NodeSelectedEvent>((_) {});
        eventCenter.on<NodeDeselectedEvent>((_) {});

        expect(eventCenter.hasListeners<NodeSelectedEvent>(), true);
        expect(eventCenter.hasListeners<NodeDeselectedEvent>(), true);

        eventCenter.dispose();

        expect(eventCenter.hasListeners<NodeSelectedEvent>(), false);
        expect(eventCenter.hasListeners<NodeDeselectedEvent>(), false);
      });
    });
  });

  group('预定义事件类型', () {
    group('NodeSelectedEvent', () {
      test('应该正确创建', () {
        const event = NodeSelectedEvent(nodeId: 'node1');
        expect(event.nodeId, 'node1');
        expect(event.addToSelection, false);
      });

      test('应该支持添加到选择', () {
        const event = NodeSelectedEvent(nodeId: 'node1', addToSelection: true);
        expect(event.addToSelection, true);
      });
    });

    group('NodeDeselectedEvent', () {
      test('应该正确创建', () {
        const event = NodeDeselectedEvent('node1');
        expect(event.nodeId, 'node1');
      });
    });

    group('SelectionClearedEvent', () {
      test('应该正确创建', () {
        const event = SelectionClearedEvent();
        expect(event, isNotNull);
      });
    });

    group('HoveredNodeChangedEvent', () {
      test('应该正确创建', () {
        const event = HoveredNodeChangedEvent(
          nodeId: 'node1',
          previousNodeId: 'node0',
        );
        expect(event.nodeId, 'node1');
        expect(event.previousNodeId, 'node0');
      });

      test('应该支持空值', () {
        const event = HoveredNodeChangedEvent();
        expect(event.nodeId, isNull);
        expect(event.previousNodeId, isNull);
      });
    });

    group('DragStartedEvent', () {
      test('应该正确创建', () {
        const event = DragStartedEvent(
          nodeId: 'node1',
          startPosition: Offset(10, 20),
        );
        expect(event.nodeId, 'node1');
        expect(event.startPosition, const Offset(10, 20));
      });
    });

    group('DragUpdatedEvent', () {
      test('应该正确创建', () {
        const event = DragUpdatedEvent(
          currentPosition: Offset(15, 25),
          delta: Offset(5, 5),
        );
        expect(event.currentPosition, const Offset(15, 25));
        expect(event.delta, const Offset(5, 5));
      });
    });

    group('DragEndedEvent', () {
      test('应该正确创建', () {
        const event = DragEndedEvent(
          nodeId: 'node1',
          endPosition: Offset(20, 30),
        );
        expect(event.nodeId, 'node1');
        expect(event.endPosition, const Offset(20, 30));
      });
    });

    group('ConnectionStartedEvent', () {
      test('应该正确创建', () {
        const event = ConnectionStartedEvent(
          sourceAnchorId: 'anchor1',
          sourceNodeId: 'node1',
          position: Offset(100, 100),
        );
        expect(event.sourceAnchorId, 'anchor1');
        expect(event.sourceNodeId, 'node1');
        expect(event.position, const Offset(100, 100));
      });
    });

    group('ConnectionPreviewUpdatedEvent', () {
      test('应该正确创建', () {
        const event = ConnectionPreviewUpdatedEvent(Offset(150, 150));
        expect(event.position, const Offset(150, 150));
      });
    });

    group('ConnectionCompletedEvent', () {
      test('应该正确创建', () {
        const event = ConnectionCompletedEvent(
          sourceAnchorId: 'anchor1',
          targetAnchorId: 'anchor2',
          sourceNodeId: 'node1',
          targetNodeId: 'node2',
        );
        expect(event.sourceAnchorId, 'anchor1');
        expect(event.targetAnchorId, 'anchor2');
        expect(event.sourceNodeId, 'node1');
        expect(event.targetNodeId, 'node2');
      });
    });

    group('ConnectionCancelledEvent', () {
      test('应该正确创建', () {
        const event = ConnectionCancelledEvent();
        expect(event, isNotNull);
      });
    });

    group('CanvasPannedEvent', () {
      test('应该正确创建', () {
        const event = CanvasPannedEvent(
          delta: Offset(10, 10),
          newOffset: Offset(100, 100),
        );
        expect(event.delta, const Offset(10, 10));
        expect(event.newOffset, const Offset(100, 100));
      });
    });

    group('CanvasZoomedEvent', () {
      test('应该正确创建', () {
        const event = CanvasZoomedEvent(
          zoom: 1.5,
          center: Offset(200, 200),
          previousZoom: 1.0,
        );
        expect(event.zoom, 1.5);
        expect(event.center, const Offset(200, 200));
        expect(event.previousZoom, 1.0);
      });
    });

    group('BoxSelectionStartedEvent', () {
      test('应该正确创建', () {
        const event = BoxSelectionStartedEvent(Offset(50, 50));
        expect(event.startPosition, const Offset(50, 50));
      });
    });

    group('BoxSelectionUpdatedEvent', () {
      test('应该正确创建', () {
        const event = BoxSelectionUpdatedEvent(
          currentPosition: Offset(100, 100),
          selectionRect: Rect.fromLTWH(50, 50, 50, 50),
        );
        expect(event.currentPosition, const Offset(100, 100));
        expect(event.selectionRect, Rect.fromLTWH(50, 50, 50, 50));
      });
    });

    group('BoxSelectionCompletedEvent', () {
      test('应该正确创建', () {
        const event = BoxSelectionCompletedEvent(['node1', 'node2', 'node3']);
        expect(event.selectedNodeIds, ['node1', 'node2', 'node3']);
      });
    });

    group('ContextMenuRequestedEvent', () {
      test('应该正确创建', () {
        const event = ContextMenuRequestedEvent(
          position: Offset(100, 100),
          nodeId: 'node1',
        );
        expect(event.position, const Offset(100, 100));
        expect(event.nodeId, 'node1');
      });

      test('应该支持无节点ID', () {
        const event = ContextMenuRequestedEvent(position: Offset(100, 100));
        expect(event.nodeId, isNull);
      });
    });

    group('NodeEditorRequestedEvent', () {
      test('应该正确创建', () {
        const event = NodeEditorRequestedEvent('node1');
        expect(event.nodeId, 'node1');
      });
    });

    group('ValueChangedEvent', () {
      test('应该正确创建', () {
        final event = ValueChangedEvent<int>(10, 20);
        expect(event.oldValue, 10);
        expect(event.newValue, 20);
      });

      test('应该支持不同类型', () {
        final stringEvent = ValueChangedEvent<String>('old', 'new');
        expect(stringEvent.oldValue, 'old');
        expect(stringEvent.newValue, 'new');

        final offsetEvent = ValueChangedEvent<Offset>(
          const Offset(0, 0),
          const Offset(10, 10),
        );
        expect(offsetEvent.oldValue, const Offset(0, 0));
        expect(offsetEvent.newValue, const Offset(10, 10));
      });
    });
  });

  group('EventCenter 集成测试', () {
    test('完整的事件流程', () async {
      final eventCenter = EventCenter();
      final log = <String>[];

      // 订阅节点选择事件
      final selectSubscription = eventCenter.on<NodeSelectedEvent>((event) {
        log.add('selected: ${event.nodeId}');
      });

      // 订阅拖拽事件
      eventCenter.on<DragStartedEvent>((event) {
        log.add('drag-start: ${event.nodeId}');
      });

      eventCenter.on<DragEndedEvent>((event) {
        log.add('drag-end: ${event.nodeId}');
      });

      // 模拟用户交互
      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node1'));
      eventCenter.emit(const DragStartedEvent(
        nodeId: 'node1',
        startPosition: Offset(100, 100),
      ));
      eventCenter.emit(const DragEndedEvent(
        nodeId: 'node1',
        endPosition: Offset(150, 150),
      ));

      // 取消选择订阅
      selectSubscription.unsubscribe();

      // 再次选择（不应该被记录）
      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node2'));

      expect(log, [
        'selected: node1',
        'drag-start: node1',
        'drag-end: node1',
      ]);

      eventCenter.dispose();
    });

    test('多订阅者场景', () {
      final eventCenter = EventCenter();
      final results = <String>[];

      // UI 层订阅
      eventCenter.on<NodeSelectedEvent>((event) {
        results.add('UI: ${event.nodeId}');
      });

      // 数据层订阅
      eventCenter.on<NodeSelectedEvent>((event) {
        results.add('Data: ${event.nodeId}');
      });

      // 日志层订阅（一次性）
      eventCenter.once<NodeSelectedEvent>((event) {
        results.add('Log: ${event.nodeId}');
      });

      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node1'));
      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node2'));

      expect(results, [
        'UI: node1',
        'Data: node1',
        'Log: node1',
        'UI: node2',
        'Data: node2',
      ]);

      eventCenter.dispose();
    });

    test('流和回调混合使用', () async {
      final eventCenter = EventCenter();
      final callbackResults = <String>[];
      final streamResults = <String>[];

      // 回调方式
      eventCenter.on<NodeSelectedEvent>((event) {
        callbackResults.add(event.nodeId);
      });

      // 流方式
      final streamSubscription = eventCenter
          .getStream<NodeSelectedEvent>()
          .listen((event) {
        streamResults.add(event.nodeId);
      });

      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node1'));
      eventCenter.emit(const NodeSelectedEvent(nodeId: 'node2'));

      await Future.delayed(Duration.zero);

      expect(callbackResults, ['node1', 'node2']);
      expect(streamResults, ['node1', 'node2']);

      await streamSubscription.cancel();
      eventCenter.dispose();
    });
  });
}
