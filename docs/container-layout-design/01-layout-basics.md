# Flutter 布局基础概念

## 一、布局系统概述

Flutter 采用 **声明式 UI** 和 **单次传递布局协议** (Single-pass layout protocol)，这意味着每个 Widget 在布局阶段只会被访问一次。

### 布局流程

```
┌─────────────────────────────────────────────────────────────┐
│                      父组件                                  │
│  1. 接收祖先传递的约束 (Constraints)                          │
│  2. 计算子组件的约束                                          │
│  3. 调用子组件的 layout 方法                                  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ 传递约束
┌─────────────────────────────────────────────────────────────┐
│                      子组件                                  │
│  4. 接收约束                                                 │
│  5. 在约束范围内确定自身尺寸                                  │
│  6. 返回尺寸给父组件                                         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ 返回尺寸
┌─────────────────────────────────────────────────────────────┐
│                      父组件                                  │
│  7. 根据返回的尺寸确定子组件位置                              │
│  8. 确定自身尺寸并返回给自己的父组件                          │
└─────────────────────────────────────────────────────────────┘
```

## 二、约束 (Constraints)

### BoxConstraints

`BoxConstraints` 描述了 Widget 可以占用的空间范围：

```dart
BoxConstraints({
  double minWidth,    // 最小宽度
  double maxWidth,    // 最大宽度
  double minHeight,   // 最小高度
  double maxHeight,   // 最大高度
})
```

### 常见约束类型

| 约束类型 | 说明 | 示例场景 |
|----------|------|----------|
| **紧密约束** (Tight) | minWidth == maxWidth 且 minHeight == maxHeight | 固定尺寸的 Container |
| **松散约束** (Loose) | minWidth == 0, maxWidth > 0 | Row/Column 中的子组件 |
| **无限约束** (Unbounded) | maxWidth == double.infinity | SingleChildScrollView 中的 Column |
| **有界约束** (Bounded) | maxWidth < double.infinity | 固定宽度的容器 |

### 约束传播示例

```dart
// 示例 1: Container 的约束传播
Container(
  width: 200,
  height: 100,
  child: Text('Hello'), // Text 接收到紧密约束: 200x100
)

// 示例 2: Row 的约束传播
Row(
  children: [
    Container(width: 50, child: Text('A')), // 宽度约束: 50
    Expanded(child: Text('B')),             // 宽度约束: 剩余空间
  ],
)

// 示例 3: 无限约束问题
Row(
  children: [
    ListView(), // ❌ 错误! ListView 需要有限高度
  ],
)
// ✅ 解决方案: 给 ListView 一个有限高度
Row(
  children: [
    SizedBox(
      height: 200,
      child: ListView(),
    ),
  ],
)
```

## 三、布局容器分类

### 1. 单子组件容器

| Widget | 特点 | 尺寸行为 |
|--------|------|----------|
| `Container` | 多功能容器 | 尽可能大，或根据子组件/尺寸属性 |
| `SizedBox` | 固定尺寸盒子 | 指定的尺寸，或子组件尺寸 |
| `ConstrainedBox` | 限制约束 | 对子组件施加额外约束 |
| `UnconstrainedBox` | 解除约束 | 允许子组件忽略父约束 |
| `LimitedBox` | 有限尺寸 | 仅在无约束时限制尺寸 |
| `FractionallySizedBox` | 比例尺寸 | 相对于父容器的百分比 |
| `AspectRatio` | 宽高比 | 保持指定宽高比 |
| `FittedBox` | 自适应缩放 | 缩放子组件适应约束 |
| `OverflowBox` | 允许溢出 | 子组件可超出约束 |
| `ClipRect` | 裁剪矩形 | 裁剪超出部分 |

### 2. 多子组件容器

| Widget | 特点 | 子组件行为 |
|--------|------|------------|
| `Row` | 水平排列 | 子组件沿主轴水平排列 |
| `Column` | 垂直排列 | 子组件沿主轴垂直排列 |
| `Stack` | 层叠布局 | 子组件可重叠定位 |
| `Wrap` | 换行布局 | 子组件自动换行 |
| `ListView` | 列表视图 | 滚动列表 |
| `GridView` | 网格视图 | 滚动网格 |
| `Flow` | 自定义布局 | 高度自定义的布局 |
| `Table` | 表格布局 | 表格形式排列 |

### 3. 弹性布局组件

| Widget | 特点 | 使用场景 |
|--------|------|----------|
| `Expanded` | 填充剩余空间 | 必须填满父容器的子组件 |
| `Flexible` | 弹性分配空间 | 可伸缩但不强制填充 |
| `Spacer` | 占位空白 | 在 Row/Column 中创建间隔 |

## 四、Expanded vs Flexible

### Expanded

```dart
// Expanded: 强制子组件填满剩余空间
Row(
  children: [
    Container(width: 50, color: Colors.red),
    Expanded(
      child: Container(color: Colors.blue), // 填满剩余宽度
    ),
  ],
)
```

### Flexible

```dart
// Flexible: 允许子组件在约束范围内调整尺寸
Row(
  children: [
    Container(width: 50, color: Colors.red),
    Flexible(
      child: Container(
        width: 100, // 可以是 100，也可以被压缩
        color: Colors.blue,
      ),
    ),
  ],
)
```

### 区别对比

```dart
Row(
  children: [
    // Expanded: 必须填满剩余空间
    Expanded(
      child: Container(
        width: 50, // 宽度被忽略，强制填满
        color: Colors.red,
      ),
    ),
    // Flexible: 可以小于剩余空间
    Flexible(
      child: Container(
        width: 50, // 宽度可能被保留或压缩
        color: Colors.blue,
      ),
    ),
  ],
)
```

## 五、flex 参数

`Expanded` 和 `Flexible` 都支持 `flex` 参数，用于按比例分配空间：

```dart
Row(
  children: [
    Expanded(
      flex: 1, // 占 1 份
      child: Container(color: Colors.red),
    ),
    Expanded(
      flex: 2, // 占 2 份
      child: Container(color: Colors.blue),
    ),
    Expanded(
      flex: 1, // 占 1 份
      child: Container(color: Colors.green),
    ),
  ],
)
// 结果: 红色 25%, 蓝色 50%, 绿色 25%
```

## 六、常见约束陷阱

### 陷阱 1: 嵌套 Row/Column 的无限约束

```dart
// ❌ 错误: 外层 Row 给内层 Row 无限宽度
Row(
  children: [
    Row(
      children: [Text('问题')],
    ),
  ],
)

// ✅ 解决方案: 使用 Expanded 限制内层 Row
Row(
  children: [
    Expanded(
      child: Row(
        children: [Text('正确')],
      ),
    ),
  ],
)
```

### 陷阱 2: ListView 在 Column 中

```dart
// ❌ 错误: ListView 在 Column 中获得无限高度
Column(
  children: [
    Text('标题'),
    ListView(), // 无限高度约束!
  ],
)

// ✅ 解决方案 A: 使用 Expanded
Column(
  children: [
    Text('标题'),
    Expanded(
      child: ListView(),
    ),
  ],
)

// ✅ 解决方案 B: 使用 shrinkWrap
Column(
  children: [
    Text('标题'),
    ListView(
      shrinkWrap: true, // 内容收缩包裹
      physics: NeverScrollableScrollPhysics(), // 禁用滚动
    ),
  ],
)
```

### 陷阱 3: Image 的尺寸问题

```dart
// ❌ 问题: 图片可能很大导致溢出
Container(
  width: 100,
  height: 100,
  child: Image.network('url'), // 图片原始尺寸可能很大
)

// ✅ 解决方案: 使用 fit
Image.network(
  'url',
  fit: BoxFit.cover, // 或 contain
)
```

## 七、约束调试工具

### 1. Layout Explorer (DevTools)

```dart
// 在运行的应用中，使用 Flutter DevTools
flutter run --observatory-port=8888
```

功能：
- 可视化查看约束传递
- 检查每个 Widget 的约束和尺寸
- 调试布局问题

### 2. debugPrint

```dart
// 打印约束信息
LayoutBuilder(
  builder: (context, constraints) {
    debugPrint('Constraints: $constraints');
    return Container();
  },
)
```

### 3. Widget Inspector

VS Code / Android Studio 内置功能：
- 选择 Widget 查看属性
- 查看布局树结构
- 实时检查约束

## 八、总结

### 核心概念

1. **约束向下传递**：父组件决定子组件的可用空间
2. **尺寸向上传递**：子组件决定自身尺寸
3. **位置由父决定**：父组件确定子组件位置

### 避免溢出的关键

1. 理解约束传递机制
2. 避免在无限约束中使用固定尺寸
3. 使用 `Expanded`/`Flexible` 处理弹性空间
4. 使用 `SingleChildScrollView` 处理可能超出的内容
5. 给图片指定 `fit` 属性

---

**相关文档**:
- [02-common-issues.md](02-common-issues.md) - 常见溢出问题
- [03-solutions-guide.md](03-solutions-guide.md) - 解决方案速查