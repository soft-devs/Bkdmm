import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// 存储服务 - 基于 Hive 的高性能本地存储
class StorageService {
  static const String _projectHistoryBoxName = 'project_history';
  static const String _settingsBoxName = 'settings';

  static Box<ProjectHistory>? _historyBox;
  static Box<dynamic>? _settingsBox;
  static bool _initialized = false;

  /// 初始化存储服务
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectHistoryAdapter());
    }

    // 打开盒子
    _historyBox = await Hive.openBox<ProjectHistory>(_projectHistoryBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    _initialized = true;
  }

  /// 确保已初始化
  static void _ensureInitialized() {
    if (!_initialized || _historyBox == null || _settingsBox == null) {
      throw StorageException('StorageService 未初始化，请先调用 StorageService.init()');
    }
  }

  /// 获取历史记录盒子
  Box<ProjectHistory> get historyBox {
    _ensureInitialized();
    return _historyBox!;
  }

  /// 获取设置盒子
  Box<dynamic> get settingsBox {
    _ensureInitialized();
    return _settingsBox!;
  }

  /// 保存设置
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// 获取设置
  T? getSetting<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    await _settingsBox!.delete(key);
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    _ensureInitialized();
    await _historyBox!.clear();
    await _settingsBox!.clear();
  }

  /// 关闭所有盒子
  Future<void> close() async {
    if (_historyBox != null && _historyBox!.isOpen) {
      await _historyBox!.close();
    }
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.close();
    }
    _initialized = false;
  }

  /// 检查是否已初始化
  static bool get isInitialized => _initialized;
}

/// 存储异常
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

/// Hive 类型适配器 - ProjectHistory
class ProjectHistoryAdapter extends TypeAdapter<ProjectHistory> {
  @override
  final int typeId = 0;

  @override
  ProjectHistory read(BinaryReader reader) {
    final path = reader.readString();
    final name = reader.readString();
    final lastOpenedAt = DateTime.parse(reader.readString());
    final thumbnailStr = reader.readString();
    return ProjectHistory(
      path: path,
      name: name,
      lastOpenedAt: lastOpenedAt,
      thumbnail: thumbnailStr.isEmpty ? null : thumbnailStr,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectHistory obj) {
    writer.writeString(obj.path);
    writer.writeString(obj.name);
    writer.writeString(obj.lastOpenedAt.toIso8601String());
    writer.writeString(obj.thumbnail ?? '');
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
