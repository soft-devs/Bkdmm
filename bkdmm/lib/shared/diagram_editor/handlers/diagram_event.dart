/// 图表事件定义
///
/// 使用 sealed class 定义所有图表事件类型，
/// 确保编译器强制处理所有事件类型。
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// 鼠标按钮常量
const int _kTertiaryMouseButton = 0x04;

/// 图表事件基类
///
/// 所有图表事件都继承自这个 sealed class，
/// 使用模式匹配可以确保处理所有事件类型。
sealed class DiagramEvent {
  /// 事件时间戳
  final Duration timestamp;

  /// 事件来源设备类型
  final PointerDeviceKind deviceKind;

  /// 是否按下修饰键
  final bool isCtrlPressed;
  final bool isShiftPressed;
  final bool isAltPressed;

  const DiagramEvent({
    required this.timestamp,
    required this.deviceKind,
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
  });

  /// 从 PointerDownEvent 创建
  factory DiagramEvent.fromPointerDown(
    PointerDownEvent event, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) {
    return DiagramPointerDownEvent(
      localPosition: event.localPosition,
      position: event.position,
      buttons: event.buttons,
      timestamp: event.timeStamp,
      deviceKind: event.kind,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  /// 从 PointerMoveEvent 创建
  factory DiagramEvent.fromPointerMove(
    PointerMoveEvent event, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) {
    return DiagramPointerMoveEvent(
      localPosition: event.localPosition,
      position: event.position,
      delta: event.localDelta,
      buttons: event.buttons,
      timestamp: event.timeStamp,
      deviceKind: event.kind,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  /// 从 PointerUpEvent 创建
  factory DiagramEvent.fromPointerUp(
    PointerUpEvent event, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) {
    return DiagramPointerUpEvent(
      localPosition: event.localPosition,
      position: event.position,
      timestamp: event.timeStamp,
      deviceKind: event.kind,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  /// 从 PointerHoverEvent 创建
  factory DiagramEvent.fromPointerHover(
    PointerHoverEvent event, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) {
    return DiagramHoverEvent(
      localPosition: event.localPosition,
      position: event.position,
      delta: event.localDelta,
      timestamp: event.timeStamp,
      deviceKind: event.kind,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }
}

/// 指针按下事件
class DiagramPointerDownEvent extends DiagramEvent {
  /// 本地坐标（相对于画布）
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 按下的按钮
  final int buttons;

  const DiagramPointerDownEvent({
    required this.localPosition,
    required this.position,
    required this.buttons,
    required super.timestamp,
    required super.deviceKind,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;

  /// 是否中键按下
  bool get isMiddleButton => buttons & _kTertiaryMouseButton != 0;
}

/// 指针移动事件
class DiagramPointerMoveEvent extends DiagramEvent {
  /// 本地坐标（相对于画布）
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 移动增量
  final Offset delta;

  /// 当前按下的按钮
  final int buttons;

  const DiagramPointerMoveEvent({
    required this.localPosition,
    required this.position,
    required this.delta,
    required this.buttons,
    required super.timestamp,
    required super.deviceKind,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;
}

/// 指针抬起事件
class DiagramPointerUpEvent extends DiagramEvent {
  /// 本地坐标（相对于画布）
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  const DiagramPointerUpEvent({
    required this.localPosition,
    required this.position,
    required super.timestamp,
    required super.deviceKind,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });
}

/// 悬停事件
class DiagramHoverEvent extends DiagramEvent {
  /// 本地坐标（相对于画布）
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 移动增量
  final Offset delta;

  const DiagramHoverEvent({
    required this.localPosition,
    required this.position,
    required this.delta,
    required super.timestamp,
    required super.deviceKind,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });
}

/// 滚轮事件
class DiagramScrollEvent extends DiagramEvent {
  /// 本地坐标（相对于画布）
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 滚动增量
  final Offset scrollDelta;

  const DiagramScrollEvent({
    required this.localPosition,
    required this.position,
    required this.scrollDelta,
    required super.timestamp,
    required super.deviceKind,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });
}

/// 键盘事件
class DiagramKeyEvent extends DiagramEvent {
  /// 按键
  final LogicalKeyboardKey key;

  /// 是否按下（true）或释放（false）
  final bool isDown;

  const DiagramKeyEvent({
    required this.key,
    required this.isDown,
    required super.timestamp,
    // Note: keyboard events don't have pointer device kind
    // Using mouse as a placeholder, but typically keyboard events
    // don't use deviceKind
    super.deviceKind = PointerDeviceKind.mouse,
    super.isCtrlPressed,
    super.isShiftPressed,
    super.isAltPressed,
  });
}
