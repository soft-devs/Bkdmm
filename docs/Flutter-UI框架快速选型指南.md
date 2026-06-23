# Flutter UI 框架快速选型指南

> 针对 Bkdmm ER 图编辑器项目的快速决策参考

---

## 一、核心问题解决方案

### ❌ 当前问题
- 边界管理不完善（超边界）
- 手势交互处理复杂
- 自定义组件维护成本高

### ✅ 解决方案

```
InteractiveViewer (边界层) + GraphView (布局层) + Material 3 (UI层)
```

---

## 二、推荐组合

| 组件 | 用途 | 来源 |
|------|------|------|
| **InteractiveViewer** | 边界约束、缩放、平移 | Flutter SDK 内置 |
| **GraphView** | ER图布局算法 | pub.dev 开源 |
| **Material 3** | 基础UI组件 | Flutter SDK 内置 |
| **fl_chart** | 数据可视化（可选） | pub.dev 开源 |

---

## 三、快速开始

### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  graphview: ^1.5.1
  fl_chart: ^0.66.0  # 可选
```

### 2. 边界管理核心代码

```dart
InteractiveViewer(
  boundaryMargin: const EdgeInsets.all(100),  // 解决超边界问题
  minScale: 0.5,                              // 最小缩放
  maxScale: 3.0,                              // 最大缩放
  panAxis: PanAxis.aligned,                   // 限制轴向移动
  child: YourCanvasWidget(),                  // 替换现有画布
)
```

### 3. ER图布局核心代码

```dart
GraphView(
  graph: erGraph,
  algorithm: SugiyamaAlgorithm(config),  // ER图分层布局
  builder: (node) => ERNodeCard(node),   // 自定义节点样式
)
```

---

## 四、框架对比速查

| 框架 | 边界管理 | ER图 | 企业级 | 免费 | 推荐度 |
|------|:--------:|:----:|:------:|:----:|:------:|
| **InteractiveViewer** | ✅✅✅ | ⚠️ | ✅✅ | ✅ | ⭐⭐⭐⭐⭐ |
| **GraphView** | ⚠️ | ✅✅✅ | ✅✅ | ✅ | ⭐⭐⭐⭐ |
| **Syncfusion** | ✅✅✅ | ✅✅✅ | ✅✅✅ | ❌ | ⭐⭐⭐⭐⭐ |
| **fl_chart** | ✅✅ | ❌ | ✅✅ | ✅ | ⭐⭐⭐⭐ |
| **fluent_ui** | ✅ | ❌ | ✅✅ | ✅ | ⭐⭐⭐ |

---

## 五、决策树

```
需要 ER 图编辑器？
├─ 是 → 需要商业支持？
│   ├─ 是 → Syncfusion (付费)
│   └─ 否 → InteractiveViewer + GraphView (推荐)
│
└─ 否 → 需要数据图表？
    ├─ 是 → fl_chart
    └─ 否 → Material 3 内置组件
```

---

## 六、关键链接

| 资源 | 链接 |
|------|------|
| InteractiveViewer 文档 | https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html |
| GraphView pub.dev | https://pub.dev/packages/graphview |
| GraphView GitHub | https://github.com/nabil6391/graphview |
| Flutter 手势指南 | https://docs.flutter.dev/ui/advanced/gestures |

---

## 七、实施清单

- [ ] 添加 graphview 依赖
- [ ] 用 InteractiveViewer 包裹现有画布
- [ ] 配置 boundaryMargin 解决边界问题
- [ ] 引入 GraphView 替换自定义布局
- [ ] 使用 SugiyamaAlgorithm 作为 ER 图默认布局
- [ ] 自定义 ERNodeWidget（表结构显示）
- [ ] 统一 Material 3 风格

---

> **一句话结论**: 用 **InteractiveViewer** 解决边界问题，用 **GraphView** 解决 ER 图布局，零成本解决核心痛点。