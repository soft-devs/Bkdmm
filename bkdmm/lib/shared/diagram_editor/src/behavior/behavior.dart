/// 行为基类
///
/// 定义可复用的交互行为接口。
/// 行为是一种可组合的交互单元，可以附加到不同组件上。
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 行为基类
///
/// 行为是可复用的交互单元，通过优先级机制协调多个行为。
/// 典型用例：拖拽、缩放、选择、连线等交互行为。
///
/// ## 使用示例
///
/// ```dart
/// class DragBehavior extends Behavior<DragState> {
///   DragBehavior({super.priority = 20, super.name = 'drag'});
///
///   @override
///   bool canHandle(BehaviorEvent event, BehaviorContext context) {
///     return event is PointerDownEvent && context.isOnNode;
///   }
///
///   @override
///   Future<bool> handle(
///     BehaviorEvent event,
///     BehaviorContext context,
///     void Function(BehaviorUpdate) update,
///   ) async {
///     // 处理拖拽逻辑
///     return true;
///   }
/// }
/// ```
abstract class Behavior<T> {
  /// 行为优先级
  ///
  /// 数值越小优先级越高，越先被处理。
  /// 推荐优先级范围：
  /// - 0-10: 系统级行为（如快捷键）
  /// - 10-30: 高优先级行为（如锚点点击）
  /// - 30-50: 中等优先级行为（如节点拖拽）
  /// - 50-100: 低优先级行为（如画布平移）
  final int priority;

  /// 行为名称（用于调试和日志）
  final String name;

  /// 行为状态
  ///
  /// 用于存储行为运行时状态，如拖拽起始位置等。
  T? state;

  Behavior({
    this.priority = 100,
    this.name = 'unnamed',
    this.state,
  });

  /// 判断是否可以处理该事件
  ///
  /// 返回 `true` 表示可以处理，事件将传递给 [handle] 方法。
  /// 返回 `false` 表示不处理，事件将传递给下一个行为。
  ///
  /// [event] - 触发的事件
  /// [context] - 行为执行上下文
  bool canHandle(BehaviorEvent event, BehaviorContext context);

  /// 处理事件
  ///
  /// 返回 `true` 表示事件已处理，不再传递给后续行为。
  /// 返回 `false` 表示事件未被完全处理，继续传递。
  ///
  /// [event] - 触发的事件
  /// [context] - 行为执行上下文
  /// [update] - 状态更新回调，用于请求状态变更
  Future<bool> handle(
    BehaviorEvent event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  );

  /// 获取当前光标样式
  ///
  /// 如果行为处于活动状态，返回对应的光标样式。
  /// 默认返回 `null`，表示不改变光标。
  MouseCursor? getCursor(BehaviorContext context) => null;

  /// 重置行为状态
  ///
  /// 当交互结束、取消或需要清理时调用。
  /// 子类应重写此方法以清理状态。
  void reset() {
    state = null;
  }

  /// 是否处于活动状态
  ///
  /// 当行为正在处理某个交互序列时返回 `true`。
  /// 默认检查 state 是否非空。
  bool get isActive => state != null;

  @override
  String toString() => 'Behavior<$T>($name, priority=$priority, active=$isActive)';
}

/// 行为事件基类
///
/// 所有传递给行为的事件都应继承此类。
/// 这是一个简化的接口，具体事件类型由实现定义。
abstract class BehaviorEvent {
  /// 事件时间戳
  final Duration timestamp;

  /// 事件来源设备类型
  final PointerDeviceKind deviceKind;

  const BehaviorEvent({
    required this.timestamp,
    this.deviceKind = PointerDeviceKind.mouse,
  });
}

/// 行为上下文
///
/// 提供行为执行所需的上下文信息。
/// 这是一个简化的接口，具体实现由使用方定义。
abstract class BehaviorContext {
  /// 当前交互位置（场景坐标）
  Offset get position;

  /// 是否命中节点
  bool get isOnNode;

  /// 是否命中锚点
  bool get isOnAnchor;

  /// 是否命中边
  bool get isOnEdge;

  /// 是否命中空白区域
  bool get isOnCanvas;

  /// 获取命中的元素 ID
  String? get hitId;
}

/// 行为状态更新
///
/// 行为通过此对象请求状态更新。
class BehaviorUpdate {
  /// 更新类型
  final String type;

  /// 相关数据
  final Map<String, dynamic> data;

  const BehaviorUpdate({
    required this.type,
    this.data = const {},
  });

  /// 创建带数据的更新
  factory BehaviorUpdate.withData(String type, Map<String, dynamic> data) {
    return BehaviorUpdate(type: type, data: data);
  }

  @override
  String toString() => 'BehaviorUpdate(type: $type, data: $data)';
}
