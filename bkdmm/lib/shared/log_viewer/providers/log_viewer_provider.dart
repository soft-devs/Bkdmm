/// 日志查看器状态管理
///
/// 使用 Riverpod 管理日志状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../services/log_buffer.dart';

/// 日志查看器状态
class LogViewerState {
  /// 过滤后的日志列表
  final List<LogEntry> entries;

  /// 当前过滤条件
  final LogFilter filter;

  /// 是否暂停接收日志
  final bool isPaused;

  /// 是否自动滚动到底部
  final bool autoScroll;

  /// 统计信息（基于所有日志，不受过滤影响）
  final LogStats stats;

  const LogViewerState({
    this.entries = const [],
    this.filter = const LogFilter(),
    this.isPaused = false,
    this.autoScroll = true,
    this.stats = const LogStats({}),
  });

  /// 复制并修改状态
  LogViewerState copyWith({
    List<LogEntry>? entries,
    LogFilter? filter,
    bool? isPaused,
    bool? autoScroll,
    LogStats? stats,
  }) {
    return LogViewerState(
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      isPaused: isPaused ?? this.isPaused,
      autoScroll: autoScroll ?? this.autoScroll,
      stats: stats ?? this.stats,
    );
  }

  /// 获取总日志数量（未过滤）
  int get totalCount => stats.total;

  /// 获取过滤后的日志数量
  int get filteredCount => entries.length;

  @override
  String toString() {
    return 'LogViewerState(total: $totalCount, filtered: $filteredCount, paused: $isPaused)';
  }
}

/// 日志查看器状态管理器
class LogViewerNotifier extends StateNotifier<LogViewerState> {
  /// 日志缓冲区
  final LogBuffer<LogEntry> _buffer;

  /// 最大日志数量
  final int maxLogs;

  /// 创建日志查看器状态管理器
  LogViewerNotifier({
    this.maxLogs = 1000,
  })  : _buffer = LogBuffer<LogEntry>(maxLogs),
        super(const LogViewerState());

  /// 添加日志
  void addLog(LogEntry entry) {
    if (state.isPaused) return;

    _buffer.add(entry);

    // 更新状态
    _updateState();
  }

  /// 批量添加日志
  void addLogs(List<LogEntry> entries) {
    if (state.isPaused) return;

    _buffer.addAll(entries);

    // 更新状态
    _updateState();
  }

  /// 设置过滤条件
  void setFilter(LogFilter filter) {
    state = state.copyWith(
      filter: filter,
      entries: _getFilteredEntries(filter),
    );
  }

  /// 切换日志级别
  void toggleLevel(ConsoleLogLevel level) {
    setFilter(state.filter.toggleLevel(level));
  }

  /// 设置搜索关键词
  void setSearchText(String? text) {
    setFilter(state.filter.withSearch(text));
  }

  /// 设置来源过滤
  void setSource(String? source) {
    setFilter(state.filter.withSource(source));
  }

  /// 重置过滤条件
  void resetFilter() {
    setFilter(const LogFilter());
  }

  /// 切换暂停状态
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// 设置暂停状态
  void setPaused(bool paused) {
    state = state.copyWith(isPaused: paused);
  }

  /// 切换自动滚动
  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  /// 设置自动滚动
  void setAutoScroll(bool autoScroll) {
    state = state.copyWith(autoScroll: autoScroll);
  }

  /// 清空日志
  void clear() {
    _buffer.clear();
    state = const LogViewerState();
  }

  /// 导出日志为文本
  String exportLogs() {
    return _buffer.getAll().map((e) => e.toExportString()).join('\n');
  }

  /// 获取所有日志来源
  Set<String> getSources() {
    return _buffer.getAll().where((e) => e.source != null).map((e) => e.source!).toSet();
  }

  /// 更新状态（重新计算过滤和统计）
  void _updateState() {
    state = state.copyWith(
      entries: _getFilteredEntries(state.filter),
      stats: LogStats.fromEntries(_buffer.getAll()),
    );
  }

  /// 获取过滤后的日志列表
  List<LogEntry> _getFilteredEntries(LogFilter filter) {
    return _buffer.getAll().where(filter.matches).toList();
  }
}

/// 日志查看器 Provider
final logViewerProvider = StateNotifierProvider<LogViewerNotifier, LogViewerState>((ref) {
  return LogViewerNotifier();
});

/// 便捷访问：当前日志列表
final logEntriesProvider = Provider<List<LogEntry>>((ref) {
  return ref.watch(logViewerProvider).entries;
});

/// 便捷访问：当前过滤条件
final logFilterProvider = Provider<LogFilter>((ref) {
  return ref.watch(logViewerProvider).filter;
});

/// 便捷访问：是否暂停
final logIsPausedProvider = Provider<bool>((ref) {
  return ref.watch(logViewerProvider).isPaused;
});

/// 便捷访问：统计信息
final logStatsProvider = Provider<LogStats>((ref) {
  return ref.watch(logViewerProvider).stats;
});