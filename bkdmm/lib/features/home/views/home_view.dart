import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../project/views/create_project_dialog.dart';
import '../../project/views/open_project_dialog.dart';
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
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            // TODO: Navigate to settings
          },
          tooltip: 'Settings',
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            // TODO: Navigate to profile
          },
          tooltip: 'Profile',
        ),
      ],
      // Remove FAB - quick actions are available in the body
      body: _buildBody(context, historyList),
    );
  }

  Widget _buildBody(BuildContext context, List<ProjectHistory> historyList) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  _buildWelcomeSection(context, theme, colorScheme),
                  const SizedBox(height: 32),

                  // Quick actions section
                  _buildQuickActionsSection(context, theme, colorScheme),
                  const SizedBox(height: 32),

                  // Recent projects section
                  _buildRecentProjectsSection(context, historyList, theme, colorScheme),

                  // Bottom padding for FAB
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
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storage,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to Bkdmm',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Database model modeling tool',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
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
                      icon: Icons.add,
                      label: 'New Project',
                      description: 'Create a new project',
                      onTap: _isCreating ? null : _showCreateProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.folder_open_outlined,
                      label: 'Open Project',
                      description: 'Open an existing project',
                      onTap: _showOpenProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.download_outlined,
                      label: 'Import',
                      description: 'Import from file',
                      onTap: () {
                        // TODO: Import project
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Import feature coming soon'),
                          ),
                        );
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
                  icon: Icons.add,
                  label: 'New Project',
                  description: 'Create a new project',
                  onTap: _isCreating ? null : _showCreateProjectDialog,
                ),
                _QuickActionCard(
                  icon: Icons.folder_open_outlined,
                  label: 'Open Project',
                  description: 'Open an existing project',
                  onTap: _showOpenProjectDialog,
                ),
                _QuickActionCard(
                  icon: Icons.download_outlined,
                  label: 'Import',
                  description: 'Import from file',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import feature coming soon'),
                      ),
                    );
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
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Projects',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (historyList.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAllHistory(historyList),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        historyList.isEmpty
            ? _buildEmptyState(context, theme, colorScheme)
            : _buildHistoryList(context, historyList, theme, colorScheme),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent projects',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new project or open an existing one to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isCreating ? null : _showCreateProjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create New Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<ProjectHistory> historyList,
    ThemeData theme,
    ColorScheme colorScheme,
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
              // TODO: Implement favorite
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorite feature coming soon')),
              );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create project: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
        // Navigate to workspace
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WorkspaceView(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from recent projects')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAllHistory(List<ProjectHistory> historyList) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('All Recent Projects'),
        content: SizedBox(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Quick action card widget with proper InkWell and visual feedback.
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Material(
          color: _isHovered
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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