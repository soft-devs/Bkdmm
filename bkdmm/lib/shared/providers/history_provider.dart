import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';
import '../../shared/services/services.dart';

/// 历史记录列表 Provider
final historyListProvider = Provider<List<ProjectHistory>>((ref) {
  return HistoryService.getHistoryList();
});

/// 历史记录管理器
class HistoryNotifier extends StateNotifier<List<ProjectHistory>> {
  HistoryNotifier() : super(HistoryService.getHistoryList());

  /// 刷新历史记录
  void refresh() {
    state = HistoryService.getHistoryList();
  }

  /// 删除历史记录
  Future<void> remove(String path) async {
    await HistoryService.removeHistory(path);
    state = HistoryService.getHistoryList();
  }

  /// 清空所有历史记录
  Future<void> clear() async {
    await HistoryService.clearHistory();
    state = [];
  }
}

/// 历史记录管理 Provider
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, List<ProjectHistory>>((ref) {
  return HistoryNotifier();
});