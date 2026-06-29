/// 日志过滤条件模型
///
/// 定义日志过滤的各种条件
library;

import 'log_entry.dart';

/// 日志过滤条件
class LogFilter {
  /// 允许的日志级别集合
  final Set<ConsoleLogLevel> levels;

  /// 搜索关键词
  final String? searchText;

  /// 日志来源过滤
  final String? source;

  /// 开始时间
  final DateTime? startTime;

  /// 结束时间
  final DateTime? endTime;

  const LogFilter({
    this.levels = const {
      ConsoleLogLevel.trace,
      ConsoleLogLevel.debug,
      ConsoleLogLevel.info,
      ConsoleLogLevel.warning,
      ConsoleLogLevel.error,
      ConsoleLogLevel.fatal,
    },
    this.searchText,
    this.source,
    this.startTime,
    this.endTime,
  });

  /// 默认过滤器（显示所有级别）
  static const LogFilter defaultFilter = LogFilter();

  /// 只显示错误和警告
  static const LogFilter errorsOnly = LogFilter(
    levels: {ConsoleLogLevel.error, ConsoleLogLevel.fatal},
  );

  /// 检查日志条目是否匹配过滤条件
  bool matches(LogEntry entry) {
    // 检查日志级别
    if (!levels.contains(entry.level)) {
      return false;
    }

    // 检查搜索关键词（在清理后的消息中搜索）
    if (searchText != null && searchText!.isNotEmpty) {
      if (!entry.cleanMessage.toLowerCase().contains(searchText!.toLowerCase())) {
        return false;
      }
    }

    // 检查来源
    if (source != null && source!.isNotEmpty) {
      if (entry.source != source) {
        return false;
      }
    }

    // 检查时间范围
    if (startTime != null && entry.timestamp.isBefore(startTime!)) {
      return false;
    }
    if (endTime != null && entry.timestamp.isAfter(endTime!)) {
      return false;
    }

    return true;
  }

  /// 复制并修改过滤条件
  LogFilter copyWith({
    Set<ConsoleLogLevel>? levels,
    String? searchText,
    String? source,
    DateTime? startTime,
    DateTime? endTime,
    bool clearSearchText = false,
    bool clearSource = false,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return LogFilter(
      levels: levels ?? this.levels,
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      source: clearSource ? null : (source ?? this.source),
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }

  /// 切换日志级别的包含状态
  LogFilter toggleLevel(ConsoleLogLevel level) {
    final newLevels = Set<ConsoleLogLevel>.from(levels);
    if (newLevels.contains(level)) {
      newLevels.remove(level);
    } else {
      newLevels.add(level);
    }
    return copyWith(levels: newLevels);
  }

  /// 设置搜索关键词
  LogFilter withSearch(String? text) {
    return copyWith(
      searchText: text,
      clearSearchText: text == null || text.isEmpty,
    );
  }

  /// 设置来源过滤
  LogFilter withSource(String? source) {
    return copyWith(
      source: source,
      clearSource: source == null || source.isEmpty,
    );
  }

  /// 重置为默认过滤条件
  LogFilter reset() {
    return const LogFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LogFilter) return false;

    // 比较级别集合
    if (levels.length != other.levels.length) return false;
    if (!levels.containsAll(other.levels)) return false;

    // 比较其他字段
    return searchText == other.searchText &&
        source == other.source &&
        startTime == other.startTime &&
        endTime == other.endTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(levels),
      searchText,
      source,
      startTime,
      endTime,
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (levels.length != ConsoleLogLevel.values.length) {
      parts.add('levels: ${levels.map((l) => l.label).join(',')}');
    }
    if (searchText != null) {
      parts.add('search: "$searchText"');
    }
    if (source != null) {
      parts.add('source: "$source"');
    }
    if (startTime != null || endTime != null) {
      parts.add('time: $startTime - $endTime');
    }
    return 'LogFilter(${parts.isEmpty ? 'all' : parts.join(', ')})';
  }
}

/// 日志统计信息
class LogStats {
  /// 各级别日志数量
  final Map<ConsoleLogLevel, int> counts;

  const LogStats(this.counts);

  /// 空统计
  static const LogStats empty = LogStats({});

  /// 获取指定级别的数量
  int count(ConsoleLogLevel level) => counts[level] ?? 0;

  /// 获取总数量
  int get total => counts.values.fold(0, (sum, c) => sum + c);

  /// 从日志列表计算统计
  static LogStats fromEntries(List<LogEntry> entries) {
    final counts = <ConsoleLogLevel, int>{};
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return LogStats(counts);
  }

  @override
  String toString() {
    return 'LogStats(total: $total, ${counts.entries.map((e) => '${e.key.label}: ${e.value}').join(', ')})';
  }
}
