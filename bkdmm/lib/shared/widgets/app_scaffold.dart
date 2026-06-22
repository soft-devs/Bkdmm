import 'package:flutter/material.dart';
import 'loading_overlay.dart';

/// A common scaffold widget that provides consistent structure across screens.
///
/// Features:
/// - Responsive navigation (rail on desktop, bottom bar on mobile)
/// - Consistent app bar with actions
/// - Optional floating action button
/// - Loading overlay support
class AppScaffold extends StatefulWidget {
  /// Creates an app scaffold.
  const AppScaffold({
    super.key,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.body,
    this.selectedIndex = 0,
    this.onNavigationChanged,
    this.navigationItems = const [],
    this.showNavigation = false,
    this.isLoading = false,
  });

  /// The title displayed in the app bar.
  final String title;

  /// Actions to display in the app bar.
  final List<Widget>? actions;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// The main content of the scaffold.
  final Widget? body;

  /// Currently selected navigation item index.
  final int selectedIndex;

  /// Callback when navigation item is selected.
  final ValueChanged<int>? onNavigationChanged;

  /// Navigation items for the rail/bar.
  final List<NavigationItem> navigationItems;

  /// Whether to show navigation rail/bar.
  final bool showNavigation;

  /// Whether to show a loading overlay.
  final bool isLoading;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final useRail = screenWidth >= 600 && widget.showNavigation;

    Widget content = Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: widget.actions,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: !useRail && widget.showNavigation
          ? NavigationBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onNavigationChanged,
              destinations: widget.navigationItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon ?? item.icon),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );

    if (useRail) {
      content = Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onNavigationChanged,
            labelType: NavigationRailLabelType.all,
            destinations: widget.navigationItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon ?? item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: content),
        ],
      );
    }

    if (widget.isLoading) {
      content = Stack(
        children: [
          content,
          const LoadingOverlay(),
        ],
      );
    }

    return content;
  }
}

/// Represents a navigation item in the scaffold.
class NavigationItem {
  /// Creates a navigation item.
  const NavigationItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  /// The icon to display.
  final IconData icon;

  /// The label text.
  final String label;

  /// Optional icon when selected (defaults to [icon]).
  final IconData? selectedIcon;
}
