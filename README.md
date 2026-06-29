# Bkdmm - 数据建模工具

<div align="center">

**免费、简洁、实用的跨平台数据库模型建模工具**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8+-0175C2.svg)](https://dart.dev/)

[English](./README_EN.md) | 简体中文

</div>

---

## 项目简介

Bkdmm 是一款对标 PowerDesigner 的数据库建模工具，使用 **Flutter** 开发，专注于为开发人员和小团队提供**简洁、高效、免费**的数据表设计和代码生成解决方案。

### 为什么选择 Flutter？

| 指标 | Electron | Flutter | 提升 |
|------|----------|---------|------|
| 内存占用 | 300MB+ | 100-150MB | **-60%** |
| 安装包大小 | 80-150MB | 20-40MB | **-70%** |
| 启动速度 | 2-5s | 0.5-1s | **4-5x** |
| 跨平台一致性 | 依赖Chromium | 完全一致 | ✅ |

### 核心特性

- 🎯 **零配置上手** - 5分钟快速入门，无需专业培训
- 🖥️ **跨平台支持** - Windows / macOS / Linux 全平台支持
- 📊 **可视化建模** - 自研高性能 ER 图编辑组件
- 🔧 **多数据库支持** - MySQL、PostgreSQL、Oracle、SQL Server 等
- ⚡ **代码生成** - 自动生成 DDL、Java 实体类等
- 📦 **版本管理** - 数据库结构变更追踪与回滚脚本生成
- 🚀 **高性能** - Flutter AOT 编译，原生级性能

---

## 技术架构

### 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 桌面框架 | Flutter | 3.8+ |
| 编程语言 | Dart | 3.8+ |
| 状态管理 | Riverpod | 2.4+ |
| 本地存储 | Hive | 2.2+ |
| 表格组件 | Syncfusion DataGrid | 24.1+ |
| 图可视化 | CustomPainter (自研) | - |
| 模板引擎 | mustache_template | 2.0+ |

### 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        表现层 (Presentation)                     │
│    首页模块  │  工作区模块  │  ER图组件  │  设置模块              │
│    (Widgets) │  (Tabs)     │  (CustomPaint)│ (Dialogs)           │
├─────────────────────────────────────────────────────────────────┤
│                        业务逻辑层 (Business Logic)               │
│    ProjectService │ ModelingService │ CodeGenService             │
│    (Riverpod StateNotifier)                                      │
├─────────────────────────────────────────────────────────────────┤
│                        数据访问层 (Data Access)                  │
│    Hive Storage │ FileService │ TemplateRepository              │
│    (高性能本地存储 + JSON文件读写)                                │
├─────────────────────────────────────────────────────────────────┤
│                        基础设施层 (Infrastructure)               │
│           Flutter SDK / Dart AOT / Platform Channels            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 文档目录

### 设计文档

| 文档 | 说明 |
|------|------|
| [技术架构文档](docs/TECH-ARCHITECTURE.md) | Flutter 四层架构设计、模块划分、数据模型设计 |
| [技术选型报告](docs/tech-selection/README.md) | Flutter vs Electron vs Qt 对比与决策记录 |
| [框架选型对比](docs/FRAMEWORK-COMPARISON.md) | 深度对比分析三大框架 |
| [数据模型设计](docs/data-model/README.md) | 核心数据结构定义 |

### 功能文档

| 文档 | 说明 |
|------|------|
| [项目管理功能](docs/features/project/README.md) | 项目创建、打开、保存、历史记录 |
| [表编辑器](docs/features/table-editor/README.md) | 数据表字段编辑 |
| [关系图编辑器](docs/features/relation-graph/README.md) | ER图可视化 ⚠️ 重点自研 |
| [代码生成](docs/features/codegen/README.md) | DDL/代码模板生成 |
| [数据类型系统](docs/features/datatype/README.md) | 抽象类型与数据库映射 |

### 开发文档

| 文档 | 说明 |
|------|------|
| [开发指南](docs/dev-setup/README.md) | Flutter 环境搭建、调试指南 |
| [PDMan 参考](docs/reference/README.md) | 原项目逆向分析参考 |

---

## 快速开始

### 环境要求

- Flutter SDK >= 3.8.0
- Dart SDK >= 3.8.0
- Git

### 安装与运行

```bash
# 克隆仓库
git clone https://github.com/your-org/bkdmm.git
cd bkdmm/bkdmm

# 安装依赖
flutter pub get

# 生成 JSON 序列化代码
dart run build_runner build

# 启动开发模式 (Windows)
flutter run -d windows

# 启动开发模式 (macOS)
flutter run -d macos

# 启动开发模式 (Linux)
flutter run -d linux
```

### 构建发布版本

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 项目结构

```
bkdmm/
├── docs/                          # 文档目录
│   ├── TECH-ARCHITECTURE.md       # 技术架构文档
│   ├── FRAMEWORK-COMPARISON.md    # 框架选型对比
│   ├── data-model/                # 数据模型设计
│   ├── features/                  # 功能模块文档
│   └── reference/                 # PDMan 参考文档
│
├── bkdmm/                         # Flutter 项目目录
│   ├── lib/
│   │   ├── main.dart              # 应用入口
│   │   ├── app/                   # 应用全局配置
│   │   ├── features/              # 功能模块
│   │   │   ├── project/           # 项目管理
│   │   │   ├── modeling/          # 数据建模核心
│   │   │   │   ├── entity_editor/ # 表编辑器
│   │   │   │   ├── er_diagram/    # ER图组件 ⚠️
│   │   │   │   └── workspace/     # 工作区
│   │   │   ├── codegen/           # 代码生成
│   │   │   └── settings/          # 设置
│   │   ├── shared/                # 共享层
│   │   │   ├── models/            # 数据模型
│   │   │   ├── services/          # 服务层
│   │   │   └── widgets/           # 通用组件
│   │   └── utils/                 # 工具函数
│   │
│   ├── assets/                    # 静态资源
│   │   └── templates/             # 代码生成模板
│   │
│   ├── windows/                   # Windows 平台配置
│   ├── macos/                     # macOS 平台配置
│   ├── linux/                     # Linux 平台配置
│   └── pubspec.yaml               # 项目配置
│
└── README.md
```

---

## 核心功能

### 1. 项目管理

- 新建 / 打开项目
- 项目历史记录
- 多 Tab 工作区

### 2. 数据建模

- 模块管理
- 数据表设计（字段、索引、注释）
- 可视化 ER 图编辑
- 数据类型映射

### 3. 代码生成

- 多数据库 DDL 生成
- Java 实体类生成
- 自定义模板支持

### 4. 版本管理

- 版本快照
- 变更对比
- 回滚脚本生成

### 5. 导出功能

- Word / PDF 文档
- SQL 脚本
- 图片导出

---

## 开发路线图

### Phase 1: 基础框架 (Week 1-2)

- [x] 技术架构设计
- [x] Flutter 项目初始化
- [ ] 基础 UI 框架搭建
- [ ] Riverpod 状态管理配置
- [ ] 项目文件读写功能
- [ ] Hive 存储初始化

### Phase 2: 核心功能 (Week 3-5)

- [ ] 数据表编辑器 (Syncfusion DataGrid)
- [ ] 字段类型系统
- [ ] Tab 工作区管理
- [ ] 索引编辑器

### Phase 3: ER图开发 (Week 6-8) ⚠️ 重点

- [ ] CustomPainter 基础框架
- [ ] 节点绘制与交互
- [ ] 连线绘制与编辑
- [ ] 缩放/平移/搜索
- [ ] 自动布局算法
- [ ] 图片导出

### Phase 4: 代码生成 (Week 9-10)

- [ ] mustache 模板引擎集成
- [ ] DDL 生成（多数据库支持）
- [ ] Java 实体类生成
- [ ] 代码预览功能

### Phase 5: 导出与发布 (Week 11-12)

- [ ] Word/PDF 导出
- [ ] 图片导出
- [ ] SQL 脚本导出
- [ ] 多平台打包与发布

---

## 参考项目

- [PDMan](https://github.com/pdman/pdman) - 开源数据库建模工具
- [Flutter](https://flutter.dev) - Google 跨平台 UI 框架
- [Riverpod](https://riverpod.dev) - Flutter 状态管理
- [Hive](https://docs.hivedb.dev) - Flutter 本地数据库

---

## 贡献指南

欢迎参与 Bkdmm 的开发！请阅读 [贡献指南](docs/CONTRIBUTING.md) 了解如何开始。

### 开发规范

- 遵循 Dart/Flutter 代码规范
- 使用 `flutter analyze` 检查代码
- 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/)
- 新功能需添加单元测试

---

## 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 联系方式

- Issue: [GitHub Issues](https://github.com/your-org/bkdmm/issues)
- Discussion: [GitHub Discussions](https://github.com/your-org/bkdmm/discussions)

---

<div align="center">

**Made with ❤️ by Bkdmm Team**

</div>
