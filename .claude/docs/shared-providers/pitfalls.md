# 坑点与注意事项

## 1. Provider 初始化顺序

**问题**: StorageService 必须在 main() 中初始化，否则 settingsProvider 会失败。

```dart
// main.dart 正确顺序
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 必须先初始化存储服务
  await StorageService.init();
  
  runApp(ProviderScope(child: BkdmmApp()));
}
```

## 2. read vs watch 的选择

**问题**: 在回调函数中使用 watch 会导致不必要的重建。

```dart
// 正确用法：在回调中使用 read
void onSavePressed(WidgetRef ref) {
  ref.read(settingsProvider.notifier).saveSettings();
}

// 错误用法：在回调中使用 watch
void onSavePressed(WidgetRef ref) {
  final settings = ref.watch(settingsProvider); // ❌ 不必要
  ref.read(settingsProvider.notifier).saveSettings();
}

// 正确用法：在 build 方法中使用 watch
Widget build(BuildContext context, WidgetRef ref) {
  final settings = ref.watch(settingsProvider); // ✅ 正确
  return Text(settings.themeMode);
}
```

## 3. 项目设置的继承机制

**问题**: 项目设置可以继承全局设置，需要使用 effective Provider。

```dart
// 错误做法：直接使用项目设置
final projectSettings = ref.watch(projectSettingsProvider);
final revision = projectSettings?.defaultFieldsRevision; // ❌ 可能为 null

// 正确做法：使用 effective Provider
final effective = ref.watch(effectiveDefaultFieldsProvider);
final revision = effective.revision; // ✅ 总是有值
```

## 4. accentColor 的存储格式

**问题**: accentColor 存储为 32 位整数，需要转换。

```dart
// 设置颜色
ref.read(settingsProvider.notifier).setAccentColor(Colors.blue);

// 内部转换
state.copyWith(accentColor: color.toARGB32()); // 存储

// 读取颜色
final color = ref.watch(accentColorProvider); // 自动转换回 Color
```

## 5. autoSaveInterval = 0 表示禁用

**问题**: autoSaveInterval 为 0 时表示禁用自动保存，不是间隔为 0 秒。

```dart
if (settings.autoSaveInterval > 0) {
  // 启用自动保存
  scheduleAutoSave(settings.autoSaveInterval);
} else {
  // 禁用自动保存
}
```

## 6. projectSettingsProvider 的生命周期

**问题**: projectSettingsProvider 在项目打开时加载，关闭时清除。

```dart
// 打开项目时
ref.read(projectSettingsProvider.notifier).loadFromProject(project);

// 关闭项目时
ref.read(projectSettingsProvider.notifier).clear();

// 检查是否有效
final hasSettings = ref.watch(hasProjectSettingsProvider);
```

## 7. 设置变更自动保存

**问题**: 所有设置变更方法都是异步的，会自动保存到存储。

```dart
// 设置变更会自动保存
await ref.read(settingsProvider.notifier).setThemeMode('dark');

// 不需要额外调用保存方法
// ref.read(settingsProvider.notifier).saveSettings(); // ❌ 不存在
```

## 8. StateNotifier 的 state 直接访问

**问题**: StateNotifier.state 是当前值，但不会触发重建。

```dart
// 在 Notifier 内部访问 state
class SettingsNotifier extends StateNotifier<SettingsState> {
  void someMethod() {
    final current = state; // ✅ 正确
    state = state.copyWith(themeMode: 'dark');
  }
}

// 在 Widget 中应该使用 ref.watch
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(settingsProvider); // ✅ 正确
  // final state = ref.read(settingsProvider.notifier).state; // ❌ 不触发重建
}
```

## 9. Provider 的依赖关系

**问题**: projectSettingsProvider 依赖 projectNotifierProvider。

```dart
// projectSettingsProvider 内部使用
projectNotifier.updateProject(updatedProject);

// 确保项目已打开
if (ref.read(currentProjectProvider) == null) {
  // 无法保存项目设置
  return;
}
```

## 10. 从 Profile 加载项目设置

**问题**: 项目设置存储在 Project.profile.settings 中。

```dart
// 加载时从 Profile 创建
final settings = ProjectSettingsState.fromProfile(
  project.id,
  project.profile.settings,
);

// 保存时更新 Profile
final updatedProfile = currentProject.profile.copyWith(
  settings: state!.toStorageMap(),
);
```