import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/shared/widgets/app_scaffold.dart';
import 'global_settings_view.dart';
import 'project_settings_view.dart';

/// Settings view - Application settings configuration
///
/// Two tabs:
/// - Global Settings: Theme mode, accent color, font size, auto-save, etc.
/// - Project Settings: Default fields, default database (can inherit from global)
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final hasProject = ref.watch(hasProjectSettingsProvider);
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settings,
      leading: Icon(
        TDIcons.chevron_left,
        size: 24,
        color: tdTheme.textColorPrimary,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              border: Border(
                bottom: BorderSide(
                  color: tdTheme.componentStrokeColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: tdTheme.brandNormalColor,
              unselectedLabelColor: tdTheme.textColorSecondary,
              indicatorColor: tdTheme.brandNormalColor,
              tabs: [
                Tab(text: l10n.globalSettings),
                Tab(text: l10n.projectSettings),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GlobalSettingsView(),
                ProjectSettingsView(hasProject: hasProject),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
