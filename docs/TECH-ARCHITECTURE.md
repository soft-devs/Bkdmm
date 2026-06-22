# Bkdmm - Flutter 技术架构设计

> **框架抉择**: Flutter 🏆 (经过 Electron vs Flutter vs Qt 三方对比后选定)
> **原因**: 性能提升60%+，内存减少60%+，UI现代化程度高，跨平台一致性好
> **创建日期**: 2026-06-22

---

## 一、四层架构总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation 表现层                           │
│                                                                 │
│   HomePage      │  WorkspacePage  │  ERDiagramWidget            │
│   (项目首页)     │  (工作区管理)    │  (ER图自绘组件)              │
│                                                                 │
│   AppScaffold   │  Dialogs       │  Toolbars                   │
│   (通用框架)     │  (对话框合集)    │  (工具栏合集)                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Business Logic 业务逻辑层                     │
│                                                                 │
│   ProjectService│  ModelingService│  CodeGenService             │
│   (项目管理)     │  (数据建模核心)   │  (代码生成引擎)             │
│                                                                 │
│   TemplateEngine│  MigrationService│ ExportService              │
│   (模板引擎)     │  (数据版本迁移)    │  (导出服务)               │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Data Access 数据访问层                        │
│                                                                 │
│   Hive Storage │  FileService   │  ConfigService               │
│   (高性能本地存储)│  (JSON文件读写)  │  (配置管理)                 │
│                                                                 │
│   HistoryRepository │  TemplateRepository                      │
│   (历史记录仓库)     │  (模板仓库)                                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Infrastructure 基础设施层                     │
│                                                                 │
│   Dart/Flutter SDK  │  Windows/macOS/Linux Platform APIs       │
│   Riverpod (DI)     │  GoRouter (路由)  │  Hive DB Engine      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、技术栈选型

### 核心竞争力

| 层级 | 技术 | 版本 | 选择理由 |
|------|------|------|----------|
| 桌面框架 | Flutter | 3.8+ | 自绘引擎Skia，跨平台一致性好 |
| 编程语言 | Dart | 3.8+ | AOT编译，性能接近原生 |
| 状态管理 | Riverpod | 2.4+ | 编译时安全，自动销毁，测试友好 |
| 路由管理 | GoRouter | 14+ | Flutter官方推荐，声明式路由 |
| 本地存储 | Hive | 2.2+ | 纯Dart实现，高性能NoSQL |
| 文件操作 | dart:io + file_picker | - | Dart原生文件API |
| 表格组件 | syncfusion_datagrid | 24.1+ | 商业级组件，数据分析场景成熟 |
| 图形绘制 | CustomPainter (自研) | - | Flutter无成熟ER图组件，自主可控 |
| 模板引擎 | mustache_template | 2.0+ | Dart原生实现，语法兼容doT.js |
| 序列化 | json_serializable | 6.7+ | 编译时代码生成，零运行时开销 |

### 完整依赖清单

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理 - 编译时安全、自动销毁
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # 本地存储 - 高性能键值数据库
  hive_flutter: ^1.1.0

  # 文件选择 - 原生文件对话框
  file_picker: ^8.0.0

  # 路径工具
  path_provider: ^2.1.0

  # UI组件
  syncfusion_flutter_datagrid: ^24.1.0

  # 模板引擎
  mustache_template: ^2.0.0

  # JSON序列化
  json_annotation: ^4.8.0

  # UUID生成
  uuid: ^4.0.0

  # 国际化
  intl: ^0.19.0

  # Material Design图标扩展
  material_design_icons_flutter: ^7.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  hive_generator: ^2.0.0
```

---

## 三、项目目录结构

```
bkdmm/
├── lib/
│   ├── main.dart                     # 应用入口，ProviderScope + Hive初始化
│   │
│   ├── app/                          # 应用全局配置
│   │   ├── app.dart                  # MaterialApp + GoRouter配置
│   │   ├── app_theme.dart            # Material Design 3主题
│   │   └── app_router.dart           # 路由定义
│   │
│   ├── features/                     # 功能模块 (Feature-First架构)
│   │   ├── home/                     # 首页模块
│   │   │   ├── views/
│   │   │   │   └── home_view.dart
│   │   │   └── widgets/
│   │   │       └── history_list_tile.dart
│   │   │
│   │   ├── project/                  # 项目管理模块
│   │   │   ├── models/
│   │   │   │   └── project_history.dart
│   │   │   ├── services/
│   │   │   │   ├── project_file_service.dart
│   │   │   │   └── data_migration.dart
│   │   │   ├── providers/
│   │   │   │   └── project_provider.dart
│   │   │   └── views/
│   │   │       ├── create_project_dialog.dart
│   │   │       └── open_project_dialog.dart
│   │   │
│   │   ├── modeling/                 # 数据建模核心 ⚠️ 重点
│   │   │   ├── entity_editor/        # 表编辑器
│   │   │   │   ├── views/
│   │   │   │   │   └── entity_editor_view.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── field_table_widget.dart
│   │   │   │   │   ├── index_table_widget.dart
│   │   │   │   │   └── entity_header_panel.dart
│   │   │   │   └── providers/
│   │   │   │       └── entity_provider.dart
│   │   │   │
│   │   │   ├── er_diagram/           # ER图组件 ⚠️ 自研
│   │   │   │   ├── widgets/
│   │   │   │   │   └── er_diagram_widget.dart
│   │   │   │   ├── painters/
│   │   │   │   │   ├── node_painter.dart
│   │   │   │   │   └── edge_painter.dart
│   │   │   │   ├── layout/
│   │   │   │   │   └── dagre_layout.dart
│   │   │   │   ├── export/
│   │   │   │   │   └── image_export.dart
│   │   │   │   └── providers/
│   │   │   │       └── graph_provider.dart
│   │   │   │
│   │   │   └── workspace/            # 工作区管理
│   │   │       ├── views/
│   │   │       │   └── workspace_view.dart
│   │   │       └── providers/
│   │   │           └── tab_provider.dart
│   │   │
│   │   ├── codegen/                  # 代码生成模块
│   │   │   ├── services/
│   │   │   │   ├── codegen_service.dart
│   │   │   │   └── template_service.dart
│   │   │   ├── views/
│   │   │   │   └── codegen_view.dart
│   │   │   └── providers/
│   │   │       └── codegen_provider.dart
│   │   │
│   │   ├── datatype/                 # 数据类型管理
│   │   │   ├── views/
│   │   │   │   └── datatype_view.dart
│   │   │   └── providers/
│   │   │       └── datatype_provider.dart
│   │   │
│   │   └── settings/                 # 设置模块
│   │       ├── views/
│   │       │   └── settings_view.dart
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   ├── shared/                       # 共享层
│   │   ├── models/                   # 核心数据模型
│   │   │   ├── project.dart
│   │   │   ├── module.dart
│   │   │   ├── entity.dart
│   │   │   ├── data_type.dart
│   │   │   ├── version.dart
│   │   │   └── template_config.dart
│   │   │
│   │   ├── services/                 # 基础服务
│   │   │   ├── storage_service.dart  # Hive存储
│   │   │   ├── file_service.dart     # 文件操作
│   │   │   └── history_service.dart  # 历史记录
│   │   │
│   │   └── widgets/                  # 通用组件
│   │       ├── app_scaffold.dart
│   │       ├── loading_overlay.dart
│   │       ├── module_tree_widget.dart
│   │       └── confirm_dialog.dart
│   │
│   ├── constants/                    # 常量
│   │   ├── app_constants.dart
│   │   └── datatype_defaults.dart
│   │
│   └── utils/                        # 工具函数
│       ├── id_generator.dart
│       ├── json_utils.dart
│       └── string_utils.dart
│
├── assets/                           # 静态资源
│   ├── icons/
│   ├── templates/                    # 代码生成模板
│   │   ├── ddl/
│   │   │   ├── mysql_create_table.mustache
│   │   │   ├── postgresql_create_table.mustache
│   │   │   └── oracle_create_table.mustache
│   │   └── code/
│   │       └── java_entity.mustache
│   └── datatypes/                    # 数据类型预设
│       └── default_types.json
│
├── test/                             # 测试
│   ├── shared/
│   │   ├── models/
│   │   └── services/
│   └── features/
│       └── project/
│
├── windows/                          # Windows平台配置
├── macos/                            # macOS平台配置
├── linux/                            # Linux平台配置
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 四、IPC通信架构 (跨层级)

```
┌─────────────────────────────────────────────────────────────────┐
│ 表现层 (Presentation)                                            │
│                                                                 │
│  Consumer Widget ──read──► Provider ──watch──► StateNotifier    │
│       │                        ▲                     │          │
│       │                        │                     │          │
│       ▼                        │                     ▼          │
│  WidgetRef.read(provider) ──────┘           Service.call()      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ 业务逻辑层 (Business Logic)                                      │
│                                                                 │
│  StateNotifier ──call──► Service ──return──► State              │
│       │                       │                                 │
│       │                       ▼                                 │
│       │              Repository (数据仓库)                        │
│       │                       │                                 │
│       │                       ▼                                 │
│  State<T> ◄──emit─── Model ──convert──► ValueObject             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ 数据访问层 (Data Access)                                         │
│                                                                 │
│  Repository ──read/write──► Hive Box / File IO                  │
│       │                       │                                 │
│       ▼                       ▼                                 │
│  Box<Model>.get()        File.readAsString()                     │
│  Box<Model>.put()        File.writeAsString()                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 数据流向

```
用户操作
  │
  ▼
Widget (UI) ──── onTap/onChanged ────► WidgetRef.read(notifier)
  │                                          │
  │                                          ▼
  │                                    StateNotifier.method()
  │                                          │
  │                                          ▼
  │                                    Service.execute()
  │                                          │
  │                                          ├──► Repository.save()
  │                                          ├──► Repository.load()
  │                                          └──► Repository.delete()
  │
  ▼
State变化 ──── rebuild ────► UI更新
```

---

## 五、核心模块设计

### 5.1 项目管理模块

```
ProjectModule
├── ProjectService (业务逻辑)
│   ├── createProject(name, path)
│   ├── openProject(path) → Project
│   ├── saveProject(project)
│   └── closeProject()
│
├── HistoryService (数据访问)
│   ├── getHistoryList() → List<ProjectHistory>
│   ├── addHistory(history)
│   └── removeHistory(path)
│
├── MigrationService (数据升级)
│   ├── checkVersion(data) → String
│   ├── migrate(data, fromVersion)
│   └── getLatestVersion() → String
│
└── ProjectState (状态)
    ├── currentProject: Project?
    ├── projectPath: String?
    ├── isDirty: bool
    ├── isLoading: bool
    └── error: String?
```

### 5.2 数据建模模块 (核心)

```
ModelingModule
├── EntityEditor (数据表编辑器)
│   ├── FieldTable (字段表格 - Syncfusion)
│   ├── IndexTable (索引表格)
│   └── EntityHeader (表基本信息)
│
├── ERDiagram (ER图 - CustomPaint自研)
│   ├── NodePainter (节点绘制)
│   ├── EdgePainter (连线绘制)
│   ├── GestureHandler (手势交互)
│   ├── LayoutEngine (自动布局)
│   └── ImageExport (图片导出)
│
└── DataTypeMapper (数据类型映射)
    ├── AbstractType → DatabaseType
    └── TypeSuggestion (智能推荐)
```

### 5.3 代码生成模块

```
CodeGenModule
├── TemplateEngine (模板引擎)
│   ├── compileTemplate(template, context)
│   ├── registerHelper(name, function)
│   └── loadTemplates(databaseType)
│
├── DDLGenerator (DDL生成)
│   ├── generateCreateTable(entity, dbType)
│   ├── generateAlterTable(changes, dbType)
│   └── generateDropTable(entity, dbType)
│
└── CodeGenerator (代码生成)
    ├── generateJavaEntity(entity)
    └── generateTypeScript(entity)
```

---

## 六、关键ADR (架构决策记录)

### ADR-001: 选择Flutter而非Electron

**状态**: 已批准

**决策**: 使用Flutter开发跨平台桌面应用

**理由**:
1. 性能提升60%+，内存占用从300MB降至100-150MB
2. AOT编译，启动速度提升4-5倍
3. Material Design 3提供现代化UI
4. 单一代码库跨平台

**代价**:
1. ER图组件需自研(2-3周)
2. 团队需学习Dart/Flutter

### ADR-002: 选择Riverpod状态管理

**状态**: 已批准

**决策**: 使用Riverpod替代Provider/Bloc/GetX

**理由**:
1. 编译时安全，避免ProviderNotFoundException
2. 自动销毁提供者，内存管理优秀
3. 不依赖BuildContext，测试更方便
4. 代码量比Bloc少30-50%

### ADR-003: 选择Hive本地存储

**状态**: 已批准

**决策**: 使用Hive作为本地存储方案

**理由**:
1. 纯Dart实现，无原生依赖
2. 读写性能优于SQLite
3. API简洁，适合键值存储场景
4. 支持加密

### ADR-004: 选择CustomPainter自研ER图

**状态**: 已批准

**决策**: 不自带成熟图库，使用CustomPainter+自研

**理由**:
1. Flutter生态无成熟ER图组件
2. 自研可完全控制功能和性能
3. 避免WebView桥接的性能开销

**风险**: 开发周期增加2-3周

### ADR-005: 数据文件格式选择JSON

**状态**: 已批准

**决策**: 项目文件使用`.bkdmm.json`格式存储

**理由**:
1. 人类可读，方便版本管理(diff友好)
2. Dart原生支持，序列化成熟
3. 可比PDMan的JSON格式，迁移成本低

---

### ADR-006: Widget架构模式选择

**状态**: 已批准

**决策**: 采用 ConsumerWidget + StateNotifier 模式

**理由**:
1. ConsumerWidget 提供简洁的 Provider 访问方式
2. StateNotifier 分离业务逻辑与 UI 状态
3. 支持不可变状态，避免意外的状态修改
4. 与 Riverpod 完美集成，编译时类型安全

**示例代码**:
```dart
// 推荐: ConsumerWidget + StateNotifier
class EntityEditorView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(entityProvider);
    final isLoading = ref.watch(entityProvider).isLoading;
    
    return Column(
      children: [
        if (isLoading) CircularProgressIndicator(),
        EntityTable(entity: entity),
      ],
    );
  }
}

class EntityNotifier extends StateNotifier<EntityState> {
  void updateField(Field field) {
    state = state.copyWith(
      entity: state.entity.copyWith(
        fields: [...state.entity.fields, field],
      ),
    );
  }
}
```

### ADR-007: Freezed vs 手写不可变模型

**状态**: 已批准

**决策**: 使用 `freezed` 包生成不可变数据模型

**理由**:
1. 自动生成 copyWith、toString、hashCode
2. 支持模式匹配和 union types
3. 减少 80%+ 的样板代码
4. 类型安全，编译时检查

**示例对比**:
```dart
// 手写方式 (约 150 行)
class Entity {
  final String id;
  final String title;
  final String chnname;
  final List<Field> fields;
  
  Entity({
    required this.id,
    required this.title,
    required this.chnname,
    required this.fields,
  });
  
  Entity copyWith({
    String? id,
    String? title,
    String? chnname,
    List<Field>? fields,
  }) {
    return Entity(
      id: id ?? this.id,
      title: title ?? this.title,
      chnname: chnname ?? this.chnname,
      fields: fields ?? this.fields,
    );
  }
  
  @override
  bool operator ==(Object other) => ...
  
  @override
  int get hashCode => ...
}

// freezed 方式 (约 20 行)
@freezed
class Entity with _$Entity {
  factory Entity({
    required String id,
    required String title,
    required String chnname,
    required List<Field> fields,
  }) = _Entity;
  
  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);
}
```

### ADR-008: 错误处理策略

**状态**: 已批准

**决策**: 使用 sealed class 定义领域异常

**理由**:
1. Dart 3 的 sealed class 提供完备性检查
2. 编译器强制处理所有异常分支
3. 类型安全的异常匹配
4. 避免 runtime exception 漏洞

**实现方式**:
```dart
// lib/shared/exceptions/app_exception.dart

sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ProjectException extends AppException {
  const ProjectException(super.message);
}

class EntityException extends AppException {
  const EntityException(super.message);
}

class DataTypeException extends AppException {
  const DataTypeException(super.message);
}

class CodeGenException extends AppException {
  const CodeGenException(super.message);
}

// 使用示例
Future<void> loadProject(String path) async {
  try {
    final project = await fileService.readProject(path);
    state = ProjectState.loaded(project);
  } on ProjectException catch (e) {
    state = ProjectState.error(e.message);
  }
}
```

### ADR-009: AsyncValue 状态管理

**状态**: 已批准

**决策**: 使用 Riverpod AsyncValue 处理异步状态

**理由**:
1. 内置 loading/data/error 状态管理
2. 自动处理缓存和刷新
3. 简化 UI 条件渲染
4. 支持数据刷新策略

**实现方式**:
```dart
// Provider 定义
final projectProvider = FutureProvider<Project>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return service.loadProject();
});

// UI 使用
class ProjectView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProject = ref.watch(projectProvider);
    
    return asyncProject.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
      data: (project) => ProjectContent(project: project),
    );
  }
}
```

### ADR-010: Feature-First 目录结构

**状态**: 已批准

**决策**: 按功能模块组织代码，而非技术分层

**理由**:
1. 高内聚低耦合，功能边界清晰
2. 易于多人协作开发
3. 支持按需加载(lazy loading)
4. 代码定位更直观

**目录对比**:
```
// 传统分层 (不推荐)
lib/
├── models/       # 所有模型在一起
├── services/     # 所有服务在一起
├── widgets/      # 所有组件在一起

// Feature-First (推荐)
lib/
├── features/
│   ├── project/           # 项目管理模块
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   └── views/
│   │   └── widgets/
│   ├── modeling/          # 数据建模模块
│   │   ├── entity_editor/
│   │   ├── er_diagram/
│   │   └── workspace/
│   └── codegen/           # 代码生成模块
│       ├── models/
│       ├── services/
│       ├── providers/
│       └── views/
└── shared/                # 跨模块共享代码
    ├── models/
    ├── widgets/
    └── utils/
```

---

## 七、自研ER图组件架构 ⚠️ 重点

```
ERDiagramWidget (ConsumerStatefulWidget)
│
├── InteractiveViewer           ← 缩放/平移(Flutter内置)
│   └── CustomPaint             ← 画布绘制
│       ├── ERGraphPainter      ← 总绘制器
│       │   ├── NodePainter     ← 表节点
│       │   │   ├── 标题栏
│       │   │   ├── 字段列表
│       │   │   └── 主键标记
│       │   └── EdgePainter     ← 关系连线
│       │       ├── 连线绘制
│       │       ├── 箭头绘制
│       │       └── 关系标签
│
├── GestureDetector             ← 手势交互
│   ├── onPanStart/Update/End   ← 拖拽节点
│   ├── onTapDown               ← 选择节点
│   └── onDoubleTapDown         ← 打开编辑
│
├── Toolbar (Overlay)           ← 浮动工具栏
│   ├── 缩放控制
│   ├── 搜索节点
│   ├── 导出图片
│   └── 自动布局
│
└── ContextMenu (Overlay)       ← 右键菜单
    ├── 编辑表
    ├── 删除节点
    ├── 添加连线
    └── 查看详情
```

### Flutter Widget 层次设计

```dart
// lib/features/modeling/er_diagram/er_diagram_widget.dart

class ERDiagramWidget extends ConsumerStatefulWidget {
  final String moduleId;

  const ERDiagramWidget({
    required this.moduleId,
    super.key,
  });

  @override
  ConsumerState<ERDiagramWidget> createState() => _ERDiagramWidgetState();
}

class _ERDiagramWidgetState extends ConsumerState<ERDiagramWidget> {
  final TransformationController _transformController = TransformationController();
  Set<String> _selectedNodes = {};
  String? _draggingNode;
  Offset _dragOffset = Offset.zero;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Riverpod 监听图数据变化
    final graphCanvas = ref.watch(graphCanvasProvider(widget.moduleId));
    final entities = ref.watch(entitiesProvider(widget.moduleId));

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.1,
          maxScale: 5.0,
          constrained: false,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTapDown: _onTapDown,
            onDoubleTapDown: _onDoubleTapDown,
            child: CustomPaint(
              painter: ERGraphPainter(
                nodes: graphCanvas.nodes,
                edges: graphCanvas.edges,
                entities: entities,
                selectedNodes: _selectedNodes,
              ),
              size: const Size(4000, 4000),
            ),
          ),
        ),
        _buildToolbar(context, ref),
        if (_contextMenu != null) _buildContextMenu(context, ref),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 16,
      right: 16,
      child: Card(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: '放大',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: '缩小',
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: _fitToScreen,
              tooltip: '适应屏幕',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context, ref),
              tooltip: '搜索节点',
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => _autoLayout(ref),
              tooltip: '自动布局',
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _exportImage,
              tooltip: '导出图片',
            ),
          ],
        ),
      ),
    );
  }
}
```

### CustomPainter 实现模式

```dart
// lib/features/modeling/er_diagram/painters/er_graph_painter.dart

class ERGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<Entity> entities;
  final Set<String> selectedNodes;

  ERGraphPainter({
    required this.nodes,
    required this.edges,
    required this.entities,
    required this.selectedNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 先绘制连线(底层)
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }

    // 再绘制节点(上层)
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawNode(Canvas canvas, GraphNode node) {
    final entity = _getEntity(node.title);
    if (entity == null) return;

    final isSelected = selectedNodes.contains(node.title);
    final rect = _calculateNodeRect(node, entity);

    // 绘制阴影
    _drawShadow(canvas, rect);

    // 绘制背景
    _drawBackground(canvas, rect, isSelected);

    // 绘制标题栏
    _drawHeader(canvas, rect, entity, isSelected);

    // 绘制字段列表
    _drawFields(canvas, rect, entity);
  }

  void _drawBackground(Canvas canvas, Rect rect, bool isSelected) {
    final bgPaint = Paint()
      ..color = isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      bgPaint,
    );

    // 边框
    final borderPaint = Paint()
      ..color = isSelected
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );
  }

  void _drawHeader(Canvas canvas, Rect rect, Entity entity, bool isSelected) {
    final headerRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      _headerHeight,
    );

    final headerPaint = Paint()
      ..color = isSelected
          ? Theme.of(context).colorScheme.primary
          : Colors.blue.shade700
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        headerRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      headerPaint,
    );

    // 标题文字
    final titlePainter = TextPainter(
      text: TextSpan(
        text: '${entity.title}[${entity.chnname}]',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    titlePainter.layout(maxWidth: rect.width - 16);
    titlePainter.paint(canvas, Offset(rect.left + 8, rect.top + 8));
  }

  void _drawFields(Canvas canvas, Rect rect, Entity entity) {
    double y = rect.top + _headerHeight + 8;

    for (final field in entity.fields) {
      final prefix = field.pk ? '🔑 ' : '  ';
      final fieldText = '$prefix${field.name}: ${field.type}';

      final fieldPainter = TextPainter(
        text: TextSpan(
          text: fieldText,
          style: TextStyle(
            fontSize: 12,
            color: field.pk ? Colors.red.shade700 : Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      fieldPainter.layout(maxWidth: rect.width - 16);
      fieldPainter.paint(canvas, Offset(rect.left + 8, y));
      y += 20;
    }
  }

  @override
  bool shouldRepaint(covariant ERGraphPainter oldDelegate) {
    // 精确控制重绘时机
    return !identical(nodes, oldDelegate.nodes) ||
           !identical(edges, oldDelegate.edges) ||
           !identical(selectedNodes, oldDelegate.selectedNodes);
  }
}
```

### Provider 架构设计

```dart
// lib/features/modeling/er_diagram/providers/graph_providers.dart

// 图画布状态
@riverpod
class GraphCanvasNotifier extends _$GraphCanvasNotifier {
  @override
  GraphCanvas build(String moduleId) {
    return GraphCanvas(nodes: [], edges: []);
  }

  void updateNodePosition(String nodeTitle, Offset newPosition) {
    final newNodes = state.nodes.map((n) {
      if (n.title == nodeTitle) {
        return n.copyWith(x: newPosition.dx, y: newPosition.dy);
      }
      return n;
    }).toList();

    state = state.copyWith(nodes: newNodes);
  }

  void addNode(GraphNode node) {
    state = state.copyWith(nodes: [...state.nodes, node]);
  }

  void removeNode(String nodeTitle) {
    state = state.copyWith(
      nodes: state.nodes.where((n) => n.title != nodeTitle).toList(),
      edges: state.edges.where((e) =>
        e.source != nodeTitle && e.target != nodeTitle
      ).toList(),
    );
  }

  void addEdge(GraphEdge edge) {
    state = state.copyWith(edges: [...state.edges, edge]);
  }

  void removeEdge(String source, String target) {
    state = state.copyWith(
      edges: state.edges.where((e) =>
        !(e.source == source && e.target == target)
      ).toList(),
    );
  }
}

// 自动布局 Provider
@riverpod
Future<GraphCanvas> autoLayout(AutoLayoutRef ref, String moduleId) async {
  final canvas = ref.watch(graphCanvasNotifierProvider(moduleId));
  final entities = ref.watch(entitiesProvider(moduleId));

  // 使用 isolate 处理大数据量布局
  return await compute(_calculateLayout, _LayoutParams(
    nodes: canvas.nodes,
    edges: canvas.edges,
    entities: entities,
  ));
}

GraphCanvas _calculateLayout(_LayoutParams params) {
  // Dagre 层次布局算法实现
  // ...
}
```

### 性能设计

```
大数据量优化策略:
├── Viewport Culling: 只绘制可视区域内的节点
├── LOD (Level of Detail):
│   ├── 缩小时: 只显示表名
│   └── 放大后: 显示完整字段列表
├── RepaintBoundary: 隔离重绘区域
├── shouldRepaint: 精确控制重绘时机
└── 虚拟化: 100+节点时启动虚拟滚动
```

---

## 八、数据迁移策略

```
版本链:
v1.0.0 → v1.1.0 → v1.2.0 → ...

迁移规则:
1. 读取项目文件 → 检查version字段
2. version < latest → 依次执行migration
3. 每次migration更新version
4. 保存时写入latest version
```

```dart
class Migration {
  final String version;      // 目标版本
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> data) migrate;
}

final List<Migration> migrations = [
  Migration(version: '1.0.0', migrate: (d) async => d),  // 初始
  Migration(version: '1.1.0', migrate: (d) async {         // 添加profile
    d.putIfAbsent('profile', () => {'defaultFields': []});
    return d;
  }),
  Migration(version: '1.2.0', migrate: (d) async {         // 添加UUID
    for (final m in (d['modules'] ?? [])) {
      m['id'] ??= const Uuid().v4();
    }
    return d;
  }),
];
```

---

## 九、窗口管理策略

```
主窗口架构:
┌──────────────────────────────────────────────────┐
│  MenuBar (系统菜单)                                │
├─────────┬────────────────────────────────────────┤
│         │  Tab Bar (工作区标签)                    │
│ Module  ├────────────────────────────────────────┤
│ Tree    │                                        │
│ (树形   │         工作区内容                       │
│  导航)  │   ┌── TableEditor ──┐                  │
│         │   │  字段编辑表格    │                  │
│         │   └─────────────────┘                  │
│         │   ┌── ERDiagram ────┐                  │
│         │   │  可视化关系图    │                  │
│         │   └─────────────────┘                  │
│         │   ┌── CodePreview ──┐                  │
│         │   │  SQL/代码预览    │                  │
│         │   └─────────────────┘                  │
├─────────┴────────────────────────────────────────┤
│  StatusBar (状态栏)                                │
└──────────────────────────────────────────────────┘

窗口状态持久化:
- 窗口位置/大小 → Hive存储
- Tab打开状态 → Hive存储
- 侧边栏宽度 → Hive存储
```

---

## 十、风险登记

| 风险ID | 风险描述 | 影响 | 概率 | 缓解措施 |
|--------|----------|------|------|----------|
| R-001 | ER图自研周期超出预估 | 延期2-3周 | 中 | 分阶段交付，MVP先支持基本拖拽 |
| R-002 | Synchusion免费版限制 | 功能受限 | 低 | 备选PlutoGrid |
| R-003 | 团队Flutter经验不足 | 代码质量 | 中 | 提前学习，代码审查 |
| R-004 | 大数据量ER图性能 | 用户体验差 | 中 | 视口裁剪+LOD策略 |

---

## 相关文档

- [框架选型对比](../docs/FRAMEWORK-COMPARISON.md)
- [技术选型分析](tech-selection/README.md)
- [数据模型设计](data-model/README.md)
- [关系图编辑器](features/relation-graph/README.md)
- [项目管理](features/project/README.md)
