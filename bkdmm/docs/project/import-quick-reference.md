# 导入重构快速参考

## 一、导入顺序规范

```dart
// 1️⃣ Dart SDK
import 'dart:async';
import 'dart:io';

// 2️⃣ Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// 3️⃣ 第三方包
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 4️⃣ 内部包 (跨模块)
import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/shared/services/services.dart';
import 'package:bkdmm/shared/widgets/widgets.dart';
import 'package:bkdmm/shared/utils/responsive_utils.dart';
import 'package:bkdmm/utils/utils.dart';
import 'package:bkdmm/l10n/app_localizations.dart';

// 5️⃣ 相对导入 (同模块内，≤2层)
import '../models/data_type.dart';
import '../providers/entity_provider.dart';
import 'widgets/field_table.dart';
```

---

## 二、决策树

```
需要导入一个文件？
│
├─ 是 Dart SDK？
│  └─ ✅ import 'dart:async';
│
├─ 是外部包？
│  └─ ✅ import 'package:flutter/material.dart';
│
├─ 是项目内其他模块？
│  │
│  ├─ 是 shared/* ?
│  │  └─ ✅ import 'package:bkdmm/shared/models/models.dart';
│  │
│  ├─ 是 core/* ?
│  │  └─ ✅ import 'package:bkdmm/core/i18n/i18n.dart';
│  │
│  ├─ 是 utils/* ?
│  │  └─ ✅ import 'package:bkdmm/utils/utils.dart';
│  │
│  └─ 是 l10n/* ?
│     └─ ✅ import 'package:bkdmm/l10n/app_localizations.dart';
│
└─ 是同模块内？
   │
   ├─ 同文件夹？
   │  └─ ✅ import 'models.dart';
   │
   ├─ 父文件夹？
   │  └─ ✅ import '../models/models.dart';
   │
   └─ 父父文件夹？
      └─ ✅ import '../../providers/providers.dart';
```

---

## 三、常见错误与修正

### ❌ 错误示例

```dart
// ❌ 深层相对路径 (3层+)
import '../../../shared/models/models.dart';
import '../../../../core/i18n/i18n.dart';

// ❌ 跨模块相对导入
import '../../../utils/id_generator.dart';
import '../../../l10n/app_localizations.dart';

// ❌ 导入顺序混乱
import '../widgets/button.dart';           // 相对导入在前
import 'package:flutter/material.dart';    // package 导入在后
import 'dart:async';                       // dart SDK 在最后
```

### ✅ 正确示例

```dart
// ✅ 使用 package 路径
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/utils/id_generator.dart';
import 'package:bkdmm/l10n/app_localizations.dart';

// ✅ 导入顺序正确
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bkdmm/shared/models/models.dart';
import '../widgets/button.dart';
```

---

## 四、Barrel Files 清单

| 模块 | 路径 | 用途 |
|------|------|------|
| Models | `package:bkdmm/shared/models/models.dart` | 数据模型 |
| Providers | `package:bkdmm/shared/providers/providers.dart` | 状态管理 |
| Services | `package:bkdmm/shared/services/services.dart` | 服务层 |
| Widgets | `package:bkdmm/shared/widgets/widgets.dart` | 通用组件 |
| Utils | `package:bkdmm/utils/utils.dart` | 工具类 |
| I18n | `package:bkdmm/core/i18n/i18n.dart` | 国际化 |
| L10n | `package:bkdmm/l10n/app_localizations.dart` | 翻译文件 |

---

## 五、重构检查清单

### 单文件检查
- [ ] 无 3层+ 相对路径 (`../../../`)
- [ ] 无跨模块相对导入
- [ ] 导入按顺序分组
- [ ] 各组之间空一行
- [ ] 无重复导入
- [ ] 无未使用的导入

### 全局检查
```bash
# 检查深层相对路径
find lib -name "*.dart" -exec grep -l "\.\./\.\./\.\./" {} \;

# 检查跨模块导入
grep -r "features.*import.*\.\./.*shared" lib/

# 运行静态分析
flutter analyze

# 运行测试
flutter test
```

---

## 六、快速命令

```bash
# 分析当前导入状态
python scripts/refactor_imports.py --analyze

# 预览变更 (不修改文件)
python scripts/refactor_imports.py --dry-run

# 执行重构
python scripts/refactor_imports.py --execute

# 验证结果
python scripts/refactor_imports.py --verify
```

---

## 七、特殊情况处理

### 情况1: 导入冲突

```dart
// ❌ 两个文件有同名类
import '../models/user.dart';
import '../services/user.dart';  // 冲突！

// ✅ 使用 show/hide 关键字
import '../models/user.dart';
import '../services/user.dart' hide User;

// ✅ 或使用 as 关键字
import '../models/user.dart';
import '../services/user.dart' as services;
```

### 情况2: 条件导入

```dart
// ✅ 条件导入保持相对路径
import 'file.dart'
    if (dart.library.io) 'file_io.dart'
    if (dart.library.html) 'file_html.dart';
```

### 情况3: part 文件

```dart
// ✅ part 文件保持相对路径
part 'user.g.dart';
```

---

**更新日期**: 2026-06-30