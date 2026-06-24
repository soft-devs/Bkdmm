# Bkdmm Flutter 项目目录重构方案

## 文档信息
- **创建日期**: 2026-06-24
- **项目**: Bkdmm - 数据库模型建模工具
- **当前分支**: refactor/ui-tdesign-full
- **Flutter SDK**: ^3.8.0
- **状态管理**: Riverpod

---

## 一、当前项目结构分析

### 1.1 当前目录结构
```
lib/
├── main.dart                    # 应用入口
├── constants/                   # 常量定义
│   └── app_constants.dart
├── utils/                       # 工具类
│   └── id_generator.dart
├── app/                         # 应用层
│   ├── main.dart
│   ├── app.dart
│   └── app_theme.dart
├── shared/                      # 共享模块
│   ├── models/                  # 数据模型 (13个文件)
│   ├── providers/               # 状态管理 (4个文件)
│   ├── services/                # 服务层 (5个文件)
│   ├── widgets/                 # 公共组件
│   ├── constants/
│   ├── theme/
│   └── diagram_editor/          # 图表编辑器框架
│       └── src/
│           ├── core/
│           ├── layout/
│           └── render/
└── features/                    # 功能模块
    ├── home/
    ├── project/
    ├── workspace/
    ├── settings/
    ├── datatype/
    ├── codegen/
    └── modeling/
        ├── entity_editor/
        ├── er_diagram/
        └── flowchart/
```

### 1.2 存在的问题

#### 问题 1: 命名风格不统一
| 问题类型 | 当前状态 | 示例 |
|---------|---------|------|
| 文件命名 | 混合使用下划线和驼峰 | `er_diagram.dart` vs `erDiagram.dart` |
| 目录命名 | 部分使用缩写 | `er_diagram` vs `entity_editor` |
| 变量命名 | 中英混用注释 | `chnname` (中文姓名) |

#### 问题 2: 模块边界不清晰
- `shared/models/` 包含业务模型，但 `features/modeling/` 也有模型
- `shared/providers/` 与 `features/*/providers/` 职责重叠
- `shared/services/` 与 `features/*/services/` 边界模糊

#### 问题 3: 缺少分层架构
- 没有 `domain` 层（领域层）
- `data` 层与业务逻辑混杂
- 缺少 `repository` 抽象

#### 问题 4: 依赖关系混乱
```
main.dart → app/app.dart → features/* → shared/*
                      ↓
              shared/providers → shared/services
                      ↓
              shared/models
```
问题：循环依赖风险，业务逻辑泄漏到 UI 层

#### 问题 5: 图表编辑器架构过于复杂
```
shared/diagram_editor/src/
├── core/           # 核心抽象
├── layout/         # 布局引擎
└── render/         # 渲染器
```
对于当前项目规模，这个抽象层级可能过度设计

---

## 二、Flutter 大型项目架构最佳实践

### 2.1 主流架构模式对比

| 架构模式 | 优点 | 缺点 | 适用场景 |
|---------|------|------|---------|
| **Feature-First** | 功能内聚，易于导航 | 共享代码管理复杂 | 中大型项目 |
| **Layer-First** | 分层清晰，职责明确 | 功能分散，难以维护 | 小型项目 |
| **Clean Architecture** | 高度解耦，易测试 | 学习曲线陡峭 | 企业级项目 |
| **MVVM + Riverpod** | 状态管理简洁 | ViewModel 过多可能冗余 | 中型项目 |

### 2.2 推荐架构：Feature-First + Clean Architecture 混合

结合 Bkdmm 项目特点，推荐采用 **Feature-First + 领域驱动设计 (DDD)** 的混合架构：

```
lib/
├── main.dart                    # 应用入口
├── app/                         # 应用层 (应用级配置)
│   ├── app.dart
│   ├── router/                  # 路由配置
│   └── theme/                   # 主题配置
├── core/                        # 核心层 (跨功能共享)
│   ├── constants/               # 常量
│   ├── errors/                  # 错误处理
│   ├── extensions/              # 扩展方法
│   ├── network/                 # 网络层
│   ├── storage/                 # 存储抽象
│   └── utils/                   # 工具类
├── domain/                      # 领域层 (业务核心)
│   ├── entities/                # 领域实体
│   ├── repositories/            # 仓储接口
│   └── usecases/                # 用例/业务逻辑
├── data/                        # 数据层
│   ├── models/                  # 数据模型 (DTO)
│   ├── repositories/            # 仓储实现
│   └── datasources/             # 数据源
└── features/                    # 功能模块
    ├── home/
    ├── project/
    ├── workspace/
    ├── settings/
    ├── modeling/                # 建模模块 (核心功能)
    └── codegen/                 # 代码生成模块
```

---

## 三、重构后目录结构设计

### 3.1 完整目录结构

```
lib/
├── main.dart                           # 应用入口
│
├── app/                                # 应用层
│   ├── app.dart                        # MaterialApp 配置
│   ├── router/                         # 路由管理
│   │   ├── app_router.dart
│   │   └── routes.dart
│   └── theme/                          # 主题配置
│       ├── app_theme.dart
│       ├── light_theme.dart
│       ├── dark_theme.dart
│       └── td_theme.dart               # TDesign 主题适配
│
├── core/                               # 核心层
│   ├── constants/                      # 常量定义
│   │   ├── app_constants.dart
│   │   └── default_data_types.dart
│   ├── errors/                         # 错误处理
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   ├── extensions/                     # 扩展方法
│   │   ├── string_extension.dart
│   │   ├── datetime_extension.dart
│   │   └── widget_extension.dart
│   ├── services/                       # 核心服务
│   │   ├── storage_service.dart
│   │   └── file_service.dart
│   └── utils/                          # 工具类
│       ├── id_generator.dart
│       ├── json_utils.dart
│       └── logger.dart
│
├── domain/                             # 领域层
│   ├── entities/                       # 领域实体
│   │   ├── module.dart
│   │   ├── entity.dart                 # 数据表实体
│   │   ├── field.dart
│   │   ├── index.dart
│   │   ├── data_type.dart
│   │   └── project.dart
│   ├── value_objects/                  # 值对象
│   │   ├── field_type.dart
│   │   ├── relation_type.dart
│   │   └── graph_position.dart
│   ├── repositories/                   # 仓储接口
│   │   ├── project_repository.dart
│   │   ├── module_repository.dart
│   │   └── history_repository.dart
│   └── usecases/                       # 用例
│       ├── project/
│       │   ├── create_project.dart
│       │   ├── open_project.dart
│       │   └── save_project.dart
│       ├── module/
│       │   ├── create_module.dart
│       │   ├── update_module.dart
│       │   └── delete_module.dart
│       └── entity/
│           ├── create_entity.dart
│           └── update_entity.dart
│
├── data/                               # 数据层
│   ├── models/                         # 数据模型 (DTO + JSON序列化)
│   │   ├── module_dto.dart
│   │   ├── entity_dto.dart
│   │   ├── field_dto.dart
│   │   ├── project_dto.dart
│   │   └── history_dto.dart
│   ├── repositories/                   # 仓储实现
│   │   ├── project_repository_impl.dart
│   │   ├── module_repository_impl.dart
│   │   └── history_repository_impl.dart
│   ├── datasources/                    # 数据源
│   │   ├── local/
│   │   │   ├── hive_datasource.dart
│   │   │   └── file_datasource.dart
│   │   └── mappers/
│   │       ├── module_mapper.dart
│   │       └── entity_mapper.dart
│   └── services/                       # 数据服务
│       ├── history_service.dart
│       └── project_file_service.dart
│
├── features/                           # 功能模块 (Feature-First)
│   │
│   ├── home/                           # 首页模块
│   │   ├── home.dart                   # 模块导出
│   │   ├── data/
│   │   │   └── home_repository.dart
│   │   ├── domain/
│   │   │   └── get_recent_projects.dart
│   │   ├── presentation/               # 表现层
│   │   │   ├── home_view.dart
│   │   │   ├── home_controller.dart    # Riverpod Notifier
│   │   │   └── home_state.dart
│   │   └── widgets/
│   │       ├── history_list_tile.dart
│   │       ├── quick_action_card.dart
│   │       └── empty_state_widget.dart
│   │
│   ├── project/                        # 项目管理模块
│   │   ├── project.dart
│   │   ├── data/
│   │   │   ├── project_repository_impl.dart
│   │   │   └── data_migration.dart
│   │   ├── domain/
│   │   │   ├── create_project.dart
│   │   │   └── open_project.dart
│   │   ├── presentation/
│   │   │   ├── project_controller.dart
│   │   │   └── project_state.dart
│   │   └── widgets/
│   │       ├── create_project_dialog.dart
│   │       └── open_project_dialog.dart
│   │
│   ├── workspace/                      # 工作区模块
│   │   ├── workspace.dart
│   │   ├── presentation/
│   │   │   ├── workspace_view.dart
│   │   │   ├── workspace_controller.dart
│   │   │   └── workspace_state.dart
│   │   └── widgets/
│   │       ├── module_tree.dart
│   │       ├── tab_bar_widget.dart
│   │       └── sidebar_widget.dart
│   │
│   ├── modeling/                       # 建模模块 (核心)
│   │   ├── modeling.dart
│   │   │
│   │   ├── entity_editor/              # 实体编辑器
│   │   │   ├── entity_editor.dart
│   │   │   ├── presentation/
│   │   │   │   ├── entity_editor_view.dart
│   │   │   │   ├── entity_editor_controller.dart
│   │   │   │   └── entity_editor_state.dart
│   │   │   └── widgets/
│   │   │       ├── field_table.dart
│   │   │       ├── index_editor.dart
│   │   │       └── code_preview.dart
│   │   │
│   │   ├── er_diagram/                 # ER图编辑器
│   │   │   ├── er_diagram.dart
│   │   │   ├── domain/
│   │   │   │   ├── er_node.dart
│   │   │   │   ├── er_edge.dart
│   │   │   │   └── er_layout.dart
│   │   │   ├── presentation/
│   │   │   │   ├── er_diagram_view.dart
│   │   │   │   ├── er_diagram_controller.dart
│   │   │   │   └── er_diagram_state.dart
│   │   │   └── widgets/
│   │   │       ├── er_canvas.dart
│   │   │       ├── er_node_widget.dart
│   │   │       └── er_edge_widget.dart
│   │   │
│   │   └── flowchart/                  # 流程图编辑器
│   │       ├── flowchart.dart
│   │       ├── domain/
│   │       ├── presentation/
│   │       └── widgets/
│   │
│   ├── codegen/                        # 代码生成模块
│   │   ├── codegen.dart
│   │   ├── domain/
│   │   │   ├── template_engine.dart
│   │   │   └── code_generator.dart
│   │   ├── data/
│   │   │   ├── template_service.dart
│   │   │   └── codegen_service.dart
│   │   ├── presentation/
│   │   │   ├── codegen_view.dart
│   │   │   ├── codegen_controller.dart
│   │   │   └── codegen_state.dart
│   │   └── templates/                  # 模板文件配置
│   │       └── template_config.dart
│   │
│   ├── datatype/                       # 数据类型管理模块
│   │   ├── datatype.dart
│   │   ├── domain/
│   │   │   ├── data_type_definition.dart
│   │   │   └── type_mapping.dart
│   │   ├── presentation/
│   │   │   ├── datatype_view.dart
│   │   │   ├── datatype_controller.dart
│   │   │   └── datatype_edit_dialog.dart
│   │   └── data/
│   │       └── datatype_repository.dart
│   │
│   └── settings/                       # 设置模块
│       ├── settings.dart
│       ├── presentation/
│       │   ├── settings_view.dart
│       │   ├── settings_controller.dart
│       │   └── settings_state.dart
│       └── domain/
│           └── settings_repository.dart
│
└── shared/                             # 共享组件 (精简后)
    ├── widgets/                        # 通用 UI 组件
    │   ├── app_scaffold.dart
    │   ├── loading_overlay.dart
    │   └── common_dialogs.dart
    └── providers/                      # 全局状态
        ├── providers.dart
        └── global_providers.dart
```

### 3.2 关键设计决策

#### 决策 1: 采用 Feature-First 组织
- **每个功能模块自包含**：包含自己的 data、domain、presentation 层
- **减少跨模块依赖**：模块间通过领域接口通信
- **便于团队协作**：不同开发者可独立开发不同功能

#### 决策 2: 引入领域层 (Domain Layer)
- **领域实体**：纯业务对象，无框架依赖
- **值对象**：封装业务规则（如字段类型验证）
- **仓储接口**：定义在领域层，实现在数据层
- **用例**：封装单一业务操作

#### 决策 3: 统一命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | snake_case | `entity_editor_view.dart` |
| 类名 | PascalCase | `EntityEditorView` |
| 变量 | camelCase | `entityEditorController` |
| 常量 | camelCase | `maxFieldLength` |
| 私有成员 | _camelCase | `_isLoading` |
| 目录名 | snake_case | `entity_editor/` |

#### 决策 4: 简化图表编辑器架构
```
# 重构前
shared/diagram_editor/
├── src/
│   ├── core/
│   ├── layout/
│   └── render/

# 重构后 (直接内联到功能模块)
features/modeling/
├── er_diagram/
│   ├── domain/          # 领域模型
│   ├── presentation/    # 控制器和状态
│   └── widgets/         # UI组件
└── flowchart/
    ├── domain/
    ├── presentation/
    └── widgets/
```

---

## 四、命名规范化

### 4.1 中文命名问题修复

当前代码中存在中文缩写命名，建议修改：

| 当前命名 | 建议命名 | 说明 |
|---------|---------|------|
| `chnname` | `displayName` | 显示名称（中文） |
| `remark` | `description` | 描述/备注 |

### 4.2 模型命名规范化

```dart
// 重构前
class Entity {
  final String chnname;  // 中文名
  final String? remark;  // 备注
}

// 重构后
class Entity {
  final String name;           // 代码名（英文）
  final String displayName;    // 显示名称（中文）
  final String? description;   // 描述
}
```

### 4.3 文件导出规范

每个模块目录应包含一个导出文件（如 `entity_editor.dart`）：

```dart
// entity_editor.dart
export 'presentation/entity_editor_view.dart';
export 'presentation/entity_editor_controller.dart';
export 'widgets/field_table.dart';
export 'widgets/index_editor.dart';
```

---

## 五、迁移策略

### 5.1 迁移顺序（推荐）

```
Phase 1: 基础设施层（1-2天）
├── 创建新的目录结构
├── 迁移 core/ 和 app/ 层
└── 更新 main.dart

Phase 2: 领域层重构（2-3天）
├── 提取领域实体
├── 定义仓储接口
└── 创建用例类

Phase 3: 数据层重构（2-3天）
├── 迁移数据模型
├── 实现仓储
└── 数据源抽象

Phase 4: 功能模块迁移（3-5天）
├── home 模块
├── project 模块
├── workspace 模块
├── modeling 模块（核心）
├── codegen 模块
├── datatype 模块
└── settings 模块

Phase 5: 清理与优化（1-2天）
├── 删除旧代码
├── 更新导入
└── 运行测试
```

### 5.2 风险控制

1. **分支策略**：在 `refactor/ui-tdesign-full` 分支进行重构
2. **增量迁移**：每次只迁移一个模块，确保编译通过
3. **保留原代码**：迁移完成前不删除旧文件
4. **测试覆盖**：每个迁移的模块需通过 `flutter analyze`

---

## 六、文件映射表

### 6.1 核心层迁移

| 原路径 | 新路径 |
|--------|--------|
| `lib/constants/app_constants.dart` | `lib/core/constants/app_constants.dart` |
| `lib/shared/constants/default_data_types.dart` | `lib/core/constants/default_data_types.dart` |
| `lib/utils/id_generator.dart` | `lib/core/utils/id_generator.dart` |
| `lib/shared/services/storage_service.dart` | `lib/core/services/storage_service.dart` |
| `lib/shared/services/file_service.dart` | `lib/core/services/file_service.dart` |

### 6.2 领域层迁移

| 原路径 | 新路径 |
|--------|--------|
| `lib/shared/models/entity.dart` | `lib/domain/entities/entity.dart` |
| `lib/shared/models/module.dart` | `lib/domain/entities/module.dart` |
| `lib/shared/models/project.dart` | `lib/domain/entities/project.dart` |
| `lib/shared/models/data_type.dart` | `lib/domain/entities/data_type.dart` |

### 6.3 功能模块迁移

| 原路径 | 新路径 |
|--------|--------|
| `lib/features/home/views/home_view.dart` | `lib/features/home/presentation/home_view.dart` |
| `lib/features/project/views/create_project_dialog.dart` | `lib/features/project/widgets/create_project_dialog.dart` |
| `lib/features/modeling/entity_editor/views/entity_editor_view.dart` | `lib/features/modeling/entity_editor/presentation/entity_editor_view.dart` |

---

## 七、代码示例

### 7.1 领域实体示例

```dart
// lib/domain/entities/entity.dart
import 'package:uuid/uuid.dart';
import 'field.dart';
import 'index.dart';

/// 数据表实体（领域层）
class Entity {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final List<Field> fields;
  final List<Index> indexes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Entity({
    String? id,
    required this.name,
    required this.displayName,
    this.description,
    List<Field>? fields,
    List<Index>? indexes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        fields = fields ?? [],
        indexes = indexes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 获取主键字段
  List<Field> get primaryKeys => fields.where((f) => f.isPrimaryKey).toList();

  Entity copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    List<Field>? fields,
    List<Index>? indexes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      fields: fields ?? this.fields,
      indexes: indexes ?? this.indexes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 7.2 仓储接口示例

```dart
// lib/domain/repositories/project_repository.dart
import '../entities/project.dart';
import '../entities/module.dart';

/// 项目仓储接口
abstract class ProjectRepository {
  /// 创建新项目
  Future<Project> createProject({
    required String name,
    String? description,
    required String filePath,
  });

  /// 打开项目
  Future<Project> openProject(String filePath);

  /// 保存项目
  Future<void> saveProject(Project project);

  /// 获取项目中的所有模块
  Future<List<Module>> getModules(String projectId);

  /// 添加模块
  Future<Module> addModule(String projectId, Module module);

  /// 更新模块
  Future<Module> updateModule(Module module);

  /// 删除模块
  Future<void> deleteModule(String projectId, String moduleId);
}
```

### 7.3 用例示例

```dart
// lib/domain/usecases/project/create_project.dart
import '../../entities/project.dart';
import '../../repositories/project_repository.dart';

/// 创建项目用例
class CreateProject {
  final ProjectRepository _repository;

  CreateProject(this._repository);

  Future<Project> call({
    required String name,
    String? description,
    required String filePath,
  }) async {
    // 业务逻辑验证
    if (name.isEmpty) {
      throw ArgumentError('Project name cannot be empty');
    }

    // 调用仓储创建项目
    return await _repository.createProject(
      name: name,
      description: description,
      filePath: filePath,
    );
  }
}
```

### 7.4 Controller 示例

```dart
// lib/features/home/presentation/home_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/usecases/project/create_project.dart';
import '../../../../domain/usecases/project/open_project.dart';
import 'home_state.dart';

class HomeController extends StateNotifier<HomeState> {
  final CreateProject _createProject;
  final OpenProject _openProject;

  HomeController({
    required CreateProject createProject,
    required OpenProject openProject,
  })  : _createProject = createProject,
        _openProject = openProject,
        super(const HomeState.initial());

  Future<void> createProject({
    required String name,
    String? description,
    required String filePath,
  }) async {
    state = const HomeState.loading();

    try {
      final project = await _createProject(
        name: name,
        description: description,
        filePath: filePath,
      );
      state = HomeState.projectCreated(project);
    } catch (e) {
      state = HomeState.error(e.toString());
    }
  }
}

// Provider 定义
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    // 依赖注入
    return HomeController(
      createProject: ref.watch(createProjectProvider),
      openProject: ref.watch(openProjectProvider),
    );
  },
);
```

---

## 八、重构检查清单

### 8.1 每个模块迁移检查

- [ ] 目录结构创建完成
- [ ] 领域实体迁移完成
- [ ] 仓储接口定义完成
- [ ] 仓储实现迁移完成
- [ ] Controller/Notifier 重构完成
- [ ] View 层迁移完成
- [ ] Widget 组件迁移完成
- [ ] 导出文件 (模块.dart) 创建完成
- [ ] 所有导入路径更新
- [ ] `flutter analyze` 无错误
- [ ] 功能测试通过

### 8.2 全局检查

- [ ] 命名规范化完成
- [ ] 中文注释/命名处理完成
- [ ] 无循环依赖
- [ ] 无未使用的导入
- [ ] 测试覆盖关键业务逻辑
- [ ] 文档更新完成

---

## 九、参考资料

### 9.1 架构模式
- Clean Architecture by Robert C. Martin
- Domain-Driven Design by Eric Evans
- Flutter Architecture Samples (github.com/brianegan/flutter_architecture_samples)

### 9.2 Flutter 最佳实践
- Effective Dart: Style Guide
- Flutter Documentation: Architecture
- Riverpod Best Practices by Andrea Bizzotto

### 9.3 相关项目
- Very Good CLI (Very Good Ventures)
- Flutter News Toolkit
- Stagehand Templates

---

## 十、版本历史

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| 1.0.0 | 2026-06-24 | 初始版本，完整重构方案 |
