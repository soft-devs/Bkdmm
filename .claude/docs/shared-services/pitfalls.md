# 坑点与注意事项

## 1. StorageService 初始化

**问题**: 必须在 main() 中调用 `StorageService.init()`，否则所有存储操作会失败。

```dart
// main.dart 正确顺序
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init(); // ✅ 必须先初始化
  runApp(MyApp());
}
```

## 2. 项目文件扩展名

**问题**: 项目文件扩展名是 `.bkdmm.json`，不是 `.json` 或 `.bkdmm`。

```dart
// 正确文件名
project.bkdmm.json

// FilePicker 配置
allowedExtensions: ['bkdmm.json']
```

## 3. Hive TypeAdapter 注册

**问题**: Hive 需要注册 TypeAdapter 才能存储自定义类型。

```dart
// StorageService 已注册 ProjectHistoryAdapter (typeId: 0)
// 新增自定义类型需要注册新 Adapter
Hive.registerAdapter(MyModelAdapter());
```

## 4. ProjectResult 状态判断

**问题**: ProjectResult 有三种状态：成功、失败、取消。

```dart
final result = await projectService.openProject();

if (result.success) {
  // 成功
} else if (result.cancelled) {
  // 用户取消（未选择文件）
} else {
  // 失败，查看 error
  print(result.error);
}
```

## 5. 历史记录数量限制

**问题**: 历史记录默认最大 20 条，超出会自动删除。

```dart
// 自定义最大数量
final projectService = ProjectService(maxHistoryCount: 50);
```

## 6. 项目保存时机

**问题**: 保存项目不会自动更新历史记录，需要通过 ProjectService 操作。

```dart
// 错误做法：直接保存文件
await fileService.saveProject(project, path);
// 历史记录不会更新

// 正确做法：通过 ProjectService
await projectService.saveProject(project, path);
// 历史记录会自动更新时间
```

## 7. 备份文件位置

**问题**: 备份文件在同一目录，文件名带时间戳。

```dart
// 原文件: project.bkdmm.json
// 备份: project_backup_2024-01-15_10-30-00.bkdmm.json
```

## 8. JSON 解析错误处理

**问题**: 项目文件损坏时 readProject 会抛出异常。

```dart
try {
  final project = await fileService.readProject(path);
} catch (e) {
  // 文件损坏或格式不兼容
  // 尝试从备份恢复
  final backupPath = fileService.getLatestBackup(path);
  if (backupPath != null) {
    final restored = await fileService.readProject(backupPath);
  }
}
```

## 9. 异步操作的并发

**问题**: Hive 的 Box 操作是异步的，避免同时读写同一 key。

```dart
// 避免这种情况
await storage.saveSetting('key', value1);
await storage.saveSetting('key', value2); // 可能覆盖

// 使用批量操作或等待完成
await storage.saveSetting('key', value1);
// 确保第一个写入完成后再执行第二个
```

## 10. StorageException 处理

**问题**: StorageService 操作可能抛出 StorageException。

```dart
try {
  final value = storage.getSetting<String>('key');
} on StorageException catch (e) {
  // 未初始化
  print(e.message); // "StorageService 未初始化"
}