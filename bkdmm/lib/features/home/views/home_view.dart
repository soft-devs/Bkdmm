import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../project/views/create_project_dialog.dart';
import '../../project/views/open_project_dialog.dart';
import '../../settings/views/settings_view.dart';
import '../../workspace/views/workspace_view.dart';
import '../widgets/history_list_tile.dart';

/// Home view displaying project history and quick actions.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final historyList = ref.watch(historyNotifierProvider);
    final projectState = ref.watch(projectProvider);

    return AppScaffold(
      title: 'Bkdmm',
      isLoading: _isCreating || projectState.isLoading,
      actions: [
        TDButton(
          icon: TDIcons.setting,
          size: TDButtonSize.small,
          type: TDButtonType.text,
          theme: TDButtonTheme.defaultTheme,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsView(),
              ),
            );
          },
        ),
        TDButton(
          icon: TDIcons.user_circle,
          size: TDButtonSize.small,
          type: TDButtonType.text,
          theme: TDButtonTheme.defaultTheme,
          onTap: () {
            // TODO: Navigate to profile
          },
        ),
      ],
      body: _buildBody(context, historyList),
    );
  }

  Widget _buildBody(BuildContext context, List<ProjectHistory> historyList) {
    final tdTheme = TDTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive max width
        final maxWidth = constraints.maxWidth > 1200
            ? 1200.0
            : constraints.maxWidth > 800
                ? 900.0
                : constraints.maxWidth;

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(context, tdTheme),
                  const SizedBox(height: 32),

                  // Quick actions section
                  _buildQuickActionsSection(context, tdTheme),
                  const SizedBox(height: 32),

                  // Recent projects section
                  _buildRecentProjectsSection(context, historyList, tdTheme),

                  // Bottom padding
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    TDThemeData tdTheme,
  ) {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: tdTheme.brandNormalColor,
            borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
            boxShadow: [
              BoxShadow(
                color: tdTheme.brandNormalColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            TDIcons.data_base,
            size: 40,
            color: tdTheme.textColorAnti,
          ),
        ),
        const SizedBox(height: 24),
        TDText(
          'Welcome to Bkdmm',
          font: tdTheme.fontHeadlineMedium,
          fontWeight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TDText(
          'Database model modeling tool',
          font: tdTheme.fontBodyLarge,
          textColor: tdTheme.textColorSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    TDThemeData tdTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TDText(
          'Quick Actions',
          font: tdTheme.fontTitleMedium,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid for quick actions
            final isWide = constraints.maxWidth > 400;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: TDIcons.add,
                      label: 'New Project',
                      description: 'Create a new project',
                      tdTheme: tdTheme,
                      onTap: _isCreating ? null : _showCreateProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: TDIcons.folder_open,
                      label: 'Open Project',
                      description: 'Open an existing project',
                      tdTheme: tdTheme,
                      onTap: _showOpenProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: TDIcons.download,
                      label: 'Import',
                      description: 'Import from file',
                      tdTheme: tdTheme,
                      onTap: () {
                        TDToast.showText('Import feature coming soon', context: context);
                      },
                    ),
                  ),
                ],
              );
            }

            // Narrow layout - wrap actions
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: TDIcons.add,
                  label: 'New Project',
                  description: 'Create a new project',
                  tdTheme: tdTheme,
                  onTap: _isCreating ? null : _showCreateProjectDialog,
                ),
                _QuickActionCard(
                  icon: TDIcons.folder_open,
                  label: 'Open Project',
                  description: 'Open an existing project',
                  tdTheme: tdTheme,
                  onTap: _showOpenProjectDialog,
                ),
                _QuickActionCard(
                  icon: TDIcons.download,
                  label: 'Import',
                  description: 'Import from file',
                  tdTheme: tdTheme,
                  onTap: () {
                    TDToast.showText('Import feature coming soon', context: context);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentProjectsSection(
    BuildContext context,
    List<ProjectHistory> historyList,
    TDThemeData tdTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TDText(
              'Recent Projects',
              font: tdTheme.fontTitleMedium,
              fontWeight: FontWeight.w600,
            ),
            if (historyList.isNotEmpty)
              TDButton(
                text: 'View All',
                icon: TDIcons.history,
                theme: TDButtonTheme.defaultTheme,
                type: TDButtonType.text,
                size: TDButtonSize.small,
                onTap: () => _showAllHistory(historyList),
              ),
          ],
        ),
        const SizedBox(height: 12),
        historyList.isEmpty
            ? _buildEmptyState(context, tdTheme)
            : _buildHistoryList(context, historyList),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    TDThemeData tdTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: tdTheme.bgColorComponent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
        border: Border.all(
          color: tdTheme.componentBorderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            TDIcons.folder_open,
            size: 64,
            color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          TDText(
            'No recent projects',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            'Create a new project or open an existing one to get started',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TDButton(
            text: 'Create New Project',
            icon: TDIcons.add,
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            disabled: _isCreating,
            onTap: _showCreateProjectDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<ProjectHistory> historyList,
  ) {
    // Show only first 5 items
    final displayList = historyList.take(5).toList();

    return Column(
      children: displayList.map((history) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HistoryListTile(
            history: history,
            onTap: () => _openFromHistory(history),
            onDelete: () => _deleteHistory(history.path),
            onFavorite: () {
              TDToast.showText('Favorite feature coming soon', context: context);
            },
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final result = await CreateProjectDialog.show(context);

    if (result != null && mounted) {
      setState(() => _isCreating = true);

      try {
        await ref.read(projectProvider.notifier).createProject(
              name: result.name,
              description: result.description,
              filePath: result.filePath,
            );

        // Refresh history
        ref.read(historyNotifierProvider.notifier).refresh();

        if (mounted) {
          // Navigate to workspace
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WorkspaceView(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          TDToast.showText('Failed to create project: $e', context: context);
        }
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }

  Future<void> _showOpenProjectDialog() async {
    final historyList = ref.read(historyNotifierProvider);
    final result = await OpenProjectDialog.show(
      context,
      recentProjects: historyList,
    );

    if (result != null && mounted) {
      await _openProjectAtPath(result);
    }
  }

  Future<void> _openProjectAtPath(String path) async {
    setState(() => _isCreating = true);

    try {
      await ref.read(projectProvider.notifier).openProject(path);

      // Refresh history
      ref.read(historyNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WorkspaceView(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('Failed to open project: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _openFromHistory(ProjectHistory history) async {
    await _openProjectAtPath(history.path);
  }

  Future<void> _deleteHistory(String path) async {
    try {
      await ref.read(historyNotifierProvider.notifier).remove(path);

      if (mounted) {
        TDToast.showSuccess('Removed from recent projects', context: context);
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('Failed to remove: $e', context: context);
      }
    }
  }

  void _showAllHistory(List<ProjectHistory> historyList) {
    showDialog(
      context: context,
      builder: (dialogContext) => TDAlertDialog(
        title: 'All Recent Projects',
        contentWidget: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return HistoryListTile(
                history: history,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _openFromHistory(history);
                },
                onDelete: () {
                  _deleteHistory(history.path);
                  Navigator.of(dialogContext).pop();
                  _showAllHistory(ref.read(historyNotifierProvider));
                },
              );
            },
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: 'Close',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.of(dialogContext).pop(),
        ),
        rightBtn: null,
      ),
    );
  }
}

/// Quick action card widget using TDTheme colors and TDText.
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.tdTheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final TDThemeData tdTheme;
  final VoidCallback? onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tdTheme = widget.tdTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        scale: _isHovered ? 1.02 : 1.0,
        child: Material(
          color: _isHovered
              ? tdTheme.bgColorContainerHover
              : tdTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tdTheme.brandLightColor,
                      borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: tdTheme.brandNormalColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TDText(
                    widget.label,
                    font: tdTheme.fontTitleSmall,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  TDText(
                    widget.description,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
