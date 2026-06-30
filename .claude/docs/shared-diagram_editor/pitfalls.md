# 坑点与注意事项

## 1. 坐标系统

**问题**: 图编辑器有两套坐标系：屏幕坐标和本地坐标。

```dart
// 屏幕坐标：Widget 左上角为原点
// 本地坐标：图内容左上角为原点（考虑缩放和偏移）

// 转换方法
final localPos = editor.toLocal(screenPos);
final screenPos = editor.toScreen(localPos);

// 处理点击事件时
void onTap(TapDownDetails details) {
  final screenPos = details.localPosition;
  final localPos = editor.toLocal(screenPos); // ✅ 转换为本地坐标
  // 使用 localPos 进行节点查询
}
```

## 2. 节点位置和缩放

**问题**: 节点位置存储的是本地坐标，不受缩放影响。

```dart
// 节点位置始终是本地坐标
node.position; // 本地坐标

// 在屏幕上显示时需要转换
final screenPos = editor.toScreen(node.position);

// 检测节点是否在视口内
final viewportRect = editor.viewportRect;
final nodeRect = Rect.fromLTWH(
  node.position.dx,
  node.position.dy,
  node.size.width,
  node.size.height,
);
if (viewportRect.overlaps(nodeRect)) {
  // 节点可见
}
```

## 3. 事件监听生命周期

**问题**: 事件监听器需要手动移除，否则会内存泄漏。

```dart
late final StreamSubscription _subscription;

void initState() {
  super.initState();
  _subscription = editor.eventCenter.on<NodeSelectedEvent>(_onNodeSelected);
}

void dispose() {
  _subscription.cancel(); // ✅ 必须取消
  super.dispose();
}
```

## 4. 空间索引更新

**问题**: 节点位置变化后需要更新空间索引。

```dart
// 移动节点后
editor.updateNodePosition(nodeId, newPosition);
// 内部会自动更新空间索引

// 直接修改 NodeModel 不会更新索引
node.position = newPosition; // ❌ 不会更新索引
```

## 5. 命令系统的使用

**问题**: 只有通过命令系统执行的操作才能撤销。

```dart
// 正确做法：使用命令
editor.executeCommand(MoveNodeCommand(nodeId, oldPos, newPos));

// 错误做法：直接修改
editor.getNode(nodeId).position = newPos; // ❌ 无法撤销
```

## 6. 选择状态同步

**问题**: 选择状态需要手动触发 UI 更新。

```dart
editor.selectNode(nodeId);
// 需要调用 notifyListeners 或 setState
editor.notifyStateChanged();
```

## 7. 边的锚点连接

**问题**: 边连接到字段锚点时，使用锚点ID而不是字段名。

```dart
// 正确做法
edge.copyWith(sourceAnchor: 'field-${fieldId}');

// 错误做法
edge.copyWith(sourceAnchor: fieldName); // ❌ 可能不唯一
```

## 8. 缩放中心点

**问题**: 缩放时需要指定焦点，否则会跳变。

```dart
// 以鼠标位置为中心缩放
void onWheel(PointerScrollEvent event) {
  final focalPoint = event.localPosition;
  editor.zoom(delta, focalPoint); // ✅ 指定焦点
}

// 错误做法：直接修改缩放比例
editor.scale = newScale; // ❌ 会在中心缩放，产生跳变
```

## 9. ER 图的关系类型

**问题**: 关系类型是字符串，需要正确匹配。

```dart
// 正确的关系类型
'1:1', '1:N', 'N:1', 'N:M'

// 大小写敏感
if (edge.relationType == '1:N') { ... } // ✅
if (edge.relationType == '1:n') { ... } // ❌ 不匹配
```

## 10. dispose 清理

**问题**: DiagramEditor 需要手动 dispose。

```dart
@override
void dispose() {
  editor.dispose(); // ✅ 释放资源
  super.dispose();
}
```

## 11. 图布局引擎集成

**问题**: graphview 布局是异步的，需要等待完成。

```dart
editor.applyLayout(builder);
// 布局是异步的，节点位置不会立即更新

// 监听布局完成
editor.eventCenter.on<LayoutCompleteEvent>((e) {
  // 布局完成，可以更新 UI
});
```

## 12. 自定义绘制性能

**问题**: 自定义 Painter 需要优化，避免重绘。

```dart
class MyNodePainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant MyNodePainter oldDelegate) {
    // 只在数据变化时重绘
    return oldDelegate.node != node;
  }
}
```