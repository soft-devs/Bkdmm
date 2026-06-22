# 开发环境配置

> **阅读时机**: 项目初始化、配置开发工具时

---

## Flutter 安装

### Windows

```powershell
# 下载 Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# 解压到 C:\flutter
# 添加到 PATH: C:\flutter\bin

# 验证安装
flutter doctor
```

### macOS

```bash
# 使用 Homebrew
brew install flutter

# 或手动下载
# https://docs.flutter.dev/get-started/install/macos

# 验证安装
flutter doctor
```

### Linux

```bash
# 使用 Snap
sudo snap install flutter --classic

# 或手动下载
# https://docs.flutter.dev/get-started/install/linux

# 验证安装
flutter doctor
```

---

## 项目初始化

```bash
# 创建项目
flutter create bkdmm --platforms=windows,macos,linux

# 进入项目目录
cd bkdmm

# 检查环境
flutter doctor
```

---

## 必要依赖

### pubspec.yaml

```yaml
name: bkdmm
description: 数据库模型建模工具

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  
  # 本地存储
  hive_flutter: ^1.1.0
  
  # 文件选择
  file_picker: ^6.1.0
  
  # 路径处理
  path_provider: ^2.1.0
  path: ^1.8.0
  
  # 表格组件
  syncfusion_flutter_datagrid: ^24.1.0
  
  # 模板引擎
  mustache_template: ^2.0.0
  
  # UUID生成
  uuid: ^4.4.0
  
  # JSON序列化
  json_annotation: ^4.8.0
  
  # 其他
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # JSON序列化代码生成
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  hive_generator: ^2.0.0

flutter:
  uses-material-design: true
```

### 安装依赖

```bash
flutter pub get
```

---

## 项目结构

```bash
# 创建目录结构
mkdir -p lib/app lib/features/project lib/features/modeling/entity_editor lib/features/modeling/er_diagram lib/features/codegen lib/features/datatype lib/shared/widgets lib/shared/models lib/shared/services lib/shared/providers lib/platform lib/templates/ddl
```

---

## 开发工具配置

### VS Code

```json
// .vscode/settings.json
{
  "dart.lineLength": 120,
  "dart.previewFlutterUiGuides": true,
  "[dart]": {
    "editor.rulers": [120],
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggestSelection": "first",
    "editor.defaultFormatter": "Dart-Code.flutter-tools"
  }
}
```

```json
// .vscode/extensions.json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "nash.awesome-flutter-snippets"
  ]
}
```

### 分析选项

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
    - prefer_single_quotes
```

---

## 运行与调试

### 开发模式

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 热重载

- 按 `r` 热重载
- 按 `R` 热重启
- 按 `q` 退出

### 调试

- VS Code: F5 启动调试
- 设置断点调试

---

## 构建发布

### 构建命令

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 输出目录

```
build/
├── windows/
│   └── runner/Release/
│       └── bkdmm.exe
├── macos/
│   └── Build/Products/Release/
│       └── bkdmm.app
└── linux/
    └── release/
    └── bundle/
```

---

## 常见问题

### Flutter Doctor 问题

```bash
# Android Studio 未安装
# 解决: 安装 Android Studio 或跳过 (桌面应用不需要)

# Visual Studio 未安装 (Windows)
# 解决: 安装 Visual Studio with C++ development tools

# CocoaPods 未安装 (macOS)
# 解决: sudo gem install cocoapods
```

### 依赖问题

```bash
# 清理依赖
flutter clean
flutter pub get

# 更新依赖
flutter pub upgrade
```

---

## 相关文档

- [技术选型分析](../tech-selection/README.md)
- [项目管理功能](../features/project/README.md)