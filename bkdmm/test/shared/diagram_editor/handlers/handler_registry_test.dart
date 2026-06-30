import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/handler_registry.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_handler.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_event.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_context.dart';
import 'package:bkdmm/shared/diagram_editor/core/diagram_state.dart';

void main() {
  group('HandlerRegistry', () {
    late HandlerRegistry registry;

    setUp(() {
      registry = HandlerRegistry();
    });

    tearDown(() {
      registry.clear();
    });

    test('should register handler', () {
      final handler = _TestHandler(name: 'test', priority: 100);
      registry.register(handler);

      expect(registry.length, 1);
      expect(registry.handlers.first, handler);
    });

    test('should register multiple handlers', () {
      final handlers = [
        _TestHandler(name: 'h1', priority: 10),
        _TestHandler(name: 'h2', priority: 20),
        _TestHandler(name: 'h3', priority: 30),
      ];

      registry.registerAll(handlers);

      expect(registry.length, 3);
    });

    test('should sort handlers by priority', () {
      registry.register(_TestHandler(name: 'low', priority: 100));
      registry.register(_TestHandler(name: 'high', priority: 10));
      registry.register(_TestHandler(name: 'mid', priority: 50));

      final sorted = registry.handlers;

      expect(sorted[0].priority, 10);
      expect(sorted[1].priority, 50);
      expect(sorted[2].priority, 100);
    });

    test('should remove handler', () {
      final handler = _TestHandler(name: 'test', priority: 100);
      registry.register(handler);
      registry.remove(handler);

      expect(registry.isEmpty, true);
    });

    test('should clear all handlers', () {
      registry.registerAll([
        _TestHandler(name: 'h1', priority: 10),
        _TestHandler(name: 'h2', priority: 20),
      ]);

      registry.clear();

      expect(registry.isEmpty, true);
    });

    test('should dispatch event to matching handler', () async {
      final handler = _TestHandler(
        name: 'test',
        priority: 10,
        canHandleResult: true,
        handleResult: true,
      );
      registry.register(handler);

      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: 0,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final context = _createMockContext();
      final updates = <HandlerUpdate>[];

      final handled = await registry.dispatch(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(handler.handleCount, 1);
    });

    test('should stop dispatching after handler handles event', () async {
      final handler1 = _TestHandler(
        name: 'h1',
        priority: 10,
        canHandleResult: true,
        handleResult: true,
      );
      final handler2 = _TestHandler(
        name: 'h2',
        priority: 20,
        canHandleResult: true,
        handleResult: true,
      );

      registry.registerAll([handler1, handler2]);

      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: 0,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final context = _createMockContext();

      await registry.dispatch(event, context, (_) {});

      expect(handler1.handleCount, 1);
      expect(handler2.handleCount, 0); // 不应该被调用
    });

    test('should continue dispatching if handler does not handle', () async {
      final handler1 = _TestHandler(
        name: 'h1',
        priority: 10,
        canHandleResult: true,
        handleResult: false, // 不处理
      );
      final handler2 = _TestHandler(
        name: 'h2',
        priority: 20,
        canHandleResult: true,
        handleResult: true,
      );

      registry.registerAll([handler1, handler2]);

      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: 0,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final context = _createMockContext();

      final handled = await registry.dispatch(event, context, (_) {});

      expect(handled, true);
      expect(handler1.handleCount, 1);
      expect(handler2.handleCount, 1); // 应该被调用
    });

    test('should skip handler that cannot handle', () async {
      final handler1 = _TestHandler(
        name: 'h1',
        priority: 10,
        canHandleResult: false, // 不能处理
      );
      final handler2 = _TestHandler(
        name: 'h2',
        priority: 20,
        canHandleResult: true,
        handleResult: true,
      );

      registry.registerAll([handler1, handler2]);

      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: 0,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final context = _createMockContext();

      await registry.dispatch(event, context, (_) {});

      expect(handler1.handleCount, 0); // 不应该被调用
      expect(handler2.handleCount, 1);
    });

    test('should set active handler when handling', () async {
      final handler = _TestHandler(
        name: 'test',
        priority: 10,
        canHandleResult: true,
        handleResult: true,
      );
      registry.register(handler);

      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: 0,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final context = _createMockContext();

      await registry.dispatch(event, context, (_) {});

      expect(registry.activeHandler, handler);
    });

    test('should reset all handlers', () {
      final handler = _TestHandler(name: 'test', priority: 10);
      registry.register(handler);
      registry.setActiveHandler(handler);

      registry.resetAll();

      expect(registry.activeHandler, null);
      expect(handler.resetCount, 1);
    });
  });

  group('HandlerUpdate', () {
    test('should create select node update', () {
      final update = HandlerUpdate.selectNode('node1', addToSelection: true);

      expect(update.type, HandlerUpdateType.selectNode);
      expect(update.data['nodeId'], 'node1');
      expect(update.data['addToSelection'], true);
    });

    test('should create clear selection update', () {
      final update = HandlerUpdate.clearSelection();

      expect(update.type, HandlerUpdateType.clearSelection);
    });

    test('should create start drag update', () {
      final update = HandlerUpdate.startDrag('node1', const Offset(100, 200));

      expect(update.type, HandlerUpdateType.startDrag);
      expect(update.data['nodeId'], 'node1');
      expect(update.data['startPosition'], const Offset(100, 200));
    });

    test('should create pan canvas update', () {
      final update = HandlerUpdate.panCanvas(const Offset(10, 20));

      expect(update.type, HandlerUpdateType.panCanvas);
      expect(update.data['delta'], const Offset(10, 20));
    });
  });
}

/// 测试处理器
class _TestHandler extends DiagramEventHandler {
  final bool canHandleResult;
  final bool handleResult;
  int handleCount = 0;
  int resetCount = 0;

  _TestHandler({
    required super.name,
    required super.priority,
    this.canHandleResult = true,
    this.handleResult = true,
  });

  @override
  bool canHandle(DiagramEvent event, DiagramContext context) {
    return canHandleResult;
  }

  @override
  Future<bool> handle(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    handleCount++;
    return handleResult;
  }

  @override
  void reset() {
    resetCount++;
  }
}

/// 创建模拟上下文
DiagramContext _createMockContext() {
  return DiagramContext(
    diagramId: 'test',
    diagramType: 'er',
    state: DiagramState(
      diagramId: 'test',
      diagramType: 'er',
    ),
    transform: Matrix4.identity(),
  );
}