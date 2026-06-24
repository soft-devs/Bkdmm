import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/widgets/td_popup_menu.dart';
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
    final tdTheme = TDTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for tabs
        final availableWidth = constraints.maxWidth;
        final hasOverflow = tabState.tabs.length > 5; // Estimate if tabs might overflow

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: tdTheme.bgColorContainer,
            border: Border(
              bottom: BorderSide(
                color: tdTheme.componentStrokeColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Left scroll button
              if (widget.showScrollButtons && _showLeftScroll && hasOverflow)
                IconButton(
                  icon: const Icon(TDIcons.chevron_left, size: 20),
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
                            maxWidth: availableWidth / 3, // Max 1/3 of available width per tab
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
              if (widget.showScrollButtons && _showRightScroll && hasOverflow)
                IconButton(
                  icon: const Icon(TDIcons.chevron_right, size: 20),
                  onPressed: _scrollRight,
                  tooltip: 'Scroll right',
                  visualDensity: VisualDensity.compact,
                ),

              // Actions
              if (widget.onNewTab != null)
                IconButton(
                  icon: const Icon(TDIcons.add, size: 20),
                  onPressed: widget.onNewTab,
                  tooltip: 'New tab',
                  visualDensity: VisualDensity.compact,
                ),

              // Overflow menu
              if (tabState.hasTabs) _buildOverflowMenu(tabState, theme, colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    final tdTheme = TDTheme.of(context);
    return Center(
      child: TDText(
        'No tabs open',
        font: tdTheme.fontBodySmall,
        textColor: tdTheme.textColorSecondary,
      ),
    );
  }

  Widget _buildOverflowMenu(
    TabState tabState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconSize: 18,
      tooltip: 'Tab options',
      items: [
        TDPopupMenuItem(
          value: 'close_all',
          icon: TDIcons.close,
          label: 'Close All',
        ),
        if (tabState.activeTab != null) ...[
          const TDPopupMenuItem.divider(),
          TDPopupMenuItem(
            value: 'close_others',
            icon: TDIcons.tab,
            label: 'Close Others',
          ),
          TDPopupMenuItem(
            value: 'close_right',
            icon: TDIcons.chevron_right,
            label: 'Close to Right',
          ),
          TDPopupMenuItem(
            value: 'close_left',
            icon: TDIcons.chevron_left,
            label: 'Close to Left',
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
  final double maxWidth;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onCloseOthers;
  final VoidCallback onCloseToRight;
  final VoidCallback onCloseToLeft;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.maxWidth,
    required this.onTap,
    required this.onClose,
    required this.onCloseOthers,
    required this.onCloseToRight,
    required this.onCloseToLeft,
  });

  IconData _getIconData() {
    switch (tab.icon) {
      case 'table_chart':
        return TDIcons.table;
      case 'view_module':
        return TDIcons.view_module;
      case 'settings':
        return TDIcons.setting;
      case 'account_tree':
        return TDIcons.tree_square_dot;
      default:
        return TDIcons.tab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return InkWell(
      onTap: onTap,
      onSecondaryTapDown: (details) => _showContextMenu(context, details),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 80,
          maxWidth: maxWidth.clamp(100.0, 200.0),
        ),
        decoration: BoxDecoration(
          color: isActive ? tdTheme.bgColorContainer : null,
          border: Border(
            left: BorderSide(
              color: tdTheme.componentBorderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            right: BorderSide(
              color: tdTheme.componentBorderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            bottom: isActive
                ? BorderSide(color: tdTheme.brandNormalColor, width: 2)
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
                  ? tdTheme.brandNormalColor
                  : tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 8),
            // Title - simplified to single line for better responsiveness
            Flexible(
              child: TDText(
                tab.title,
                font: tdTheme.fontBodySmall,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                textColor: isActive ? tdTheme.brandNormalColor : tdTheme.textColorPrimary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                    color: tdTheme.bgColorComponentHover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    TDIcons.close,
                    size: 14,
                    color: tdTheme.textColorSecondary,
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
    showTDPopupMenu(
      context: context,
      position: details.globalPosition,
      items: [
        TDPopupMenuItem(
          value: 'close',
          icon: TDIcons.close,
          label: 'Close',
        ),
        TDPopupMenuItem(
          value: 'close_others',
          icon: TDIcons.tab,
          label: 'Close Others',
        ),
        TDPopupMenuItem(
          value: 'close_right',
          icon: TDIcons.chevron_right,
          label: 'Close to Right',
        ),
        TDPopupMenuItem(
          value: 'close_left',
          icon: TDIcons.chevron_left,
          label: 'Close to Left',
        ),
      ],
      onSelected: (value) {
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
      },
    );
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
