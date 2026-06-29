# Bkdmm

## 概述

BK Datasource Model Manager - 数据库模型建模工具。用于设计数据库表结构、管理数据模型、生成DDL语句的Flutter桌面应用。

## 构建

**运行时要求**: Flutter 3.8+ / Dart 3.8+
**构建命令**:
```bash
flutter pub get          # 安装依赖
flutter run -d windows   # 开发运行
flutter build windows    # 构建发布版
flutter analyze          # 静态分析
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app/                         # 应用层 (3 files)
│   ├── app.dart                 # MaterialApp 配置
│   ├── app_theme.dart           # TDesign 主题
│   └── main.dart
├── shared/                      # 共享模块 (36 files)
│   ├── models/                  # 数据模型 (13 files)
│   ├── providers/               # 状态管理 (5 files)
│   ├── services/                # 服务层 (5 files)
│   ├── widgets/                 # 公共组件 (3 files)
│   ├── diagram_editor/          # 图表编辑器 (8 files)
│   ├── constants/               # 常量 (1 file)
│   └── theme/                   # 主题 (1 file)
└── features/                    # 功能模块 (91 files)
    ├── home/                    # 首页 (3 files)
    ├── project/                 # 项目管理 (11 files)
    ├── workspace/               # 工作区 (24 files)
    ├── modeling/                # 建模 (21 files)
    │   ├── entity_editor/       # 实体编辑器
    │   ├── er_diagram/          # ER图
    │   └── flowchart/           # 流程图
    ├── settings/                # 设置 (20 files)
    ├── datatype/                # 数据类型 (7 files)
    └── codegen/                 # 代码生成 (5 files)
```

## 模块索引

### 基础层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| shared/models | 核心数据模型 | 13 | [README](docs/shared-models/README.md) |
| shared/constants | 应用常量 | 1 | [README](docs/shared-constants/README.md) |
| shared/theme | TDesign主题 | 1 | [README](docs/shared-theme/README.md) |
| shared/widgets | 公共UI组件 | 3 | [README](docs/shared-widgets/README.md) |
| shared/diagram_editor | 图表编辑器框架 | 8 | [README](docs/shared-diagram_editor/README.md) |

### 数据层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| shared/providers | Riverpod状态管理 | 5 | [README](docs/shared-providers/README.md) |
| shared/services | 文件/存储服务 | 5 | [README](docs/shared-services/README.md) |

### 配置层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| settings | 全局/项目设置 | 20 | [README](docs/features-settings/README.md) |

### 业务层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| home | 首页/项目历史 | 3 | [README](docs/features-home/README.md) |
| project | 项目创建/打开 | 11 | [README](docs/features-project/README.md) |
| workspace | 主工作区 | 24 | [README](docs/features-workspace/README.md) |
| modeling | 实体编辑/ER图/流程图 | 21 | [README](docs/features-modeling/README.md) |
| datatype | 数据类型管理 | 7 | [README](docs/features-datatype/README.md) |
| codegen | DDL生成/预览 | 5 | [README](docs/features-codegen/README.md) |

## 核心架构

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  features/* (Views/Widgets/Dialogs)                         │
├─────────────────────────────────────────────────────────────┤
│                      State Layer                             │
│  shared/providers (Riverpod Notifiers)                      │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                           │
│  shared/services (FileService, StorageService, HistoryService)│
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                              │
│  shared/models (Entity, Module, Field, Project)             │
│  Hive Local Storage                                          │
└─────────────────────────────────────────────────────────────┘
```

## 模块依赖关系

```
features/home ──────────────┐
features/project ───────────┤
features/workspace ─────────┼──► shared/providers ──► shared/services
features/modeling ──────────┤           │                   │
features/settings ──────────┤           └───────────────────┘
features/datatype ──────────┤                     │
features/codegen ───────────┘                     ▼
                                          shared/models
```

## 环境配置

- **开发环境**: Windows 11
- **目标平台**: Windows Desktop
- **状态持久化**: Hive (本地NoSQL)
- **UI框架**: TDesign Flutter

## 重要坑点

1. **TDesign组件兼容性**: `tdesign_flutter: ^0.2.7` 需要配合 `tdesign_flutter_adaptation`
2. **Riverpod状态更新**: 使用 `ref.read(provider.notifier)` 获取Notifier调用方法
3. **Hive初始化**: 必须在 `main()` 中调用 `Hive.initFlutter()`
4. **文件路径**: Windows路径使用反斜杠，跨平台需用 `path` 包处理
5. **图表布局**: `graphview` 库节点ID必须唯一，否则会覆盖

## 模块变更日志

每个模块的变更历史记录在 `docs/{模块}/CHANGELOG.md`，排查问题时优先阅读。

## 文档索引

| 模块 | README | API文档 | 数据模型 | 坑点 | CHANGELOG | 状态 |
|------|--------|---------|----------|------|-----------|------|
| shared/models | [链接](docs/shared-models/README.md) | - | ✓ | ✓ | ✓ | ✅ 完成 |
| shared/providers | [链接](docs/shared-providers/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| shared/services | [链接](docs/shared-services/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| features/workspace | [链接](docs/features-workspace/README.md) | ✓ | ✓ | ✓ | ✓ | ✅ 完成 |
| features/modeling | [链接](docs/features-modeling/README.md) | ✓ | ✓ | ✓ | - | ✅ 完成 |
| features/settings | [链接](docs/features-settings/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| features/project | [链接](docs/features-project/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| features/codegen | [链接](docs/features-codegen/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| features/datatype | [链接](docs/features-datatype/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
| features/home | [链接](docs/features-home/README.md) | - | ✓ | ✓ | - | ✅ 完成 |
