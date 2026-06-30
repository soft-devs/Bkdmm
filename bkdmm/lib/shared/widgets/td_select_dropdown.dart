import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 下拉选择选项
class TDDropdownOption {
  final String value;
  final String label;
  final bool selected;
  final bool disabled;

  const TDDropdownOption({
    required this.value,
    required this.label,
    this.selected = false,
    this.disabled = false,
  });
}

/// TDesign 风格的下拉选择组件
///
/// 点击触发按钮后，在按钮下方显示选项列表，宽度与触发按钮一致。
class TDSelectDropdown extends StatefulWidget {
  /// 当前选中的值
  final String selectedValue;

  /// 选项列表
  final List<TDDropdownOption> options;

  /// 选中值变化回调
  final void Function(String value) onChanged;

  /// 自定义触发按钮构建器
  final Widget Function(BuildContext context, String selectedLabel)? triggerBuilder;

  /// 触发按钮宽度（默认使用触发按钮的实际宽度）
  final double? width;

  /// 下拉菜单最大高度
  final double maxHeight;

  /// 是否显示选中图标
  final bool showCheckIcon;

  const TDSelectDropdown({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.triggerBuilder,
    this.width,
    this.maxHeight = 300,
    this.showCheckIcon = true,
  });

  @override
  State<TDSelectDropdown> createState() => _TDSelectDropdownState();
}

class _TDSelectDropdownState extends State<TDSelectDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
    setState(() {});
  }

  void _showDropdown() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // 计算下拉菜单位置
    final menuWidth = widget.width ?? size.width;
    final left = offset.dx;
    final top = offset.dy + size.height + 4;

    // 确保菜单在屏幕范围内
    final adjustedTop = top + widget.maxHeight > screenSize.height
        ? offset.dy - widget.maxHeight - 4  // 向上显示
        : top;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _DropdownOverlay(
        left: left,
        top: adjustedTop,
        width: menuWidth,
        maxHeight: widget.maxHeight,
        options: widget.options,
        selectedValue: widget.selectedValue,
        showCheckIcon: widget.showCheckIcon,
        onSelect: (value) {
          widget.onChanged(value);
          _removeOverlay();
          setState(() {});
        },
        onClose: () {
          _removeOverlay();
          setState(() {});
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = widget.options.firstWhere(
      (opt) => opt.value == widget.selectedValue,
      orElse: () => widget.options.first,
    );

    return GestureDetector(
      onTap: _toggleDropdown,
      child: widget.triggerBuilder != null
          ? widget.triggerBuilder!(context, selectedOption.label)
          : _buildDefaultTrigger(context, selectedOption.label),
    );
  }

  Widget _buildDefaultTrigger(BuildContext context, String selectedLabel) {
    final tdTheme = TDTheme.of(context);

    return Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(
          color: _isOpen ? tdTheme.brandNormalColor : tdTheme.componentBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TDText(
              selectedLabel,
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorPrimary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          RotationTransition(
            turns: _isOpen ? const AlwaysStoppedAnimation(0.5) : const AlwaysStoppedAnimation(0),
            child: Icon(
              TDIcons.chevron_down,
              size: 18,
              color: tdTheme.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 下拉菜单覆盖层
class _DropdownOverlay extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double maxHeight;
  final List<TDDropdownOption> options;
  final String selectedValue;
  final bool showCheckIcon;
  final void Function(String value) onSelect;
  final VoidCallback onClose;

  const _DropdownOverlay({
    required this.left,
    required this.top,
    required this.width,
    required this.maxHeight,
    required this.options,
    required this.selectedValue,
    required this.showCheckIcon,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 调整位置确保在屏幕内
    final adjustedLeft = left + width > screenSize.width
        ? screenSize.width - width - 8
        : left;

    return Stack(
      children: [
        // 点击遮罩关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 下拉菜单内容
        Positioned(
          left: adjustedLeft,
          top: top,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: tdTheme.bgColorContainer,
                borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                border: Border.all(color: tdTheme.componentBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: tdTheme.grayColor10.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selectedValue;

                    return InkWell(
                      onTap: option.disabled ? null : () => onSelect(option.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tdTheme.brandLightColor
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TDText(
                                option.label,
                                font: tdTheme.fontBodyMedium,
                                textColor: option.disabled
                                    ? tdTheme.textDisabledColor
                                    : isSelected
                                        ? tdTheme.brandColor7
                                        : tdTheme.textColorPrimary,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showCheckIcon && isSelected)
                              Icon(
                                TDIcons.check,
                                size: 16,
                                color: tdTheme.brandNormalColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 简便方法：在指定位置显示下拉选择菜单
void showTDDropdown({
  required BuildContext context,
  required Offset position,
  required double width,
  required List<TDDropdownOption> options,
  required String selectedValue,
  required void Function(String value) onChanged,
  double maxHeight = 300,
  bool showCheckIcon = true,
}) {
  final tdTheme = TDTheme.of(context);
  final screenSize = MediaQuery.of(context).size;

  // 调整位置确保在屏幕内
  final adjustedTop = position.dy + maxHeight > screenSize.height
      ? position.dy - maxHeight - 4
      : position.dy;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (dialogContext) => Stack(
      children: [
        // 点击遮罩关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(dialogContext),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 下拉菜单内容
        Positioned(
          left: position.dx,
          top: adjustedTop,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: tdTheme.bgColorContainer,
                borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                border: Border.all(color: tdTheme.componentBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: tdTheme.grayColor10.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selectedValue;

                    return InkWell(
                      onTap: option.disabled
                          ? null
                          : () {
                              Navigator.pop(dialogContext);
                              onChanged(option.value);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tdTheme.brandLightColor
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TDText(
                                option.label,
                                font: tdTheme.fontBodyMedium,
                                textColor: option.disabled
                                    ? tdTheme.textDisabledColor
                                    : isSelected
                                        ? tdTheme.brandColor7
                                        : tdTheme.textColorPrimary,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showCheckIcon && isSelected)
                              Icon(
                                TDIcons.check,
                                size: 16,
                                color: tdTheme.brandNormalColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}