# Bkdmm 导入包重构计划

## 一、现状分析

### 1.1 统计数据

| 指标 | 数量 | 占比 |
|------|------|------|
| 总文件数 | 201 | - |
| 总导入语句 | 729 | - |
| dart: SDK 导入 | 55 | 7.5% |
| package: 包导入 | 280 | 38.4% |
| 相对路径导入 | 309 | 42.4% |

### 1.2 相对路径深度分布

| 层级 | 示例 | 数量 | 占比 | 优先级 |
|------|------|------|------|--------|
| 1层 | `../models.dart` | 144 | 46.6% | ✅ 保留 |
| 2层 | `../../utils/id_generator.dart` | 39 | 12.6% | ✅ 保留 |
| 3层 | `../../../shared/models/models.dart` | 84 | 27.2% | ⚠️ 重构 |
| 4层 | `../../../../shared/providers/providers.dart` | 42 | 13.6% | 🔴 必须重构 |

### 1.3 问题识别

1. **深层相对路径过多**: 3层以上相对路径占 40.8% (126次)
2. **跨模块导入混乱**: `features → shared` 跨模块导入有 87 处
3. **barrel file 利用不足**: 部分模块缺少统一的导出文件
4. **不一致性**: 同类文件使用不同导入风格

---

## 二、重构目标

### 2.1 遵循 Flutter 官方规范

```
Under lib/src, for in-folder import, use relative import.
For cross-folder import, import the entire package with absolute import.
```

### 2.2 具体规则

| 场景 | 规则 | 示例 |
|------|------|------|
| **dart SDK** | 保持 `dart:` | `import 'dart:async';` |
| **外部包** | 保持 `package:` | `import 'package:flutter/material.dart';` |
| **同文件夹** | 相对路径 (≤1层) | `import 'models.dart';` |
| **父文件夹** | 相对路径 (≤2层) | `import '../models/models.dart';` |
| **跨模块/深层** | package 绝对路径 | `import 'package:bkdmm/shared/models/models.dart';` |

### 2.3 预期效果

- ✅ 3层以上相对路径减少到 **0**
- ✅ 跨模块导入统一使用 package 路径
- ✅ barrel file 覆盖率达到 **100%**
- ✅ 代码可读性和可维护性提升

---

## 三、重构范围

### 3.1 需要重构的文件

**优先级 P0 (4层相对路径 - 19个文件)**:
```
lib/features/workspace/widgets/toolbar/view_menu.dart
lib/features/workspace/widgets/toolbar/file_menu.dart
lib/features/workspace/widgets/toolbar/top_menu_bar.dart
lib/features/workspace/widgets/left_view/left_view_container.dart
lib/features/workspace/widgets/bottom_view/bottom_view_container.dart
lib/features/modeling/entity_editor/providers/entity_provider.dart
lib/features/modeling/entity_editor/widgets/index_editor.dart
lib/features/modeling/entity_editor/widgets/field_table.dart
lib/features/modeling/entity_editor/widgets/code_preview.dart
lib/features/modeling/entity_editor/views/entity_editor_view.dart
lib/features/modeling/er_diagram/core/er_graph_builder.dart
lib/features/modeling/er_diagram/views/er_diagram_view.dart
lib/features/modeling/er_diagram/views/er_interaction_overlay.dart
lib/features/modeling/er_diagram/widgets/er_table_node_widget.dart
lib/features/modeling/er_diagram/widgets/er_table_node_widget_v2.dart
lib/features/modeling/er_diagram/widgets/er_field_anchor_widget.dart
lib/features/modeling/er_diagram/widgets/er_diagram_canvas.dart
lib/features/modeling/er_diagram/controllers/er_diagram_controller.dart
lib/features/modeling/er_diagram/painters/er_relation_painter_adapter.dart
```

**优先级 P1 (3层相对路径 - 39个文件)**:
```
lib/features/home/views/home_view.dart
lib/features/home/widgets/history_list_tile.dart
lib/features/home/widgets/quick_action_card.dart
lib/features/project/views/create_project_dialog.dart
lib/features/project/views/open_project_dialog.dart
lib/features/project/widgets/recent_project_tile.dart
lib/features/project/widgets/recent_projects_list.dart
lib/features/project/services/project_file_service.dart
lib/features/project/providers/project_notifier.dart
lib/features/workspace/views/workspace_view.dart
lib/features/workspace/dialogs/module_dialogs.dart
lib/features/workspace/widgets/module_tree.dart
lib/features/workspace/widgets/module_tree_item.dart
lib/features/workspace/widgets/tab_bar.dart
lib/features/workspace/providers/tab_provider.dart
lib/features/workspace/providers/layout_provider.dart
lib/features/workspace/constants/view_configs.dart
lib/features/settings/views/settings_view.dart
lib/features/settings/views/settings_dialog.dart
... (共39个)
```

### 3.2 Barrel File 补充计划

**需要创建的 barrel files**:
| 模块 | 文件路径 | 导出内容 |
|------|----------|----------|
| `core/i18n` | `lib/core/i18n/i18n.dart` | ✅ 已存在 |
| `utils` | `lib/utils/utils.dart` | ✅ 已存在 |
| `shared/widgets` | `lib/shared/widgets/widgets.dart` | ❌ 需创建 |
| `shared/utils` | `lib/shared/utils/utils.dart` | ❌ 需创建 |

---

## 四、重构执行计划

### Phase 1: Barrel File 补充 (预计 30 分钟)

**任务清单**:
- [ ] 创建 `lib/shared/widgets/widgets.dart`
- [ ] 创建 `lib/shared/utils/utils.dart`
- [ ] 更新 `lib/shared/services/services.dart` (补充缺失导出)
- [ ] 验证 barrel files 导出完整性

**示例 - `lib/shared/widgets/widgets.dart`**:
```dart
// Shared widgets barrel file

export 'app_scaffold.dart';
export 'loading_overlay.dart';
export 'td_popup_menu.dart';
```

---

### Phase 2: P0 文件重构 (预计 1 小时)

**重构示例 - `entity_editor_view.dart`**:

**Before**:
```dart
import '../../../core/i18n/i18n.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../utils/id_generator.dart';
import '../widgets/field_table.dart';
import '../widgets/index_editor.dart';
import '../widgets/code_preview.dart';
import '../providers/entity_provider.dart';
```

**After**:
```dart
// dart SDK imports
import 'dart:async';

// External package imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

// Internal package imports (cross-module)
import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/shared/widgets/widgets.dart';
import 'package:bkdmm/shared/utils/responsive_utils.dart';
import 'package:bkdmm/utils/id_generator.dart';

// Relative imports (same module)
import '../widgets/field_table.dart';
import '../widgets/index_editor.dart';
import '../widgets/code_preview.dart';
import '../providers/entity_provider.dart';
```

**重构步骤**:
1. 添加必要的 package 导入 (如有缺失)
2. 将 3层+ 相对路径改为 `package:bkdmm/...`
3. 保持 1-2层相对路径不变
4. 按 Flutter 官方推荐顺序排列导入
5. 运行 `flutter analyze` 验证

---

### Phase 3: P1 文件重构 (预计 1.5 小时)

**批量重构策略**:
1. 使用脚本批量替换 3层相对路径
2. 手动检查特殊情况
3. 分模块逐步重构

**替换规则**:
```
../../../shared/models/models.dart
  → package:bkdmm/shared/models/models.dart

../../../core/i18n/i18n.dart
  → package:bkdmm/core/i18n/i18n.dart

../../../utils/utils.dart
  → package:bkdmm/utils/utils.dart
```

---

### Phase 4: P2 文件检查 (预计 30 分钟)

**检查项**:
- [ ] 2层相对路径是否合理 (同模块内)
- [ ] 是否有遗漏的 3层+ 路径
- [ ] 导入顺序是否符合规范
- [ ] 无用导入是否清理

---

### Phase 5: 验证与清理 (预计 30 分钟)

**验证步骤**:
```bash
# 1. 静态分析
flutter analyze

# 2. 检查深层相对路径
find lib -name "*.dart" -exec grep -l "\.\./\.\./\.\./\.\./" {} \;

# 3. 检查跨模块相对导入
grep -r "features.*import.*\.\./.*shared" lib/

# 4. 运行测试
flutter test
```

---

## 五、导入顺序规范

### 5.1 推荐顺序

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Flutter SDK imports
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// 3. Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 4. Internal package imports (跨模块)
import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/shared/services/services.dart';
import 'package:bkdmm/utils/utils.dart';

// 5. Relative imports (同模块内，≤2层)
import '../models/data_type.dart';
import '../providers/settings_provider.dart';
import 'widgets/field_table.dart';  // 同文件夹
```

### 5.2 分隔规范

- 各分组之间**空一行**
- 同组内按**字母顺序**排列
- 使用 `show` 关键字明确导入内容 (可选)

---

## 六、自动化脚本

### 6.1 批量替换脚本

```bash
#!/bin/bash
# refactor_imports.sh

# 替换 4层相对路径
find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../../shared/|import 'package:bkdmm/shared/|g" {} \;

find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../../core/|import 'package:bkdmm/core/|g" {} \;

find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../../utils/|import 'package:bkdmm/utils/|g" {} \;

# 替换 3层相对路径
find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../shared/|import 'package:bkdmm/shared/|g" {} \;

find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../core/|import 'package:bkdmm/core/|g" {} \;

find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../utils/|import 'package:bkdmm/utils/|g" {} \;

# 替换 l10n
find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../../l10n/|import 'package:bkdmm/l10n/|g" {} \;

find lib -name "*.dart" -type f -exec sed -i \
  "s|import '../../l10n/|import 'package:bkdmm/l10n/|g" {} \;
```

### 6.2 导入排序工具

使用 `dart format` 自动排序:
```bash
dart format --set-exit-if-changed lib/
```

---

## 七、预期收益

### 7.1 代码质量

| 指标 | 当前 | 重构后 | 改善 |
|------|------|--------|------|
| 3层+ 相对路径 | 126 | 0 | -100% |
| 跨模块相对导入 | 87 | 0 | -100% |
| 导入一致性 | 60% | 95% | +35% |
| IDE 跳转效率 | 中 | 高 | ↑ |

### 7.2 开发体验

- ✅ **重构友好**: 改包名/目录结构不需要批量替换
- ✅ **IDE 友好**: 更好的自动补全和导航
- ✅ **新人友好**: 统一的导入风格降低理解成本
- ✅ **维护友好**: 清晰的模块边界

---

## 八、风险评估

### 8.1 潜在问题

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 循环导入 | 编译失败 | 分模块逐步验证 |
| 遗漏替换 | 编译失败 | 运行 flutter analyze |
| 导入冲突 | 命名冲突 | 使用 `show/hide` 关键字 |
| IDE 缓存 | 跳转失效 | 重启 IDE / flutter clean |

### 8.2 回滚策略

- 提交前创建备份分支: `git checkout -b backup/import-refactor`
- 使用 git 跟踪所有变更: `git diff` 检查
- 如遇问题可快速回滚: `git reset --hard HEAD`

---

## 九、执行时间表

| 阶段 | 任务 | 预计时间 | 负责人 |
|------|------|----------|--------|
| Phase 1 | Barrel File 补充 | 30 min | Claude |
| Phase 2 | P0 文件重构 (19个) | 1 h | Claude |
| Phase 3 | P1 文件重构 (39个) | 1.5 h | Claude |
| Phase 4 | P2 文件检查 | 30 min | Claude |
| Phase 5 | 验证与清理 | 30 min | Claude |
| **总计** | - | **3.5 h** | - |

---

## 十、检查清单

### 重构前检查
- [ ] 创建备份分支
- [ ] 运行 `flutter analyze` 确保无错误
- [ ] 运行 `flutter test` 确保测试通过
- [ ] 记录当前导入统计数据

### 重构后检查
- [ ] `flutter analyze` 无 error/warning
- [ ] `flutter test` 全部通过
- [ ] 无 3层+ 相对路径
- [ ] 无跨模块相对导入
- [ ] 导入顺序符合规范
- [ ] IDE 代码导航正常

---

**创建日期**: 2026-06-30
**参考文档**: [Flutter Style Guide](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md)