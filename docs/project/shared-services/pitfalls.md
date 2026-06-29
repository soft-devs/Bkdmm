# 已知坑点

## 1. Hive初始化时机

**问题**: 未初始化Hive就调用存储方法会报错。

**解决方案**: 在 `main()` 中初始化。

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const App());
}
```

## 2. 文件路径处理

**问题**: Windows路径使用反斜杠 `\`，在不同平台可能出问题。

**解决方案**: 使用 `path` 包处理。

```dart
import 'package:path/path.dart' as p;

final normalized = p.join(dir, 'file.json');
```

## 3. 文件不存在错误

**问题**: 读取不存在的文件会抛出异常。

**解决方案**: 先检查文件存在或捕获异常。

```dart
// 方式1: 先检查
if (await fileService.fileExists(path)) {
  final content = await fileService.readTextFile(path);
}

// 方式2: 捕获异常
try {
  final content = await fileService.readTextFile(path);
} catch (e) {
  // 文件不存在或无法读取
}
```

## 4. 异步操作未等待

**问题**: 服务方法都是异步的，未等待可能导致数据不一致。

**解决方案**: 使用 `await` 等待完成。

```dart
// ❌ 错误
storage.put('key', value);
final result = storage.get('key'); // 可能还没写入

// ✅ 正确
await storage.put('key', value);
final result = storage.get('key');
```

## 5. 项目JSON格式兼容性

**问题**: 项目文件格式变更后旧文件无法加载。

**解决方案**: 使用版本字段和数据迁移。

```dart
if (projectVersion < currentVersion) {
  project = migrateProject(project);
}
```

## 6. 历史记录容量限制

**问题**: 历史记录无限增长可能影响性能。

**解决方案**: 设置最大历史数量。

```dart
if (history.length > MAX_HISTORY) {
  history = history.sublist(0, MAX_HISTORY);
}
```