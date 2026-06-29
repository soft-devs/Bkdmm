# 服务方法签名

## StorageService

```dart
Future<void> init()                    // 初始化Hive存储
Future<void> put(String key, dynamic value)  // 存储键值
dynamic get(String key)                // 获取值
Future<void> delete(String key)        // 删除键
Future<void> clear()                   // 清空所有
Box getBox(String name)                // 获取指定盒子
```

## FileService

```dart
Future<String?> readTextFile(String path)     // 读取文本文件
Future<void> writeTextFile(String path, String content)  // 写入文件
Future<bool> fileExists(String path)          // 检查文件存在
Future<void> deleteFile(String path)          // 删除文件
Future<String?> pickDirectory()               // 选择目录
Future<String?> pickFile({List<String>? extensions})  // 选择文件
Future<List<String>> listFiles(String directory)  // 列出文件
```

## HistoryService

```dart
Future<List<ProjectHistory>> loadHistory()    // 加载历史
Future<void> addHistory(ProjectHistory history)  // 添加历史
Future<void> removeHistory(String path)       // 删除历史
Future<void> clearHistory()                   // 清空历史
List<ProjectHistory> getRecent({int limit = 10})  // 获取最近项目
```

## ProjectService

```dart
Future<Project> createProject({
  required String name,
  String? description,
  required String path,
})  // 创建项目

Future<Project> loadProject(String path)      // 加载项目
Future<void> saveProject(Project project, String path)  // 保存项目
Future<void> deleteProject(String path)       // 删除项目
Future<void> createBackup(Project project)    // 创建备份
Future<Project?> restoreBackup(String path)   // 恢复备份
```