import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/view_config.dart';

/// 图标栏按钮
class IconBarButton extends StatelessWidget {
  /// 视图配置
  final ViewConfig config;

  /// 是否激活
  final bool isActive;

  /// 点击回调
  final VoidCallback onTap;

  const IconBarButton({
    super.key,
    required this.config,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Tooltip(
      message: '${config.title} (${config.shortcut})',
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? tdTheme.brandLightColor : Colors.transparent,
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: tdTheme.brandNormalColor,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标
                Icon(
                  config.icon,
                  size: 22,
                  color: isActive
                      ? tdTheme.brandNormalColor
                      : tdTheme.textColorSecondary,
                ),
                const SizedBox(height: 2),
                // 快捷键徽章
                if (config.shortcut.contains('Alt+'))
                  Text(
                    config.shortcut.replaceAll('Alt+', ''),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? tdTheme.brandNormalColor
                          : tdTheme.textColorSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}