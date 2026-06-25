import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/selection_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_event.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/core/diagram_state.dart' hide InteractionMode;

// 显式导入需要的类型，避免与 Flutter 的同名类冲突
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_context.dart' as diag_ctx;

void main() {
  group('SelectionHandler', () {
    late SelectionHandler handler;

    setUp(() {
      handler = SelectionHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 50', () {
      expect(handler.priority, 50);
    });

    test('should not handle pointer down on node', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: false);

      expect(handler.canHandle(event, context), false);
    });

    test('should handle pointer down on canvas', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: true);

      expect(handler.canHandle(event, context), true);
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
        isOnCanvas: true,
        interactionMode: diag_ctx.InteractionMode.move,
      );

      expect(handler.canHandle(event, context), false);
    });

    test('should start selection on pointer down', () async {
      final event = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: true);
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(handler.isSelecting, true);
      expect(updates.any((u) => u.type == HandlerUpdateType.clearSelection), true);
      expect(updates.any((u) => u.type == HandlerUpdateType.startBoxSelection), true);
    });

    test('should update selection on pointer move', () async {
      // 首先开始选择
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: true);
      await handler.handle(downEvent, context, (_) {});

      // 然后移动
      final moveEvent = DiagramPointerMoveEvent(
        localPosition: const Offset(200, 200),
        position: const Offset(200, 200),
        delta: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(moveEvent, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(updates.any((u) => u.type == HandlerUpdateType.updateBoxSelection), true);
    });

    test('should complete selection on pointer up', () async {
      // 首先开始选择
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: true);
      await handler.handle(downEvent, context, (_) {});

      // 确认正在框选
      expect(handler.isSelecting, true);

      // 移动鼠标（模拟框选过程）
      final moveEvent = DiagramPointerMoveEvent(
        localPosition: const Offset(200, 200),
        position: const Offset(200, 200),
        delta: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      await handler.handle(moveEvent, context, (_) {});

      // 然后释放
      final upEvent = DiagramPointerUpEvent(
        localPosition: const Offset(200, 200),
        position: const Offset(200, 200),
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      await handler.handle(upEvent, context, (update) {
        updates.add(update);
      });

      expect(handler.isSelecting, false);
      // 框选应该被完成
      expect(updates.any((u) => u.type == HandlerUpdateType.completeBoxSelection), true);
    });

    test('should clear selection on small drag', () async {
      // 首先开始选择
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnCanvas: true);
      await handler.handle(downEvent, context, (_) {});

      // 然后释放（小范围，小于阈值）
      final upEvent = DiagramPointerUpEvent(
        localPosition: const Offset(105, 105), // 只移动了 5 像素
        position: const Offset(105, 105),
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      await handler.handle(upEvent, context, (update) {
        updates.add(update);
      });

      expect(handler.isSelecting, false);
      // 小范围拖动应该清空选择
      expect(updates.any((u) => u.type == HandlerUpdateType.clearSelection), true);
    });

    test('should not clear selection with Ctrl pressed', () async {
      final event = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
        isCtrlPressed: true,
      );
      final context = _createMockContext(isOnCanvas: true);
      final updates = <HandlerUpdate>[];

      await handler.handle(event, context, (update) {
        updates.add(update);
      });

      // Ctrl 按下时不应该清空选择
      expect(updates.any((u) => u.type == HandlerUpdateType.clearSelection), false);
    });
  });
}

/// 创建模拟上下文
diag_ctx.DiagramContext _createMockContext({
  bool isOnCanvas = false,
  diag_ctx.InteractionMode interactionMode = diag_ctx.InteractionMode.edit,
}) {
  return diag_ctx.DiagramContext(
    diagramId: 'test',
    diagramType: 'er',
    state: DiagramState(diagramId: 'test', diagramType: 'er'),
    transform: Matrix4.identity(),
    interactionMode: interactionMode,
    hitTestResult: diag_ctx.HitTestResult(
      hitPosition: Offset.zero,
      type: isOnCanvas ? diag_ctx.HitTestType.canvas : diag_ctx.HitTestType.node,
    ),
  );
}