# 已知坑点

## 1. 创建项目时重复点击

**问题**: 用户快速多次点击"新建项目"可能导致创建多个项目。

**解决方案**: 使用 `_isCreating` 状态锁定。

```dart
bool _isCreating = false;

Future<void> _showCreateProjectDialog() async {
  if (_isCreating) return;
  setState(() => _isCreating = true);
  try {
    // 创建项目逻辑
  } finally {
    setState(() => _isCreating = false);
  }
}
```

## 2. 历史项目文件丢失

**问题**: 历史记录中的文件可能已被删除或移动。

**解决方案**: 打开前检查文件是否存在。

```dart
final exists = await File(history.path).exists();
if (!exists) {
  // 提示用户文件不存在
  return;
}
```

## 3. 异步导航时机

**问题**: 项目创建/打开是异步的，可能在操作完成前导航。

**解决方案**: 使用 `mounted` 检查和 `async/await`。

```dart
Future<void> _openProjectAtPath(String path) async {
  setState(() => _isCreating = true);
  try {
    await ref.read(projectProvider.notifier).openProject(path);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(...));
    }
  } finally {
    if (mounted) {
      setState(() => _isCreating = false);
    }
  }
}
```