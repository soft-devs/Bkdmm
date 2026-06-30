# Bkdmm - 数据库模型建模工具

## 概述

BK Datasource Model Manager (Bkdmm) 是一款桌面端数据库模型建模工具，支持可视化ER图编辑、代码生成(DDL/实体类)、项目管理等功能。面向开发者和DBA，用于快速设计和生成数据库模型代码。

## 构建

**运行时要求**: Flutter 3.32+ / Dart 3.8+ / Windows 10+

```bash
cd bkdmm
flutter pub get          # 安装依赖
flutter analyze          # 静态分析
flutter run -d windows   # Windows桌面运行
```

## 项目结构

```
bkdmm/lib/
├── main.dart                 # 应用入口
├── app/                      # 应用配置层 (3文件)
│   ├── app.dart              # 主应用Widget
│   ├── app_theme.dart        # 主题配置
│   └── main.dart             # 入口函数
├── core/i18n/                # 国际化支持 (4文件)
├── constants/                # 默认常量 (1文件)
├── utils/                    # 工具类 (7文件)
├── l10n/                     # ARB翻译文件 (4文件)
├── shared/                   # 共享模块 (90文件)
│   ├── models/               # 核心数据模型 (13文件)
│   ├── providers/            # 全局状态管理 (5文件)
│   ├── services/             # 服务层 (5文件)
│   ├── widgets/              # 通用UI组件 (3文件)
│   ├── diagram_editor/       # 图编辑器引擎 (44文件)
│   ├── log_viewer/           # 日志查看器 (11文件)
│   ├── terminal/             # 终端组件 (6文件)
│   ├── theme/                # TDesign主题 (1文件)
│   └── utils/                # 工具类 (1文件)
└── features/                 # 业务功能模块 (84文件)
    ├── home/                 # 主页 (3文件)
    ├── workspace/            # 工作区 (24文件)
    ├── modeling/             # 建模 (14文件)
    ├── project/              # 项目管理 (11文件)
    ├── codegen/              # 代码生成 (5文件)
    ├── datatype/             # 数据类型 (7文件)
    └── settings/             # 设置 (20文件)
```

## 模块索引

### 基础层 (40文件)

| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| shared/models | 核心数据模型(Project/Entity/Module/Field) | 13 | [README](docs/shared-models/README.md) |
| shared/providers | 全局状态管理(Riverpod Providers) | 5 | [README](docs/shared-providers/README.md) |
| shared/services | 存储服务、文件服务、项目服务 | 5 | [README](docs/shared-services/README.md) |
| shared/widgets | 通用UI组件(AppScaffold, LoadingOverlay) | 3 | [README](docs/shared-widgets/README.md) |
| utils | ID生成器、日志服务 | 7 | [README](docs/utils/README.md) |
| core/i18n | 国际化支持(zh/en) | 4 | [README](docs/core-i18n/README.md) |
| constants | 默认数据类型常量 | 1 | [README](docs/constants/README.md) |
| shared/theme | TDesign主题适配 | 1 | [README](docs/shared-theme/README.md) |
| shared/utils | 响应式布局工具 | 1 | [README](docs/shared-utils/README.md) |

### 业务层 (84文件)

| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| shared/diagram_editor | **核心组件**: 图编辑器引擎 | 44 | [README](docs/shared-diagram_editor/README.md) |
| features/workspace | **主业务界面**: 工作区布局 | 24 | [README](docs/features-workspace/README.md) |
| features/modeling | **核心业务**: 实体编辑器、ER图编辑 | 14 | [README](docs/features-modeling/README.md) |
| features/project | 项目管理(创建/打开/保存) | 11 | [README](docs/features-project/README.md) |
| features/settings | 设置界面(全局/项目) | 20 | [README](docs/features-settings/README.md) |
| shared/log_viewer | 日志查看器组件 | 11 | [README](docs/shared-log_viewer/README.md) |
| features/datatype | 数据类型管理 | 7 | [README](docs/features-datatype/README.md) |
| shared/terminal | 终端模拟组件 | 6 | [README](docs/shared-terminal/README.md) |
| features/codegen | 代码生成(DDL/实体类) | 5 | [README](docs/features-codegen/README.md) |
| features/home | 主页视图、历史记录 | 3 | [README](docs/features-home/README.md) |

### 配置层 (3文件)

| 模块 | 描述 | 文件数 | 文档链接 |
|------|------|--------|----------|
| app | 应用入口、主题配置 | 3 | [README](docs/app/README.md) |
| l10n | ARB翻译文件(自动生成) | 4 | - |

## 核心架构

```
┌─────────────────────────────────────────────────────────────┐
│                      用户界面层                              │
│  HomeView → WorkspaceView → EntityEditorView/ERDiagramCanvas │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                      状态管理层 (Riverpod)                   │
│  SettingsProvider → ProjectProvider → EntityProvider         │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                      服务层                                  │
│  StorageService → ProjectService → FileService               │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                      数据模型层                              │
│  Project → Module → Entity → Field/Index                     │
└─────────────────────────────────────────────────────────────┘
```

## 模块依赖关系

```
main.dart
    └── app/app.dart
            ├── core/i18n (国际化)
            ├── shared/providers (状态管理)
            │       └── shared/models
            │       └── shared/services
            └── features/home
                    └── features/workspace
                            ├── shared/diagram_editor
                            │       └── shared/models
                            ├── features/modeling
                            │       └── shared/diagram_editor
                            ├── features/project
                            │       └── shared/services
                            └── features/settings
                                    └── shared/providers
```

## 环境配置

- **开发环境**: `flutter run -d windows`
- **构建发布**: `flutter build windows`
- **国际化**: 支持 zh(中文) / en(英文)，ARB文件位于 `lib/l10n/`

## 重要坑点

1. **shared/diagram_editor**: 图编辑器使用 GraphView 布局引擎，节点位置计算需考虑缩放偏移
2. **shared/models**: Entity/Field 的 ID 必须唯一，使用 `IdGenerator.generate()` 生成
3. **shared/services/StorageService**: Hive 初始化必须在 `main()` 中调用
4. **features/project**: 项目文件格式为 JSON，版本兼容性需注意
5. **core/i18n**: TDesign 组件国际化需通过 `AppTDResourceDelegate` 适配

## 模块变更日志

每个模块的变更历史记录在 `.claude/docs/{模块}/CHANGELOG.md`，排查问题时优先阅读。

## 文档索引

| 模块 | README | API文档 | 数据模型 | 坑点 | 状态 |
|------|--------|---------|----------|------|------|
| shared/models | [链接](docs/shared-models/README.md) | - | [data-model](docs/shared-models/data-model.md) | [pitfalls](docs/shared-models/pitfalls.md) | ⏳ |
| shared/providers | [链接](docs/shared-providers/README.md) | [api-providers](docs/shared-providers/api-providers.md) | - | [pitfalls](docs/shared-providers/pitfalls.md) | ⏳ |
| shared/services | [链接](docs/shared-services/README.md) | [api-services](docs/shared-services/api-services.md) | - | [pitfalls](docs/shared-services/pitfalls.md) | ⏳ |
| shared/diagram_editor | [链接](docs/shared-diagram_editor/README.md) | [api-diagram](docs/shared-diagram_editor/api-diagram.md) | [data-model](docs/shared-diagram_editor/data-model.md) | [pitfalls](docs/shared-diagram_editor/pitfalls.md) | ⏳ |
| features/workspace | [链接](docs/features-workspace/README.md) | [api-workspace](docs/features-workspace/api-workspace.md) | [data-model](docs/features-workspace/data-model.md) | [pitfalls](docs/features-workspace/pitfalls.md) | ⏳ |
| features/modeling | [链接](docs/features-modeling/README.md) | [api-modeling](docs/features-modeling/api-modeling.md) | [data-model](docs/features-modeling/data-model.md) | [pitfalls](docs/features-modeling/pitfalls.md) | ⏳ |
| features/project | [链接](docs/features-project/README.md) | [api-project](docs/features-project/api-project.md) | [data-model](docs/features-project/data-model.md) | [pitfalls](docs/features-project/pitfalls.md) | ⏳ |

## 开发指南

### 组件/页面开发流程

开发新组件或页面时，**必须参考** [容器布局设计文档](docs/container-layout-design/README.md) 以减少溢出问题：

| 阶段 | 参考文档 | 说明 |
|------|----------|------|
| **设计前** | [04-best-practices.md](docs/container-layout-design/04-best-practices.md) | 确认项目布局规范、尺寸常量 |
| **编码时** | [05-component-patterns.md](docs/container-layout-design/05-component-patterns.md) | 使用标准布局模板代码 |
| **TDesign 组件** | [06-tdesign-notes.md](docs/container-layout-design/06-tdesign-notes.md) | 查看组件使用注意事项 |
| **遇到溢出** | [03-solutions-guide.md](docs/container-layout-design/03-solutions-guide.md) | 查找解决方案 |
| **提交前** | [README.md](docs/container-layout-design/README.md) | 使用检查清单确认 |

### 布局开发检查清单

每次开发组件/页面时检查：

- [ ] Row/Column 子组件是否使用 Expanded/Flexible？
- [ ] 文本是否设置 overflow: TextOverflow.ellipsis？
- [ ] 图片是否设置 fit: BoxFit.cover/contain？
- [ ] ListView/GridView 是否有父组件约束？
- [ ] 是否使用 LayoutSpacing/Height/Width 常量？
