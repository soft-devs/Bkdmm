import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/layout_provider.dart';

/// 工作区快捷键处理器
class WorkspaceShortcuts extends ConsumerWidget {
  final Widget child;

  const WorkspaceShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // 检查修饰键状态
        final rawKeys = RawKeyboard.instance.keysPressed;
        final isAltPressed = rawKeys.any((key) =>
            key == LogicalKeyboardKey.altLeft ||
            key == LogicalKeyboardKey.altRight);
        final isCtrlPressed = rawKeys.any((key) =>
            key == LogicalKeyboardKey.controlLeft ||
            key == LogicalKeyboardKey.controlRight);
        final isShiftPressed = rawKeys.any((key) =>
            key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight);

        // 处理 Alt+数字 快捷键
        if (isAltPressed) {
          final key = event.logicalKey;

          // Alt+1: 模块树
          if (key == LogicalKeyboardKey.digit1 ||
              key == LogicalKeyboardKey.numpad1) {
            ref.read(layoutProvider.notifier).toggleLeftView('module_tree');
            return KeyEventResult.handled;
          }

          // Alt+D: 数据类型
          if (key == LogicalKeyboardKey.keyD) {
            ref.read(layoutProvider.notifier).toggleLeftView('datatype');
            return KeyEventResult.handled;
          }

          // Alt+P: 属性面板
          if (key == LogicalKeyboardKey.keyP) {
            ref.read(layoutProvider.notifier).toggleRightView();
            return KeyEventResult.handled;
          }

          // Alt+C: 控制台
          if (key == LogicalKeyboardKey.keyC) {
            ref.read(layoutProvider.notifier).toggleBottomView('console');
            return KeyEventResult.handled;
          }

          // Alt+L: 日志
          if (key == LogicalKeyboardKey.keyL) {
            ref.read(layoutProvider.notifier).toggleBottomView('log');
            return KeyEventResult.handled;
          }

          // Alt+O: 输出
          if (key == LogicalKeyboardKey.keyO) {
            ref.read(layoutProvider.notifier).toggleBottomView('output');
            return KeyEventResult.handled;
          }
        }

        // Ctrl+Shift+F12: 隐藏所有视图
        if (isCtrlPressed &&
            isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.f12) {
          ref.read(layoutProvider.notifier).hideAllViews();
          return KeyEventResult.handled;
        }

        // Shift+Escape: 隐藏当前活动视图
        if (isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          final state = ref.read(layoutProvider);
          if (state.activeBottomView != null) {
            ref.read(layoutProvider.notifier).hideBottomView();
          } else if (state.activeLeftView != null) {
            ref.read(layoutProvider.notifier).hideLeftView();
          } else if (state.rightViewVisible) {
            ref.read(layoutProvider.notifier).hideRightView();
          }
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// 快捷键常量定义
class WorkspaceShortcutKeys {
  WorkspaceShortcutKeys._();

  // 视图切换快捷键
  static const String toggleModuleTree = 'Alt+1';
  static const String toggleDatatype = 'Alt+D';
  static const String toggleProperties = 'Alt+P';
  static const String toggleConsole = 'Alt+C';
  static const String toggleLog = 'Alt+L';
  static const String toggleOutput = 'Alt+O';

  // 布局快捷键
  static const String hideAllViews = 'Ctrl+Shift+F12';
  static const String hideCurrentView = 'Shift+Escape';

  // 文件操作快捷键
  static const String saveProject = 'Ctrl+S';
  static const String newProject = 'Ctrl+N';
  static const String openProject = 'Ctrl+O';
}

/// 快捷键帮助信息
class WorkspaceShortcutHelp {
  static const Map<String, String> viewShortcuts = {
    'Alt+1': '切换模块树',
    'Alt+D': '切换数据类型视图',
    'Alt+P': '切换属性面板',
    'Alt+C': '切换控制台',
    'Alt+L': '切换日志',
    'Alt+O': '切换输出',
  };

  static const Map<String, String> layoutShortcuts = {
    'Ctrl+Shift+F12': '隐藏所有视图',
    'Shift+Escape': '隐藏当前视图',
  };

  static const Map<String, String> fileShortcuts = {
    'Ctrl+S': '保存项目',
    'Ctrl+N': '新建项目',
    'Ctrl+O': '打开项目',
  };

  static String getHelpText() {
    final buffer = StringBuffer();

    buffer.writeln('=== 视图切换 ===');
    viewShortcuts.forEach((key, desc) {
      buffer.writeln('$key: $desc');
    });

    buffer.writeln('\n=== 布局操作 ===');
    layoutShortcuts.forEach((key, desc) {
      buffer.writeln('$key: $desc');
    });

    buffer.writeln('\n=== 文件操作 ===');
    fileShortcuts.forEach((key, desc) {
      buffer.writeln('$key: $desc');
    });

    return buffer.toString();
  }
}