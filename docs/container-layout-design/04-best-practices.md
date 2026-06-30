# Bkdmm 项目布局最佳实践

本文档针对 Bkdmm 项目特点，提供具体的布局设计最佳实践，确保开发一致性并减少溢出问题。

## 一、项目布局架构

### 1.1 整体布局结构

Bkdmm 采用经典的 **侧边栏 + 主内容区** 布局模式：

```
┌─────────────────────────────────────────────────────────────┐
│                      Scaffold                                │
├──────────────────┬──────────────────────────────────────────┤
│                  │                                          │
│   WorkspacePanel │              MainContent                  │
│   (侧边栏)        │              (主内容区)                   │
│                  │                                          │
│   - 项目导航      │              - EntityEditor              │
│   - 实体列表      │              - ERDiagramCanvas           │
│   - 模块树        │              - CodeGenView               │
│                  │                                          │
│   固定宽度        │              Expanded                    │
│   200-280px      │              填充剩余空间                  │
│                  │                                          │
└──────────────────┴──────────────────────────────────────────┘
```

### 1.2 响应式断点设计

```dart
// 推荐断点定义
class LayoutBreakpoints {
  static const double compact = 600;   // 手机/小屏
  static const double medium = 900;    // 平板/中屏
  static const double expanded = 1200; // 桌面/大屏
}

// 使用示例
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;

    if (width < LayoutBreakpoints.compact) {
      // 紧凑布局：隐藏侧边栏，使用 Drawer
      return CompactLayout();
    } else if (width < LayoutBreakpoints.medium) {
      // 中等布局：可折叠侧边栏
      return MediumLayout();
    } else {
      // 宽松布局：固定显示侧边栏
      return ExpandedLayout();
    }
  },
)
```

## 二、WorkspaceView 布局规范

### 2.1 主框架布局

```dart
// ✅ 推荐：WorkspaceView 标准布局
class WorkspaceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧面板：固定宽度
          SizedBox(
            width: 240,
            child: WorkspacePanel(),
          ),

          // 主内容区：填充剩余空间
          Expanded(
            child: MainContentView(),
          ),
        ],
      ),
    );
  }
}
```

### 2.2 面板内部布局

```dart
// ✅ 推荐：WorkspacePanel 内部布局
class WorkspacePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部搜索框：固定高度
          SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TDSearchBar(
                placeholder: '搜索实体...',
              ),
            ),
          ),

          // 中间内容：可滚动
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ModuleTreeWidget(),
                  EntityListWidget(),
                ],
              ),
            ),
          ),

          // 底部操作栏：固定高度
          SizedBox(
            height: 48,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  TDButton(
                    text: '新建实体',
                    icon: TDIcons.add,
                    onClick: () => _createEntity(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 三、EntityEditor 布局规范

### 3.1 实体编辑器主布局

```dart
// ✅ 推荐：EntityEditorView 布局
class EntityEditorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部工具栏：固定高度
        SizedBox(
          height: 48,
          child: EntityToolbar(),
        ),

        // 主体内容：表格编辑区
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: EntityTableWidget(),
            ),
          ),
        ),

        // 底部状态栏：固定高度
        SizedBox(
          height: 32,
          child: EntityStatusBar(),
        ),
      ],
    );
  }
}
```

### 3.2 实体表格行布局

```dart
// ✅ 推荐：EntityTableRow 布局
class EntityTableRow extends StatelessWidget {
  final Field field;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // 序号列：固定宽度
          SizedBox(
            width: 60,
            child: TDText('${field.index + 1}'),
          ),

          // 字段名：可伸缩
          Expanded(
            flex: 2,
            child: TDInput(
              value: field.name,
              placeholder: '字段名',
            ),
          ),

          // 数据类型：固定宽度
          SizedBox(
            width: 150,
            child: TDSelect(
              value: field.dataType,
              options: dataTypeOptions,
            ),
          ),

          // 是否必填：固定宽度
          SizedBox(
            width: 80,
            child: TDSwitch(
              isOn: field.required,
            ),
          ),

          // 备注：可伸缩
          Expanded(
            flex: 3,
            child: TDInput(
              value: field.comment,
              placeholder: '备注',
            ),
          ),

          // 操作按钮：固定宽度
          SizedBox(
            width: 100,
            child: Row(
              children: [
                TDButton(
                  icon: TDIcons.edit,
                  size: TDButtonSize.small,
                ),
                TDButton(
                  icon: TDIcons.delete,
                  size: TDButtonSize.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 四、ERDiagramCanvas 布局规范

### 4.1 图编辑器布局

```dart
// ✅ 推荐：ERDiagramCanvas 布局
class ERDiagramCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 画布层：填充整个空间
        Positioned.fill(
          child: InteractiveViewer(
            boundary: CanvasBoundary(),
            child: DiagramLayer(),
          ),
        ),

        // 工具栏：右上角浮动
        Positioned(
          top: 16,
          right: 16,
          child: DiagramToolbar(),
        ),

        // 属性面板：右侧浮动（可选）
        Positioned(
          top: 80,
          right: 16,
          width: 280,
          child: DiagramPropertyPanel(),
        ),

        // 缩放控件：右下角浮动
        Positioned(
          bottom: 16,
          right: 16,
          child: ZoomControl(),
        ),

        // 实体节点：允许超出画布边界
        ...entityNodes.map((node) => Positioned(
          left: node.x,
          top: node.y,
          child: EntityNodeWidget(entity: node.entity),
        )),
      ],
    );
  }
}
```

### 4.2 实体节点布局

```dart
// ✅ 推荐：EntityNodeWidget 布局
class EntityNodeWidget extends StatelessWidget {
  final Entity entity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // 固定宽度
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: 400, // 限制最大高度防止溢出
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 实体名称头部：固定高度
          Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TDText(
                    entity.name,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TDButton(
                  icon: TDIcons.more,
                  size: TDButtonSize.small,
                ),
              ],
            ),
          ),

          // 字段列表：可滚动
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: entity.fields.map((field) => FieldRowWidget(
                  field: field,
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.3 字段行布局

```dart
// ✅ 推荐：FieldRowWidget 布局
class FieldRowWidget extends StatelessWidget {
  final Field field;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 图标：固定宽度
          SizedBox(
            width: 20,
            child: Icon(
              field.isPrimaryKey ? TDIcons.key : TDIcons.field,
              size: 14,
            ),
          ),

          // 字段名：可伸缩
          Expanded(
            child: TDText(
              field.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 12),
            ),
          ),

          // 类型标签：固定宽度
          SizedBox(
            width: 60,
            child: TDText(
              field.dataType,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 五、表单和输入布局规范

### 5.1 表单容器布局

```dart
// ✅ 推荐：表单布局模板
class FormContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 表单标题
          TDText(
            '新建实体',
            fontWeight: FontWeight.bold,
            size: TDFontSize.large,
          ),
          SizedBox(height: 24),

          // 表单字段
          FormSection(
            title: '基本信息',
            children: [
              TDInput(
                label: '实体名称',
                placeholder: '请输入实体名称',
                required: true,
              ),
              SizedBox(height: 16),
              TDInput(
                label: '描述',
                placeholder: '请输入描述',
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TDSelect(
                label: '所属模块',
                options: moduleOptions,
              ),
            ],
          ),
          SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              TDButton(
                text: '取消',
                theme: TDButtonTheme.secondary,
                onClick: () => Navigator.pop(context),
              ),
              SizedBox(width: 16),
              TDButton(
                text: '保存',
                theme: TDButtonTheme.primary,
                onClick: () => _saveForm(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 5.2 搜索框布局

```dart
// ✅ 推荐：搜索框布局
class SearchBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TDSearchBar(
      placeholder: '搜索...',
      onChanged: (value) => _onSearch(value),
    );
  }
}

// ✅ 推荐：带筛选的搜索布局
class SearchWithFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TDSearchBar(
            placeholder: '搜索实体...',
          ),
        ),
        SizedBox(width: 8),
        TDButton(
          icon: TDIcons.filter,
          size: TDButtonSize.small,
        ),
      ],
    );
  }
}
```

## 六、列表和卡片布局规范

### 6.1 实体列表布局

```dart
// ✅ 推荐：实体列表布局
class EntityListWidget extends StatelessWidget {
  final List<Entity> entities;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        return EntityCardWidget(entity: entities[index]);
      },
    );
  }
}
```

### 6.2 卡片组件布局

```dart
// ✅ 推荐：实体卡片布局
class EntityCardWidget extends StatelessWidget {
  final Entity entity;

  @override
  Widget build(BuildContext context) {
    return TDCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Expanded(
                child: TDText(
                  entity.name,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TDTag(
                text: entity.moduleName,
                size: TDTagSize.small,
              ),
            ],
          ),
          SizedBox(height: 8),

          // 描述行
          TDText(
            entity.description ?? '暂无描述',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 12),

          // 统计信息行
          Row(
            children: [
              TDText(
                '${entity.fields.length} 字段',
                size: TDFontSize.small,
              ),
              SizedBox(width: 16),
              TDText(
                '${entity.indexes.length} 索引',
                size: TDFontSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 6.3 模块树布局

```dart
// ✅ 推荐：模块树布局
class ModuleTreeWidget extends StatelessWidget {
  final List<Module> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 树标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TDText(
            '模块列表',
            fontWeight: FontWeight.bold,
          ),
        ),

        // 树节点列表
        ...modules.map((module) => ModuleNodeWidget(
          module: module,
          level: 0,
        )),
      ],
    );
  }
}
```

## 七、对话框和弹窗布局规范

### 7.1 模态对话框布局

```dart
// ✅ 推荐：对话框布局模板
class EntityDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏：固定高度
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TDText(
                      '编辑实体',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 内容区：可滚动
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TDInput(label: '名称'),
                    TDInput(label: '描述', maxLines: 3),
                    // 更多字段...
                  ],
                ),
              ),
            ),

            // 操作栏：固定高度
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TDButton(
                    text: '取消',
                    theme: TDButtonTheme.secondary,
                  ),
                  SizedBox(width: 8),
                  TDButton(
                    text: '保存',
                    theme: TDButtonTheme.primary,
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
```

### 7.2 底部弹窗布局

```dart
// ✅ 推荐：BottomSheet 布局
class EntityOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Container(
            height: 48,
            child: Center(
              child: TDText('选择操作'),
            ),
          ),

          // 操作列表
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(TDIcons.edit),
                  title: TDText('编辑'),
                  onTap: () => _edit(),
                ),
                ListTile(
                  leading: Icon(TDIcons.copy),
                  title: TDText('复制'),
                  onTap: () => _copy(),
                ),
                ListTile(
                  leading: Icon(TDIcons.delete),
                  title: TDText('删除'),
                  onTap: () => _delete(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 八、布局尺寸规范

### 8.1 间距规范

```dart
// ✅ 推荐使用统一的间距常量
class LayoutSpacing {
  // 组件间距
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // 区域间距
  static const double section = 24;
  static const double block = 16;

  // 内边距
  static const double paddingScreen = 16;
  static const double paddingCard = 12;
  static const double paddingPanel = 12;
}
```

### 8.2 高度规范

```dart
// ✅ 推荐使用统一的高度常量
class LayoutHeight {
  // 工具栏
  static const double toolbar = 48;

  // 标题栏
  static const double header = 56;

  // 底部栏
  static const double footer = 48;

  // 状态栏
  static const double statusBar = 32;

  // 列表项
  static const double listItemSmall = 32;
  static const double listItemMedium = 48;
  static const double listItemLarge = 64;

  // 输入框
  static const double input = 40;
  static const double inputSmall = 32;
  static const double inputLarge = 48;

  // 按钮
  static const double buttonSmall = 24;
  static const double buttonMedium = 32;
  static const double buttonLarge = 40;
}
```

### 8.3 宽度规范

```dart
// ✅ 推荐使用统一的宽度常量
class LayoutWidth {
  // 侧边栏
  static const double sidebarCompact = 200;
  static const double sidebarMedium = 240;
  static const double sidebarExpanded = 280;

  // 弹窗
  static const double dialogSmall = 300;
  static const double dialogMedium = 400;
  static const double dialogLarge = 600;

  // 列
  static const double columnIcon = 40;
  static const double columnCheckbox = 48;
  static const double columnAction = 80;
  static const double columnType = 120;
}
```

## 九、开发检查清单

### 9.1 新组件开发检查

```markdown
## 新组件布局检查清单

### 基础检查
- [ ] 是否使用 Expanded/Flexible 处理可变尺寸？
- [ ] 文本是否设置 overflow 属性？
- [ ] 图片是否设置 fit 属性？
- [ ] 是否使用 SizedBox 限制固定尺寸组件？

### 滚动检查
- [ ] 内容可能超出时是否添加 SingleChildScrollView？
- [ ] ListView 是否有父组件约束？
- [ ] 是否避免嵌套滚动组件？

### 响应式检查
- [ ] 是否考虑不同屏幕尺寸？
- [ ] 是否使用 LayoutBuilder 响应式布局？
- [ ] 固定宽度是否合理（不超过屏幕宽度的固定百分比）？

### Stack 检查
- [ ] Positioned 组件是否可能超出边界？
- [ ] 是否设置适当的 clipBehavior？

### 间距检查
- [ ] 是否使用 LayoutSpacing 常量？
- [ ] 间距是否一致？
- [ ] 内边距是否合理？
```

### 9.2 代码审查检查

```markdown
## 布局代码审查要点

### Row/Column 使用
1. 检查是否有未包裹 Expanded/Flexible 的可变尺寸子组件
2. 检查是否有固定尺寸子组件导致溢出风险
3. 确认子组件顺序和 flex 分配是否合理

### 文本处理
1. 检查长文本是否设置 overflow
2. 确认 maxLines 设置是否合理
3. 检查是否需要 FittedBox 缩放

### 滚动处理
1. 检查 ListView/GridView 是否有约束
2. 确认 shrinkWrap 使用是否正确
3. 检查滚动方向是否正确

### 尺寸规范
1. 检查是否使用 LayoutSpacing/Height/Width 常量
2. 确认固定尺寸是否合理
3. 检查最大/最小尺寸约束
```

## 十、常见问题修复模板

### 10.1 Row 文本溢出修复

```dart
// 修复前
Row(children: [Text('长文本'), Icon()])

// 修复后
Row(children: [
  Expanded(child: Text('长文本', overflow: TextOverflow.ellipsis)),
  Icon(),
])
```

### 10.2 Column ListView 溢出修复

```dart
// 修复前
Column(children: [Text(), ListView()])

// 修复后
Column(children: [
  Text(),
  Expanded(child: ListView()),
])
```

### 10.3 Stack Positioned 溢出修复

```dart
// 修复前
Stack(children: [Container(), Positioned(right: -20, child: Icon())])

// 修复后
Stack(
  clipBehavior: Clip.hardEdge,
  children: [Container(), Positioned(right: -20, child: Icon())]
)
```

---

**相关文档**:
- [03-solutions-guide.md](03-solutions-guide.md) - 解决方案速查
- [05-component-patterns.md](05-component-patterns.md) - 组件模式模板
- [06-tdesign-notes.md](06-tdesign-notes.md) - TDesign 组件注意事项