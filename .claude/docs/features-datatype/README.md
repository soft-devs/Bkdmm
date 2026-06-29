# features/datatype - 数据类型模块

## 概述

数据类型管理功能，用于定义和管理项目中使用的数据类型。支持默认数据类型和自定义数据类型，提供数据库类型映射和 Java 类型映射配置。

## 文件结构

```
bkdmm/lib/features/datatype/
  datatype.dart                    # 模块导出
  providers/
    datatype_provider.dart         # 状态管理
  views/
    datatype_view.dart             # 数据类型视图
    datatype_edit_dialog.dart      # 编辑对话框
  dialogs/
    datatype_dialogs.dart          # 对话框函数
  widgets/
    datatype_type_card.dart        # 卡片组件
  utils/
    datatype_utils.dart            # 工具函数
```

## 核心组件

| 组件 | 文件 | 描述 |
|------|------|------|
| `DataTypeView` | views/datatype_view.dart | 数据类型管理主视图 |
| `DataTypeEditDialog` | views/datatype_edit_dialog.dart | 数据类型编辑对话框 |
| `DataTypeCard` | widgets/datatype_type_card.dart | 数据类型卡片组件 |
| `DataTypeMappings` | widgets/datatype_type_card.dart | 数据库映射展示组件 |
| `DataTypeNotifier` | providers/datatype_provider.dart | 状态管理 Notifier |
| `DataTypeState` | providers/datatype_provider.dart | 状态数据类 |

## 功能特性

- 查看所有数据类型（默认类型 + 自定义类型）
- 添加/编辑/复制/删除自定义数据类型
- 数据库类型映射配置（MySQL、Oracle、PostgreSQL、SQL Server 等）
- Java 类型映射配置
- 恢复默认数据类型
- 搜索和过滤数据类型

---

## API 索引

### 状态管理 (datatype_provider.dart)

#### DataTypeState

数据类型状态数据类。

**属性**

| 属性 | 类型 | 描述 |
|------|------|------|
| `dataTypes` | `List<DataType>` | 所有数据类型（默认 + 自定义） |
| `databaseTemplates` | `List<DatabaseTemplate>` | 数据库模板列表 |
| `isDirty` | `bool` | 是否有未保存的修改 |
| `selectedDataType` | `DataType?` | 当前选中的数据类型 |
| `error` | `String?` | 错误信息 |

**计算属性**

| 属性 | 类型 | 描述 |
|------|------|------|
| `defaultTypes` | `List<DataType>` | 默认数据类型（ID 1-10） |
| `customTypes` | `List<DataType>` | 自定义数据类型 |

**方法**

| 方法 | 签名 | 描述 |
|------|------|------|
| `getById` | `DataType? getById(String id)` | 根据 ID 获取数据类型 |
| `getByName` | `DataType? getByName(String name)` | 根据名称获取数据类型 |
| `nameExists` | `bool nameExists(String name, {String? excludeId})` | 检查名称是否已存在 |
| `findTypeUsage` | `Map<String, List<String>> findTypeUsage(String typeId, List<Module> modules)` | 查找数据类型在模块中的使用情况 |

#### DataTypeNotifier

数据类型状态管理 Notifier，继承自 `StateNotifier<DataTypeState>`。

**初始化方法**

| 方法 | 签名 | 描述 |
|------|------|------|
| `initialize` | `void initialize(DataTypeDomains domains)` | 使用项目数据初始化状态 |
| `reset` | `void reset()` | 重置为空状态 |

**CRUD 操作**

| 方法 | 签名 | 返回值 | 描述 |
|------|------|--------|------|
| `addDataType` | `bool addDataType(DataType dataType)` | `bool` | 添加新数据类型，名称重复返回 false |
| `updateDataType` | `bool updateDataType(String id, DataType updated)` | `bool` | 更新数据类型，名称重复返回 false |
| `deleteDataType` | `Map<String, List<String>>? deleteDataType(String id, List<Module> modules)` | `Map?` | 删除数据类型，若被使用返回使用情况映射 |
| `forceDeleteDataType` | `void forceDeleteDataType(String id)` | - | 强制删除数据类型（忽略使用情况） |
| `duplicateDataType` | `bool duplicateDataType(String id)` | `bool` | 复制数据类型 |

**恢复操作**

| 方法 | 签名 | 描述 |
|------|------|------|
| `restoreDefaults` | `void restoreDefaults()` | 恢复所有默认数据类型 |
| `restoreDefaultType` | `void restoreDefaultType(String id)` | 恢复单个默认数据类型 |

**辅助方法**

| 方法 | 签名 | 描述 |
|------|------|------|
| `selectDataType` | `void selectDataType(DataType? dataType)` | 设置选中的数据类型 |
| `clearError` | `void clearError()` | 清除错误信息 |
| `markClean` | `void markClean()` | 标记为已保存状态 |
| `toDataTypeDomains` | `DataTypeDomains toDataTypeDomains()` | 导出为 DataTypeDomains 对象 |
| `createNewDataType` | `DataType createNewDataType({required String name, required String chnname, String? remark, Map<String, String>? apply, String? java})` | 创建新数据类型（自动生成 ID） |

#### Providers

| Provider | 类型 | 描述 |
|----------|------|------|
| `dataTypeNotifierProvider` | `StateNotifierProvider<DataTypeNotifier, DataTypeState>` | 主状态 Provider |
| `dataTypesProvider` | `Provider<List<DataType>>` | 所有数据类型列表 |
| `defaultDataTypesProvider` | `Provider<List<DataType>>` | 默认数据类型列表 |
| `customDataTypesProvider` | `Provider<List<DataType>>` | 自定义数据类型列表 |
| `isDataTypeDirtyProvider` | `Provider<bool>` | 是否有未保存修改 |
| `selectedDataTypeProvider` | `Provider<DataType?>` | 当前选中的数据类型 |

---

### 对话框函数 (dialogs/datatype_dialogs.dart)

| 函数 | 签名 | 描述 |
|------|------|------|
| `showAddDataTypeDialog` | `void showAddDataTypeDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate)` | 显示添加数据类型对话框 |
| `showEditDataTypeDialog` | `void showEditDataTypeDialog(BuildContext context, WidgetRef ref, DataType type, VoidCallback onUpdate)` | 显示编辑数据类型对话框 |
| `showDeleteDataTypeDialog` | `void showDeleteDataTypeDialog(BuildContext context, WidgetRef ref, DataType type, List<Module> modules, VoidCallback onUpdate)` | 显示删除确认对话框 |
| `showUsageWarningDialog` | `void showUsageWarningDialog(BuildContext context, WidgetRef ref, DataType type, Map<String, List<String>> usage, VoidCallback onUpdate)` | 显示使用中警告对话框 |
| `showRestoreDefaultsDialog` | `void showRestoreDefaultsDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate)` | 显示恢复默认对话框 |

---

### 视图组件 (views/)

#### DataTypeView

数据类型管理主视图，继承自 `ConsumerStatefulWidget`。

**功能**
- 显示数据类型列表（默认类型 / 自定义类型分组）
- 搜索过滤
- 类型切换（默认/自定义）
- 添加、编辑、复制、删除操作
- 恢复默认数据类型

#### DataTypeEditDialog

数据类型编辑对话框，继承自 `ConsumerStatefulWidget`。

**参数**

| 参数 | 类型 | 描述 |
|------|------|------|
| `existingType` | `DataType?` | 编辑时传入现有数据类型，新建时为 null |
| `onSave` | `void Function(DataType)` | 保存回调 |

**表单字段**
- 英文名称 (name)
- 中文名称 (chnname)
- 备注 (remark)
- Java 类型 (java)
- 数据库类型映射 (apply) - 支持多种数据库

---

### 卡片组件 (widgets/datatype_type_card.dart)

#### DataTypeCard

数据类型卡片组件，继承自 `StatelessWidget`。

**参数**

| 参数 | 类型 | 描述 |
|------|------|------|
| `type` | `DataType` | 要显示的数据类型 |
| `isSelected` | `bool` | 是否选中状态 |
| `onTap` | `VoidCallback?` | 点击回调 |
| `onAction` | `TypeActionCallback?` | 操作菜单回调 |

**操作菜单项**
- 编辑 (`edit`)
- 复制 (`duplicate`)
- 删除 (`delete`) - 仅自定义类型显示

#### DataTypeMappings

数据库映射展示组件，继承自 `StatelessWidget`。

**参数**

| 参数 | 类型 | 描述 |
|------|------|------|
| `type` | `DataType` | 要显示映射的数据类型 |

**显示内容**
- 各数据库类型映射（MySQL、Oracle、PostgreSQL、SQL Server 等）
- Java 类型映射（如有）

#### TypeActionCallback

```dart
typedef TypeActionCallback = void Function(DataType type, String action);
```

---

### 工具函数 (utils/datatype_utils.dart)

#### getTypeIcon

```dart
IconData getTypeIcon(String typeName)
```

根据数据类型名称返回对应的图标。

**映射规则**

| 类型名称 | 图标 |
|----------|------|
| IDorKey | `TDIcons.key` |
| Name | `TDIcons.edit` |
| Intro | `TDIcons.edit` |
| LongText | `TDIcons.article` |
| Integer | `TDIcons.filter_1` |
| Long | `TDIcons.filter` |
| Money | `TDIcons.money` |
| DateTime | `TDIcons.time` |
| YesNo | `TDIcons.check` |
| Dict | `TDIcons.book` |
| 其他 | `TDIcons.data` |

---

## 数据模型

### DataType

```dart
class DataType {
  final String id;           // 类型唯一标识
  final String name;         // 类型代码（英文）
  final String chnname;      // 类型中文名
  final String? remark;      // 类型备注
  final Map<String, String> apply;  // 数据库映射 {数据库代码: 类型}
  final String? java;        // Java 类型映射

  String? getDatabaseType(String databaseCode);
}
```

### DataTypeDomains

```dart
class DataTypeDomains {
  final List<DataType> datatype;        // 数据类型列表
  final List<DatabaseTemplate> database; // 数据库模板列表
}
```

---

## 使用示例

### 读取数据类型列表

```dart
// 获取所有数据类型
final types = ref.watch(dataTypesProvider);

// 仅获取默认数据类型
final defaultTypes = ref.watch(defaultDataTypesProvider);

// 仅获取自定义数据类型
final customTypes = ref.watch(customDataTypesProvider);

// 检查是否有未保存的修改
final isDirty = ref.watch(isDataTypeDirtyProvider);
```

### 添加数据类型

```dart
final notifier = ref.read(dataTypeNotifierProvider.notifier);

final newType = notifier.createNewDataType(
  name: 'Email',
  chnname: '邮箱地址',
  remark: '电子邮件地址格式',
  java: 'String',
  apply: {'MYSQL': 'VARCHAR(255)', 'ORACLE': 'VARCHAR2(255)'},
);

if (notifier.addDataType(newType)) {
  // 添加成功
} else {
  // 名称已存在，检查错误
  final error = ref.read(dataTypeNotifierProvider).error;
}
```

### 更新数据类型

```dart
final notifier = ref.read(dataTypeNotifierProvider.notifier);
final updated = type.copyWith(chnname: '新中文名');

if (notifier.updateDataType(type.id, updated)) {
  // 更新成功
}
```

### 删除数据类型

```dart
final notifier = ref.read(dataTypeNotifierProvider.notifier);
final modules = ref.read(currentProjectProvider)?.modules ?? [];

final usage = notifier.deleteDataType(typeId, modules);
if (usage != null) {
  // 类型正在被使用，usage 为使用情况映射
  // 可选择强制删除: notifier.forceDeleteDataType(typeId);
}
```

### 保存到项目

```dart
void _updateProject() {
  final project = ref.read(currentProjectProvider);
  if (project == null) return;

  final domains = ref.read(dataTypeNotifierProvider.notifier).toDataTypeDomains();
  final updated = project.copyWith(
    dataTypeDomains: domains,
    updatedAt: DateTime.now(),
  );
  ref.read(projectProvider.notifier).updateProject(updated);
}
```

---

## 依赖关系

- `shared/models` - DataType、DataTypeDomains、Module 等数据模型
- `shared/providers` - currentProjectProvider、projectProvider
- `shared/constants/default_data_types` - 默认数据类型定义、DatabaseCodes
- `shared/utils/responsive_utils` - 响应式布局工具
- `shared/widgets/td_popup_menu` - TDesign 弹出菜单组件
- `core/i18n` - 国际化支持
- `utils/id_generator` - ID 生成器
- `tdesign_flutter` - TDesign Flutter UI 组件库
- `flutter_riverpod` - 状态管理
