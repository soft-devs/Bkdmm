# 已知坑点

## 1. read vs watch 使用错误

**问题**: 在事件处理中使用 `watch()` 导致不必要的重建。

**解决方案**:
- `ref.watch()` - 用于UI显示状态
- `ref.read()` - 用于事件处理/调用方法

```dart
// ❌ 错误 - 在按钮点击中使用watch
onPressed: () => ref.watch(projectNotifierProvider.notifier).saveProject()

// ✅ 正确
onPressed: () => ref.read(projectNotifierProvider.notifier).saveProject()

// ✅ 正确 - UI显示使用watch
final project = ref.watch(currentProjectProvider);
```

## 2. 异步操作未等待

**问题**: 保存操作是异步的，未等待就进行其他操作可能出错。

**解决方案**: 使用 `async/await` 等待操作完成。

```dart
// ❌ 错误
ref.read(projectNotifierProvider.notifier).saveProject();
Navigator.pop(context); // 可能保存未完成

// ✅ 正确
await ref.read(projectNotifierProvider.notifier).saveProject();
Navigator.pop(context);
```

## 3. 状态直接赋值

**问题**: 直接修改状态对象无效，Riverpod状态不可变。

**解决方案**: 必须通过Notifier的方法更新。

```dart
// ❌ 错误
ref.read(settingsProvider).themeMode = 'dark';

// ✅ 正确
ref.read(settingsProvider.notifier).setThemeMode('dark');
```

## 4. Provider依赖循环

**问题**: Provider之间相互依赖可能导致循环。

**解决方案**: 仔细设计依赖关系，必要时使用 `ref.read()` 延迟获取。

## 5. 项目设置继承逻辑

**问题**: 项目设置的可空字段表示"使用全局值"。

**解决方案**: 检查 `inheritXxx` 标志或检查字段是否为null。

```dart
// 判断实际使用的值
final actualDatabase = projectSettings.inheritDefaultDatabase
    ? globalSettings.defaultDatabase
    : projectSettings.defaultDatabase;
```

## 6. 监听状态变化

**问题**: 需要在状态变化时执行操作但不知道如何监听。

**解决方案**: 使用 `ref.listen()`。

```dart
ref.listen<ProjectState>(projectNotifierProvider, (prev, next) {
  if (next.error != null) {
    showErrorSnackBar(next.error);
  }
});
```

## 7. 自动保存时机

**问题**: 自动保存间隔为0时表示禁用，但代码中可能未正确处理。

**解决方案**: 检查 `autoSaveInterval > 0` 再启动自动保存。
