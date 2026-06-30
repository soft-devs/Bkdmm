import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/anchor_click_handler.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_event.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_handler.dart';
import 'package:bkdmm/shared/diagram_editor/core/diagram_state.dart' hide InteractionMode;
import 'package:bkdmm/shared/diagram_editor/core/diagram_node.dart';

// 显式导入需要的类型，避免与 Flutter 的 HitTestResult 冲突
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_context.dart' as diag_ctx;
import 'package:bkdmm/shared/diagram_editor/integration/er_interaction_manager.dart' show InteractionMode;

void main() {
  group('AnchorClickHandler', () {
    late AnchorClickHandler handler;

    setUp(() {
      handler = AnchorClickHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 10', () {
      expect(handler.priority, 10);
    });

    test('should not handle non-pointer-down events', () {
      final event = DiagramPointerMoveEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        delta: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnAnchor: true);

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
      final context = _createMockContext(isOnAnchor: true);

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
        isOnAnchor: true,
        interactionMode: InteractionMode.move,
      );

      expect(handler.canHandle(event, context), false);
    });

    test('should handle left button on anchor in edit mode', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnAnchor: true);

      expect(handler.canHandle(event, context), true);
    });

    test('should not handle when not on anchor', () {
      final event = DiagramPointerDownEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext(isOnAnchor: false);

      expect(handler.canHandle(event, context), false);
    });

    test('should start connection on handle', () async {
      final event = DiagramPointerDownEvent(
        localPosition: const Offset(100, 100),
        position: const Offset(100, 100),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final anchor = AnchorPoint(
        node: _MockDiagramNode('node1'),
        id: 'node1:field:0:right',
        position: const Offset(100, 100),
      );

      final context = _createMockContextWithAnchor(anchor);
      final updates = <HandlerUpdate>[];

      final handled = await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(updates.length, 1);
      expect(updates[0].type, HandlerUpdateType.startConnection);
      expect(updates[0].data['anchorId'], 'node1:field:0:right');
    });

    test('should return click cursor on anchor', () {
      final context = _createMockContext(isOnAnchor: true);
      expect(handler.getCursor(context), SystemMouseCursors.click);
    });

    test('should return null cursor when not on anchor', () {
      final context = _createMockContext(isOnAnchor: false);
      expect(handler.getCursor(context), null);
    });
  });

  group('ConnectionHandler', () {
    late ConnectionHandler handler;

    setUp(() {
      handler = ConnectionHandler();
    });

    tearDown(() {
      handler.reset();
    });

    test('should have priority 30', () {
      expect(handler.priority, 30);
    });

    test('should not handle when not connecting', () {
      final event = DiagramPointerMoveEvent(
        localPosition: Offset.zero,
        position: Offset.zero,
        delta: Offset.zero,
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext();

      expect(handler.canHandle(event, context), false);
    });

    test('should handle move when connecting', () async {
      // 首先开始连线
      handler.startConnection('anchor1', const Offset(100, 100));

      final event = DiagramPointerMoveEvent(
        localPosition: const Offset(150, 150),
        position: const Offset(150, 150),
        delta: const Offset(50, 50),
        buttons: kPrimaryMouseButton,
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );
      final context = _createMockContext();
      final updates = <HandlerUpdate>[];

      expect(handler.canHandle(event, context), true);

      final handled = await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(handled, true);
      expect(updates.length, 1);
      expect(updates[0].type, HandlerUpdateType.updateConnectionPreview);
    });

    test('should complete connection on target anchor', () async {
      handler.startConnection('anchor1', const Offset(100, 100));

      final event = DiagramPointerUpEvent(
        localPosition: const Offset(200, 200),
        position: const Offset(200, 200),
        timestamp: Duration.zero,
        deviceKind: PointerDeviceKind.mouse,
      );

      final targetAnchor = AnchorPoint(
        node: _MockDiagramNode('node2'),
        id: 'node2:field:0:left',
        position: const Offset(200, 200),
      );

      final context = _createMockContextWithAnchor(targetAnchor);
      final updates = <HandlerUpdate>[];

      await handler.handle(event, context, (update) {
        updates.add(update);
      });

      expect(updates.last.type, HandlerUpdateType.completeConnection);
      expect(handler.isConnecting, false);
    });
  });
}

/// 创建模拟上下文
diag_ctx.DiagramContext _createMockContext({
  bool isOnAnchor = false,
  bool isOnNode = false,
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
      type: isOnAnchor
          ? diag_ctx.HitTestType.anchor
          : isOnNode
              ? diag_ctx.HitTestType.node
              : diag_ctx.HitTestType.canvas,
    ),
  );
}

/// 创建带有锚点的模拟上下文
diag_ctx.DiagramContext _createMockContextWithAnchor(AnchorPoint anchor) {
  return diag_ctx.DiagramContext(
    diagramId: 'test',
    diagramType: 'er',
    state: DiagramState(diagramId: 'test', diagramType: 'er'),
    transform: Matrix4.identity(),
    interactionMode: InteractionMode.edit,
    hitTestResult: diag_ctx.HitTestResult(
      anchor: anchor,
      hitPosition: anchor.position,
      type: diag_ctx.HitTestType.anchor,
    ),
  );
}

/// 模拟 DiagramNode
class _MockDiagramNode implements DiagramNode {
  @override
  final String id;

  _MockDiagramNode(this.id);

  @override
  Offset position = Offset.zero;

  @override
  Size get size => const Size(200, 100);

  @override
  String get type => 'mock';

  @override
  String get title => 'Mock Node';

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => true;

  @override
  bool get isConnectable => true;

  @override
  List<AnchorPoint> getAnchors() => [];

  @override
  AnchorPoint? getAnchor(String direction) => null;

  @override
  dynamic getData() => null;
}