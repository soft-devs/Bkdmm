# Flutter 容器布局设计指南

> 本文档为 Bkdmm 项目布局设计参考指南，旨在减少开发中组件超出容器的问题。

## 快速导航

| 文档 | 说明 |
|------|------|
| [01-layout-basics.md](01-layout-basics.md) | Flutter 布局基础概念与约束传递机制 |
| [02-common-issues.md](02-common-issues.md) | 常见溢出问题与诊断方法 |
| [03-solutions-guide.md](03-solutions-guide.md) | 溢出问题解决方案速查表 |
| [04-best-practices.md](04-best-practices.md) | Bkdmm 项目布局最佳实践 |
| [05-component-patterns.md](05-component-patterns.md) | 常用组件布局模式模板 |
| [06-tdesign-notes.md](06-tdesign-notes.md) | TDesign Flutter 组件布局注意事项 |

## 核心原则

### 1. 约束传递机制

Flutter 布局遵循 **约束向下传递，尺寸向上传递** 的规则：

```
父组件传递约束 (minWidth, maxWidth, minHeight, maxHeight)
    ↓
子组件在约束范围内确定自身尺寸
    ↓
子组件将尺寸返回给父组件
    ↓
父组件确定子组件位置
```

### 2. 三大布局规则

1. **向下传递约束**：父组件告诉子组件可用空间范围
2. **向上传递尺寸**：子组件告诉父组件实际占用空间
3. **父组件设置位置**：父组件决定子组件在自身内部的位置

### 3. 溢出产生原因

当子组件请求的尺寸 **超过** 父组件传递的约束范围时，就会产生溢出。

```
约束: maxWidth = 100px
子组件请求: width = 150px
结果: 溢出 50px (黄黑条纹警告)
```

## 快速解决方案速查

| 场景 | 推荐方案 | 代码示例 |
|------|----------|----------|
| Row/Column 子组件过大 | `Expanded` | `Expanded(child: Widget)` |
| 文本过长 | `TextOverflow.ellipsis` | `Text('...', overflow: TextOverflow.ellipsis)` |
| 内容需要滚动 | `SingleChildScrollView` | `SingleChildScrollView(child: Column(...))` |
| 子组件列表换行 | `Wrap` | `Wrap(children: [...])` |
| 图片超出 | `BoxFit.cover` | `Image.network('url', fit: BoxFit.cover)` |
| 强制裁剪 | `ClipRect` | `ClipRect(child: Widget)` |
| 允许超出不报错 | `OverflowBox` | `OverflowBox(child: Widget)` |
| 响应式布局 | `LayoutBuilder` | `LayoutBuilder(builder: (ctx, constraints) {...})` |
| 自动缩放 | `FittedBox` | `FittedBox(fit: BoxFit.scaleDown, child: Widget)` |

## 常见错误信息解读

### RenderFlex overflowed

```
A RenderFlex overflowed by 23 pixels on the right.
```

**含义**：Row 或 Column 的子组件总宽度/高度超过了父容器
**解决**：使用 `Expanded`/`Flexible` 或添加滚动

### Bottom overflowed by

```
Bottom overflowed by 156 pixels.
```

**含义**：内容超出屏幕底部（常见于键盘弹出）
**解决**：使用 `SingleChildScrollView` 或 `resizeToAvoidBottomInset: true`

## 开发前检查清单

每次编写布局代码前，检查以下事项：

- [ ] 是否有固定尺寸的子组件在 Row/Column 中？
- [ ] 是否有长文本可能超出容器？
- [ ] 是否需要滚动功能？
- [ ] 是否有图片组件需要尺寸控制？
- [ ] 是否有列表组件需要自适应？
- [ ] 是否考虑了不同屏幕尺寸的适配？

## 文档版本

- **版本**: 1.0.0
- **更新日期**: 2026-06-29
- **维护者**: Bkdmm 开发团队

---

> 💡 **提示**: 开发新组件时，优先参考 [05-component-patterns.md](05-component-patterns.md) 中的模板代码，可大幅减少溢出问题。