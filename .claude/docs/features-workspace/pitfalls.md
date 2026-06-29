# Workspace 模块坑点文档

## 1. 标签页 ID 生成策略

**问题描述**: TabNotifier 使用 `_generateId()` 方法生成标签 ID，格式为 `tab_${timestamp}_${counter}`。如果需要在应用重启后恢复标签页状态，需要确保 ID 的一致性。

**解决方案**:
- 标签页使用固定的语义化 ID（如 `entity_${entityId}`、`module_${moduleId}`）
- `openEntity` 和 `openModule` 方法已经使用语义化 ID，可直接通过 ID 查找已存在的标签

```dart
// 正确做法 - 使用语义化 ID
void openEntity(Entity entity, String moduleId) {
  final tabId = 'entity_${entity.id}';  // 固定 ID
  final tab = WorkspaceTab.forEntity(id: tabId, entity: entity, moduleId: moduleId);
  openTab(tab);
}
```

---

## 2. 布局状态 copyWith 的 clearActiveLeftView/clearActiveBottomView 参数

**问题描述**: LayoutState.copyWith 方法使用特殊的布尔参数来清除激活状态，而不是接受 null 值。这是因为 Dart 不支持区分 "未传递参数" 和 "传递 null"。

**解决方案**: 使用 `clearActiveLeftView: true` 或 `clearActiveBottomView: true` 来清除激活状态。

```dart
// 错误做法
state = state.copyWith(activeLeftView: null);  // 不会清除，保持原值

// 正确做法
state = state.copyWith(clearActiveLeftView: true);  // 清除激活状态
```

---

## 3. 模块树展开状态管理

**问题描述**: ModuleTree 组件的展开状态 `_expandedModules` 是本地状态，不会持久化。如果模块数据变化（如新增模块），需要手动处理展开状态。

**解决方案**: 在 `didUpdateWidget` 中检查新模块并自动展开。

```dart
@override
void didUpdateWidget(ModuleTree oldWidget) {
  super.didUpdateWidget(oldWidget);
  // 自动展开新模块
  for (final module in widget.project.modules) {
    if (!_expandedModules.contains(module.id)) {
      _expandedModules.add(module.id);
    }
  }
}
```

---

## 4. 标签页关闭时的激活标签选择逻辑

**问题描述**: 关闭当前激活的标签时，需要选择新的激活标签。TabNotifier.closeTab 的选择逻辑是：优先选择同位置的下一个标签，如果是最后一个标签则选择前一个。

**注意事项**:
- 关闭唯一标签后 `activeTabId` 变为 null
- 关闭非激活标签不会改变 `activeTabId`

```dart
void closeTab(String tabId) {
  // ... 移除标签 ...
  if (state.activeTabId == tabId) {
    if (newTabs.isEmpty) {
      newActiveTabId = null;
    } else if (tabIndex >= newTabs.length) {
      newActiveTabId = newTabs.last.id;  // 选择前一个
    } else {
      newActiveTabId = newTabs[tabIndex].id;  // 选择同位置
    }
  }
}
```

---

## 5. 视图可见性的双重判断

**问题描述**: LayoutState.isLeftViewVisible 和 isBottomViewVisible 方法需要同时检查 `activeView == viewId` 和 `visibility[viewId]`。仅检查其中一个可能导致视图状态不一致。

**解决方案**: 始终使用 LayoutState 提供的辅助方法，不要直接访问 visibility 映射。

```dart
// 错误做法
if (layoutState.leftViewVisibility['module_tree'] == true) { ... }

// 正确做法
if (layoutState.isLeftViewVisible('module_tree')) { ... }
```

---

## 6. 快捷键处理使用 HardwareKeyboard

**问题描述**: Flutter 3.10+ 废弃了 RawKeyboard，推荐使用 HardwareKeyboard。WorkspaceShortcuts 使用 HardwareKeyboard 检查修饰键状态。

**注意事项**:
- `HardwareKeyboard.instance.isAltPressed` 检查 Alt 键状态
- `HardwareKeyboard.instance.isControlPressed` 检查 Ctrl 键状态
- 需要在 Focus 组件的 onKeyEvent 中处理

```dart
return Focus(
  autofocus: true,
  onKeyEvent: (node, event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final hardwareKeyboard = HardwareKeyboard.instance;
    if (hardwareKeyboard.isAltPressed) {
      // 处理 Alt 组合快捷键
    }
    return KeyEventResult.ignored;
  },
  child: child,
);
```

---

## 7. TabState 的持久化存储键

**问题描述**: TabNotifier 使用固定的存储键 `'workspace_tabs'` 来持久化标签状态。如果需要区分不同项目的标签状态，需要修改存储策略。

**注意事项**:
- 当前实现是全局存储，不区分项目
- 切换项目后可能显示上一个项目的标签

**改进方案**: 将存储键改为项目相关，如 `'workspace_tabs_${projectId}'`

---

## 8. LeftViewContainer 的拖拽调整宽度

**问题描述**: LeftViewContainer 使用 GestureDetector 的 onHorizontalDragUpdate 来调整宽度，但整个容器都是可拖拽区域，可能与内部滚动组件冲突。

**解决方案**:
- 在容器右边缘添加专用的拖拽手柄
- 或在标题栏添加拖拽响应区域

**当前实现**: 整个容器响应拖拽，宽度限制在 200-400 之间。

```dart
onHorizontalDragUpdate: (details) {
  final newWidth = ref.read(layoutProvider).leftViewWidth + details.delta.dx;
  ref.read(layoutProvider.notifier).setLeftViewWidth(newWidth);
},
```

---

## 9. ModuleTreeItem 的 tdTheme 参数传递

**问题描述**: ModuleTreeItem 和 EntityTreeItem 需要显式传递 tdTheme 参数，而不是在内部使用 TDTheme.of(context)。这是因为 TDesign 的主题获取需要在 build 方法内进行，而 StatelessWidget 的 build 方法不支持传递额外参数。

**注意事项**:
- 在父组件中获取 tdTheme 并传递给子组件
- 确保在主题变化时子组件能正确更新

```dart
// 正确做法 - 在父组件获取主题并传递
final tdTheme = TDTheme.of(context);
return ModuleTreeItem(
  module: module,
  tdTheme: tdTheme,  // 传递主题
  // ... 其他参数
);
```

---

## 10. WorkspaceView 的 _isClosing 状态

**问题描述**: WorkspaceView 有一个 `_isClosing` 状态，用于在关闭项目时显示加载指示器。但这个状态目前没有被正确重置。

**注意事项**:
- 关闭项目后应该重置 `_isClosing = false`
- 或者使用项目状态来判断是否显示加载

**当前实现**:
```dart
bool _isClosing = false;

// 在 build 中
if (_isClosing || project == null) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

**问题**: `_isClosing` 设置为 true 后从未重置，可能导致切换项目时显示加载。