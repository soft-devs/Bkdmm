import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
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

    return AppScaffold(
      title: 'Settings',
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
              tabs: const [
                Tab(text: 'Global Settings'),
                Tab(text: 'Project Settings'),
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
