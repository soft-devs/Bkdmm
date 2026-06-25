# shared/services - 服务层

## 概述

提供文件操作、本地存储、历史管理等核心服务。

## 服务清单

| 服务 | 文件 | 说明 |
|------|------|------|
| StorageService | storage_service.dart | Hive本地存储封装 |
| FileService | file_service.dart | 文件读写操作 |
| HistoryService | history_service.dart | 项目历史管理 |
| ProjectService | project_service.dart | 项目文件操作 |

## 核心服务详解

### StorageService

Hive本地存储封装，提供键值对持久化。

**主要方法**:
```dart
class StorageService {
  // 初始化Hive
  Future<void> init();

  // 存储操作
  Future<void> put(String key, dynamic value);
  dynamic get(String key);
  Future<void> delete(String key);
  Future<void> clear();

  // 盒子操作
  Box getBox(String name);
}
```

**使用场景**:
- 应用设置持久化
- 最近项目列表
- 用户偏好

### FileService

文件系统操作封装。

**主要方法**:
```dart
class FileService {
  // 文件操作
  Future<String?> readTextFile(String path);
  Future<void> writeTextFile(String path, String content);
  Future<bool> fileExists(String path);
  Future<void> deleteFile(String path);

  // 目录操作
  Future<String?> pickDirectory();
  Future<String?> pickFile({List<String>? extensions});
  Future<List<String>> listFiles(String directory);
}
```

**使用场景**:
- 项目文件读写
- 导入/导出文件
- 文件选择对话框

### HistoryService

项目打开历史管理。

**主要方法**:
```dart
class HistoryService {
  // 历史操作
  Future<List<ProjectHistory>> loadHistory();
  Future<void> addHistory(ProjectHistory history);
  Future<void> removeHistory(String path);
  Future<void> clearHistory();

  // 最近项目
  List<ProjectHistory> getRecent({int limit = 10});
}
```

### ProjectService

项目文件CRUD操作。

**主要方法**:
```dart
class ProjectService {
  // 项目操作
  Future<Project> createProject({required String name, required String path});
  Future<Project> loadProject(String path);
  Future<void> saveProject(Project project, String path);
  Future<void> deleteProject(String path);

  // 备份
  Future<void> createBackup(Project project);
  Future<Project?> restoreBackup(String path);
}
```

## 使用示例

```dart
// 注入服务
final storage = ref.read(storageServiceProvider);
final fileService = ref.read(fileServiceProvider);

// 存储数据
await storage.put('theme', 'dark');
final theme = storage.get('theme');

// 读取文件
final content = await fileService.readTextFile(projectPath);

// 添加历史
await historyService.addHistory(ProjectHistory(
  name: project.name,
  path: projectPath,
  lastOpened: DateTime.now(),
));
```

## 坑点

1. **Hive初始化**: 必须在 `main()` 中调用 `Hive.initFlutter()`
2. **路径处理**: Windows路径使用反斜杠，跨平台需用 `path` 包
3. **异步操作**: 所有文件操作都是异步的，需要await
4. **错误处理**: 文件可能不存在或权限不足，需要try-catch

## 详细文档

- [data-model.md](data-model.md) - 服务方法签名
- [pitfalls.md](pitfalls.md) - 已知坑点