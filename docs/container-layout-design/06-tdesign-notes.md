# TDesign Flutter 组件布局注意事项

本文档记录 Bkdmm 项目中使用 TDesign Flutter 组件时的布局注意事项，帮助避免常见的溢出问题。

## 一、TDesign 组件概述

Bkdmm 项目使用 TDesign Flutter 作为 UI 组件库，主要组件包括：

| 组件类型 | 主要组件 | 文档位置 |
|----------|----------|----------|
| 基础组件 | TDButton, TDText, TDIcon | `shared/theme/` |
| 表单组件 | TDInput, TDSelect, TDSearchBar | `features/*/widgets/` |
| 数据展示 | TDCell, TDCard, TDTable, TDTag | `features/*/views/` |
| 导航组件 | TDNavBar, TDTabs, TDDrawer | `features/workspace/` |
| 反馈组件 | TDDialog, TDToast, TDLoading | `shared/widgets/` |
| 布局组件 | TDHeader, TDSideBar, TDPanel | `features/workspace/` |

## 二、常见组件布局注意事项

### 2.1 TDInput 输入框

#### 注意事项

1. **宽度约束**：TDInput 默认会填满父容器，需要明确约束
2. **标签宽度**：label 属性占用空间，需考虑布局
3. **多行文本**：maxLines 属性会影响高度

#### 正确用法

```dart
// ✅ 推荐：固定宽度输入框
SizedBox(
  width: 200,
  child: TDInput(
    label: '字段名',
    placeholder: '请输入',
  ),
)

// ✅ 推荐：自适应宽度输入框
Expanded(
  child: TDInput(
    placeholder: '搜索...',
  ),
)

// ✅ 推荐：多行文本输入框
Container(
  constraints: BoxConstraints(
    minHeight: 80,
    maxHeight: 200,
  ),
  child: TDInput(
    maxLines: 5,
    placeholder: '请输入描述',
  ),
)

// ❌ 避免：无宽度约束的 Row 中使用
Row(
  children: [
    TDInput(), // 没有宽度约束，可能溢出
  ],
)

// ✅ 正确：添加 Expanded
Row(
  children: [
    Expanded(
      child: TDInput(),
    ),
  ],
)
```

### 2.2 TDButton 按钮

#### 注意事项

1. **文本长度**：按钮文本过长可能导致溢出
2. **图标大小**：icon 和 text 组合时注意尺寸
3. **按钮组**：多个按钮排列时注意间距

#### 正确用法

```dart
// ✅ 推荐：固定尺寸按钮
TDButton(
  text: '确定',
  size: TDButtonSize.medium,
)

// ✅ 推荐：带图标按钮
TDButton(
  text: '添加',
  icon: TDIcons.add,
  size: TDButtonSize.small,
)

// ✅ 推荐：按钮组布局
Row(
  children: [
    TDButton(
      text: '取消',
      theme: TDButtonTheme.secondary,
      size: TDButtonSize.medium,
    ),
    SizedBox(width: 8),
    TDButton(
      text: '确定',
      theme: TDButtonTheme.primary,
      size: TDButtonSize.medium,
    ),
  ],
)

// ✅ 推荐：长文本按钮
TDButton(
  text: '这是一个很长的按钮文本',
  size: TDButtonSize.medium,
  width: double.infinity, // 填满父容器
)

// ❌ 避免：按钮文本过长不处理
TDButton(
  text: '这是一个非常非常非常长的按钮文本', // 可能溢出
)

// ✅ 正确：限制按钮宽度
SizedBox(
  width: 150,
  child: TDButton(
    text: '长文本按钮',
  ),
)
```

### 2.3 TDText 文本

#### 注意事项

1. **文本溢出**：必须设置 overflow 属性处理长文本
2. **最大行数**：maxLines 限制显示行数
3. **富文本**：支持多种样式组合

#### 正确用法

```dart
// ✅ 推荐：单行省略号
TDText(
  '这是一段很长的文本内容',
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)

// ✅ 推荐：多行省略号
TDText(
  '这是一段很长的文本内容可能需要多行显示',
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)

// ✅ 推荐：自适应缩放
FittedBox(
  fit: BoxFit.scaleDown,
  child: TDText(
    '文本会自动缩放适应容器',
    fontWeight: FontWeight.bold,
  ),
)

// ✅ 推荐：在 Row 中使用 Expanded
Row(
  children: [
    TDText('标签:'),
    SizedBox(width: 8),
    Expanded(
      child: TDText(
        '这是一段很长的内容',
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)

// ❌ 避免：无 overflow 处理
Row(
  children: [
    TDText('这是一段很长的文本内容'), // 可能溢出
  ],
)
```

### 2.4 TDSearchBar 搜索栏

#### 注意事项

1. **容器约束**：需要明确的宽度约束
2. **高度固定**：搜索栏高度固定，无需设置
3. **内边距**：建议使用 padding 控制间距

#### 正确用法

```dart
// ✅ 推荐：填满父容器
Container(
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: TDSearchBar(
    placeholder: '搜索实体...',
    onChanged: (value) => _search(value),
  ),
)

// ✅ 推荐：固定宽度
SizedBox(
  width: 300,
  child: TDSearchBar(
    placeholder: '搜索...',
  ),
)

// ✅ 推荐：在工具栏中使用
Container(
  height: 56,
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: TDSearchBar(
    placeholder: '搜索...',
  ),
)
```

### 2.5 TDCard 卡片

#### 注意事项

1. **内容高度**：卡片内容可能超出，需要约束
2. **子组件布局**：内部子组件需正确处理溢出
3. **边距设置**：使用 padding 控制内容边距

#### 正确用法

```dart
// ✅ 推荐：固定高度卡片
SizedBox(
  height: 120,
  child: TDCard(
    child: Column(
      children: [
        TDText('标题', fontWeight: FontWeight.bold),
        SizedBox(height: 8),
        TDText(
          '描述内容',
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    ),
  ),
)

// ✅ 推荐：自适应高度卡片
TDCard(
  child: Column(
    mainAxisSize: MainAxisSize.min, // 自适应高度
    children: [
      TDText('标题'),
      SizedBox(height: 8),
      TDText('描述'),
    ],
  ),
)

// ✅ 推荐：带最大高度约束
Container(
  constraints: BoxConstraints(
    maxHeight: 200,
  ),
  child: TDCard(
    child: SingleChildScrollView(
      child: Column(
        children: [
          // 多个内容项...
        ],
      ),
    ),
  ),
)

// ❌ 避免：卡片内容无约束
TDCard(
  child: Column(
    children: [
      TDText('内容可能很长导致溢出'), // 无 overflow
      Image.network('url'), // 无尺寸限制
    ],
  ),
)
```

### 2.6 TDTag 标签

#### 注意事项

1. **标签文本**：文本过长会自动处理
2. **标签组**：多个标签使用 Wrap 包裹
3. **尺寸选择**：根据场景选择合适的 size

#### 正确用法

```dart
// ✅ 推荐：单个标签
TDTag(
  text: '必填',
  size: TDTagSize.small,
  theme: TDTagTheme.primary,
)

// ✅ 推荐：标签组（自动换行）
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    TDTag(text: '系统模块', size: TDTagSize.small),
    TDTag(text: '用户表', size: TDTagSize.small),
    TDTag(text: '已发布', size: TDTagSize.small),
  ],
)

// ✅ 推荐：在 Row 中使用
Row(
  children: [
    TDText('状态:'),
    SizedBox(width: 8),
    TDTag(text: '已发布', size: TDTagSize.small),
  ],
)

// ❌ 避免：Row 中多个标签不换行
Row(
  children: [
    TDTag(text: '标签1'),
    TDTag(text: '标签2'),
    TDTag(text: '标签3'),
    // ...更多标签会溢出
  ],
)
```

### 2.7 TDCell 单元格

#### 注意事项

1. **右侧元素**：rightWidget 可能超出，需约束
2. **标题宽度**：title/leftIcon 占用空间需平衡
3. **多行内容**：note 属性可显示多行描述

#### 正确用法

```dart
// ✅ 推荐：标准单元格
TDCell(
  title: '字段名',
  note: 'user_name',
)

// ✅ 推荐：带右侧元素
TDCell(
  title: '数据类型',
  note: 'VARCHAR(50)',
  rightWidget: Icon(Icons.chevron_right),
)

// ✅ 推荐：带左侧图标
TDCell(
  leftIcon: TDIcons.table,
  title: '用户表',
  note: '存储用户基本信息',
  rightWidget: TDTag(text: '8字段', size: TDTagSize.small),
)

// ✅ 推荐：单元格列表
Column(
  children: [
    TDCell(title: '名称', note: 'user'),
    TDCell(title: '类型', note: 'VARCHAR'),
  ],
)

// ❌ 避免：rightWidget 无约束
TDCell(
  title: '标题',
  rightWidget: TDText('很长的文本内容'), // 可能溢出
)

// ✅ 正确：约束 rightWidget
TDCell(
  title: '标题',
  rightWidget: SizedBox(
    width: 100,
    child: TDText(
      '很长的文本',
      overflow: TextOverflow.ellipsis,
    ),
  ),
)
```

### 2.8 TDTable 表格

#### 注意事项

1. **列宽设置**：必须设置明确的列宽
2. **单元格内容**：单元格内容需处理溢出
3. **表格高度**：大量数据时需设置滚动

#### 正确用法

```dart
// ✅ 推荐：带列宽定义的表格
TDTable(
  columns: [
    TDTableColumn(
      title: '序号',
      width: 60,
    ),
    TDTableColumn(
      title: '字段名',
      width: 150,
    ),
    TDTableColumn(
      title: '类型',
      width: 120,
    ),
  ],
  dataSource: data.map((item) => TDTableRow(
    data: {
      '序号': item.index,
      '字段名': item.name,
      '类型': item.type,
    },
  )).toList(),
)

// ✅ 推荐：带滚动的表格
Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: TDTable(
      columns: columns,
      dataSource: data,
    ),
  ),
)

// ✅ 推荐：带水平滚动的表格
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: TDTable(
    columns: columns,
    dataSource: data,
  ),
)
```

### 2.9 TDDrawer 侧边抽屉

#### 注意事项

1. **抽屉宽度**：默认宽度可能不适合所有场景
2. **内容布局**：内容需处理溢出
3. **头部高度**：header 高度固定

#### 正确用法

```dart
// ✅ 推荐：标准抽屉
TDDrawer(
  width: 240, // 明确宽度
  header: TDDrawerHeader(
    title: '模块列表',
  ),
  body: SingleChildScrollView(
    child: Column(
      children: [
        // 多个菜单项...
      ],
    ),
  ),
)

// ✅ 推荐：抽屉菜单项
TDDrawerItem(
  title: '用户模块',
  icon: TDIcons.user,
  onTap: () => _selectModule(),
)

// ✅ 推荐：可折叠抽屉
TDDrawer(
  width: 240,
  body: ExpandableMenuList(
    items: menuItems,
  ),
)
```

### 2.10 TDDialog 对话框

#### 注意事项

1. **对话框尺寸**：需设置合理的宽度和高度约束
2. **内容溢出**：内容区域需可滚动
3. **按钮布局**：多个按钮需合理排列

#### 正确用法

```dart
// ✅ 推荐：确认对话框
TDDialog(
  title: '确认删除',
  content: '确定要删除此实体吗？此操作不可撤销。',
  actions: [
    TDButton(
      text: '取消',
      theme: TDButtonTheme.secondary,
      onClick: () => Navigator.pop(context),
    ),
    TDButton(
      text: '确定',
      theme: TDButtonTheme.primary,
      onClick: () => _deleteEntity(),
    ),
  ],
)

// ✅ 推荐：自定义内容对话框
TDDialog(
  title: '新建实体',
  content: SizedBox(
    width: 400,
    height: 300,
    child: SingleChildScrollView(
      child: Column(
        children: [
          TDInput(label: '名称'),
          TDInput(label: '描述'),
        ],
      ),
    ),
  ),
  actions: [
    TDButton(text: '取消'),
    TDButton(text: '保存'),
  ],
)

// ✅ 推荐：长内容对话框
TDDialog(
  title: '详情',
  content: Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          // 多个内容项...
        ],
      ),
    ),
  ),
)
```

### 2.11 TDSelect 选择器

#### 注意事项

1. **选项显示**：选项文本可能过长
2. **宽度约束**：选择器宽度需明确
3. **弹出层**：弹出层内容需处理溢出

#### 正确用法

```dart
// ✅ 推荐：固定宽度选择器
SizedBox(
  width: 200,
  child: TDSelect(
    title: '数据类型',
    options: dataTypeOptions,
    selectedOption: selectedType,
    onSelect: (option) => _selectType(option),
  ),
)

// ✅ 推荐：自适应宽度
Expanded(
  child: TDSelect(
    title: '选择模块',
    options: moduleOptions,
  ),
)

// ✅ 推荐：处理长选项文本
TDSelect(
  title: '类型',
  options: options.map((opt) => TDSelectOption(
    label: opt.label,
    value: opt.value,
    // 长文本会被自动截断显示
  )).toList(),
)
```

## 三、组合组件布局模式

### 3.1 表单组合

```dart
// ✅ 推荐：TDesign 表单组合
Container(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      // 输入项
      TDInput(
        label: '实体名称',
        placeholder: '请输入名称',
        required: true,
      ),
      SizedBox(height: 16),

      // 选择项
      SizedBox(
        width: double.infinity,
        child: TDSelect(
          title: '所属模块',
          options: moduleOptions,
        ),
      ),
      SizedBox(height: 16),

      // 多行文本
      TDInput(
        label: '描述',
        placeholder: '请输入描述',
        maxLines: 3,
      ),
      SizedBox(height: 24),

      // 按钮组
      Row(
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
    ],
  ),
)
```

### 3.2 列表组合

```dart
// ✅ 推荐：TDesign 列表组合
Column(
  children: [
    // 搜索栏
    Container(
      padding: EdgeInsets.all(12),
      child: TDSearchBar(
        placeholder: '搜索实体...',
      ),
    ),

    // 列表
    Expanded(
      child: ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          return TDCard(
            child: Row(
              children: [
                // 图标
                Container(
                  width: 48,
                  height: 48,
                  child: Icon(TDIcons.table),
                ),
                SizedBox(width: 12),

                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        entities[index].name,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 4),
                      TDText(
                        entities[index].description,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        font: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // 标签
                TDTag(
                  text: '${entities[index].fields.length}字段',
                  size: TDTagSize.small,
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
)
```

### 3.3 工具栏组合

```dart
// ✅ 推荐：TDesign 工具栏组合
Container(
  height: 48,
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: Row(
    children: [
      // 左侧按钮
      TDButton(
        icon: TDIcons.add,
        size: TDButtonSize.small,
      ),
      SizedBox(width: 8),
      TDButton(
        icon: TDIcons.delete,
        size: TDButtonSize.small,
      ),

      SizedBox(width: 16),
      Container(width: 1, height: 24, color: Colors.grey),

      SizedBox(width: 16),

      // 搜索框
      Expanded(
        child: TDSearchBar(
          placeholder: '搜索...',
        ),
      ),

      SizedBox(width: 12),

      // 右侧按钮
      TDButton(
        icon: TDIcons.filter,
        size: TDButtonSize.small,
      ),
      TDButton(
        icon: TDIcons.more,
        size: TDButtonSize.small,
      ),
    ],
  ),
)
```

## 四、特殊场景处理

### 4.1 长文本处理

```dart
// ✅ TDText 长文本处理
TDText(
  '这是一段非常长的文本内容需要正确处理溢出问题',
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
  style: TextStyle(fontSize: 14),
)

// ✅ TDInput 长文本处理
TDInput(
  value: longText,
  maxLines: 3,
  placeholder: '请输入',
)

// ✅ TDCell 长文本处理
TDCell(
  title: '描述',
  note: longDescription,
  noteMaxLines: 2, // 限制行数
)
```

### 4.2 图片处理

```dart
// ✅ TDCard 中图片处理
TDCard(
  child: Row(
    children: [
      SizedBox(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: TDText('内容'),
      ),
    ],
  ),
)
```

### 4.3 滚动处理

```dart
// ✅ TDDrawer 滚动处理
TDDrawer(
  body: SingleChildScrollView(
    child: Column(
      children: menuItems,
    ),
  ),
)

// ✅ TDDialog 滚动处理
TDDialog(
  content: SingleChildScrollView(
    child: Column(
      children: formFields,
    ),
  ),
)

// ✅ 列表滚动处理
Expanded(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => TDCell(...),
  ),
)
```

## 五、常见错误示例

### 5.1 错误：无宽度约束

```dart
// ❌ 错误
Row(
  children: [
    TDInput(), // 无宽度约束
    TDSelect(), // 无宽度约束
  ],
)

// ✅ 正确
Row(
  children: [
    Expanded(child: TDInput()),
    SizedBox(width: 200, child: TDSelect()),
  ],
)
```

### 5.2 错误：文本无 overflow

```dart
// ❌ 错误
TDText('这是一段很长的文本') // 无 overflow

// ✅ 正确
TDText(
  '这是一段很长的文本',
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

### 5.3 错误：图片无尺寸限制

```dart
// ❌ 错误
TDCard(
  child: Image.network('url'), // 无尺寸限制
)

// ✅ 正确
TDCard(
  child: SizedBox(
    width: 100,
    height: 100,
    child: Image.network('url', fit: BoxFit.cover),
  ),
)
```

### 5.4 错误：按钮组无间距

```dart
// ❌ 错误
Row(
  children: [
    TDButton(text: '取消'),
    TDButton(text: '确定'),
  ],
)

// ✅ 正确
Row(
  children: [
    TDButton(text: '取消'),
    SizedBox(width: 8),
    TDButton(text: '确定'),
  ],
)
```

## 六、TDesign 组件尺寸参考

| 组件 | Small | Medium | Large |
|------|-------|--------|-------|
| TDButton | 24px | 32px | 40px |
| TDTag | - | - | - |
| TDIcon | 16px | 24px | 32px |
| TDInput | 32px | 40px | 48px |

## 七、检查清单

### 开发前检查

```markdown
## TDesign 组件使用检查

### 输入组件 (TDInput/TDSelect)
- [ ] 是否设置宽度约束？
- [ ] 多行文本是否设置 maxLines？
- [ ] 是否在 Row 中使用 Expanded？

### 文本组件 (TDText)
- [ ] 是否设置 overflow？
- [ ] 是否设置 maxLines？
- [ ] 是否需要 FittedBox？

### 卡片组件 (TDCard)
- [ ] 内容高度是否约束？
- [ ] 子组件是否处理溢出？
- [ ] 图片是否设置 fit？

### 表格组件 (TDTable)
- [ ] 列宽是否明确设置？
- [ ] 是否需要滚动？
- [ ] 单元格内容是否处理溢出？

### 列表组件 (TDCell)
- [ ] rightWidget 是否约束？
- [ ] 文本是否设置 overflow？
- [ ] 图标尺寸是否合理？

### 弹窗组件 (TDDialog)
- [ ] 尺寸是否合理？
- [ ] 内容是否可滚动？
- [ ] 按钮布局是否合理？
```

---

**相关文档**:
- [04-best-practices.md](04-best-practices.md) - 最佳实践
- [05-component-patterns.md](05-component-patterns.md) - 组件模式模板
- [TDesign Flutter 官方文档](https://tdesign.tencent.com/flutter)