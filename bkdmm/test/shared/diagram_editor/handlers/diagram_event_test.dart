import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/diagram_event.dart';

void main() {
  group('DiagramEvent', () {
    group('DiagramPointerDownEvent', () {
      test('should create from PointerDownEvent', () {
        // 注意：在测试环境中不能创建真实的 PointerDownEvent
        // 这里测试构造函数
        final event = DiagramPointerDownEvent(
          localPosition: const Offset(100, 200),
          position: const Offset(100, 200),
          buttons: kPrimaryMouseButton,
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.localPosition, const Offset(100, 200));
        expect(event.buttons, kPrimaryMouseButton);
        expect(event.deviceKind, PointerDeviceKind.mouse);
      });

      test('should detect left button', () {
        final event = DiagramPointerDownEvent(
          localPosition: Offset.zero,
          position: Offset.zero,
          buttons: kPrimaryMouseButton,
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.isLeftButton, true);
        expect(event.isRightButton, false);
      });

      test('should detect right button', () {
        final event = DiagramPointerDownEvent(
          localPosition: Offset.zero,
          position: Offset.zero,
          buttons: kSecondaryMouseButton,
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.isLeftButton, false);
        expect(event.isRightButton, true);
      });

      test('should detect modifier keys', () {
        final event = DiagramPointerDownEvent(
          localPosition: Offset.zero,
          position: Offset.zero,
          buttons: kPrimaryMouseButton,
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
          isCtrlPressed: true,
          isShiftPressed: true,
        );

        expect(event.isCtrlPressed, true);
        expect(event.isShiftPressed, true);
        expect(event.isAltPressed, false);
      });
    });

    group('DiagramPointerMoveEvent', () {
      test('should create with delta', () {
        final event = DiagramPointerMoveEvent(
          localPosition: const Offset(110, 210),
          position: const Offset(110, 210),
          delta: const Offset(10, 10),
          buttons: kPrimaryMouseButton,
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.delta, const Offset(10, 10));
        expect(event.localPosition, const Offset(110, 210));
      });
    });

    group('DiagramPointerUpEvent', () {
      test('should create', () {
        final event = DiagramPointerUpEvent(
          localPosition: const Offset(100, 200),
          position: const Offset(100, 200),
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.localPosition, const Offset(100, 200));
        expect(event.deviceKind, PointerDeviceKind.mouse);
      });
    });

    group('DiagramHoverEvent', () {
      test('should create', () {
        final event = DiagramHoverEvent(
          localPosition: const Offset(100, 200),
          position: const Offset(100, 200),
          delta: const Offset(5, 5),
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.localPosition, const Offset(100, 200));
        expect(event.delta, const Offset(5, 5));
      });
    });

    group('DiagramScrollEvent', () {
      test('should create', () {
        final event = DiagramScrollEvent(
          localPosition: const Offset(100, 200),
          position: const Offset(100, 200),
          scrollDelta: const Offset(0, -10),
          timestamp: Duration.zero,
          deviceKind: PointerDeviceKind.mouse,
        );

        expect(event.scrollDelta, const Offset(0, -10));
      });
    });

    group('DiagramKeyEvent', () {
      test('should create', () {
        final event = DiagramKeyEvent(
          key: LogicalKeyboardKey.controlLeft,
          isDown: true,
          timestamp: Duration.zero,
          isCtrlPressed: true,
        );

        expect(event.key, LogicalKeyboardKey.controlLeft);
        expect(event.isDown, true);
        // Note: keyboard events use mouse as placeholder for deviceKind
        expect(event.deviceKind, PointerDeviceKind.mouse);
      });
    });

    group('Sealed class pattern matching', () {
      test('should match all event types', () {
        final events = <DiagramEvent>[
          DiagramPointerDownEvent(
            localPosition: Offset.zero,
            position: Offset.zero,
            buttons: 0,
            timestamp: Duration.zero,
            deviceKind: PointerDeviceKind.mouse,
          ),
          DiagramPointerMoveEvent(
            localPosition: Offset.zero,
            position: Offset.zero,
            delta: Offset.zero,
            buttons: 0,
            timestamp: Duration.zero,
            deviceKind: PointerDeviceKind.mouse,
          ),
          DiagramPointerUpEvent(
            localPosition: Offset.zero,
            position: Offset.zero,
            timestamp: Duration.zero,
            deviceKind: PointerDeviceKind.mouse,
          ),
          DiagramHoverEvent(
            localPosition: Offset.zero,
            position: Offset.zero,
            delta: Offset.zero,
            timestamp: Duration.zero,
            deviceKind: PointerDeviceKind.mouse,
          ),
          DiagramScrollEvent(
            localPosition: Offset.zero,
            position: Offset.zero,
            scrollDelta: Offset.zero,
            timestamp: Duration.zero,
            deviceKind: PointerDeviceKind.mouse,
          ),
          DiagramKeyEvent(
            key: LogicalKeyboardKey.keyA,
            isDown: true,
            timestamp: Duration.zero,
          ),
        ];

        for (final event in events) {
          final type = switch (event) {
            DiagramPointerDownEvent() => 'down',
            DiagramPointerMoveEvent() => 'move',
            DiagramPointerUpEvent() => 'up',
            DiagramHoverEvent() => 'hover',
            DiagramScrollEvent() => 'scroll',
            DiagramKeyEvent() => 'key',
          };

          expect(type, isNotNull);
        }
      });
    });
  });
}