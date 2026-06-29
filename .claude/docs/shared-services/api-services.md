# API 文档

## StorageService - 存储服务

基于 Hive 的高性能本地存储服务。

### 静态方法

| 方法 | 描述 |
|------|------|
| `init()` | 初始化存储服务（必须在main()中调用） |
| `isInitialized` | 检查是否已初始化 |

### 实例方法

| 方法 | 描述 |
|------|------|
| `historyBox` | 获取历史记录盒子 |
| `settingsBox` | 获取设置盒子 |
| `saveSetting(key, value)` | 保存设置 |
| `getSetting<T>(key, defaultValue)` | 获取设置 |
| `deleteSetting(key)` | 删除设置 |
| `clearAll()` | 清除所有数据 |
| `close()` | 关闭所有盒子 |

### 使用示例

```dart
// 初始化（main.dart）
await StorageService.init();

// 获取服务实例
final storage = StorageService();

// 保存设置
await storage.saveSetting('theme_mode', 'dark');

// 获取设置
final theme = storage.getSetting<String>('theme_mode', defaultValue: 'system');

// 清除数据
await storage.clearAll();
```

## FileService - 文件服务

项目文件读写服务。

### 方法

| 方法 | 描述 |
|------|------|
| `saveProject(project, path)` | 保存项目到文件 |
| `readProject(path)` | 从文件读取项目 |
| `fileExists(path)` | 检查文件是否存在 |
| `createBackup(path)` | 创建备份文件 |
| `getProjectFileName(path)` | 获取项目文件名 |

### 项目文件格式

```json
{
  "id": "uuid",
  "name": "项目名称",
  "version": "1.0.0",
  "modules": [...],
  "dataTypeDomains": {...},
  "profile": {...}
}
```

### 使用示例

```dart
final fileService = FileService();

// 保存项目
await fileService.saveProject(project, '/path/to/project.bkdmm.json');

// 读取项目
final project = await fileService.readProject('/path/to/project.bkdmm.json');

// 创建备份
final backupPath = await fileService.createBackup('/path/to/project.bkdmm.json');
```

## ProjectService - 项目服务

整合项目操作的统一入口。

### 方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `createProject(name, description, filePath)` | `ProjectResult` | 创建新项目 |
| `openProject(filePath)` | `ProjectResult` | 打开项目 |
| `saveProject(project, filePath)` | `ProjectResult` | 保存项目 |
| `saveProjectAs(project, filePath)` | `ProjectResult` | 另存为 |
| `createBackup(filePath)` | `String?` | 创建备份 |
| `getHistoryList()` | `List<ProjectHistory>` | 获取历史记录 |
| `removeHistory(path)` | `Future<void>` | 删除历史记录 |
| `clearHistory()` | `Future<void>` | 清空历史记录 |
| `validateProject(filePath)` | `ProjectValidationResult` | 验证项目文件 |
| `getStatistics(project)` | `ProjectStatistics` | 获取项目统计 |

### ProjectResult

```dart
class ProjectResult {
  final bool success;      // 是否成功
  final bool cancelled;    // 是否取消
  final Project? project;  // 项目对象
  final String? path;      // 文件路径
  final String? error;     // 错误信息
}
```

### 使用示例

```dart
final projectService = ProjectService();

// 创建项目
final result = await projectService.createProject(name: 'MyProject');
if (result.success) {
  print('创建成功: ${result.path}');
}

// 打开项目
final openResult = await projectService.openProject();
if (openResult.success) {
  final project = openResult.project!;
}

// 保存项目
await projectService.saveProject(project, filePath);

// 获取统计
final stats = projectService.getStatistics(project);
print('模块: ${stats.moduleCount}, 表: ${stats.entityCount}');
```

## HistoryService - 历史记录服务

项目历史记录管理。

### 静态方法

| 方法 | 描述 |
|------|------|
| `addHistory(history)` | 添加历史记录 |
| `getHistoryList()` | 获取历史记录列表 |
| `removeHistory(path)` | 删除指定历史 |
| `clearHistory()` | 清空历史记录 |
| `hasHistory(path)` | 检查历史是否存在 |
| `updateThumbnail(path, thumbnail)` | 更新缩略图 |

### 使用示例

```dart
// 添加历史
await HistoryService.addHistory(ProjectHistory(
  path: '/path/to/project.bkdmm.json',
  name: 'MyProject',
  lastOpenedAt: DateTime.now(),
));

// 获取列表
final history = HistoryService.getHistoryList();
for (final h in history) {
  print('${h.name} - ${h.lastOpenedAt}');
}
```