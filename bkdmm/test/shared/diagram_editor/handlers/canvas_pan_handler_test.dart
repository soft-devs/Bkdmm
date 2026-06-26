import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/canvas_pan_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_event.dart';
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_handler.dart';
import 'package:bkdmm/shared/diagram_editor/src/core/diagram_state.dart' hide InteractionMode;

// 显式导入需要的类型，避免与 Flutter 的同名类冲突
import 'package:bkdmm/shared/diagram_editor/src/handlers/diagram_context.dart' as diag_ctx;
import 'package:bkdmm/shared/diagram_editor/src/integration/er_interaction_manager.dart' show InteractionMode;

void main() {
  group('CanvasPanHandler', () {
    late CanvasPanHandler handler;

    setUp(() {
      handler = CanvasPanHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 100', () {
      expect(handler.priority, 100);
    });

    test('should handle left button in preview mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(
        interactionMode: InteractionMode.move,
      );

      expect(handler.canHandle(event, context), true);
    });

    test('should handle right button in edit mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(
        interactionMode: InteractionMode.edit,
      );

      expect(handler.canHandle(event, context), true);
    });

    test('should not handle left button in edit mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(
        interactionMode: InteractionMode.edit,
      );

      expect(handler.canHandle(event, context), false);
    });

    test('should start pan on pointer down', () async {
      final event = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(interactionMode: InteractionMode.edit);
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(handler.isPanning, true);
    });

    test('should pan on pointer move', () async {
      // 首先开始平移
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(interactionMode: InteractionMode.edit);
      await handler.handle(downEvent, context, (_) {});

      // 然后移动
      final moveEvent = DiagramPointerMoveEvent(
        localPosition: const Offset(150, 150),
        position: const Offset(150, 150),
        delta: const Offset(50, 50),
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(moveEvent, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(updates.any((u) => u.type == HandlerUpdateType.panCanvas), true);
    });

    test('should end pan on pointer up', () async {
      // 首先开始平移
      final downEvent = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kSecondaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(interactionMode: InteractionMode.edit);
      await handler.handle(downEvent, context, (_) {});

      // 然后释放
      final upEvent = DiagramPointerUpEvent(
        localPosition: const Offset(150, 150),
        position: const Offset(150, 150),
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      await handler.handle(upEvent, context, (_) {});

      expect(handler.isPanning, false);
    });

    test('should return grab cursor in preview mode', () {
      final context = _createMockContext(interactionMode: InteractionMode.move);
      expect(handler.getCursor(context), SystemMouseCursors.grab);
    });

    test('should return null cursor in edit mode when not panning', () {
      final context = _createMockContext(interactionMode: InteractionMode.edit);
      expect(handler.getCursor(context), null);
    });
  });

  group('HoverHandler', () {
    late HoverHandler handler;

    setUp(() {
      handler = HoverHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 200', () {
      expect(handler.priority, 200);
    });

    test('should only handle hover events', () {
      final downEvent = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext();

      expect(handler.canHandle(downEvent, context), false);

      final hoverEvent = DiagramHoverEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        delta: Offset.zero,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      expect(handler.canHandle(hoverEvent, context), true);
    });

    test('should not block other handlers', () async {
      final event = DiagramHoverEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        delta: Offset.zero,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext();

      final handled = await handler.handle(event, context, (_) {});

      // HoverHandler 返回 false 以允许其他处理器处理
      expect(handled, false);
    });
  });
}

/// 创建模拟上下文
diag_ctx.DiagramContext _createMockContext({
  InteractionMode interactionMode = InteractionMode.edit,
}) {
  return diag_ctx.DiagramContext(
    diagramId: 'test',
    diagramType: 'er',
    state: DiagramState(diagramId: 'test', diagramType: 'er'),
    transform: Matrix4.identity(),
    interactionMode: interactionMode,
    hitTestResult: diag_ctx.HitTestResult(
      hitPosition: Offset.zero,
      type: diag_ctx.HitTestType.canvas,
    ),
  );
}