import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/node_drag_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_event.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/core/diagram_state.dart' hide InteractionMode;

// 显式导入需要的类型，避免与 Flutter 的同名类冲突
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_context.dart' as diag_ctx;
import 'package:bkdmm/shared/diagram_editor/src/integration/er_interaction_manager.dart' show InteractionMode;

void main() {
  group('NodeDragHandler', () {
    late NodeDragHandler handler;

    setUp(() {
      handler = NodeDragHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 20', () {
      expect(handler.priority, 20);
    });

    test('should not handle non-pointer-down events initially', () {
      final event = DiagramPointerMoveEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        delta: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true);

      expect(handler.canHandle(event, context), false);
    });

    test('should not handle right button', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true);

      expect(handler.canHandle(event, context), false);
    });

    test('should not handle in preview mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(
        isOnNode: true,
        interactionMode: InteractionMode.move,
      );

      expect(handler.canHandle(event, context), false);
    });

    test('should handle left button on node in edit mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true);

      expect(handler.canHandle(event, context), true);
    });

    test('should not handle when not on node', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: false);

      expect(handler.canHandle(event, context), false);
    });

    test('should start drag on pointer down', () async {
      final event = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true, nodeId: 'node1');
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(handler.isDragging, true);
      expect(updates.any((u) => u.type == HandlerUpdateType.selectNode), true);
      expect(updates.any((u) => u.type == HandlerUpdateType.startDrag), true);
    });

    test('should update drag on pointer move', () async {
      // 首先开始拖动
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true, nodeId: 'node1');
      await handler.handle(downEvent, context, (_) {});

      // 然后移动（超过阈值）
      final moveEvent = DiagramPointerMoveEvent(
        localPosition: const Offset(150, 150),
        position: const Offset(150, 150),
        delta: const Offset(50, 50),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(moveEvent, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(updates.any((u) => u.type == HandlerUpdateType.updateDrag), true);
    });

    test('should end drag on pointer up', () async {
      // 首先开始拖动
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true, nodeId: 'node1');
      await handler.handle(downEvent, context, (_) {});

      // 然后释放
      final upEvent = DiagramPointerUpEvent(
        localPosition: const Offset(150, 150),
        position: const Offset(150, 150),
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      await handler.handle(upEvent, context, (update) {
        updates.add(update);
      });

      expect(handler.isDragging, false);
      expect(updates.any((u) => u.type == HandlerUpdateType.endDrag), true);
    });

    test('should return grab cursor on node', () {
      final context = _createMockContext(isOnNode: true);
      expect(handler.getCursor(context), SystemMouseCursors.grab);
    });

    test('should return grabbing cursor while dragging', () async {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnNode: true, nodeId: 'node1');
      await handler.handle(event, context, (_) {});

      expect(handler.getCursor(context), SystemMouseCursors.grabbing);
    });

    test('should support Ctrl+click for multi-select', () async {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
        isCtrlPressed: true,
      );
      final context = _createMockContext(isOnNode: true, nodeId: 'node1');
      final updates = <HandlerUpdate>[];

      await handler.handle(event, context, (update) {
        updates.add(update);
      });

      final selectUpdate = updates.firstWhere(
        (u) => u.type == HandlerUpdateType.selectNode,
      );
      expect(selectUpdate.data['addToSelection'], true);
    });
  });
}

/// 创建模拟上下文
diag_ctx.DiagramContext _createMockContext({
  bool isOnNode = false,
  String? nodeId,
  InteractionMode interactionMode = InteractionMode.edit,
}) {
  return diag_ctx.DiagramContext(
    diagramId: 'test',
    diagramType: 'er',
    state: DiagramState(diagramId: 'test', diagramType: 'er'),
    transform: Matrix4.identity(),
    interactionMode: interactionMode,
    hitTestResult: diag_ctx.HitTestResult(
      nodeId: nodeId,
      hitPosition: Offset.zero,
      type: isOnNode ? diag_ctx.HitTestType.node : diag_ctx.HitTestType.canvas,
    ),
  );
}