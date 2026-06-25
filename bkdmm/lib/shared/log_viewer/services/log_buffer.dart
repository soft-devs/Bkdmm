/// 环形缓冲区
///
/// 参考 xterm.dart 的 CircularBuffer 设计
/// 固定大小，自动淘汰旧数据
library;

/// 环形缓冲区
///
/// 一种固定大小的数据结构，当缓冲区满时，
/// 新数据会覆盖最旧的数据。
///
/// 特点：
/// - 固定内存占用
/// - O(1) 添加操作
/// - O(n) 获取所有数据
class LogBuffer<T> {
  /// 缓冲区最大容量
  final int maxSize;

  /// 内部存储数组
  final List<T?> _buffer;

  /// 写入位置指针（下一个写入位置）
  int _head = 0;

  /// 当前元素数量
  int _count = 0;

  /// 创建环形缓冲区
  ///
  /// [maxSize] 缓冲区最大容量
  LogBuffer(this.maxSize) : _buffer = List<T?>.filled(maxSize, null);

  /// 当前元素数量
  int get length => _count;

  /// 是否为空
  bool get isEmpty => _count == 0;

  /// 是否已满
  bool get isFull => _count >= maxSize;

  /// 剩余容量
  int get remainingCapacity => maxSize - _count;

  /// 添加元素
  ///
  /// 如果缓冲区已满，会覆盖最旧的元素
  void add(T item) {
    _buffer[_head] = item;
    _head = (_head + 1) % maxSize;
    if (_count < maxSize) _count++;
  }

  /// 批量添加元素
  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  /// 获取所有元素（按添加顺序）
  ///
  /// 返回一个新的列表，不影响缓冲区内部状态
  List<T> getAll() {
    if (_count == 0) return [];

    final result = <T>[];

    if (_count < maxSize) {
      // 缓冲区未满，从头开始读取
      for (int i = 0; i < _count; i++) {
        final item = _buffer[i];
        if (item != null) result.add(item);
      }
    } else {
      // 缓冲区已满，从 head 开始循环读取
      for (int i = _head; i < maxSize; i++) {
        final item = _buffer[i];
        if (item != null) result.add(item);
      }
      for (int i = 0; i < _head; i++) {
        final item = _buffer[i];
        if (item != null) result.add(item);
      }
    }

    return result;
  }

  /// 获取最新的 N 个元素
  ///
  /// [n] 要获取的元素数量，如果 n 大于当前元素数量，返回所有元素
  List<T> getLatest(int n) {
    if (n <= 0 || _count == 0) return [];

    final all = getAll();
    if (n >= all.length) return all;

    return all.sublist(all.length - n);
  }

  /// 获取最早的 N 个元素
  ///
  /// [n] 要获取的元素数量
  List<T> getEarliest(int n) {
    if (n <= 0 || _count == 0) return [];

    final all = getAll();
    if (n >= all.length) return all;

    return all.sublist(0, n);
  }

  /// 获取指定索引的元素
  ///
  /// [index] 索引，0 表示最早添加的元素
  T? get(int index) {
    if (index < 0 || index >= _count) return null;

    if (_count < maxSize) {
      return _buffer[index];
    } else {
      return _buffer[(_head + index) % maxSize];
    }
  }

  /// 清空缓冲区
  void clear() {
    _buffer.fillRange(0, maxSize, null);
    _head = 0;
    _count = 0;
  }

  /// 遍历元素
  void forEach(void Function(T item) action) {
    final items = getAll();
    for (final item in items) {
      action(item);
    }
  }

  /// 查找满足条件的第一个元素
  T? find(bool Function(T item) test) {
    final items = getAll();
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  /// 过滤元素
  List<T> where(bool Function(T item) test) {
    return getAll().where(test).toList();
  }

  @override
  String toString() {
    return 'LogBuffer(maxSize: $maxSize, count: $_count, head: $_head)';
  }
}

/// 扩展方法：将 List 转换为 LogBuffer
extension ListToLogBufferExtension<T> on List<T> {
  /// 将列表转换为 LogBuffer
  ///
  /// 如果列表长度超过 maxSize，只保留最后 maxSize 个元素
  LogBuffer<T> toLogBuffer(int maxSize) {
    final buffer = LogBuffer<T>(maxSize);
    final start = length > maxSize ? length - maxSize : 0;
    for (int i = start; i < length; i++) {
      buffer.add(this[i]);
    }
    return buffer;
  }
}
