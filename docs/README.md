# Bkdmm - 数据库模型建模工具

> **BK Datasource Model Manager** - 免费、简洁、实用的跨平台数据库模型建模工具

## 概述

Bkdmm 是一款对标 PowerDesigner 的数据库建模工具，使用 Flutter 开发，专注于为开发人员和小团队提供简洁、高效、免费的数据表设计和代码生成解决方案。支持 Windows / macOS / Linux 全平台。

## 构建

### 环境要求
- Flutter SDK >= 3.8.0
- Dart SDK >= 3.8.0
- Git

### 构建命令
```bash
# 安装依赖
flutter pub get

# 生成 JSON 序列化代码
dart run build_runner build

# 启动开发模式
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux

# 构建发布版本
flutter build windows --release
```

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| UI框架 | Flutter | 3.8+ |
| 编程语言 | Dart | 3.8+ |
| 状态管理 | Riverpod | 2.4+ |
| 本地存储 | Hive | 2.2+ |
| UI组件库 | TDesign Flutter | 0.1.4 |
| 表格组件 | Syncfusion DataGrid | 24.1+ |
| 图布局 | graphview | 1.2.0 |
| 模板引擎 | mustache_template | 2.0+ |

## 项目结构

```
bkdmm/lib/
├── main.dart                    # 应用入口
├── app/                         # 应用全局配置 (3 files)
│   ├── app.dart                 # BkdmmApp 根组件
│   ├── app_theme.dart           # 主题配置
│   └── main.dart                # 备用入口
├── features/                    # 功能模块 (39 files)
│   ├── project/                 # 项目管理 (6 files)
│   ├── workspace/               # 工作区 (5 files)
│   ├── modeling/                # 数据建模核心 (15 files)
│   │   ├── entity_editor/       # 实体编辑器
│   │   ├── er_diagram/          # ER图组件
│   │   └── flowchart/           # 流程图
│   ├── codegen/                 # 代码生成 (5 files)
│   ├── datatype/                # 数据类型管理 (4 files)
│   ├── home/                    # 首页 (2 files)
│   └── settings/                # 设置 (2 files)
└── shared/                      # 共享层 (35 files)
    ├── models/                  # 数据模型 (13 files)
    ├── providers/               # 状态管理 (4 files)
    ├── services/                # 服务层 (5 files)
    ├── diagram_editor/          # 图表编辑框架 (9 files)
    ├── widgets/                 # 通用组件 (3 files)
    ├── theme/                   # 主题配置 (1 file)
    └── constants/               # 常量定义
```

## 模块索引

### 基础层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| shared/models | 数据模型定义 (Entity, Module, Project, DataType 等) | 13 | [README](shared/models/README.md) |
| shared/providers | Riverpod 状态管理 (projectProvider, historyProvider, settingsProvider) | 4 | [README](shared/providers/README.md) |
| shared/services | 服务层 (StorageService, FileService, HistoryService, ProjectService) | 5 | [README](shared/services/README.md) |
| shared/diagram_editor | 通用图表编辑框架 (节点、边、画布、布局) | 9 | [README](shared/diagram_editor/README.md) |
| shared/widgets | 通用UI组件 (AppScaffold, LoadingOverlay) | 3 | [README](shared/widgets/README.md) |
| shared/theme | TDesign 主题集成 | 1 | - |
| shared/constants | 常量定义 (默认数据类型) | 1 | - |

### 业务层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| features/project | 项目管理 (创建/打开/保存/历史/迁移) | 6 | [README](features/project/README.md) |
| features/workspace | 工作区 (模块树、Tab管理、属性面板) | 5 | [README](features/workspace/README.md) |
| features/modeling | 数据建模核心 (实体编辑、ER图、流程图) | 15 | [README](features/modeling/README.md) |
| features/codegen | 代码生成 (DDL、Java实体类) | 5 | [README](features/codegen/README.md) |
| features/datatype | 数据类型管理 (抽象类型与数据库映射) | 4 | [README](features/datatype/README.md) |
| features/home | 首页 (项目历史、快速入口) | 2 | [README](features/home/README.md) |
| features/settings | 设置页面 | 2 | [README](features/settings/README.md) |

### 应用层
| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| app | 应用全局配置、主题、入口 | 3 | - |

## 核心架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        表现层 (Presentation)                     │
│    HomeView   │  WorkspaceView  │  EntityEditor  │  Settings    │
│    (Widgets)  │  (Tabs + Tree)  │  (DataGrid)    │  (Dialogs)   │
├─────────────────────────────────────────────────────────────────┤
│                        业务逻辑层 (Business Logic)               │
│    ProjectProvider │ EntityProvider │ CodegenProvider           │
│    (Riverpod StateNotifier)                                      │
├─────────────────────────────────────────────────────────────────┤
│                        数据访问层 (Data Access)                  │
│    StorageService │ FileService │ HistoryService                │
│    (Hive 本地存储 + JSON 文件读写)                               │
├─────────────────────────────────────────────────────────────────┤
│                        基础设施层 (Infrastructure)               │
│           Flutter SDK / Dart AOT / Platform Channels            │
└─────────────────────────────────────────────────────────────────┘
```

## 模块依赖关系

```
app
├── features/home → shared
├── features/workspace → shared, features/modeling, features/datatype
├── features/modeling → shared/diagram_editor
├── features/codegen → shared/services
└── shared
    ├── models (无依赖)
    ├── providers → models, services
    ├── services → models
    ├── diagram_editor → graphview
    └── widgets (无依赖)
```

## 环境配置

项目使用 Hive 进行本地存储，配置文件存储在：
- Windows: `%APPDATA%/bkdmm/`
- macOS: `~/Library/Application Support/bkdmm/`
- Linux: `~/.local/share/bkdmm/`

项目文件格式：`.bkdmm` (JSON 格式)

## 重要坑点

1. **JSON 序列化** - 修改模型后需重新运行 `dart run build_runner build`
2. **Hive 初始化** - 必须在 `main()` 中调用 `StorageService.init()` 后才能使用存储
3. **图表编辑器** - diagram_editor 使用 graphview 进行布局，需要正确配置节点 ID
4. **Tab 管理** - WorkspaceView 中的 Tab 状态由 tabProvider 管理，关闭项目时需清理
5. **数据迁移** - 旧版本项目文件可能需要 data_migration.dart 进行格式转换

## 文档索引

| 文档 | 状态 | 说明 |
|------|------|------|
| [shared/models](shared/models/README.md) | ✅ | 数据模型文档 |
| [shared/providers](shared/providers/README.md) | ✅ | 状态管理文档 |
| [shared/services](shared/services/README.md) | ✅ | 服务层文档 |
| [shared/diagram_editor](shared/diagram_editor/README.md) | ✅ | 图表编辑框架文档 |
| [features/project](features/project/README.md) | ✅ | 项目管理文档 |
| [features/workspace](features/workspace/README.md) | ✅ | 工作区文档 |
| [features/modeling](features/modeling/README.md) | ✅ | 数据建模文档 |
| [features/codegen](features/codegen/README.md) | ✅ | 代码生成文档 |
| [features/datatype](features/datatype/README.md) | ✅ | 数据类型文档 |
| [features/home](features/home/README.md) | ✅ | 首页文档 |
| [features/settings](features/settings/README.md) | ✅ | 设置文档 |
