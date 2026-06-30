/// 历史控制器
///
/// 管理命令的执行、撤销和重做。
library;

import 'dart:collection';
import 'diagram_command.dart';

/// 历史控制器
///
/// 维护撤销和重做栈，提供命令执行和撤销功能。
class HistoryController {
  /// 撤销栈
  final ListQueue<DiagramCommand> _undoStack = ListQueue();

  /// 重做栈
  final ListQueue<DiagramCommand> _redoStack = ListQueue();

  /// 最大历史记录数
  final int maxHistorySize;

  /// 历史变更监听器
  final List<void Function()> _listeners = [];

  HistoryController({
    this.maxHistorySize = 100,
  });

  /// 执行命令
  ///
  /// 执行命令并将其添加到撤销栈。
  /// 清空重做栈（新操作使重做历史失效）。
  dynamic execute(DiagramCommand command) {
    final result = command.execute();

    // 尝试与栈顶命令合并
    if (_undoStack.isNotEmpty && _undoStack.last.canMergeWith(command)) {
      final merged = _undoStack.removeLast().mergeWith(command);
      _undoStack.add(merged);
    } else {
      _undoStack.add(command);
    }

    // 限制历史大小
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeFirst();
    }

    // 清空重做栈
    _redoStack.clear();

    _notifyListeners();
    return result;
  }

  /// 撤销最后一个命令
  ///
  /// 如果撤销栈为空，不做任何操作。
  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    _notifyListeners();
  }

  /// 重做最后一个撤销的命令
  ///
  /// 如果重做栈为空，不做任何操作。
  dynamic redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    final result = command.redo();
    _undoStack.add(command);

    _notifyListeners();
    return result;
  }

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 撤销栈大小
  int get undoStackSize => _undoStack.length;

  /// 重做栈大小
  int get redoStackSize => _redoStack.length;

  /// 清空历史
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyListeners();
  }

  /// 获取撤销历史描述列表
  List<String> get undoHistory {
    return _undoStack.map((c) => c.description).toList().reversed.toList();
  }

  /// 获取重做历史描述列表
  List<String> get redoHistory {
    return _redoStack.map((c) => c.description).toList();
  }

  /// 添加历史变更监听器
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// 移除历史变更监听器
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 导出历史状态
  Map<String, dynamic> exportState() {
    return {
      'undoStack': _undoStack.map((c) => c.toJson()).toList(),
      'redoStack': _redoStack.map((c) => c.toJson()).toList(),
    };
  }

  /// 从导出状态恢复
  ///
  /// 注意：此方法仅用于测试，实际恢复需要命令工厂。
  void importState(Map<String, dynamic> state) {
    // 实际实现需要命令工厂来反序列化
    throw UnimplementedError('importState requires command factory');
  }
}

/// 命令工厂
///
/// 用于从 JSON 反序列化命令对象。
class CommandFactory {
  /// 命令类型到构造函数的映射
  final Map<String, DiagramCommand Function(Map<String, dynamic>)> _constructors = {};

  /// 注册命令类型
  void register(
    String type,
    DiagramCommand Function(Map<String, dynamic>) constructor,
  ) {
    _constructors[type] = constructor;
  }

  /// 从 JSON 创建命令
  DiagramCommand createFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final constructor = _constructors[type];
    if (constructor == null) {
      throw ArgumentError('Unknown command type: $type');
    }
    return constructor(json);
  }
}
