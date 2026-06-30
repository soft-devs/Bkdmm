import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/widgets/app_scaffold.dart';
import '../../project/views/create_project_dialog.dart';
import '../../project/views/open_project_dialog.dart';
import '../../settings/views/settings_view.dart';
import '../../workspace/views/workspace_view.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/quick_action_card.dart';

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

    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.appName,
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
    final l10n = context.l10n;

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
          l10n.welcomeTo,
          font: tdTheme.fontHeadlineMedium,
          fontWeight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TDText(
          l10n.appDescription,
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TDText(
          l10n.quickActions,
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
                    child: QuickActionCard(
                      icon: TDIcons.add,
                      label: l10n.newProject,
                      description: l10n.createNewProjectHint,
                      tdTheme: tdTheme,
                      onTap: _isCreating ? null : _showCreateProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionCard(
                      icon: TDIcons.folder_open,
                      label: l10n.openProject,
                      description: l10n.openExistingProject,
                      tdTheme: tdTheme,
                      onTap: _showOpenProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionCard(
                      icon: TDIcons.download,
                      label: l10n.import,
                      description: l10n.importFromFile,
                      tdTheme: tdTheme,
                      onTap: () {
                        TDToast.showText(l10n.featureComingSoon, context: context);
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
                QuickActionCard(
                  icon: TDIcons.add,
                  label: l10n.newProject,
                  description: l10n.createNewProjectHint,
                  tdTheme: tdTheme,
                  onTap: _isCreating ? null : _showCreateProjectDialog,
                ),
                QuickActionCard(
                  icon: TDIcons.folder_open,
                  label: l10n.openProject,
                  description: l10n.openExistingProject,
                  tdTheme: tdTheme,
                  onTap: _showOpenProjectDialog,
                ),
                QuickActionCard(
                  icon: TDIcons.download,
                  label: l10n.import,
                  description: l10n.importFromFile,
                  tdTheme: tdTheme,
                  onTap: () {
                    TDToast.showText(l10n.featureComingSoon, context: context);
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TDText(
              l10n.recentProjects,
              font: tdTheme.fontTitleMedium,
              fontWeight: FontWeight.w600,
            ),
            if (historyList.isNotEmpty)
              TDButton(
                text: l10n.viewAll,
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
    final l10n = context.l10n;

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
            l10n.noRecentProjects,
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            l10n.noRecentProjectsHint,
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TDButton(
            text: l10n.createNewProject,
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
    final l10n = context.l10n;
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
              TDToast.showText(l10n.featureComingSoon, context: context);
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
          TDToast.showText(context.l10n.failedToCreateProject, context: context);
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
        TDToast.showText(context.l10n.failedToOpenProject, context: context);
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
        TDToast.showSuccess(context.l10n.removedFromRecent, context: context);
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText(context.l10n.failedToRemove, context: context);
      }
    }
  }

  void _showAllHistory(List<ProjectHistory> historyList) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (dialogContext) => TDAlertDialog(
        title: l10n.allRecentProjects,
        contentWidget: SizedBox(
          width: 650, // 500 * 1.3
          height: 520, // 400 * 1.3
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
          title: l10n.close,
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.of(dialogContext).pop(),
        ),
        rightBtn: null,
      ),
    );
  }
}
