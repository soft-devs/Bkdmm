/// 图表事件中心
///
/// 提供事件发布/订阅机制，支持组件间的松耦合通信。
/// 使用 on/emit/off 模式管理自定义事件。
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// 事件监听器类型
typedef EventListener<T> = void Function(T data);

/// 事件订阅器
///
/// 用于取消事件订阅
class EventSubscription {
  final void Function() _unsubscribe;
  bool _isUnsubscribed = false;

  EventSubscription(this._unsubscribe);

  /// 取消订阅
  void unsubscribe() {
    if (_isUnsubscribed) return;
    _isUnsubscribed = true;
    _unsubscribe();
  }

  /// 是否已取消订阅
  bool get isUnsubscribed => _isUnsubscribed;
}

/// 事件中心
///
/// 统一管理图表事件的发布和订阅。
/// 支持类型安全的事件数据传递。
///
/// 使用示例:
/// ```dart
/// final eventCenter = EventCenter();
///
/// // 订阅事件
/// final subscription = eventCenter.on<NodeSelectedEvent>((data) {
///   print('Node selected: ${data.nodeId}');
/// });
///
/// // 发布事件
/// eventCenter.emit(NodeSelectedEvent(nodeId: 'node-1'));
///
/// // 取消订阅
/// subscription.unsubscribe();
/// // 或使用 off
/// eventCenter.off<NodeSelectedEvent>(listener);
/// ```
class EventCenter {
  /// 事件监听器映射
  ///
  /// Key: 事件类型名称
  /// Value: 监听器列表
  final Map<String, dynamic> _listeners = {};

  /// 事件流控制器映射
  ///
  /// 用于支持 Stream 订阅模式
  final Map<String, StreamController<dynamic>> _streamControllers = {};

  /// 订阅事件
  ///
  /// [listener] - 事件监听器
  ///
  /// 返回订阅器，可用于取消订阅
  EventSubscription on<T>(EventListener<T> listener) {
    final key = T.toString();
    final listeners = _listeners.putIfAbsent(key, () => <EventListener<T>>[]);
    (listeners as List<EventListener<T>>).add(listener);

    return EventSubscription(() => _removeListener(key, listener));
  }

  /// 订阅一次性事件
  ///
  /// 事件触发后自动取消订阅
  EventSubscription once<T>(EventListener<T> listener) {
    late EventSubscription subscription;

    void wrapper(T data) {
      listener(data);
      if (!subscription.isUnsubscribed) {
        subscription.unsubscribe();
      }
    }

    subscription = on<T>(wrapper);
    return subscription;
  }

  /// 取消订阅事件
  ///
  /// [listener] - 要移除的监听器
  void off<T>(EventListener<T> listener) {
    final key = T.toString();
    _removeListener(key, listener);
  }

  /// 发布事件
  ///
  /// [data] - 事件数据
  void emit<T>(T data) {
    final key = T.toString();
    final listeners = _listeners[key];

    if (listeners != null) {
      // 复制列表以防止在迭代时修改
      final listenersCopy = List<EventListener<T>>.from(listeners);
      for (final listener in listenersCopy) {
        try {
          listener(data);
        } catch (e) {
          // 记录错误但继续执行其他监听器
          _handleError('EventCenter.emit', e);
        }
      }
    }

    // 同时发送到流
    _streamControllers[key]?.add(data);
  }

  /// 异步发布事件
  ///
  /// 在下一个微任务中发布事件，避免阻塞当前执行
  Future<void> emitAsync<T>(T data) async {
    await Future.microtask(() => emit<T>(data));
  }

  /// 获取事件流
  ///
  /// 用于支持响应式编程模式
  Stream<T> getStream<T>() {
    final key = T.toString();
    return (_streamControllers.putIfAbsent(
          key,
          () => StreamController<T>.broadcast(),
        )
        as StreamController<T>)
        .stream;
  }

  /// 检查是否有指定类型的监听器
  bool hasListeners<T>() {
    final key = T.toString();
    final listeners = _listeners[key];
    if (listeners == null) return false;
    return (listeners as List).isNotEmpty;
  }

  /// 获取指定类型的监听器数量
  int listenerCount<T>() {
    final key = T.toString();
    final listeners = _listeners[key];
    if (listeners == null) return 0;
    return (listeners as List).length;
  }

  /// 清除指定类型的所有监听器
  void clear<T>() {
    final key = T.toString();
    _listeners.remove(key);
    _streamControllers[key]?.close();
    _streamControllers.remove(key);
  }

  /// 清除所有监听器
  void clearAll() {
    _listeners.clear();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }

  /// 移除监听器
  void _removeListener<T>(String key, EventListener<T> listener) {
    final listeners = _listeners[key];
    if (listeners != null) {
      (listeners as List<EventListener<T>>).remove(listener);
      if (listeners.isEmpty) {
        _listeners.remove(key);
      }
    }
  }

  /// 错误处理
  void _handleError(String context, dynamic error) {
    // 在开发环境下打印错误
    // 生产环境可以通过日志系统记录
    assert(() {
      // ignore: avoid_print
      print('[$context] Error in event listener: $error');
      return true;
    }());
  }

  /// 释放资源
  void dispose() {
    clearAll();
  }
}

// ============================================================================
// 预定义事件类型
// ============================================================================

/// 节点选中事件
class NodeSelectedEvent {
  final String nodeId;
  final bool addToSelection;

  const NodeSelectedEvent({
    required this.nodeId,
    this.addToSelection = false,
  });
}

/// 节点取消选中事件
class NodeDeselectedEvent {
  final String nodeId;

  const NodeDeselectedEvent(this.nodeId);
}

/// 选择清空事件
class SelectionClearedEvent {
  const SelectionClearedEvent();
}

/// 悬停节点变更事件
class HoveredNodeChangedEvent {
  final String? nodeId;
  final String? previousNodeId;

  const HoveredNodeChangedEvent({
    this.nodeId,
    this.previousNodeId,
  });
}

/// 拖拽开始事件
class DragStartedEvent {
  final String nodeId;
  final Offset startPosition;

  const DragStartedEvent({
    required this.nodeId,
    required this.startPosition,
  });
}

/// 拖拽更新事件
class DragUpdatedEvent {
  final Offset currentPosition;
  final Offset delta;

  const DragUpdatedEvent({
    required this.currentPosition,
    required this.delta,
  });
}

/// 拖拽结束事件
class DragEndedEvent {
  final String nodeId;
  final Offset endPosition;

  const DragEndedEvent({
    required this.nodeId,
    required this.endPosition,
  });
}

/// 连线开始事件
class ConnectionStartedEvent {
  final String sourceAnchorId;
  final String sourceNodeId;
  final Offset position;

  const ConnectionStartedEvent({
    required this.sourceAnchorId,
    required this.sourceNodeId,
    required this.position,
  });
}

/// 连线预览更新事件
class ConnectionPreviewUpdatedEvent {
  final Offset position;

  const ConnectionPreviewUpdatedEvent(this.position);
}

/// 连线完成事件
class ConnectionCompletedEvent {
  final String sourceAnchorId;
  final String targetAnchorId;
  final String sourceNodeId;
  final String targetNodeId;

  const ConnectionCompletedEvent({
    required this.sourceAnchorId,
    required this.targetAnchorId,
    required this.sourceNodeId,
    required this.targetNodeId,
  });
}

/// 连线取消事件
class ConnectionCancelledEvent {
  const ConnectionCancelledEvent();
}

/// 画布平移事件
class CanvasPannedEvent {
  final Offset delta;
  final Offset newOffset;

  const CanvasPannedEvent({
    required this.delta,
    required this.newOffset,
  });
}

/// 画布缩放事件
class CanvasZoomedEvent {
  final double zoom;
  final Offset center;
  final double previousZoom;

  const CanvasZoomedEvent({
    required this.zoom,
    required this.center,
    required this.previousZoom,
  });
}

/// 框选开始事件
class BoxSelectionStartedEvent {
  final Offset startPosition;

  const BoxSelectionStartedEvent(this.startPosition);
}

/// 框选更新事件
class BoxSelectionUpdatedEvent {
  final Offset currentPosition;
  final Rect selectionRect;

  const BoxSelectionUpdatedEvent({
    required this.currentPosition,
    required this.selectionRect,
  });
}

/// 框选完成事件
class BoxSelectionCompletedEvent {
  final List<String> selectedNodeIds;

  const BoxSelectionCompletedEvent(this.selectedNodeIds);
}

/// 上下文菜单请求事件
class ContextMenuRequestedEvent {
  final Offset position;
  final String? nodeId;

  const ContextMenuRequestedEvent({
    required this.position,
    this.nodeId,
  });
}

/// 节点编辑器请求事件
class NodeEditorRequestedEvent {
  final String nodeId;

  const NodeEditorRequestedEvent(this.nodeId);
}

/// 状态变更事件基类
///
/// 用于标记所有状态变更事件
abstract class StateChangedEvent<T> {
  T get oldValue;
  T get newValue;
}

/// 通用状态变更事件
class ValueChangedEvent<T> extends StateChangedEvent<T> {
  @override
  final T oldValue;
  @override
  final T newValue;

  ValueChangedEvent(this.oldValue, this.newValue);
}