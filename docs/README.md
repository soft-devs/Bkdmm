# Bkdmm - Flutter 数据建模工具

> **技术栈**: Flutter 3.x + Dart
> **创建日期**: 2026-06-22

---

## 快速导航

| 当你要... | 请阅读... |
|-----------|----------|
| 了解产品功能和目标 | [产品定位](product/README.md) |
| 设计数据模型结构 | [数据模型](data-model/README.md) |
| 开发项目管理功能 | [项目管理](features/project/README.md) |
| 开发数据表编辑器 | [表编辑器](features/table-editor/README.md) |
| 开发关系图编辑器 | [关系图](features/relation-graph/README.md) |
| 开发代码生成功能 | [代码生成](features/codegen/README.md) |
| 开发数据类型系统 | [数据类型](features/datatype/README.md) |
| 配置开发环境 | [开发环境](dev-setup/README.md) |
| 了解 Flutter 技术选型 | [技术选型](tech-selection/README.md) |
| 参考原 PDMan 实现 | [PDMan 参考](reference/README.md) |

---

## 项目概述

Bkdmm 是一款**免费、简洁、实用的跨平台数据库模型建模工具**，使用 Flutter 开发，支持 Windows/macOS/Linux 三平台。

### 核心功能

| 功能模块 | 说明 | Flutter 需自研 |
|----------|------|---------------|
| 项目管理 | 创建/打开/保存项目 | ❌ 可用现有包 |
| 数据表编辑 | 字段/索引配置 | ❌ 可用现有包 |
| 关系图可视化 | ER图拖拽编辑 | ⚠️ 需自研 |
| 代码生成 | 多数据库DDL生成 | ❌ 可用现有包 |
| 数据类型管理 | 类型映射配置 | ❌ 可用现有包 |
| 版本管理 | 变更追踪/回滚 | ❌ 可用现有包 |

### Flutter vs Electron 对比

| 指标 | Electron | Flutter |
|------|----------|---------|
| 内存占用 | 300MB+ | 100-150MB |
| 安装包大小 | 80-150MB | 20-40MB |
| 启动速度 | 2-5s | 0.5-1s |
| ER图生态 | G6成熟 | **需自研** |

---

## 项目结构规划

```
lib/
├── app/
│   ├── main.dart               # 应用入口
│   ├── app_theme.dart          # 主题配置
│   └── routes.dart             # 路由配置
│
├── features/                   # 功能模块(按需加载文档)
│   ├── project/                # 项目管理
│   ├── modeling/               # 数据建模核心
│   │   ├── entity_editor/      # 表编辑器
│   │   ├── er_diagram/         # ER图 ⚠️
│   │   └── field_editor/       # 字段编辑
│   ├── codegen/                # 代码生成
│   └── settings/               # 设置
│
├── shared/
│   ├── widgets/                # 通用组件
│   ├── models/                 # 数据模型
│   ├── services/               # 服务层
│   └── utils/                  # 工具函数
│
├── platform/                   # 平台特定实现
│   ├── windows/
│   ├── macos/
│   └── linux/
│
└── templates/                  # 代码生成模板
    ├── ddl/
    └── code/
```

---

## 开发阶段规划

### Phase 1: 基础框架 (Week 1-2)
- [ ] Flutter 项目初始化
- [ ] 基础 UI 框架搭建
- [ ] 项目文件读写功能
- [ ] 状态管理(Riverpod)

**相关文档**: [开发环境](dev-setup/README.md) | [项目管理](features/project/README.md)

### Phase 2: 核心功能 (Week 3-5)
- [ ] 数据表编辑器
- [ ] 字段类型系统
- [ ] Tab 工作区管理

**相关文档**: [表编辑器](features/table-editor/README.md) | [数据类型](features/datatype/README.md)

### Phase 3: ER图开发 (Week 6-8) ⚠️ 重点
- [ ] 自研图编辑组件
- [ ] 拖拽布局
- [ ] 连线编辑
- [ ] 自动布局算法

**相关文档**: [关系图](features/relation-graph/README.md)

### Phase 4: 代码生成 (Week 9-10)
- [ ] 模板引擎集成
- [ ] DDL生成
- [ ] 代码预览

**相关文档**: [代码生成](features/codegen/README.md)

---

## 关键决策记录

| 决策 | 选择 | 原因 |
|------|------|------|
| 状态管理 | Riverpod | 推荐，性能好 |
| 本地存储 | Hive/Isar | 高性能 NoSQL |
| 图可视化 | **自研** | Flutter 生态无成熟方案 |
| 模板引擎 | mustache | Dart 成熟方案 |
| 表格组件 | syncfusion_datagrid | 商业级，免费版够用 |

---

## 参考资源

- Flutter 官方文档: https://flutter.dev
- Riverpod 文档: https://riverpod.dev
- Hive 文档: https://docs.hivedb.dev
- 原项目文档: [reference/README.md](reference/README.md)