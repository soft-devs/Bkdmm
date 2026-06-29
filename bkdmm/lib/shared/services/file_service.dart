import 'dart:io';
import 'dart:convert';
import '../models/models.dart';

/// 数据迁移接口
abstract class DataMigration {
  /// 目标版本号
  String get version;

  /// 执行迁移
  Map<String, dynamic> migrate(Map<String, dynamic> data);
}

/// 文件服务 - 处理项目文件读写
class FileService {
  /// 已注册的数据迁移列表
  final List<DataMigration> _migrations = [];

  /// 注册数据迁移
  void registerMigration(DataMigration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => _compareVersion(a.version, b.version));
  }

  /// 读取项目文件
  Future<Project> readProject(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ProjectFileException('项目文件不存在: $filePath');
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 执行数据升级
      final upgradedJson = _upgradeData(json);

      return Project.fromJson(upgradedJson);
    } catch (e) {
      if (e is ProjectFileException) rethrow;
      throw ProjectFileException('读取项目失败: $e');
    }
  }

  /// 保存项目文件
  Future<void> saveProject(Project project, String filePath) async {
    try {
      final file = File(filePath);
      final json = project.toJson();

      // 更新时间戳
      json['updatedAt'] = DateTime.now().toIso8601String();

      // 确保目录存在
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
        mode: FileMode.writeOnly,
      );
    } catch (e) {
      throw ProjectFileException('保存项目失败: $e');
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  /// 删除文件
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 复制文件
  Future<void> copyFile(String source, String destination) async {
    await File(source).copy(destination);
  }

  /// 移动文件
  Future<void> moveFile(String source, String destination) async {
    await File(source).rename(destination);
  }

  /// 读取 JSON 文件
  Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ProjectFileException('文件不存在: $filePath');
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// 写入 JSON 文件
  Future<void> writeJsonFile(
    String filePath,
    Map<String, dynamic> data,
  ) async {
    final file = File(filePath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  /// 读取文本文件
  Future<String> readTextFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ProjectFileException('文件不存在: $filePath');
    }
    return await file.readAsString();
  }

  /// 写入文本文件
  Future<void> writeTextFile(String filePath, String content) async {
    final file = File(filePath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  /// 获取文件信息
  Future<FileInfo?> getFileInfo(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    final stat = await file.stat();
    return FileInfo(
      path: filePath,
      size: stat.size,
      modifiedTime: stat.modified,
      accessedTime: stat.accessed,
    );
  }

  /// 创建备份
  Future<String> createBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ProjectFileException('文件不存在: $filePath');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '$filePath.backup.$timestamp';
    await file.copy(backupPath);
    return backupPath;
  }

  /// 数据升级处理
  Map<String, dynamic> _upgradeData(Map<String, dynamic> data) {
    final currentVersion = data['version'] as String? ?? '1.0.0';
    var upgradedData = Map<String, dynamic>.from(data);

    // 执行所有需要的迁移
    for (final migration in _migrations) {
      if (_compareVersion(migration.version, currentVersion) > 0) {
        upgradedData = migration.migrate(upgradedData);
      }
    }

    // 更新版本号
    if (_migrations.isNotEmpty) {
      upgradedData['version'] = _migrations.last.version;
    }

    return upgradedData;
  }

  /// 比较版本号
  int _compareVersion(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }
}

/// 文件信息
class FileInfo {
  final String path;
  final int size;
  final DateTime modifiedTime;
  final DateTime accessedTime;

  FileInfo({
    required this.path,
    required this.size,
    required this.modifiedTime,
    required this.accessedTime,
  });
}

/// 项目文件异常
class ProjectFileException implements Exception {
  final String message;
  ProjectFileException(this.message);

  @override
  String toString() => 'ProjectFileException: $message';
}
