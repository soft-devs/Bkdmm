# features/project - 项目管理

项目创建、打开、保存、历史记录和数据迁移功能。

## 概述

该模块提供项目生命周期管理，包括项目文件的创建、读取、保存，以及旧版本数据的迁移。

## 文件结构

```
features/project/
├── project.dart               # 模块导出
├── providers/
│   └── project_notifier.dart  # 项目状态通知器 (废弃，已移至 shared)
├── services/
│   ├── project_file_service.dart  # 项目文件服务
│   └── data_migration.dart        # 数据迁移服务
└── views/
    ├── create_project_dialog.dart # 创建项目对话框
    └── open_project_dialog.dart   # 打开项目对话框
```

## 主要功能

### 创建项目

```dart
// 显示创建项目对话框
final result = await showDialog<bool>(
  context: context,
  builder: (context) => CreateProjectDialog(),
);

if (result == true) {
  // 创建新项目
  final project = ref.read(projectProvider.notifier).createProject(
    name: name,
    description: description,
  );
}
```

### 打开项目

```dart
// 显示打开项目对话框
final result = await showDialog<bool>(
  context: context,
  builder: (context) => OpenProjectDialog(),
);

if (result == true) {
  // 打开选中的项目
  await ref.read(projectProvider.notifier).openProject(path);
}
```

### 保存项目

```dart
// 保存当前项目
await ref.read(projectProvider.notifier).saveProject();
```

### 关闭项目

```dart
// 关闭当前项目
await ref.read(projectProvider.notifier).closeProject();
```

## DataMigration (数据迁移)

处理旧版本项目文件的格式转换。

### 支持的迁移

| 版本 | 说明 |
|------|------|
| v1 → v2 | 旧版 PDMan 格式转换 |
| 无版本 → v1.0 | 无版本号项目添加版本 |

### 迁移流程

```dart
// 检查是否需要迁移
if (DataMigration.needsMigration(json)) {
  // 执行迁移
  json = DataMigration.migrate(json);
}

// 读取迁移后的项目
final project = Project.fromJson(json);
```

## CreateProjectDialog

创建新项目的对话框组件。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| onCreated | Function(Project)? | 项目创建回调 |

### 字段

- **项目名称** - 必填，英文标识
- **项目描述** - 可选，项目说明
- **保存路径** - 必填，.bkdmm 文件保存位置

## OpenProjectDialog

打开已有项目的对话框组件。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| onOpened | Function(Project)? | 项目打开回调 |

### 功能

- 显示最近项目历史列表
- 支持浏览文件选择项目
- 显示项目基本信息预览

## 注意事项

1. **文件扩展名** - 项目文件使用 `.bkdmm` 扩展名
2. **异步操作** - 所有文件操作都是异步的
3. **错误处理** - 文件不存在或格式错误需要友好提示
4. **历史记录** - 打开项目后自动添加到历史记录
5. **脏状态** - 修改项目后 `isDirty` 变为 true，关闭前需确认保存