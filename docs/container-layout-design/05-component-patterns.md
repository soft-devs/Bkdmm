# 常用组件布局模式模板

本文档提供可直接复用的布局模板代码，开发新组件时可直接参考使用。

## 一、基础布局模板

### 1.1 标准页面布局

```dart
/// 标准页面布局模板
/// 适用于大多数页面场景
class StandardPageLayout extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;

  const StandardPageLayout({
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// 使用示例
StandardPageLayout(
  title: '实体管理',
  body: EntityList(),
  actions: [
    IconButton(icon: Icon(Icons.search), onPressed: () {}),
    IconButton(icon: Icon(Icons.filter), onPressed: () {}),
  ],
)
```

### 1.2 主从布局（Master-Detail）

```dart
/// 主从布局模板
/// 适用于列表-详情、树-内容等场景
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget detail;
  final double masterWidth;

  const MasterDetailLayout({
    required this.master,
    required this.detail,
    this.masterWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 主面板（左侧）
        SizedBox(
          width: masterWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: master,
          ),
        ),

        // 详情面板（右侧）
        Expanded(
          child: detail,
        ),
      ],
    );
  }
}

// 使用示例
MasterDetailLayout(
  master: EntityList(),
  detail: EntityEditor(),
  masterWidth: 240,
)
```

### 1.3 三栏布局

```dart
/// 三栏布局模板
/// 适用于导航-列表-详情等场景
class ThreeColumnLayout extends StatelessWidget {
  final Widget left;
  final Widget center;
  final Widget right;
  final double leftWidth;
  final double rightWidth;

  const ThreeColumnLayout({
    required this.left,
    required this.center,
    required this.right,
    this.leftWidth = 200,
    this.rightWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧栏
        SizedBox(
          width: leftWidth,
          child: left,
        ),

        // 中间栏
        Expanded(
          child: center,
        ),

        // 右侧栏
        SizedBox(
          width: rightWidth,
          child: right,
        ),
      ],
    );
  }
}

// 使用示例
ThreeColumnLayout(
  left: ModuleTree(),
  center: EntityList(),
  right: PropertyPanel(),
)
```

## 二、卡片布局模板

### 2.1 基础卡片

```dart
/// 基础卡片模板
/// 适用于列表项、信息展示
class BasicCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BasicCard({
    required this.title,
    this.subtitle,
    this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),

              // 描述
              if (description != null) ...[
                SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 使用示例
BasicCard(
  title: '用户实体',
  subtitle: '模块: 系统',
  description: '存储用户基本信息',
  trailing: Icon(Icons.chevron_right),
  onTap: () => _openEntity(),
)
```

### 2.2 带图标卡片

```dart
/// 带图标卡片模板
/// 适用于实体卡片、模块卡片等
class IconCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final List<Widget>? badges;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IconCard({
    required this.icon,
    required this.title,
    this.description,
    this.badges,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 描述
                    if (description != null) ...[
                      SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 徽章
                    if (badges != null && badges!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: badges!,
                      ),
                    ],
                  ],
                ),
              ),

              // 操作按钮
              if (onEdit != null || onDelete != null)
                Column(
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, size: 20),
                        onPressed: onDelete,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 使用示例
IconCard(
  icon: Icons.table_chart,
  title: '用户表',
  description: '存储用户基本信息',
  badges: [
    Chip(label: Text('8 字段')),
    Chip(label: Text('2 索引')),
  ],
  onTap: () => _openEntity(),
  onEdit: () => _editEntity(),
  onDelete: () => _deleteEntity(),
)
```

## 三、列表布局模板

### 3.1 标准列表项

```dart
/// 标准列表项模板
/// 适用于各种列表场景
class StandardListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StandardListItem({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// 使用示例
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return StandardListItem(
      leading: Icon(Icons.table_chart),
      title: items[index].name,
      subtitle: items[index].description,
      trailing: Icon(Icons.chevron_right),
      onTap: () => _openItem(items[index]),
    );
  },
)
```

### 3.2 可展开列表项

```dart
/// 可展开列表项模板
/// 适用于树形结构、折叠列表
class ExpandableListItem extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  const ExpandableListItem({
    required this.title,
    required this.children,
    this.leading,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableListItem> createState() => _ExpandableListItemState();
}

class _ExpandableListItemState extends State<ExpandableListItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: widget.leading,
          title: Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded)
          ...widget.children.map((child) => Padding(
                padding: EdgeInsets.only(left: 16),
                child: child,
              )),
      ],
    );
  }
}

// 使用示例
ExpandableListItem(
  leading: Icon(Icons.folder),
  title: '系统模块',
  subtitle: '3 个实体',
  children: [
    ListTile(title: Text('用户实体')),
    ListTile(title: Text('角色实体')),
    ListTile(title: Text('权限实体')),
  ],
)
```

### 3.3 表格列表项

```dart
/// 表格列表项模板
/// 适用于字段列表、属性列表
class TableListItem extends StatelessWidget {
  final List<TableCellData> cells;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TableListItem({
    required this.cells,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // 数据列
            ...cells.map((cell) => SizedBox(
                  width: cell.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: cell.child ?? Text(
                          cell.text ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                )),

            // 操作列
            if (onEdit != null || onDelete != null)
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, size: 18),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TableCellData {
  final double width;
  final String? text;
  final Widget? child;

  const TableCellData({
    required this.width,
    this.text,
    this.child,
  });
}

// 使用示例
TableListItem(
  cells: [
    TableCellData(width: 60, text: '1'),
    TableCellData(width: 150, text: 'user_name'),
    TableCellData(width: 120, text: 'VARCHAR(50)'),
    TableCellData(width: 80, child: Checkbox(value: true, onChanged: null)),
  ],
  onTap: () => _selectField(),
  onEdit: () => _editField(),
  onDelete: () => _deleteField(),
)
```

## 四、表单布局模板

### 4.1 标准表单

```dart
/// 标准表单模板
/// 适用于新建/编辑对话框
class StandardForm extends StatelessWidget {
  final String title;
  final List<FormFieldItem> fields;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final String submitText;

  const StandardForm({
    required this.title,
    required this.fields,
    this.onCancel,
    this.onSubmit,
    this.submitText = '保存',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 表单字段
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: fields.map((field) => Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildField(field),
                    )).toList(),
              ),
            ),
          ),

          // 操作按钮
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null) ...[
                  TextButton(
                    onPressed: onCancel,
                    child: Text('取消'),
                  ),
                  SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: onSubmit,
                  child: Text(submitText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FormFieldItem field) {
    switch (field.type) {
      case FormFieldType.text:
        return TextFormField(
          initialValue: field.initialValue,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
          ),
        );
      case FormFieldType.select:
        return DropdownButtonFormField(
          value: field.initialValue,
          decoration: InputDecoration(
            labelText: field.label,
          ),
          items: field.options?.map((opt) => DropdownMenuItem(
                value: opt.value,
                child: Text(opt.label),
              )).toList(),
          onChanged: (_) {},
        );
      case FormFieldType.checkbox:
        return CheckboxListTile(
          title: Text(field.label),
          value: field.initialValue == 'true',
          onChanged: (_) {},
        );
      default:
        return SizedBox();
    }
  }
}

enum FormFieldType { text, select, checkbox, multiline }

class FormFieldItem {
  final String label;
  final FormFieldType type;
  final String? initialValue;
  final String? hint;
  final List<OptionItem>? options;

  const FormFieldItem({
    required this.label,
    required this.type,
    this.initialValue,
    this.hint,
    this.options,
  });
}

class OptionItem {
  final String value;
  final String label;

  const OptionItem({required this.value, required this.label});
}

// 使用示例
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: StandardForm(
      title: '新建实体',
      fields: [
        FormFieldItem(
          label: '实体名称',
          type: FormFieldType.text,
          hint: '请输入实体名称',
        ),
        FormFieldItem(
          label: '所属模块',
          type: FormFieldType.select,
          options: [
            OptionItem(value: 'sys', label: '系统模块'),
            OptionItem(value: 'biz', label: '业务模块'),
          ],
        ),
        FormFieldItem(
          label: '是否启用',
          type: FormFieldType.checkbox,
        ),
      ],
      onCancel: () => Navigator.pop(context),
      onSubmit: () => _saveEntity(),
    ),
  ),
)
```

### 4.2 行内表单

```dart
/// 行内表单模板
/// 适用于快速编辑、筛选条件
class InlineForm extends StatelessWidget {
  final List<InlineFormItem> items;
  final VoidCallback? onReset;
  final VoidCallback onSubmit;

  const InlineForm({
    required this.items,
    required this.onSubmit,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 表单项
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: item.width,
                child: TextFormField(
                  initialValue: item.initialValue,
                  decoration: InputDecoration(
                    labelText: item.label,
                    hintText: item.hint,
                    isDense: true,
                  ),
                ),
              ),
            )),

        // 操作按钮
        Spacer(),
        if (onReset != null)
          TextButton(
            onPressed: onReset,
            child: Text('重置'),
          ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: onSubmit,
          child: Text('查询'),
        ),
      ],
    );
  }
}

class InlineFormItem {
  final String label;
  final double width;
  final String? initialValue;
  final String? hint;

  const InlineFormItem({
    required this.label,
    required this.width,
    this.initialValue,
    this.hint,
  });
}

// 使用示例
InlineForm(
  items: [
    InlineFormItem(label: '名称', width: 150),
    InlineFormItem(label: '类型', width: 120),
  ],
  onReset: () => _resetFilter(),
  onSubmit: () => _applyFilter(),
)
```

## 五、工具栏布局模板

### 5.1 标准工具栏

```dart
/// 标准工具栏模板
/// 适用于列表页、编辑页顶部
class StandardToolbar extends StatelessWidget {
  final String? title;
  final List<Widget>? leadingActions;
  final List<Widget>? trailingActions;
  final Widget? search;

  const StandardToolbar({
    this.title,
    this.leadingActions,
    this.trailingActions,
    this.search,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧操作
          if (leadingActions != null) ...leadingActions!,

          // 标题
          if (title != null) ...[
            if (leadingActions != null && leadingActions!.isNotEmpty)
              SizedBox(width: 12),
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],

          // 搜索框
          if (search != null) ...[
            Expanded(child: search!),
            SizedBox(width: 12),
          ] else
            Spacer(),

          // 右侧操作
          if (trailingActions != null) ...trailingActions!,
        ],
      ),
    );
  }
}

// 使用示例
StandardToolbar(
  title: '实体管理',
  leadingActions: [
    IconButton(icon: Icon(Icons.arrow_back), onPressed: () {}),
  ],
  trailingActions: [
    IconButton(icon: Icon(Icons.filter), onPressed: () {}),
    IconButton(icon: Icon(Icons.add), onPressed: () {}),
  ],
)
```

### 5.2 编辑器工具栏

```dart
/// 编辑器工具栏模板
/// 适用于实体编辑器、图编辑器
class EditorToolbar extends StatelessWidget {
  final List<ToolbarGroup> groups;

  const EditorToolbar({
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: groups.map((group) => Row(
              children: [
                ...group.items.map((item) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: item.tooltip,
                        child: IconButton(
                          icon: Icon(item.icon),
                          iconSize: 20,
                          onPressed: item.onPressed,
                        ),
                      ),
                    )),
                if (group != groups.last)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
              ],
            )).toList(),
      ),
    );
  }
}

class ToolbarGroup {
  final List<ToolbarItem> items;

  const ToolbarGroup({required this.items});
}

class ToolbarItem {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const ToolbarItem({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
}

// 使用示例
EditorToolbar(
  groups: [
    ToolbarGroup(items: [
      ToolbarItem(icon: Icons.add, tooltip: '添加', onPressed: () {}),
      ToolbarItem(icon: Icons.delete, tooltip: '删除', onPressed: () {}),
    ]),
    ToolbarGroup(items: [
      ToolbarItem(icon: Icons.undo, tooltip: '撤销', onPressed: () {}),
      ToolbarItem(icon: Icons.redo, tooltip: '重做', onPressed: () {}),
    ]),
    ToolbarGroup(items: [
      ToolbarItem(icon: Icons.save, tooltip: '保存', onPressed: () {}),
    ]),
  ],
)
```

## 六、状态栏布局模板

### 6.1 标准状态栏

```dart
/// 标准状态栏模板
/// 适用于窗口底部、编辑器底部
class StandardStatusBar extends StatelessWidget {
  final List<StatusItem> items;

  const StandardStatusBar({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) => Padding(
              padding: EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 14),
                    SizedBox(width: 4),
                  ],
                  Text(
                    item.text,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

class StatusItem {
  final IconData? icon;
  final String text;

  const StatusItem({this.icon, required this.text});
}

// 使用示例
StandardStatusBar(
  items: [
    StatusItem(icon: Icons.table_chart, text: '实体: 8'),
    StatusItem(icon: Icons.field, text: '字段: 45'),
    StatusItem(icon: Icons.save, text: '已保存'),
  ],
)
```

## 七、面板布局模板

### 7.1 可折叠面板

```dart
/// 可折叠面板模板
/// 适用于属性面板、设置面板
class CollapsiblePanel extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const CollapsiblePanel({
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<CollapsiblePanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.expand_more
                        : Icons.chevron_right,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 内容
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}

// 使用示例
CollapsiblePanel(
  title: '基本信息',
  children: [
    TextFormField(
      decoration: InputDecoration(labelText: '名称'),
    ),
    SizedBox(height: 12),
    TextFormField(
      decoration: InputDecoration(labelText: '描述'),
    ),
  ],
)
```

## 八、使用建议

### 8.1 模板选择指南

| 场景 | 推荐模板 | 说明 |
|------|----------|------|
| 标准页面 | `StandardPageLayout` | 大多数页面场景 |
| 列表-详情 | `MasterDetailLayout` | 实体列表+编辑器 |
| 信息展示 | `BasicCard`/`IconCard` | 实体卡片、模块卡片 |
| 列表项 | `StandardListItem`/`ExpandableListItem` | 各种列表场景 |
| 表单 | `StandardForm` | 新建/编辑对话框 |
| 工具栏 | `StandardToolbar`/`EditorToolbar` | 页面/编辑器顶部 |
| 状态栏 | `StandardStatusBar` | 窗口/编辑器底部 |
| 面板 | `CollapsiblePanel` | 属性面板、设置面板 |

### 8.2 自定义扩展

基于模板自定义时，遵循以下原则：

1. **保持布局结构**：不要破坏模板的溢出处理机制
2. **使用 Expanded/Flexible**：确保可变尺寸组件正确约束
3. **文本设置 overflow**：防止文本溢出
4. **固定尺寸用 SizedBox**：明确约束固定尺寸组件
5. **可滚动内容用 Expanded + ScrollView**：确保滚动区域有约束

---

**相关文档**:
- [04-best-practices.md](04-best-practices.md) - 最佳实践
- [06-tdesign-notes.md](06-tdesign-notes.md) - TDesign 组件注意事项