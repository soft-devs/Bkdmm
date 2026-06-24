# shared/widgets - 通用UI组件

共享 UI 组件，提供通用的页面结构和加载状态显示。

## 组件列表

| 组件 | 文件 | 说明 |
|------|------|------|
| AppScaffold | app_scaffold.dart | 应用脚手架组件 |
| LoadingOverlay | loading_overlay.dart | 加载遮罩组件 |

## AppScaffold

统一的应用页面结构。

```dart
class AppScaffold extends StatelessWidget {
  final String title;               // 页面标题
  final Widget body;                // 页面内容
  final List<Widget>? actions;      // 顶部操作按钮
  final Widget? floatingActionButton; // 悬浮按钮
  final Widget? drawer;             // 侧边栏
  final Widget? bottomNavigationBar; // 底部导航栏
}
```

### 使用示例

```dart
AppScaffold(
  title: 'Settings',
  body: SettingsForm(),
  actions: [
    IconButton(icon: Icon(Icons.save), onPressed: _save),
  ],
)
```

## LoadingOverlay

加载状态遮罩，显示加载进度。

```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;             // 是否加载中
  final Widget child;               // 子组件
  final String? message;            // 加载提示信息
}
```

### 使用示例

```dart
LoadingOverlay(
  isLoading: _isLoading,
  message: 'Saving...',
  child: MyForm(),
)
```

## 设计原则

1. **无状态优先** - 组件尽量保持无状态
2. **可组合性** - 组件可嵌套组合
3. **主题适配** - 使用 Theme.of(context) 获取主题
4. **响应式** - 支持不同屏幕尺寸
