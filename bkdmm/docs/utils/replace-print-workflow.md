# 替换 Print 为日志库输出工作流

## 概述

本文档定义了将项目中所有 `print()` 和 `debugPrint()` 调用替换为日志库输出的工作流。

## 执行步骤

### 1. 扫描项目中的 print 调用

```bash
# 查找所有 print 和 debugPrint 调用
flutter analyze lib/ | grep -E "print\(|debugPrint\(" || \
  grep -rn "print\(|debugPrint\(" lib/ --include="*.dart"
```

### 2. 分析每个调用点

对于每个 print 调用，确定：
- **日志级别**: debug / info / warning / error
- **标签**: 所在类或模块名
- **是否需要错误对象**: catch 块中的 print 通常需要传递 error

### 3. 日志级别映射规则

| 场景 | 原调用 | 替换为 |
|------|--------|--------|
| 调试信息 | `print('xxx')` | `logging.d('xxx', tag: 'ClassName')` |
| 状态变更 | `print('xxx updated')` | `logging.i('xxx updated', tag: 'ClassName')` |
| 错误信息 | `print('Error: $e')` | `logging.e('Error', error: e, tag: 'ClassName')` |
| 警告信息 | `print('Warning: xxx')` | `logging.w('xxx', tag: 'ClassName')` |

### 4. 替换模板

#### 简单 print 替换

```dart
// 替换前
print('Loading data...');

// 替换后
logging.d('Loading data...', tag: 'MyService');
```

#### catch 块中的 print 替换

```dart
// 替换前
try {
  // ...
} catch (e) {
  print('Error: $e');
}

// 替换后
try {
  // ...
} catch (e, stackTrace) {
  logging.e('操作失败', error: e, stackTrace: stackTrace, tag: 'MyService');
}
```

#### debugPrint 替换

```dart
// 替换前
debugPrint('Widget built: $widgetName');

// 替换后
logging.d('Widget built: $widgetName', tag: 'WidgetName');
```

### 5. 添加导入

在修改的文件顶部添加：

```dart
import 'package:bkdmm/utils/utils.dart';
```

### 6. 验证修改

```bash
# 1. 确认没有遗漏的 print
grep -rn "print\(|debugPrint\(" lib/ --include="*.dart"

# 2. 静态分析
flutter analyze lib/

# 3. 运行测试
flutter test
```

## 已完成的替换

| 文件 | 原调用 | 替换后 |
|------|--------|--------|
| `settings_provider.dart` | `debugPrint('Failed to save settings: $e')` | `logging.e('Failed to save settings', error: e, tag: 'SettingsProvider')` |
| `er_diagram_canvas.dart` | `debugPrint('构建 GraphView...')` | `logging.d('构建 GraphView...', tag: 'ERDiagramCanvas')` |
| `er_table_node_widget.dart` | `debugPrint('ERTableNodeWidget.build...')` | `logging.d('ERTableNodeWidget.build...', tag: 'ERTableNodeWidget')` |

## 自动化脚本 (可选)

创建脚本自动扫描并生成替换建议：

```bash
#!/bin/bash
# scripts/scan_prints.sh

echo "=== 扫描项目中的 print/debugPrint 调用 ==="
echo ""

grep -rn "print\(|debugPrint\(" lib/ --include="*.dart" | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  linenum=$(echo "$line" | cut -d: -f2)
  content=$(echo "$line" | cut -d: -f3-)

  # 提取可能的标签名 (文件名)
  tag=$(basename "$file" .dart | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')

  echo "文件: $file:$linenum"
  echo "原内容: $content"
  echo "建议标签: $tag"
  echo ""
done
```

## 注意事项

1. **不要替换测试文件中的 print**: 测试文件中的 print 是正常的测试输出
2. **保留必要的用户提示**: 如果 print 是用于向用户显示信息，考虑使用 Toast 或 Dialog
3. **性能敏感区域**: 高频调用的位置使用 debug 级别，生产环境会自动过滤

## 相关文档

- [日志服务文档](./logging-service.md)
- [设计文档](../design/logging-service-design.md)
