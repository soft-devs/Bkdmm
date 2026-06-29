import 'package:flutter/material.dart';
import '../../models/view_config.dart';
import 'icon_bar_button.dart';

/// 图标栏上部区域 - 控制左侧视图
class UpperSection extends StatelessWidget {
  /// 视图配置列表
  final List<ViewConfig> views;

  /// 当前激活的视图ID
  final String? activeViewId;

  /// 视图切换回调
  final ValueChanged<String> onViewToggle;

  const UpperSection({
    super.key,
    required this.views,
    required this.activeViewId,
    required this.onViewToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 按排序顺序排列
    final sortedViews = List<ViewConfig>.from(views)
      ..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      child: Column(
        children: sortedViews
            .map((view) => IconBarButton(
                  config: view,
                  isActive: activeViewId == view.id,
                  onTap: () => onViewToggle(view.id),
                ))
            .toList(),
      ),
    );
  }
}