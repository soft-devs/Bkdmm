import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/l10n/app_localizations.dart';

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

  AppLocalizations? get _l10n => AppLocalizations.of(context);

  @override
  String get cancel => _l10n?.cancel ?? '取消';

  @override
  String get confirm => _l10n?.confirm ?? '确定';

  @override
  String get loading => _l10n?.loading ?? '加载中';

  @override
  String get emptyData => _l10n?.noData ?? '暂无数据';

  // TDSwitch
  @override
  String get open => '开';

  @override
  String get close => '关';

  // TDBadge
  @override
  String get badgeZero => '0';

  // TDDropdownMenu
  @override
  String get other => '其它';

  @override
  String get reset => '重置';

  // TDLoading
  @override
  String get loadingWithPoint => '加载中...';

  // TDConfirmDialog
  @override
  String get knew => '知道了';

  // TDRefreshHeader
  @override
  String get refreshing => '正在刷新';

  @override
  String get releaseRefresh => '松开刷新';

  @override
  String get pullToRefresh => '下拉刷新';

  @override
  String get completeRefresh => '刷新完成';

  // TDTimeCounter
  @override
  String get days => '天';

  @override
  String get hours => '时';

  @override
  String get minutes => '分';

  @override
  String get seconds => '秒';

  @override
  String get milliseconds => '毫秒';

  // TDDatePicker
  @override
  String get yearLabel => '年';

  @override
  String get monthLabel => '月';

  @override
  String get dateLabel => '日';

  @override
  String get weeksLabel => '周';

  // TDCalendarHeader
  @override
  String get sunday => '日';

  @override
  String get monday => '一';

  @override
  String get tuesday => '二';

  @override
  String get wednesday => '三';

  @override
  String get thursday => '四';

  @override
  String get friday => '五';

  @override
  String get saturday => '六';

  // TDCalendarBody
  @override
  String get year => ' 年';

  @override
  String get january => '1 月';

  @override
  String get february => '2 月';

  @override
  String get march => '3 月';

  @override
  String get april => '4 月';

  @override
  String get may => '5 月';

  @override
  String get june => '6 月';

  @override
  String get july => '7 月';

  @override
  String get august => '8 月';

  @override
  String get september => '9 月';

  @override
  String get october => '10 月';

  @override
  String get november => '11 月';

  @override
  String get december => '12 月';

  // TDCalendar
  @override
  String get time => '时间';

  @override
  String get start => '开始';

  @override
  String get end => '结束';

  // TDRate
  @override
  String get notRated => '未评分';

  @override
  String get cascadeLabel => '选择选项';

  // TDBackTop
  @override
  String get back => '返回';

  @override
  String get top => '顶部';
}