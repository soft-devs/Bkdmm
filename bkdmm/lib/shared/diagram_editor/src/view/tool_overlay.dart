/// 工具层覆盖组件
///
/// 提供图表编辑器的工具层 UI 组件：
/// - 缩放控制（放大/缩小/适应屏幕）
/// - 位置信息显示（鼠标坐标/缩放比例）
/// - 交互模式切换（预览/编辑模式）
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 工具层覆盖组件
///
/// 叠加在图表画布上方，提供常用的工具控制。
/// 使用 [Positioned] 定位在画布的角落位置。
class ToolOverlay extends StatelessWidget {
  /// 缩放控制回调
  final VoidCallback? onZoomIn;

  /// 缩小回调
  final VoidCallback? onZoomOut;

  /// 适应屏幕回调
  final VoidCallback? onFitToScreen;

  /// 当前缩放比例（0.1 - 5.0）
  final double zoom;

  /// 鼠标位置（屏幕坐标）
  final Offset? mousePosition;

  /// 是否显示坐标信息
  final bool showCoordinates;

  /// 是否显示缩放控制
  final bool showZoomControls;

  /// 是否显示缩放比例
  final bool showZoomLevel;

  /// 是否为暗色模式
  final bool isDark;

  /// 交互模式切换回调
  final VoidCallback? onToggleMode;

  /// 进入预览模式回调
  final VoidCallback? onEnterPreviewMode;

  /// 进入编辑模式回调
  final VoidCallback? onEnterEditMode;

  /// 当前交互模式
  final ToolOverlayInteractionMode interactionMode;

  /// 是否显示模式切换按钮
  final bool showModeToggle;

  /// 自动布局回调
  final VoidCallback? onAutoLayout;

  /// 是否显示布局按钮
  final bool showLayoutButton;

  const ToolOverlay({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    this.onFitToScreen,
    this.zoom = 1.0,
    this.mousePosition,
    this.showCoordinates = true,
    this.showZoomControls = true,
    this.showZoomLevel = true,
    this.isDark = false,
    this.onToggleMode,
    this.onEnterPreviewMode,
    this.onEnterEditMode,
    this.interactionMode = ToolOverlayInteractionMode.edit,
    this.showModeToggle = true,
    this.onAutoLayout,
    this.showLayoutButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 右上角：工具栏
        if (showModeToggle || showZoomControls || showLayoutButton)
          Positioned(
            top: 16,
            right: 16,
            child: _buildToolbar(),
          ),

        // 左下角：坐标显示
        if (showCoordinates)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildCoordinateDisplay(),
          ),

        // 右下角：缩放比例
        if (showZoomLevel)
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildZoomLevelDisplay(),
          ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 模式切换按钮
          if (showModeToggle) ...[
            _buildModeButton(
              icon: Icons.pan_tool,
              isActive: interactionMode == ToolOverlayInteractionMode.preview,
              onTap: onEnterPreviewMode,
              tooltip: '预览模式',
            ),
            const SizedBox(width: 4),
            _buildModeButton(
              icon: TDIcons.edit,
              isActive: interactionMode == ToolOverlayInteractionMode.edit,
              onTap: onEnterEditMode,
              tooltip: '编辑模式',
            ),
            const SizedBox(width: 8),
            _buildDivider(),
            const SizedBox(width: 8),
          ],

          // 缩放控制按钮
          if (showZoomControls) ...[
            _buildToolButton(
              icon: TDIcons.zoom_in,
              onTap: onZoomIn,
              tooltip: '放大',
            ),
            const SizedBox(width: 4),
            _buildToolButton(
              icon: TDIcons.zoom_out,
              onTap: onZoomOut,
              tooltip: '缩小',
            ),
            const SizedBox(width: 4),
            _buildToolButton(
              icon: TDIcons.fullscreen,
              onTap: onFitToScreen,
              tooltip: '适应屏幕',
            ),
            const SizedBox(width: 8),
            _buildDivider(),
            const SizedBox(width: 8),
          ],

          // 布局按钮
          if (showLayoutButton)
            _buildToolButton(
              icon: TDIcons.view_module,
              onTap: onAutoLayout,
              tooltip: '自动布局',
            ),
        ],
      ),
    );
  }

  /// 构建模式按钮
  Widget _buildModeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: TDButton(
        theme: isActive ? TDButtonTheme.primary : TDButtonTheme.defaultTheme,
        icon: icon,
        onTap: onTap,
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: TDButton(
        icon: icon,
        onTap: onTap,
      ),
    );
  }

  /// 构建分隔线
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }

  /// 构建坐标显示
  Widget _buildCoordinateDisplay() {
    final pos = mousePosition ?? Offset.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        'X: ${pos.dx.toStringAsFixed(0)}  Y: ${pos.dy.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }

  /// 构建缩放比例显示
  Widget _buildZoomLevelDisplay() {
    final zoomPercent = (zoom * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        '$zoomPercent%',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

/// 交互模式枚举
enum ToolOverlayInteractionMode {
  /// 预览模式 - 仅查看，pan/zoom
  preview,

  /// 编辑模式 - 可拖拽节点、创建连线
  edit,
}

/// 缩放控制组件
///
/// 独立的缩放控制组件，可单独使用。
class ZoomControls extends StatelessWidget {
  /// 放大回调
  final VoidCallback? onZoomIn;

  /// 缩小回调
  final VoidCallback? onZoomOut;

  /// 适应屏幕回调
  final VoidCallback? onFitToScreen;

  /// 当前缩放比例
  final double zoom;

  /// 是否显示缩放比例
  final bool showZoomLevel;

  /// 是否为暗色模式
  final bool isDark;

  /// 是否为垂直布局
  final bool vertical;

  const ZoomControls({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    this.onFitToScreen,
    this.zoom = 1.0,
    this.showZoomLevel = true,
    this.isDark = false,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildButton(TDIcons.zoom_in, onZoomIn, '放大'),
      const SizedBox(width: 4, height: 4),
      _buildButton(TDIcons.zoom_out, onZoomOut, '缩小'),
      const SizedBox(width: 4, height: 4),
      _buildButton(TDIcons.fullscreen, onFitToScreen, '适应屏幕'),
    ];

    if (showZoomLevel) {
      children.addAll([
        const SizedBox(width: 4, height: 4),
        _buildZoomLabel(),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback? onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: TDButton(
        icon: icon,
        size: TDButtonSize.small,
        onTap: onTap,
      ),
    );
  }

  Widget _buildZoomLabel() {
    final zoomPercent = (zoom * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '$zoomPercent%',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

/// 位置信息组件
///
/// 显示鼠标位置或指定位置信息。
class PositionInfo extends StatelessWidget {
  /// 显示的位置
  final Offset position;

  /// 是否显示场景坐标（画布坐标）
  final bool showScenePosition;

  /// 场景坐标（画布坐标）
  final Offset? scenePosition;

  /// 是否为暗色模式
  final bool isDark;

  /// 标签前缀
  final String label;

  const PositionInfo({
    super.key,
    required this.position,
    this.showScenePosition = false,
    this.scenePosition,
    this.isDark = false,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (label.isNotEmpty) {
      parts.add('$label:');
    }

    parts.add('X: ${position.dx.toStringAsFixed(0)}');
    parts.add('Y: ${position.dy.toStringAsFixed(0)}');

    if (showScenePosition && scenePosition != null) {
      parts.add('|');
      parts.add('场景: (${scenePosition!.dx.toStringAsFixed(0)}, ${scenePosition!.dy.toStringAsFixed(0)})');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        parts.join('  '),
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

/// 模式切换组件
///
/// 提供交互模式切换按钮组。
class ModeToggle extends StatelessWidget {
  /// 当前模式
  final ToolOverlayInteractionMode mode;

  /// 进入预览模式回调
  final VoidCallback? onEnterPreviewMode;

  /// 进入编辑模式回调
  final VoidCallback? onEnterEditMode;

  /// 是否为暗色模式
  final bool isDark;

  const ModeToggle({
    super.key,
    required this.mode,
    this.onEnterPreviewMode,
    this.onEnterEditMode,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '预览模式',
            child: TDButton(
              theme: mode == ToolOverlayInteractionMode.preview
                  ? TDButtonTheme.primary
                  : TDButtonTheme.defaultTheme,
              icon: Icons.pan_tool,
              size: TDButtonSize.small,
              onTap: onEnterPreviewMode,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: '编辑模式',
            child: TDButton(
              theme: mode == ToolOverlayInteractionMode.edit
                  ? TDButtonTheme.primary
                  : TDButtonTheme.defaultTheme,
              icon: TDIcons.edit,
              size: TDButtonSize.small,
              onTap: onEnterEditMode,
            ),
          ),
        ],
      ),
    );
  }
}
