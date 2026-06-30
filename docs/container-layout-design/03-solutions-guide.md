# 溢出问题解决方案速查表

本文档提供各类溢出问题的快速解决方案，按场景分类，方便开发时快速查阅。

## 一、Row/Column 溢出解决方案

### 1.1 子组件过大

**问题**：Row/Column 中的子组件总尺寸超过容器

```dart
// ❌ 问题代码
Row(
  children: [
    Container(width: 200, child: Text('左侧')),
    Container(width: 200, child: Text('中间')),
    Container(width: 200, child: Text('右侧')),
    // 总宽度 600px 可能超出屏幕
  ],
)
```

#### 方案 A: 使用 Expanded（推荐）

```dart
// ✅ 子组件按比例分配空间
Row(
  children: [
    Expanded(
      flex: 1,
      child: Container(child: Text('左侧')),
    ),
    Expanded(
      flex: 2,
      child: Container(child: Text('中间')),
    ),
    Expanded(
      flex: 1,
      child: Container(child: Text('右侧')),
    ),
  ],
)
```

#### 方案 B: 使用 Flexible

```dart
// ✅ 子组件可收缩但不强制填充
Row(
  children: [
    Container(width: 100, child: Text('固定宽度')),
    Flexible(
      child: Container(
        child: Text('可收缩内容'),
      ),
    ),
    Container(width: 50, child: Text('固定')),
  ],
)
```

#### 方案 C: 添加滚动

```dart
// ✅ 允许用户滚动查看超出内容
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      Container(width: 200, child: Text('左侧')),
      Container(width: 200, child: Text('中间')),
      Container(width: 200, child: Text('右侧')),
    ],
  ),
)
```

### 1.2 文本溢出

**问题**：文本内容过长导致容器溢出

```dart
// ❌ 问题代码
Row(
  children: [
    Icon(Icons.star),
    Text('这是一段非常长的标题文本内容肯定会导致溢出问题'),
    Icon(Icons.more),
  ],
)
```

#### 方案 A: 省略号截断（推荐）

```dart
// ✅ 单行省略号
Row(
  children: [
    Icon(Icons.star),
    Expanded(
      child: Text(
        '这是一段非常长的标题文本内容肯定会导致溢出问题',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    Icon(Icons.more),
  ],
)
```

#### 方案 B: 多行显示

```dart
// ✅ 多行文本
Row(
  children: [
    Icon(Icons.star),
    Expanded(
      child: Text(
        '这是一段非常长的标题文本内容',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Icon(Icons.more),
  ],
)
```

#### 方案 C: 自动缩放

```dart
// ✅ 文本自动缩放适应容器
Row(
  children: [
    Icon(Icons.star),
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('这是一段长文本会自动缩放'),
    ),
    Icon(Icons.more),
  ],
)
```

### 1.3 图片溢出

**问题**：图片尺寸过大导致溢出

```dart
// ❌ 问题代码
Row(
  children: [
    Image.asset('assets/large_image.png'),
    Text('标题'),
  ],
)
```

#### 方案 A: 限制尺寸 + BoxFit（推荐）

```dart
// ✅ 固定尺寸 + 裁剪
Row(
  children: [
    SizedBox(
      width: 48,
      height: 48,
      child: Image.asset(
        'assets/large_image.png',
        fit: BoxFit.cover,
      ),
    ),
    Text('标题'),
  ],
)
```

#### 方案 B: 使用 Expanded

```dart
// ✅ 图片占满剩余空间
Row(
  children: [
    Expanded(
      child: Image.asset(
        'assets/image.png',
        fit: BoxFit.cover,
      ),
    ),
  ],
)
```

## 二、键盘弹出溢出解决方案

### 2.1 表单溢出

**问题**：键盘弹出时表单内容被挤压溢出

```dart
// ❌ 问题代码
Scaffold(
  body: Column(
    children: [
      TextField(),
      TextField(),
      TextField(),
      // 更多 TextField...
    ],
  ),
)
```

#### 方案 A: SingleChildScrollView（推荐）

```dart
// ✅ 添加滚动
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(),
        TextField(),
        TextField(),
        // 更多 TextField...
      ],
    ),
  ),
)
```

#### 方案 B: 使用 Form + 键盘动作

```dart
// ✅ 完整表单处理
Scaffold(
  resizeToAvoidBottomInset: true,
  body: Form(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            textInputAction: TextInputAction.next,
          ),
          TextFormField(
            textInputAction: TextInputAction.next,
          ),
          TextFormField(
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submitForm(),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: submitForm,
            child: Text('提交'),
          ),
        ],
      ),
    ),
  ),
)
```

## 三、ListView/GridView 溢出解决方案

### 3.1 在 Column/Row 中使用

**问题**：ListView 需要有限约束，但 Column/Row 提供无限约束

```dart
// ❌ 问题代码
Column(
  children: [
    Text('标题'),
    ListView(
      children: [...],
    ),
  ],
)
```

#### 方案 A: Expanded（推荐）

```dart
// ✅ ListView 填满剩余空间
Column(
  children: [
    Text('标题'),
    Expanded(
      child: ListView(
        children: [...],
      ),
    ),
  ],
)
```

#### 方案 B: shrinkWrap + NeverScrollable

```dart
// ✅ ListView 收缩到内容高度（适合少量项目）
Column(
  children: [
    Text('标题'),
    ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [...],
    ),
  ],
)
```

#### 方案 C: SizedBox 固定高度

```dart
// ✅ 固定 ListView 高度
Column(
  children: [
    Text('标题'),
    SizedBox(
      height: 300,
      child: ListView(
        children: [...],
      ),
    ),
  ],
)
```

### 3.2 嵌套 ListView

**问题**：多个 ListView 嵌套导致滚动冲突

```dart
// ❌ 问题代码
ListView(
  children: [
    ListView(...), // 内部 ListView 滚动冲突
  ],
)
```

#### 方案 A: 使用 shrinkWrap

```dart
// ✅ 内部 ListView 收缩，只保留外部滚动
ListView(
  children: [
    ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [...],
    ),
  ],
)
```

#### 方案 B: 使用 CustomScrollView + Sliver

```dart
// ✅ 统一滚动
CustomScrollView(
  slivers: [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(title: Text('Item $index')),
        childCount: 10,
      ),
    ),
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(child: Text('Grid $index')),
        childCount: 20,
      ),
    ),
  ],
)
```

## 四、Stack 溢出解决方案

### 4.1 Positioned 超出边界

**问题**：Positioned 组件超出 Stack 边界

```dart
// ❌ 问题代码
Stack(
  children: [
    Container(width: 100, height: 100, color: Colors.blue),
    Positioned(
      right: -30,
      child: Icon(Icons.star),
    ),
  ],
)
```

#### 方案 A: 使用 clipBehavior

```dart
// ✅ 裁剪超出部分
Stack(
  clipBehavior: Clip.hardEdge,
  children: [
    Container(width: 100, height: 100, color: Colors.blue),
    Positioned(
      right: -30,
      child: Icon(Icons.star),
    ),
  ],
)
```

#### 方案 B: 使用 OverflowBox

```dart
// ✅ 允许子组件超出
Stack(
  children: [
    Container(width: 100, height: 100, color: Colors.blue),
    OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      alignment: Alignment.topRight,
      child: Positioned(
        right: -30,
        child: Icon(Icons.star),
      ),
    ),
  ],
)
```

### 4.2 Stack 内容溢出

```dart
// ❌ 问题代码
Stack(
  children: [
    Container(width: 100, height: 100),
    Container(width: 150, height: 150), // 超出
  ],
)
```

#### 方案: 裁剪或扩容

```dart
// ✅ 裁剪超出部分
ClipRect(
  child: Stack(
    children: [
      Container(width: 100, height: 100),
      Container(width: 150, height: 150),
    ],
  ),
)

// ✅ 或使用 fit 属性
Stack(
  fit: StackFit.expand,
  children: [
    Container(width: 100, height: 100),
    Container(width: 150, height: 150),
  ],
)
```

## 五、图片溢出解决方案

### 5.1 图片尺寸过大

```dart
// ❌ 问题代码
Container(
  child: Image.network('url'), // 图片可能很大
)
```

#### 方案 A: 使用 fit 属性（推荐）

```dart
// ✅ 图片缩放适应容器
Container(
  width: 200,
  height: 150,
  child: Image.network(
    'url',
    fit: BoxFit.cover, // 裁剪填充
    // fit: BoxFit.contain, // 完整显示
  ),
)
```

#### 方案 B: 使用 FittedBox

```dart
// ✅ 自动缩放
FittedBox(
  fit: BoxFit.scaleDown,
  child: Image.network('url'),
)
```

### 5.2 图片在 Row/Column 中溢出

```dart
// ❌ 问题代码
Row(
  children: [
    Image.network('url'),
    Text('标题'),
  ],
)
```

#### 方案: 限制图片尺寸

```dart
// ✅ 固定图片尺寸
Row(
  children: [
    SizedBox(
      width: 80,
      height: 80,
      child: Image.network('url', fit: BoxFit.cover),
    ),
    Expanded(
      child: Text('标题'),
    ),
  ],
)
```

## 六、组件列表换行

### 6.1 Chip/Button 列表溢出

**问题**：Chip 或 Button 列表在一行排不下

```dart
// ❌ 问题代码
Row(
  children: [
    Chip(label: Text('标签1')),
    Chip(label: Text('标签2')),
    Chip(label: Text('标签3')),
    // 更多标签会溢出
  ],
)
```

#### 方案: 使用 Wrap

```dart
// ✅ 自动换行
Wrap(
  spacing: 8, // 水平间距
  runSpacing: 8, // 垂直间距
  children: [
    Chip(label: Text('标签1')),
    Chip(label: Text('标签2')),
    Chip(label: Text('标签3')),
    Chip(label: Text('标签4')),
    Chip(label: Text('标签5')),
  ],
)
```

## 七、响应式布局解决方案

### 7.1 根据屏幕尺寸调整

```dart
// ✅ 使用 LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return _buildWideLayout();
    } else {
      return _buildNarrowLayout();
    }
  },
)
```

### 7.2 根据平台调整

```dart
// ✅ 使用 MediaQuery
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final isLandscape = size.width > size.height;

  return isLandscape
    ? _buildLandscapeLayout()
    : _buildPortraitLayout();
}
```

### 7.3 使用百分比尺寸

```dart
// ✅ 使用 FractionallySizedBox
FractionallySizedBox(
  widthFactor: 0.8, // 父容器宽度的 80%
  child: Container(
    child: Text('占 80% 宽度'),
  ),
)
```

## 八、强制裁剪方案

### 8.1 ClipRect - 矩形裁剪

```dart
// ✅ 裁剪超出矩形区域的内容
ClipRect(
  child: Container(
    width: 100,
    child: Text('超出的内容会被裁剪'),
  ),
)
```

### 8.2 ClipRRect - 圆角裁剪

```dart
// ✅ 带圆角的裁剪
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Container(
    child: Image.network('url'),
  ),
)
```

### 8.3 ClipOval - 椭圆裁剪

```dart
// ✅ 裁剪为椭圆形
ClipOval(
  child: Container(
    width: 100,
    height: 100,
    child: Image.network('url'),
  ),
)
```

### 8.4 ClipPath - 自定义路径裁剪

```dart
// ✅ 自定义形状裁剪
ClipPath(
  clipper: CustomClipper<Path>(),
  child: Container(
    child: Widget,
  ),
)
```

## 九、解决方案速查表

| 问题场景 | 推荐方案 | 代码模式 |
|----------|----------|----------|
| Row 子组件过大 | `Expanded` | `Row(children: [Expanded(child: ...)])` |
| Column 子组件过大 | `Expanded` | `Column(children: [Expanded(child: ...)])` |
| 文本过长 | `TextOverflow.ellipsis` | `Text('...', overflow: TextOverflow.ellipsis)` |
| 图片过大 | `BoxFit.cover` | `Image.network('url', fit: BoxFit.cover)` |
| 键盘弹出溢出 | `SingleChildScrollView` | `SingleChildScrollView(child: Column(...))` |
| ListView 在 Column 中 | `Expanded` | `Column(children: [Expanded(child: ListView())])` |
| Stack 子组件超出 | `clipBehavior` | `Stack(clipBehavior: Clip.hardEdge, ...)` |
| Chip 列表换行 | `Wrap` | `Wrap(children: [Chip(...), ...])` |
| 响应式布局 | `LayoutBuilder` | `LayoutBuilder(builder: (ctx, constraints) {...})` |
| 自适应缩放 | `FittedBox` | `FittedBox(fit: BoxFit.scaleDown, child: ...)` |
| 强制裁剪 | `ClipRect` | `ClipRect(child: ...)` |
| 允许超出 | `OverflowBox` | `OverflowBox(child: ...)` |

## 十、决策树

```
遇到溢出问题
    │
    ├─ 是 Row/Column 吗？
    │   ├─ 是 → 子组件使用 Expanded/Flexible
    │   │       或添加 SingleChildScrollView
    │   │
    │   └─ 否 → 继续判断
    │
    ├─ 是文本溢出吗？
    │   ├─ 是 → 设置 TextOverflow.ellipsis
    │   │       或使用 FittedBox
    │   │
    │   └─ 否 → 继续判断
    │
    ├─ 是图片溢出吗？
    │   ├─ 是 → 设置 BoxFit.cover/contain
    │   │       或限制图片尺寸
    │   │
    │   └─ 否 → 继续判断
    │
    ├─ 是键盘弹出溢出吗？
    │   ├─ 是 → 使用 SingleChildScrollView
    │   │       设置 resizeToAvoidBottomInset: true
    │   │
    │   └─ 否 → 继续判断
    │
    ├─ 是 Stack 溢出吗？
    │   ├─ 是 → 设置 clipBehavior
    │   │       或使用 OverflowBox
    │   │
    │   └─ 否 → 使用 ClipRect 裁剪
    │           或 LayoutBuilder 响应式处理
```

---

**相关文档**:
- [02-common-issues.md](02-common-issues.md) - 常见问题诊断
- [04-best-practices.md](04-best-practices.md) - 最佳实践