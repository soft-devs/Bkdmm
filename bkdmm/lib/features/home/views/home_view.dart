import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Home view displaying project history and quick actions.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final historyList = ref.watch(historyListProvider);
    final projectState = ref.watch(projectProvider);

    return AppScaffold(
      title: 'Bkdmm',
      isLoading: _isLoading || projectState.isLoading,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: _buildBody(context, historyList),
    );
  }

  Widget _buildBody(BuildContext context, List<ProjectHistory> historyList) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        // Welcome section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storage,
                      size: 40,
                      color: Colors.white,
                    ),
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
            ),
          ),
        ),

        // Quick actions section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QuickActionCard(
                        icon: Icons.add,
                        label: 'New Project',
                        onTap: () => _createProject(context),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionCard(
                        icon: Icons.folder_open_outlined,
                        label: 'Open Project',
                        onTap: () => _openProject(context),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionCard(
                        icon: Icons.download_outlined,
                        label: 'Import',
                        onTap: () {
                          // TODO: Import project
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),

        // Project history section
        if (historyList.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Projects',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (historyList.length > 5)
                    TextButton.icon(
                      onPressed: () => _showAllHistory(context),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('View All'),
                    ),
                ],
              ),
            ),
          ),

          // Project history list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= (historyList.length > 5 ? 5 : historyList.length)) {
                    return null;
                  }
                  final history = historyList[index];
                  return _buildHistoryItem(context, history);
                },
                childCount: historyList.length > 5 ? 5 : historyList.length,
              ),
            ),
          ),
        ],

        // Empty state
        if (historyList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
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
                ],
              ),
            ),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, ProjectHistory history) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description_outlined,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          history.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              history.path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatDateTime(history.lastOpenedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'open':
                _openFromHistory(context, history);
                break;
              case 'delete':
                _deleteHistory(history.path);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('Open'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Remove from List'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _openFromHistory(context, history),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Future<void> _createProject(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(projectProvider.notifier).createProject(
            name: 'New Project',
            filePath: 'project.bkdmm.json',
          );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openProject(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(projectProvider.notifier).openProject(null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openFromHistory(BuildContext context, ProjectHistory history) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(projectProvider.notifier).openProject(history.path);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHistory(String path) async {
    await ref.read(historyNotifierProvider.notifier).remove(path);
  }

  void _showAllHistory(BuildContext context) {
    // TODO: Show all history in a dialog or navigate to history view
  }
}

/// Quick action card widget.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}