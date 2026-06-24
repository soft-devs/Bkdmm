# shared/services - 服务层

核心服务实现，提供存储、文件操作、历史记录等功能。

## 概述

该模块提供底层服务实现，所有服务使用单例模式或静态方法。

## 服务列表

| 服务 | 文件 | 说明 |
|------|------|------|
| StorageService | storage_service.dart | Hive 本地存储服务 |
| FileService | file_service.dart | 文件读写服务 |
| HistoryService | history_service.dart | 项目历史记录服务 |
| ProjectService | project_service.dart | 项目文件操作服务 |

## StorageService

基于 Hive 的本地存储服务。

### 初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();  // 必须先初始化
  runApp(const BkdmmApp());
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `static Future<void> init()` | 初始化 Hive |
| `static Future<void> put<T>(String key, T value)` | 存储数据 |
| `static T? get<T>(String key)` | 获取数据 |
| `static Future<void> delete(String key)` | 删除数据 |
| `static Future<void> clear()` | 清空所有数据 |

### 存储键

| 键 | 类型 | 说明 |
|------|------|------|
| `settings` | Settings | 应用设置 |
| `project_history` | List<ProjectHistory> | 项目历史 |

## FileService

文件读写服务，处理项目文件的导入导出。

### 主要方法

| 方法 | 说明 |
|------|------|
| `static Future<String?> pickProjectFile()` | 选择项目文件 |
| `static Future<String?> pickProjectSavePath()` | 选择保存路径 |
| `static Future<Project?> readProject(String path)` | 读取项目文件 |
| `static Future<void> writeProject(Project project, String path)` | 写入项目文件 |
| `static Future<bool> exists(String path)` | 检查文件是否存在 |
| `static Future<void> delete(String path)` | 删除文件 |

### 文件格式

项目文件使用 `.bkdmm` 扩展名，内容为 JSON 格式：

```json
{
  "id": "xxx",
  "name": "My Project",
  "version": "1.0.0",
  "modules": [...],
  "dataTypeDomains": {...},
  "profile": {...}
}
```

## HistoryService

项目历史记录管理。

### 主要方法

| 方法 | 说明 |
|------|------|
| `static Future<List<ProjectHistory>> load()` | 加载历史记录 |
| `static Future<void> add(ProjectHistory history)` | 添加历史记录 |
| `static Future<void> remove(String projectId)` | 删除历史记录 |
| `static Future<void> clear()` | 清空历史记录 |

### 历史记录结构

```dart
class ProjectHistory {
  final String projectId;
  final String projectName;
  final String projectPath;
  final DateTime lastOpened;
}
```

## ProjectService

项目业务逻辑封装。

### 主要方法

| 方法 | 说明 |
|------|------|
| `static Project createProject({...})` | 创建新项目 |
| `static Module createModule({...})` | 创建新模块 |
| `static Entity createEntity({...})` | 创建新实体 |
| `static Future<void> save(Project project, String path)` | 保存项目 |
| `static Future<Project> open(String path)` | 打开项目 |

## 注意事项

1. **初始化顺序** - 必须先调用 `StorageService.init()` 才能使用其他服务
2. **文件路径** - Windows 使用反斜杠 `\`，需要正确处理路径分隔符
3. **异步操作** - 所有文件操作都是异步的，需使用 `await`
4. **错误处理** - 文件操作可能抛出异常，需使用 `try-catch` 处理
5. **存储位置** - Hive 数据存储在系统应用数据目录
