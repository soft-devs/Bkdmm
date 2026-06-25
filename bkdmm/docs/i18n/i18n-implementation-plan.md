---
name: i18n-implementation-plan
description: Bkdmm Flutter 国际化(i18n)实施方案
metadata:
  type: reference
---

# Bkdmm 国际化(i18n)实施方案

## 概述

本文档描述 Bkdmm Flutter 项目的国际化实施方案，支持中文和英文两种语言，并与 TDesign Flutter 组件库的国际化能力无缝集成。

## 1. 架构设计

### 1.1 技术选型

| 方案 | 优点 | 缺点 | 推荐 |
|------|------|------|------|
| Flutter 官方 intl + ARB | 官方支持、IDE友好、类型安全 | 需要代码生成步骤 | ✅ 推荐 |
| easy_localization | API简洁、支持JSON/YAML | 额外依赖、非官方 | 可选 |
| 自定义 Map 方案 | 简单直接、无依赖 | 无类型安全、IDE支持差 | 不推荐 |

**结论**: 采用 Flutter 官方 `intl` 包 + ARB 文件方案，项目已依赖 `intl: ^0.19.0`。

### 1.2 目录结构

```
bkdmm/
├── lib/
│   ├── l10n/
│   │   ├── l10n.dart                    # 导出文件
│   │   └── app_localizations.dart       # 生成的本地化类
│   ├── core/
│   │   └── i18n/
│   │       ├── i18n.dart                # 导出文件
│   │       ├── app_localizations_ext.dart  # 扩展方法
│   │       ├── locale_provider.dart     # 语言状态管理
│   │       └── td_resource_delegate.dart   # TDesign 国际化代理
│   └── app/
│       └── app.dart                     # 集成 MaterialApp
├── l10n.yaml                            # l10n 配置文件
└── lib/l10n/
    ├── app_en.arb                       # 英文翻译
    └── app_zh.arb                       # 中文翻译
```

## 2. 实施步骤

### 2.1 创建 l10n.yaml 配置

在项目根目录创建 `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

> **注意**: 以中文为模板，因为项目主要用户群体使用中文。

### 2.2 创建 ARB 翻译文件

**lib/l10n/app_zh.arb** (中文模板):

```json
{
  "@@locale": "zh",
  "appName": "Bkdmm",
  "@appName": {
    "description": "应用名称"
  },
  "appTitle": "Bkdmm - 数据建模工具",
  "@appTitle": {
    "description": "应用标题"
  },

  "welcomeTo": "欢迎使用 Bkdmm",
  "@welcomeTo": {
    "description": "欢迎语"
  },
  "appDescription": "数据库模型建模工具",
  "@appDescription": {
    "description": "应用描述"
  },

  "quickActions": "快速操作",
  "@quickActions": {
    "description": "快速操作区域标题"
  },
  "newProject": "新建项目",
  "@newProject": {
    "description": "新建项目按钮"
  },
  "createNewProject": "创建新项目",
  "@createNewProject": {
    "description": "创建新项目完整文本"
  },
  "openProject": "打开项目",
  "@openProject": {
    "description": "打开项目按钮"
  },
  "openExistingProject": "打开已有项目",
  "@openExistingProject": {
    "description": "打开已有项目描述"
  },
  "import": "导入",
  "@import": {
    "description": "导入按钮"
  },
  "importFromFile": "从文件导入",
  "@importFromFile": {
    "description": "从文件导入描述"
  },

  "recentProjects": "最近项目",
  "@recentProjects": {
    "description": "最近项目标题"
  },
  "viewAll": "查看全部",
  "@viewAll": {
    "description": "查看全部按钮"
  },
  "noRecentProjects": "暂无最近项目",
  "@noRecentProjects": {
    "description": "空状态提示"
  },
  "noRecentProjectsHint": "创建新项目或打开已有项目开始使用",
  "@noRecentProjectsHint": {
    "description": "空状态提示详情"
  },

  "cancel": "取消",
  "@cancel": {
    "description": "取消按钮"
  },
  "confirm": "确认",
  "@confirm": {
    "description": "确认按钮"
  },
  "delete": "删除",
  "@delete": {
    "description": "删除按钮"
  },
  "edit": "编辑",
  "@edit": {
    "description": "编辑按钮"
  },
  "save": "保存",
  "@save": {
    "description": "保存按钮"
  },
  "close": "关闭",
  "@close": {
    "description": "关闭按钮"
  },
  "loading": "加载中...",
  "@loading": {
    "description": "加载状态"
  },
  "noData": "暂无数据",
  "@noData": {
    "description": "空数据状态"
  },
  "select": "请选择",
  "@select": {
    "description": "选择提示"
  },

  "settings": "设置",
  "@settings": {
    "description": "设置"
  },
  "language": "语言",
  "@language": {
    "description": "语言设置"
  },
  "theme": "主题",
  "@theme": {
    "description": "主题设置"
  },
  "lightMode": "浅色模式",
  "@lightMode": {
    "description": "浅色模式"
  },
  "darkMode": "深色模式",
  "@darkMode": {
    "description": "深色模式"
  },
  "systemDefault": "跟随系统",
  "@systemDefault": {
    "description": "跟随系统"
  },

  "projectName": "项目名称",
  "@projectName": {
    "description": "项目名称"
  },
  "projectDescription": "项目描述",
  "@projectDescription": {
    "description": "项目描述"
  },
  "projectPath": "项目路径",
  "@projectPath": {
    "description": "项目路径"
  },
  "browse": "浏览",
  "@browse": {
    "description": "浏览按钮"
  },

  "entity": "实体",
  "@entity": {
    "description": "实体"
  },
  "entities": "实体",
  "@entities": {
    "description": "实体(复数)"
  },
  "field": "字段",
  "@field": {
    "description": "字段"
  },
  "fields": "字段",
  "@fields": {
    "description": "字段(复数)"
  },
  "index": "索引",
  "@index": {
    "description": "索引"
  },
  "relation": "关系",
  "@relation": {
    "description": "关系"
  },
  "dataType": "数据类型",
  "@dataType": {
    "description": "数据类型"
  },

  "ddlGeneration": "DDL 生成",
  "@ddlGeneration": {
    "description": "DDL生成"
  },
  "selectDatabase": "选择数据库",
  "@selectDatabase": {
    "description": "选择数据库"
  },
  "selectDdlType": "选择 DDL 类型",
  "@selectDdlType": {
    "description": "选择DDL类型"
  },
  "generateDdl": "生成 DDL",
  "@generateDdl": {
    "description": "生成DDL按钮"
  },
  "ddlGenerated": "DDL 已生成",
  "@ddlGenerated": {
    "description": "DDL生成成功"
  },

  "success": "成功",
  "@success": {
    "description": "成功"
  },
  "error": "错误",
  "@error": {
    "description": "错误"
  },
  "warning": "警告",
  "@warning": {
    "description": "警告"
  },
  "info": "信息",
  "@info": {
    "description": "信息"
  },

  "featureComingSoon": "功能即将推出",
  "@featureComingSoon": {
    "description": "功能即将推出提示"
  },
  "projectCreated": "项目已创建",
  "@projectCreated": {
    "description": "项目创建成功"
  },
  "projectOpened": "项目已打开",
  "@projectOpened": {
    "description": "项目打开成功"
  },
  "failedToCreateProject": "创建项目失败",
  "@failedToCreateProject": {
    "description": "创建项目失败"
  },
  "failedToOpenProject": "打开项目失败",
  "@failedToOpenProject": {
    "description": "打开项目失败"
  },
  "removedFromRecent": "已从最近项目中移除",
  "@removedFromRecent": {
    "description": "移除成功"
  },

  "deleteConfirmTitle": "确认删除",
  "@deleteConfirmTitle": {
    "description": "删除确认标题"
  },
  "deleteConfirmMessage": "确定要删除 \"{name}\" 吗？此操作不可撤销。",
  "@deleteConfirmMessage": {
    "description": "删除确认消息",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "项目名称"
      }
    }
  },
  "restoreDefaults": "恢复默认",
  "@restoreDefaults": {
    "description": "恢复默认按钮"
  },
  "restoreDefaultsConfirm": "确定要恢复默认设置吗？",
  "@restoreDefaultsConfirm": {
    "description": "恢复默认确认"
  },

  "allRecentProjects": "所有最近项目",
  "@allRecentProjects": {
    "description": "所有最近项目对话框标题"
  }
}
```

**lib/l10n/app_en.arb** (英文翻译):

```json
{
  "@@locale": "en",
  "appName": "Bkdmm",
  "appTitle": "Bkdmm - Data Modeling Tool",

  "welcomeTo": "Welcome to Bkdmm",
  "appDescription": "Database model modeling tool",

  "quickActions": "Quick Actions",
  "newProject": "New Project",
  "createNewProject": "Create New Project",
  "openProject": "Open Project",
  "openExistingProject": "Open an existing project",
  "import": "Import",
  "importFromFile": "Import from file",

  "recentProjects": "Recent Projects",
  "viewAll": "View All",
  "noRecentProjects": "No recent projects",
  "noRecentProjectsHint": "Create a new project or open an existing one to get started",

  "cancel": "Cancel",
  "confirm": "Confirm",
  "delete": "Delete",
  "edit": "Edit",
  "save": "Save",
  "close": "Close",
  "loading": "Loading...",
  "noData": "No Data",
  "select": "Select",

  "settings": "Settings",
  "language": "Language",
  "theme": "Theme",
  "lightMode": "Light Mode",
  "darkMode": "Dark Mode",
  "systemDefault": "System Default",

  "projectName": "Project Name",
  "projectDescription": "Project Description",
  "projectPath": "Project Path",
  "browse": "Browse",

  "entity": "Entity",
  "entities": "Entities",
  "field": "Field",
  "fields": "Fields",
  "index": "Index",
  "relation": "Relation",
  "dataType": "Data Type",

  "ddlGeneration": "DDL Generation",
  "selectDatabase": "Select Database",
  "selectDdlType": "Select DDL Type",
  "generateDdl": "Generate DDL",
  "ddlGenerated": "DDL Generated",

  "success": "Success",
  "error": "Error",
  "warning": "Warning",
  "info": "Info",

  "featureComingSoon": "Feature coming soon",
  "projectCreated": "Project created",
  "projectOpened": "Project opened",
  "failedToCreateProject": "Failed to create project",
  "failedToOpenProject": "Failed to open project",
  "removedFromRecent": "Removed from recent projects",

  "deleteConfirmTitle": "Confirm Delete",
  "deleteConfirmMessage": "Are you sure you want to delete \"{name}\"? This action cannot be undone.",
  "restoreDefaults": "Restore Defaults",
  "restoreDefaultsConfirm": "Are you sure you want to restore default settings?",

  "allRecentProjects": "All Recent Projects"
}
```

### 2.3 生成本地化代码

运行 Flutter 命令生成代码:

```bash
flutter gen-l10n
```

或添加到 `pubspec.yaml`:

```yaml
flutter:
  generate: true
```

### 2.4 创建语言状态管理

**lib/core/i18n/locale_provider.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 支持的语言列表
const List<Locale> supportedLocales = [
  Locale('zh', 'CN'),
  Locale('en', 'US'),
];

/// 语言代码映射
const Map<Locale, String> localeNames = {
  Locale('zh', 'CN'): '简体中文',
  Locale('en', 'US'): 'English',
};

/// 语言状态
class LocaleState {
  final Locale locale;

  const LocaleState(this.locale);

  /// 是否为中文
  bool get isChinese => locale.languageCode == 'zh';

  /// 获取语言显示名称
  String get displayName => localeNames[locale] ?? 'Unknown';
}

/// 语言 Notifier
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _key = 'locale_language_code';
  static const String _countryKey = 'locale_country_code';

  LocaleNotifier() : super(const LocaleState(Locale('zh', 'CN'))) {
    _loadFromStorage();
  }

  /// 从存储加载语言设置
  Future<void> _loadFromStorage() async {
    final box = Hive.box('settings');
    final languageCode = box.get(_key) as String?;
    final countryCode = box.get(_countryKey) as String?;

    if (languageCode != null) {
      final locale = Locale(languageCode, countryCode);
      if (supportedLocales.contains(locale)) {
        state = LocaleState(locale);
      }
    }
  }

  /// 切换语言
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;

    final box = Hive.box('settings');
    await box.put(_key, locale.languageCode);
    await box.put(_countryKey, locale.countryCode);

    state = LocaleState(locale);
  }

  /// 切换到下一个语言
  Future<void> toggleLanguage() async {
    final currentIndex = supportedLocales.indexOf(state.locale);
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    await setLocale(supportedLocales[nextIndex]);
  }
}

/// 语言 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(),
);
```

### 2.5 创建 TDesign 资源代理

**lib/core/i18n/td_resource_delegate.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'app_localizations.dart';

/// TDesign 国际化资源代理
///
/// 将 TDesign 组件内部的文案与应用国际化系统集成
class AppTDResourceDelegate extends TDResourceDelegate {
  AppTDResourceDelegate(this.context);

  BuildContext context;

  /// 更新 context（国际化需要每次更新）
  void updateContext(BuildContext context) {
    this.context = context;
  }

  @override
  String get cancel => AppLocalizations.of(context)?.cancel ?? '取消';

  @override
  String get confirm => AppLocalizations.of(context)?.confirm ?? '确认';

  @override
  String get select => AppLocalizations.of(context)?.select ?? '请选择';

  @override
  String get loading => AppLocalizations.of(context)?.loading ?? '加载中';

  @override
  String get noData => AppLocalizations.of(context)?.noData ?? '暂无数据';
}
```

### 2.6 创建扩展方法简化使用

**lib/core/i18n/app_localizations_ext.dart**:

```dart
import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// AppLocalizations 扩展方法
///
/// 提供简洁的访问方式
extension AppLocalizationsExt on BuildContext {
  /// 获取本地化实例
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// 获取本地化实例（可空）
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}
```

### 2.7 创建导出文件

**lib/core/i18n/i18n.dart**:

```dart
export 'app_localizations_ext.dart';
export 'locale_provider.dart';
export 'td_resource_delegate.dart';
```

### 2.8 修改 app.dart 集成国际化

**lib/app/app.dart** (关键修改):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../l10n/l10n.dart';
import '../core/i18n/i18n.dart';
import '../features/home/views/home_view.dart';
import '../shared/providers/providers.dart';
import 'app_theme.dart';

class BkdmmApp extends ConsumerWidget {
  const BkdmmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeModeEnum;
    final accentColor = settings.accentColorValue;
    final localeState = ref.watch(localeProvider);

    // ... 主题相关代码 ...

    // 创建 TDesign 资源代理
    final tdDelegate = AppTDResourceDelegate(context);

    return TDTheme(
      data: tdThemeData,
      child: MaterialApp(
        title: AppLocalizations.of(context)?.appTitle ?? 'Bkdmm',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,

        // 国际化配置
        locale: localeState.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,

        home: Builder(
          builder: (context) {
            // 设置 TDesign 文案代理
            TDTheme.setResourceBuilder(
              (context) => tdDelegate..updateContext(context),
              needAlwaysBuild: true,
            );
            return const HomeView();
          },
        ),
      ),
    );
  }
}
```

## 3. 使用示例

### 3.1 在 Widget 中使用

```dart
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../core/i18n/i18n.dart';

class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.appName,
      body: Column(
        children: [
          TDText(l10n.welcomeTo),
          TDButton(
            text: l10n.newProject,
            onTap: () => _createProject(context),
          ),
          TDButton(
            text: l10n.openProject,
            onTap: () => _openProject(context),
          ),
        ],
      ),
    );
  }
}
```

### 3.2 带参数的翻译

```dart
// ARB 定义
"deleteConfirmMessage": "确定要删除 \"{name}\" 吗？",

// 使用
final message = l10n.deleteConfirmMessage(entityName);
```

### 3.3 语言切换

```dart
import 'package:flutter/material.dart';
import '../../core/i18n/i18n.dart';

class LanguageSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final l10n = context.l10n;

    return TDDropdownMenu(
      items: supportedLocales.map((locale) => TDDropdownItem(
        label: localeNames[locale]!,
        value: locale.toString(),
        selected: locale == localeState.locale,
      )).toList(),
      onChanged: (value) {
        final locale = supportedLocales.firstWhere(
          (l) => l.toString() == value,
        );
        ref.read(localeProvider.notifier).setLocale(locale);
      },
    );
  }
}
```

## 4. 翻译清单

### 4.1 需要翻译的模块

| 模块 | 文件路径 | 翻译 Key 数量(估计) |
|------|----------|---------------------|
| 首页 | `features/home/` | ~20 |
| 项目管理 | `features/project/` | ~15 |
| 工作区 | `features/workspace/` | ~10 |
| 实体编辑器 | `features/modeling/entity_editor/` | ~30 |
| ER 图 | `features/modeling/er_diagram/` | ~15 |
| 数据类型 | `features/datatype/` | ~20 |
| 代码生成 | `features/codegen/` | ~20 |
| 设置 | `features/settings/` | ~15 |
| 公共组件 | `shared/widgets/` | ~10 |
| **总计** | | **~155** |

### 4.2 翻译 Key 命名规范

```dart
// 使用 camelCase，按功能模块分组
home.welcomeTitle       // 首页.欢迎标题
home.quickActions       // 首页.快速操作
project.createTitle     // 项目.创建标题
entity.fieldName        // 实体.字段名称
settings.themeMode      // 设置.主题模式

// 通用词汇不加前缀
cancel
confirm
delete
save
```

## 5. 测试计划

### 5.1 单元测试

```dart
test('AppLocalizations returns correct Chinese strings', () {
  // 测试中文翻译
});

test('AppLocalizations returns correct English strings', () {
  // 测试英文翻译
});

test('LocaleNotifier toggles language correctly', () {
  // 测试语言切换
});
```

### 5.2 集成测试

- [ ] 验证所有页面语言切换正常
- [ ] 验证 TDesign 组件国际化生效
- [ ] 验证语言设置持久化
- [ ] 验证应用重启后语言保持

## 6. 迁移步骤

### 阶段一：基础设施 (1-2小时)

1. [ ] 创建 `l10n.yaml` 配置
2. [ ] 创建 ARB 文件（先添加核心 key）
3. [ ] 运行 `flutter gen-l10n` 生成代码
4. [ ] 创建 i18n 核心模块
5. [ ] 修改 `app.dart` 集成

### 阶段二：核心功能 (2-3小时)

1. [ ] 迁移首页 `home_view.dart`
2. [ ] 迁移项目管理模块
3. [ ] 迁移设置页面（含语言切换）

### 阶段三：完整迁移 (3-4小时)

1. [ ] 迁移实体编辑器
2. [ ] 迁移数据类型模块
3. [ ] 迁移代码生成模块
4. [ ] 迁移公共组件

### 阶段四：测试验证 (1-2小时)

1. [ ] 编写单元测试
2. [ ] 手动测试所有页面
3. [ ] 验证语言切换流程

## 7. 最佳实践

### 7.1 开发规范

1. **禁止硬编码字符串**: 所有用户可见文本必须通过 `l10n` 获取
2. **使用扩展方法**: 优先使用 `context.l10n` 而非 `AppLocalizations.of(context)!`
3. **ARB 文件维护**: 添加新功能时同步更新 ARB 文件
4. **翻译完整性**: 确保 `app_en.arb` 和 `app_zh.arb` 的 key 一致

### 7.2 代码审查 Checklist

- [ ] 新增的用户可见文本是否添加到 ARB 文件
- [ ] 是否使用了 `context.l10n` 扩展
- [ ] TDesign 组件是否通过 `TDResourceDelegate` 国际化
- [ ] 语言切换是否正常工作

## 8. 参考资源

- [[tdesign-i18n]](../../docs/tdesign/i18n.md) - TDesign Flutter 国际化文档
- [Flutter 官方国际化文档](https://docs.flutter.cn/ui/accessibility-and-internationalization/internationalization)
- [Flutter intl 包文档](https://pub.dev/packages/intl)

---

**相关文档**: [[architecture-refactor-plan]]
