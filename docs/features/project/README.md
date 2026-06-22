# 项目管理功能

> **阅读时机**: 开发项目创建、打开、保存、历史记录功能时

---

## 功能概述

项目管理模块负责：
- 创建新项目
- 打开现有项目
- 保存项目文件
- 管理项目历史记录
- 项目数据升级迁移

---

## Flutter 实现方案

### 文件选择

使用 `file_picker` 包：

```dart
// lib/features/project/services/project_service.dart

import 'package:file_picker/file_picker.dart';

class ProjectService {
  // 选择项目文件
  Future<String?> pickProjectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: '打开项目',
    );
    
    return result?.files.first.path;
  }
  
  // 创建新项目文件
  Future<String?> createNewProject() async {
    final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: '创建新项目',
      fileName: 'project.bkdmm.json',
    );
    
    return result;
  }
}
```

### 项目文件读写

```dart
// lib/features/project/services/project_file_service.dart

import 'dart:io';
import 'dart:convert';

class ProjectFileService {
  /// 读取项目文件
  Future<Project> readProject(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ProjectException('项目文件不存在');
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // 数据升级检查
      final upgradedJson = await _upgradeData(json);
      
      return Project.fromJson(upgradedJson);
    } catch (e) {
      throw ProjectException('读取项目失败: $e');
    }
  }
  
  /// 保存项目文件
  Future<void> saveProject(Project project, String filePath) async {
    try {
      final file = File(filePath);
      final json = project.toJson();
      
      // 添加更新时间
      json['updatedAt'] = DateTime.now().toIso8601String();
      
      await file.writeAsString(
        jsonEncode(json),
        mode: FileMode.writeOnly,
      );
    } catch (e) {
      throw ProjectException('保存项目失败: $e');
    }
  }
  
  /// 数据升级
  Future<Map<String, dynamic>> _upgradeData(Map<String, dynamic> data) async {
    final currentVersion = data['version'] ?? '1.0.0';
    var upgradedData = data;
    
    // 检查并执行迁移
    for (final migration in migrations) {
      if (_compareVersion(migration.version, currentVersion) > 0) {
        upgradedData = migration.migrate(upgradedData);
      }
    }
    
    upgradedData['version'] = migrations.last.version;
    return upgradedData;
  }
}
```

---

## 项目历史记录

```dart
// lib/features/project/models/project_history.dart

class ProjectHistory {
  final String path;
  final String name;
  final DateTime lastOpenedAt;
  final String? thumbnail;            // 缩略图 Base64
}

// lib/features/project/services/history_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class HistoryService {
  static const int maxHistoryCount = 20;
  static late Box<ProjectHistory> _box;
  
  static Future<void> init() async {
    _box = await Hive.openBox<ProjectHistory>('project_history');
  }
  
  /// 获取历史记录列表
  List<ProjectHistory> getHistoryList() {
    return _box.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  }
  
  /// 添加历史记录
  Future<void> addHistory(ProjectHistory history) async {
    // 检查是否已存在
    final existing = _box.values.firstWhere(
      (h) => h.path == history.path,
      orElse: () => null,
    );
    
    if (existing != null) {
      await _box.delete(existing.key);
    }
    
    await _box.add(history);
    
    // 限制历史记录数量
    if (_box.length > maxHistoryCount) {
      final oldest = getHistoryList().last;
      await _box.delete(oldest.key);
    }
  }
  
  /// 删除历史记录
  Future<void> removeHistory(String path) async {
    final history = _box.values.firstWhere(
      (h) => h.path == path,
      orElse: () => null,
    );
    if (history != null) {
      await _box.delete(history.key);
    }
  }
  
  /// 清空历史记录
  Future<void> clearHistory() async {
    await _box.clear();
  }
}
```

---

## 状态管理 (Riverpod + Freezed)

### 安装依赖

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
```

### 数据模型 (使用 Freezed)

```dart
// lib/features/project/models/project_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'project_state.freezed.dart';

@freezed
class ProjectState with _$ProjectState {
  const factory ProjectState({
    Project? project,
    String? projectPath,
    @Default(false) bool isDirty,
    @Default(false) bool isLoading,
    String? error,
  }) = _ProjectState;
}

@freezed
class ProjectHistory with _$ProjectHistory {
  const factory ProjectHistory({
    required String path,
    required String name,
    required DateTime lastOpenedAt,
    String? thumbnail,
  }) = _ProjectHistory;
}
```

### Provider 定义 (使用 riverpod_generator)

```dart
// lib/features/project/providers/project_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_provider.g.dart';

@riverpod
class ProjectNotifier extends _$ProjectNotifier {
  @override
  ProjectState build() {
    return const ProjectState();
  }

  /// 打开项目
  Future<void> openProject(String? path) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final filePath = path ?? await ref.read(projectServiceProvider).pickProjectFile();
      if (filePath == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final project = await ref.read(projectServiceProvider).readProject(filePath);

      // 添加到历史记录
      await ref.read(historyServiceProvider.notifier).addHistory(
        ProjectHistory(
          path: filePath,
          name: project.name,
          lastOpenedAt: DateTime.now(),
        ),
      );

      state = ProjectState(
        project: project,
        projectPath: filePath,
        isDirty: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 保存项目
  Future<void> saveProject() async {
    if (state.project == null || state.projectPath == null) return;

    try {
      await ref.read(projectServiceProvider).saveProject(
        state.project!,
        state.projectPath!,
      );
      state = state.copyWith(isDirty: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新项目数据
  void updateProject(Project project) {
    state = state.copyWith(
      project: project,
      isDirty: true,
    );
  }

  /// 关闭项目
  void closeProject() {
    state = const ProjectState();
  }
}

@riverpod
Project? project(ProjectRef ref) {
  return ref.watch(projectNotifierProvider).project;
}

@riverpod
bool isDirty(IsDirtyRef ref) {
  return ref.watch(projectNotifierProvider).isDirty;
}
```

### 项目历史 Provider

```dart
// lib/features/project/providers/history_provider.dart

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  static const int maxHistoryCount = 20;

  @override
  List<ProjectHistory> build() {
    _loadFromStorage();
    return [];
  }

  Future<void> _loadFromStorage() async {
    final box = await Hive.openBox<ProjectHistory>('project_history');
    state = box.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  }

  Future<void> addHistory(ProjectHistory history) async {
    final box = await Hive.openBox<ProjectHistory>('project_history');

    // 检查是否已存在
    final existingKey = state.indexWhere((h) => h.path == history.path);
    if (existingKey >= 0) {
      await box.deleteAt(existingKey);
    }

    await box.add(history);

    // 更新状态
    state = [...state.where((h) => h.path != history.path), history]
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    // 限制历史记录数量
    if (state.length > maxHistoryCount) {
      await box.deleteAt(state.length - 1);
      state = state.take(maxHistoryCount).toList();
    }
  }

  Future<void> removeHistory(String path) async {
    final box = await Hive.openBox<ProjectHistory>('project_history');
    final index = state.indexWhere((h) => h.path == path);
    if (index >= 0) {
      await box.deleteAt(index);
      state = state.where((h) => h.path != path).toList();
    }
  }

  Future<void> clearHistory() async {
    final box = await Hive.openBox<ProjectHistory>('project_history');
    await box.clear();
    state = [];
  }
}
```

---

## UI 组件

### 首页视图

```dart
// lib/features/project/views/home_view.dart

class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyListProvider);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 和标题
            _buildHeader(),
            
            SizedBox(height: 32),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('新建项目'),
                  onPressed: () => _createProject(context, ref),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.folder_open),
                  label: Text('打开项目'),
                  onPressed: () => ref.read(currentProjectProvider.notifier).openProject(),
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            // 历史记录列表
            if (historyList.isNotEmpty) _buildHistoryList(context, ref, historyList),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryList(BuildContext context, WidgetRef ref, List<ProjectHistory> history) {
    return Container(
      width: 400,
      child: Card(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              leading: Icon(Icons.history),
              title: Text(item.name),
              subtitle: Text(item.path),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => ref.read(historyServiceProvider).removeHistory(item.path),
              ),
              onTap: () => ref.read(currentProjectProvider.notifier).openProject(item.path),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 数据升级机制

```dart
// lib/features/project/services/data_migration.dart

class Migration {
  final String version;
  final Map<String, dynamic> Function(Map<String, dynamic>) migrate;
}

final migrations = [
  Migration(
    version: '1.0.0',
    migrate: (data) => data,           // 初始版本
  ),
  Migration(
    version: '1.1.0',
    migrate: (data) {
      // 添加新字段
      if (!data.containsKey('profile')) {
        data['profile'] = {
          'defaultFields': [],
          'defaultFieldsType': '1',
        };
      }
      return data;
    },
  ),
  Migration(
    version: '1.2.0',
    migrate: (data) {
      // 添加 id 字段
      for (final module in data['modules'] as List) {
        if (!module.containsKey('id')) {
          module['id'] = _generateId();
        }
        for (final entity in module['entities'] as List) {
          if (!entity.containsKey('id')) {
            entity['id'] = _generateId();
          }
        }
      }
      return data;
    },
  ),
];
```

---

## 相关文档

- [数据模型设计](../../data-model/README.md)
- [开发环境配置](../../dev-setup/README.md)