import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tab_provider.dart';

/// Custom tab bar widget with close buttons and overflow handling
class WorkspaceTabBar extends ConsumerStatefulWidget {
  final VoidCallback? onNewTab;
  final VoidCallback? onSettingsTab;
  final bool showScrollButtons;

  const WorkspaceTabBar({
    super.key,
    this.onNewTab,
    this.onSettingsTab,
    this.showScrollButtons = true,
  });

  @override
  ConsumerState<WorkspaceTabBar> createState() => _WorkspaceTabBarState();
}

class _WorkspaceTabBarState extends ConsumerState<WorkspaceTabBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftScroll = false;
  bool _showRightScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted) return;
    setState(() {
      _showLeftScroll = _scrollController.position.pixels > 0;
      _showRightScroll = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.position.pixels - 200,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.position.pixels + 200,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left scroll button
          if (widget.showScrollButtons && _showLeftScroll)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: _scrollLeft,
              tooltip: 'Scroll left',
              visualDensity: VisualDensity.compact,
            ),

          // Tab list
          Expanded(
            child: tabState.hasTabs
                ? ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: tabState.tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabState.tabs[index];
                      final isActive = tab.id == tabState.activeTabId;
                      return _TabItem(
                        tab: tab,
                        isActive: isActive,
                        onTap: () => ref
                            .read(tabProvider.notifier)
                            .setActiveTab(tab.id),
                        onClose: () =>
                            ref.read(tabProvider.notifier).closeTab(tab.id),
                        onCloseOthers: () =>
                            ref.read(tabProvider.notifier).closeOtherTabs(),
                        onCloseToRight: () =>
                            ref.read(tabProvider.notifier).closeTabsToRight(),
                        onCloseToLeft: () =>
                            ref.read(tabProvider.notifier).closeTabsToLeft(),
                      );
                    },
                  )
                : _buildEmptyState(theme, colorScheme),
          ),

          // Right scroll button
          if (widget.showScrollButtons && _showRightScroll)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: _scrollRight,
              tooltip: 'Scroll right',
              visualDensity: VisualDensity.compact,
            ),

          // Actions
          if (widget.onNewTab != null)
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: widget.onNewTab,
              tooltip: 'New tab',
              visualDensity: VisualDensity.compact,
            ),

          // Overflow menu
          if (tabState.hasTabs) _buildOverflowMenu(tabState, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Text(
        'No tabs open',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildOverflowMenu(
    TabState tabState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      tooltip: 'Tab options',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'close_all',
          child: const ListTile(
            leading: Icon(Icons.close),
            title: Text('Close All'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (tabState.activeTab != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'close_others',
            child: const ListTile(
              leading: Icon(Icons.tab),
              title: Text('Close Others'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'close_right',
            child: const ListTile(
              leading: Icon(Icons.keyboard_arrow_right),
              title: Text('Close to Right'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'close_left',
            child: const ListTile(
              leading: Icon(Icons.keyboard_arrow_left),
              title: Text('Close to Left'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
      onSelected: (value) {
        switch (value) {
          case 'close_all':
            ref.read(tabProvider.notifier).closeAllTabs();
            break;
          case 'close_others':
            ref.read(tabProvider.notifier).closeOtherTabs();
            break;
          case 'close_right':
            ref.read(tabProvider.notifier).closeTabsToRight();
            break;
          case 'close_left':
            ref.read(tabProvider.notifier).closeTabsToLeft();
            break;
        }
      },
    );
  }
}

/// Individual tab item
class _TabItem extends StatelessWidget {
  final WorkspaceTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onCloseOthers;
  final VoidCallback onCloseToRight;
  final VoidCallback onCloseToLeft;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onCloseOthers,
    required this.onCloseToRight,
    required this.onCloseToLeft,
  });

  IconData _getIconData() {
    switch (tab.icon) {
      case 'table_chart':
        return Icons.table_chart;
      case 'view_module':
        return Icons.view_module;
      case 'settings':
        return Icons.settings;
      case 'account_tree':
        return Icons.account_tree;
      default:
        return Icons.tab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      onSecondaryTapDown: (details) => _showContextMenu(context, details),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : null,
          border: Border(
            left: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            bottom: isActive
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              _getIconData(),
              size: 16,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            // Title
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : null,
                      color: isActive ? colorScheme.primary : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (tab.subtitle != null)
                    Text(
                      tab.subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Close button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = RelativeRect.fromRect(
      Rect.fromLTWH(
        details.globalPosition.dx,
        details.globalPosition.dy,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    ).leftTop;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'close',
          child: ListTile(
            leading: Icon(Icons.close),
            title: Text('Close'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'close_others',
          child: ListTile(
            leading: Icon(Icons.tab),
            title: Text('Close Others'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'close_right',
          child: ListTile(
            leading: Icon(Icons.keyboard_arrow_right),
            title: Text('Close to Right'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'close_left',
          child: ListTile(
            leading: Icon(Icons.keyboard_arrow_left),
            title: Text('Close to Left'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'close':
          onClose();
          break;
        case 'close_others':
          onCloseOthers();
          break;
        case 'close_right':
          onCloseToRight();
          break;
        case 'close_left':
          onCloseToLeft();
          break;
      }
    });
  }
}

/// Keyboard shortcuts for tab navigation
class TabShortcuts extends ConsumerWidget {
  final Widget child;

  const TabShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            const _CloseTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true):
            const _NextTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
            const _PreviousTabIntent(),
      },
      child: Actions(
        actions: {
          _CloseTabIntent: _CloseTabAction(ref),
          _NextTabIntent: _NextTabAction(ref),
          _PreviousTabIntent: _PreviousTabAction(ref),
        },
        child: child,
      ),
    );
  }
}

// Intent classes
class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

// Action classes
class _CloseTabAction extends Action<_CloseTabIntent> {
  final WidgetRef ref;

  _CloseTabAction(this.ref);

  @override
  Object? invoke(_CloseTabIntent intent) {
    final activeTabId = ref.read(tabProvider).activeTabId;
    if (activeTabId != null) {
      ref.read(tabProvider.notifier).closeTab(activeTabId);
    }
    return null;
  }
}

class _NextTabAction extends Action<_NextTabIntent> {
  final WidgetRef ref;

  _NextTabAction(this.ref);

  @override
  Object? invoke(_NextTabIntent intent) {
    ref.read(tabProvider.notifier).nextTab();
    return null;
  }
}

class _PreviousTabAction extends Action<_PreviousTabIntent> {
  final WidgetRef ref;

  _PreviousTabAction(this.ref);

  @override
  Object? invoke(_PreviousTabIntent intent) {
    ref.read(tabProvider.notifier).previousTab();
    return null;
  }
}
