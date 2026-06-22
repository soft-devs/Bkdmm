import '../models/models.dart';
import 'storage_service.dart';

/// 历史记录服务 - 管理项目打开历史
class HistoryService {
  static const int maxHistoryCount = 20;

  /// 获取历史记录列表
  static List<ProjectHistory> getHistoryList() {
    final box = StorageService().historyBox;
    final list = box.values.toList();
    list.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return list;
  }

  /// 添加历史记录
  static Future<void> addHistory(ProjectHistory history) async {
    final box = StorageService().historyBox;

    // 检查是否已存在相同路径的记录
    final existingKey = box.keys.firstWhere(
      (key) => box.get(key)?.path == history.path,
      orElse: () => null,
    );

    // 删除旧记录
    if (existingKey != null) {
      await box.delete(existingKey);
    }

    // 添加新记录
    await box.add(history);

    // 限制历史记录数量
    if (box.length > maxHistoryCount) {
      final list = getHistoryList();
      // 删除最旧的记录
      for (var i = maxHistoryCount; i < list.length; i++) {
        final key = box.keys.firstWhere(
          (k) => box.get(k) == list[i],
          orElse: () => null,
        );
        if (key != null) {
          await box.delete(key);
        }
      }
    }
  }

  /// 删除历史记录
  static Future<void> removeHistory(String path) async {
    final box = StorageService().historyBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.path == path,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
    }
  }

  /// 清空所有历史记录
  static Future<void> clearHistory() async {
    await StorageService().historyBox.clear();
  }

  /// 检查历史记录是否存在
  static bool hasHistory(String path) {
    final box = StorageService().historyBox;
    return box.values.any((h) => h.path == path);
  }

  /// 更新历史记录的缩略图
  static Future<void> updateThumbnail(String path, String thumbnail) async {
    final box = StorageService().historyBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.path == path,
      orElse: () => null,
    );
    if (key != null) {
      final existing = box.get(key)!;
      await box.put(
        key,
        existing.copyWith(thumbnail: thumbnail),
      );
    }
  }
}