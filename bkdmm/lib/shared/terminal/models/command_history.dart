/// 命令历史管理
///
/// 存储和管理执行的命令历史
library;

/// 命令历史管理器
class CommandHistory {
  /// 历史命令列表
  final List<String> _history;

  /// 最大历史数量
  final int maxSize;

  /// 创建命令历史管理器
  CommandHistory({this.maxSize = 100}) : _history = [];

  /// 获取历史列表
  List<String> get history => List.unmodifiable(_history);

  /// 获取历史数量
  int get length => _history.length;

  /// 是否为空
  bool get isEmpty => _history.isEmpty;

  /// 添加命令到历史
  void add(String command) {
    if (command.trim().isEmpty) return;

    // 避免重复添加相同的命令
    if (_history.isNotEmpty && _history.last == command) return;

    _history.add(command);

    // 超出最大数量时移除最旧的
    if (_history.length > maxSize) {
      _history.removeAt(0);
    }
  }

  /// 清空历史
  void clear() {
    _history.clear();
  }

  /// 获取指定索引的命令
  String? get(int index) {
    if (index < 0 || index >= _history.length) return null;
    return _history[index];
  }

  /// 搜索历史命令
  List<String> search(String pattern) {
    if (pattern.isEmpty) return history;
    return _history.where((cmd) => cmd.contains(pattern)).toList();
  }

  /// 获取上一个命令（用于上键导航）
  String? getPrevious(int currentIndex) {
    if (currentIndex <= 0) return null;
    return _history[currentIndex - 1];
  }

  /// 获取下一个命令（用于下键导航）
  String? getNext(int currentIndex) {
    if (currentIndex >= _history.length - 1) return null;
    return _history[currentIndex + 1];
  }

  /// 导出历史为文本
  String export() {
    return _history.join('\n');
  }

  /// 从文本导入历史
  void import(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    for (final line in lines) {
      add(line);
    }
  }
}