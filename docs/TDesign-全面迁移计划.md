# Bkdmm TDesign 全面迁移计划

> 将整个项目底座完全切换到 TDesign Flutter 组件库

---

## 一、当前问题分析

### 1.1 发现的问题

| 问题 | 描述 | 影响 |
|------|------|------|
| 黑色按钮 | TDButton 默认主题显示为黑色 | 视觉不统一 |
| 按钮风格不一致 | 部分使用 Material，部分使用 TDesign | 用户体验混乱 |
| 主题未适配 | 未配置 TDTheme 全局主题 | 颜色、字体不统一 |
| 图标不统一 | TDIcons 和 Icons 混用 | 视觉风格差异 |
| 对话框风格 | AlertDialog 和 TDDialog 混用 | 交互不一致 |

### 1.2 需要完全替换的组件

| Material 组件 | TDesign 替代 | 优先级 |
|--------------|-------------|--------|
| 所有 Button 类型 | TDButton | 🔴 高 |
| TextField | TDInput | 🔴 高 |
| AlertDialog | TDDialog | 🔴 高 |
| SnackBar | TDToast/TDMessage | 🔴 高 |
| Card | TDCard/TDCell | 🟡 中 |
| Chip/ChoiceChip | TDTag | 🟡 中 |
| AppBar | TDNavBar | 🟡 中 |
| TabBar | TDTabBar | 🟡 中 |
| BottomNavigationBar | TDNavBar | 🟡 中 |
| ListTile | TDCell | 🟡 中 |
| Checkbox | TDCheckbox | 🟢 低 |
| Switch | TDSwitch | 🟢 低 |
| Radio | TDRadio | 🟢 低 |
| Slider | TDSlider | 🟢 低 |
| PopupMenuButton | TDDropdownMenu | 🟢 低 |
| Divider | TDDivider | 🟢 低 |
| Icons.* | TDIcons.* | 🔴 高 |

---

## 二、TDesign 主题配置

### 2.1 创建全局主题配置

```dart
// lib/shared/theme/td_app_theme.dart
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// TDesign 全局主题配置
class TDAppTheme {
  /// 品牌色 - 蓝色系
  static const Color brandColor = Color(0xFF0052D9);
  
  /// 功能色
  static const Color successColor = Color(0xFF2BA471);
  static const Color warningColor = Color(0xFFE37318);
  static const Color errorColor = Color(0xFFD54941);
  
  /// 浅色主题配置
  static TDThemeData lightTheme() => TDThemeData.defaultData().copyWith(
    brandColor: brandColor,
    successColor: successColor,
    warningColor: warningColor,
    errorColor: errorColor,
  );
  
  /// 深色主题配置
  static TDThemeData darkTheme() => TDThemeData.defaultData().copyWith(
    brandColor: Color(0xFF4582E6),
    bgColor: Color(0xFF1D1D1D),
    bgColorContainer: Color(0xFF2C2C2C),
  );
  
  /// 按钮主题映射
  static TDButtonTheme get primaryButton => TDButtonTheme.primary;
  static TDButtonTheme get defaultButton => TDButtonTheme.defaultTheme;
  static TDButtonTheme get dangerButton => TDButtonTheme.danger;
  static TDButtonTheme get successButton => TDButtonTheme.success;
}
```

### 2.2 在 main.dart 中应用全局主题

```dart
// lib/main.dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'shared/theme/td_app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  
  runApp(
    TDTheme(
      data: TDAppTheme.lightTheme(),  // 全局 TDesign 主题
      child: const ProviderScope(
        child: BkdmmApp(),
      ),
    ),
  );
}
```

---

## 三、组件替换规范

### 3.1 按钮替换规则

```dart
// ❌ 错误 - 黑色按钮
TDButton(
  text: '保存',
  type: TDButtonType.fill,
  // 缺少 theme 配置，默认是黑色
)

// ✅ 正确 - 蓝色主按钮
TDButton(
  text: '保存',
  type: TDButtonType.fill,
  theme: TDButtonTheme.primary,  // 蓝色主题
  onTap: () {},
)

// ✅ 正确 - 次要按钮
TDButton(
  text: '取消',
  type: TDButtonType.outline,
  theme: TDButtonTheme.defaultTheme,  // 白色边框
  onTap: () {},
)

// ✅ 正确 - 危险按钮
TDButton(
  text: '删除',
  type: TDButtonType.fill,
  theme: TDButtonTheme.danger,  // 红色
  onTap: () {},
)

// ✅ 正确 - 成功按钮
TDButton(
  text: '完成',
  type: TDButtonType.fill,
  theme: TDButtonTheme.success,  // 绿色
  onTap: () {},
)

// ✅ 正确 - 图标按钮
TDButton(
  icon: TDIcons.add,
  size: TDButtonSize.small,
  type: TDButtonType.text,
  theme: TDButtonTheme.primary,
  onTap: () {},
)
```

### 3.2 输入框替换规则

```dart
// ❌ Material TextField
TextField(
  decoration: InputDecoration(
    labelText: '用户名',
    hintText: '请输入',
  ),
)

// ✅ TDesign TDInput
TDInput(
  leftLabel: '用户名',
  hintText: '请输入',
  backgroundColor: Colors.transparent,
  onChanged: (value) {},
)

// ✅ 带图标的输入框
TDInput(
  leftLabel: '搜索',
  leftIcon: TDIcons.search,
  hintText: '搜索表名',
  backgroundColor: Colors.transparent,
  clearBtn: true,
  onChanged: (value) {},
)

// ✅ 多行输入
TDTextarea(
  hintText: '请输入描述',
  maxLines: 4,
  backgroundColor: Colors.transparent,
)
```

### 3.3 对话框替换规则

```dart
// ❌ Material AlertDialog
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text('确认删除'),
    content: Text('删除后无法恢复'),
    actions: [
      TextButton(child: Text('取消')),
      FilledButton(child: Text('删除')),
    ],
  ),
)

// ✅ TDesign TDDialog
TDAlertDialog.showTextAlert(
  context: context,
  title: '确认删除',
  content: '删除后无法恢复',
  leftBtn: TDDialogButtonOptions(
    text: '取消',
    theme: TDButtonTheme.defaultTheme,
    action: () => Navigator.pop(context),
  ),
  rightBtn: TDDialogButtonOptions(
    text: '删除',
    theme: TDButtonTheme.danger,
    action: () {
      _delete();
      Navigator.pop(context);
    },
  ),
);
```

### 3.4 消息提示替换规则

```dart
// ❌ Material SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('保存成功')),
)

// ✅ TDesign TDToast
TDToast.showText('保存成功', context: context);

// ✅ 成功提示
TDToast.showSuccessToast('保存成功', context: context);

// ✅ 错误提示
TDToast.showFailToast('操作失败', context: context);

// ✅ 加载提示
TDLoading.showLoading(context, text: '正在加载...');
TDLoading.hideLoading(context);
```

### 3.5 图标替换映射

| Material Icons | TDesign TDIcons |
|---------------|----------------|
| Icons.add | TDIcons.add |
| Icons.edit | TDIcons.edit |
| Icons.delete | TDIcons.delete |
| Icons.save | TDIcons.save |
| Icons.close | TDIcons.close |
| Icons.search | TDIcons.search |
| Icons.settings | TDIcons.setting |
| Icons.refresh | TDIcons.refresh |
| Icons.zoom_in | TDIcons.zoom_in |
| Icons.zoom_out | TDIcons.zoom_out |
| Icons.fullscreen | TDIcons.fullscreen |
| Icons.list | TDIcons.unordered_list |
| Icons.table_chart | TDIcons.table |
| Icons.code | TDIcons.code |
| Icons.folder | TDIcons.folder |
| Icons.file_copy | TDIcons.file_copy |
| Icons.chevron_left | TDIcons.chevron_left |
| Icons.chevron_right | TDIcons.chevron_right |
| Icons.check | TDIcons.check |
| Icons.error | TDIcons.error |
| Icons.warning | TDIcons.warning |
| Icons.info | TDIcons.info |
| Icons.help | TDIcons.help |
| Icons.user | TDIcons.user |
| Icons.home | TDIcons.home |
| Icons.menu | TDIcons.menu |
| Icons.more_vert | TDIcons.more |
| Icons.arrow_back | TDIcons.chevron_left |

---

## 四、分阶段迁移计划

### Phase 1: 主题全局配置 (Day 1)

**目标**: 配置全局 TDesign 主题，确保所有 TDButton 显示正确颜色

**任务**:
- [ ] 创建 TDAppTheme 配置类
- [ ] 在 main.dart 应用 TDTheme 包裹
- [ ] 配置浅色/深色主题切换支持
- [ ] 验证按钮颜色正确显示

**验收标准**:
- 所有 TDButton 使用 theme 参数
- 主按钮显示蓝色而非黑色
- 主题切换功能正常

---

### Phase 2: 核心组件替换 (Day 2-3)

**目标**: 替换所有核心交互组件

**任务**:
- [ ] 替换所有按钮 (TDButton + theme)
- [ ] 替换所有输入框 (TDInput/TDTextarea)
- [ ] 替换所有对话框 (TDDialog)
- [ ] 替换所有消息提示 (TDToast/TDLoading)
- [ ] 替换所有图标 (TDIcons)

**涉及文件**:
- `lib/features/home/views/home_view.dart`
- `lib/features/workspace/views/workspace_view.dart`
- `lib/features/project/views/*.dart`
- `lib/features/modeling/entity_editor/**/*.dart`
- `lib/features/modeling/er_diagram/**/*.dart`
- `lib/features/datatype/views/*.dart`
- `lib/features/codegen/views/*.dart`
- `lib/features/settings/views/*.dart`
- `lib/shared/widgets/*.dart`

**验收标准**:
- 无 Material Button/TextField/AlertDialog/SnackBar
- 所有按钮有明确的 theme 配置
- flutter analyze 0 errors

---

### Phase 3: 布局组件替换 (Day 4-5)

**目标**: 替换布局和展示组件

**任务**:
- [ ] 替换 Card → TDCard
- [ ] 替换 ListTile → TDCell
- [ ] 替换 Chip → TDTag
- [ ] 替换 Divider → TDDivider
- [ ] 替换 PopupMenuButton → TDDropdownMenu
- [ ] 替换 Checkbox → TDCheckbox
- [ ] 替换 Switch → TDSwitch
- [ ] 替换 Radio → TDRadio

**验收标准**:
- 视觉风格统一
- 交互体验一致

---

### Phase 4: 导航组件替换 (Day 6)

**目标**: 替换导航相关组件

**任务**:
- [ ] 评估 TDNavBar 替换 AppBar
- [ ] 评估 TDTabBar 替换 TabBar
- [ ] 评估 TDSideBar 替换侧边导航
- [ ] 保持功能兼容性

**验收标准**:
- 导航功能正常
- 风格统一

---

### Phase 5: 样式细节优化 (Day 7)

**目标**: 统一颜色、字体、间距等细节

**任务**:
- [ ] 统一颜色使用 (从 TDTheme.of(context) 获取)
- [ ] 统一字体大小 (使用 TDesign 设计规范)
- [ ] 统一间距 (使用 TDesign 间距规范)
- [ ] 优化深色模式支持

**验收标准**:
- 风格完全统一
- 深色模式正常

---

### Phase 6: 测试和修复 (Day 8-9)

**目标**: 全面测试和问题修复

**任务**:
- [ ] 功能测试清单
- [ ] 修复发现的问题
- [ ] 性能测试
- [ ] UI/UX 审查

**验收标准**:
- 所有功能正常
- 无视觉问题
- 性能良好

---

## 五、文件清单

### 需要修改的文件 (按优先级)

| 优先级 | 文件 | 组件数量 |
|--------|------|----------|
| 🔴 | home_view.dart | ~8 |
| 🔴 | workspace_view.dart | ~20 |
| 🔴 | create_project_dialog.dart | ~5 |
| 🔴 | open_project_dialog.dart | ~5 |
| 🔴 | entity_editor_view.dart | ~10 |
| 🔴 | field_table.dart | ~5 |
| 🔴 | index_editor.dart | ~5 |
| 🔴 | datatype_edit_dialog.dart | ~10 |
| 🔴 | er_diagram_canvas.dart | ~7 |
| 🔴 | codegen_view.dart | ~5 |
| 🟡 | settings_view.dart | ~15 |
| 🟡 | code_preview.dart | ~3 |
| 🟡 | module_tree.dart | ~10 |
| 🟡 | tab_bar.dart | ~5 |
| 🟢 | loading_overlay.dart | ~2 |
| 🟢 | app_scaffold.dart | ~5 |

---

## 六、风险和缓解

| 风险 | 缓解措施 |
|------|----------|
| TDesign API 不熟悉 | 参考 TDesign 文档和示例 |
| 部分组件缺失 | 保留 Material 组件或自定义实现 |
| 深色模式适配 | 配置 darkTheme 并测试 |
| 功能兼容性 | 逐个测试每个替换 |
| 性能下降 | 使用 const 构造函数 |

---

## 七、验收清单

### 功能验收

- [ ] 项目创建/打开
- [ ] 实体创建/编辑
- [ ] 字段编辑
- [ ] 索引编辑
- [ ] ER 图操作
- [ ] 关系创建
- [ ] 代码生成
- [ ] 设置保存
- [ ] 主题切换

### 视觉验收

- [ ] 所有按钮蓝色而非黑色
- [ ] 主按钮和次要按钮区分明显
- [ ] 危险操作红色提示
- [ ] 成功操作绿色提示
- [ ] 输入框风格统一
- [ ] 对话框风格统一
- [ ] 消息提示风格统一
- [ ] 深色模式正常显示

---

## 八、执行命令

### 开始迁移

```bash
cd F:/projects/Bkdmm/bkdmm
git checkout -b migrate/tdesign-full
```

### 每阶段验证

```bash
flutter analyze
flutter build windows
```

### 完成迁移

```bash
git add .
git commit -m "完成 TDesign 全面迁移"
git checkout main
git merge migrate/tdesign-full
```