/// 事件处理器注册表
///
/// 管理所有事件处理器，提供优先级排序的事件分发机制
library;

import 'package:flutter/material.dart';
import 'diagram_event.dart';
import 'diagram_context.dart';
import 'diagram_handler.dart';
import 'anchor_click_handler.dart';
import 'node_drag_handler.dart';
import 'selection_handler.dart';
import 'canvas_pan_handler.dart';

/// 事件处理器注册表
///
/// 负责管理处理器列表并按优先级分发事件
class HandlerRegistry {
  /// 已注册的处理器列表
  final List<DiagramEventHandler> _handlers = [];

  /// 当前活跃的处理器（正在处理某个交互）
  DiagramEventHandler? _activeHandler;

  /// 是否已排序
  bool _isSorted = false;

  /// 注册处理器
  void register(DiagramEventHandler handler) {
    _handlers.add(handler);
    _isSorted = false;
  }

  /// 注册多个处理器
  void registerAll(List<DiagramEventHandler> handlers) {
    _handlers.addAll(handlers);
    _isSorted = false;
  }

  /// 移除处理器
  void remove(DiagramEventHandler handler) {
    _handlers.remove(handler);
  }

  /// 清空所有处理器
  void clear() {
    _handlers.clear();
    _activeHandler = null;
    _isSorted = false;
  }

  /// 获取已排序的处理器列表
  List<DiagramEventHandler> get handlers {
    if (!_isSorted) {
      _handlers.sort((a, b) => a.priority.compareTo(b.priority));
      _isSorted = true;
    }
    return List.unmodifiable(_handlers);
  }

  /// 分发事件
  ///
  /// 按优先级顺序将事件分发给处理器。
  /// 如果某个处理器处理了事件（返回 true），则停止分发。
  ///
  /// [event] - 要分发的事件
  /// [context] - 图表上下文
  /// [updateState] - 状态更新回调
  ///
  /// 返回是否有处理器处理了该事件
  Future<bool> dispatch(
    DiagramEvent event,
    DiagramContext context,
    void Function(HandlerUpdate update) updateState,
  ) async {
    // 如果有活跃处理器，优先让它处理
    if (_activeHandler != null) {
      final handled = await _activeHandler!.handle(event, context, updateState);
      if (handled) {
        return true;
      }
      // 活跃处理器不再处理，重置
      _activeHandler = null;
    }

    // 按优先级分发事件
    for (final handler in handlers) {
      if (handler.canHandle(event, context)) {
        final handled = await handler.handle(event, context, updateState);
        if (handled) {
          _activeHandler = handler;
          return true;
        }
      }
    }

    return false;
  }

  /// 获取当前光标样式
  ///
  /// 遍历处理器，返回第一个提供光标样式的处理器的光标
  MouseCursor getCursor(DiagramContext context) {
    // 先检查活跃处理器
    if (_activeHandler != null) {
      final cursor = _activeHandler!.getCursor(context);
      if (cursor != null) {
        return cursor;
      }
    }

    // 按优先级检查所有处理器
    for (final handler in handlers) {
      final cursor = handler.getCursor(context);
      if (cursor != null) {
        return cursor;
      }
    }

    return SystemMouseCursors.basic;
  }

  /// 重置所有处理器状态
  void resetAll() {
    _activeHandler = null;
    for (final handler in _handlers) {
      handler.reset();
    }
  }

  /// 获取处理器数量
  int get length => _handlers.length;

  /// 检查是否为空
  bool get isEmpty => _handlers.isEmpty;

  /// 检查是否不为空
  bool get isNotEmpty => _handlers.isNotEmpty;

  /// 获取当前活跃处理器
  DiagramEventHandler? get activeHandler => _activeHandler;

  /// 设置活跃处理器
  void setActiveHandler(DiagramEventHandler? handler) {
    _activeHandler = handler;
  }

  /// 清除活跃处理器
  void clearActiveHandler() {
    _activeHandler = null;
  }

  @override
  String toString() {
    return 'HandlerRegistry(handlers: ${handlers.map((h) => h.name).join(', ')})';
  }
}

/// 处理器注册表工厂
///
/// 用于创建预配置的处理器注册表
class HandlerRegistryFactory {
  /// 创建默认处理器注册表
  static HandlerRegistry createDefault() {
    return HandlerRegistry();
  }

  /// 创建 ER 图处理器注册表
  static HandlerRegistry createERDiagram({
    bool enableConnection = true,
    bool enableDrag = true,
    bool enableSelection = true,
    bool enablePan = true,
  }) {
    final registry = HandlerRegistry();

    if (enableConnection) {
      registry.register(AnchorClickHandler(priority: 10));
      registry.register(ConnectionHandler(priority: 30));
    }
    if (enableDrag) {
      registry.register(NodeDragHandler(priority: 20));
    }
    if (enableSelection) {
      registry.register(SelectionHandler(priority: 50));
    }
    if (enablePan) {
      registry.register(CanvasPanHandler(priority: 100));
    }

    return registry;
  }

  /// 创建流程图处理器注册表
  static HandlerRegistry createFlowchart() {
    final registry = HandlerRegistry();

    // TODO: 在 Phase 5 添加流程图处理器

    return registry;
  }
}