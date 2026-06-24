import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'loading_overlay.dart';

/// A common scaffold widget that provides consistent structure across screens.
///
/// Features:
/// - Responsive navigation (rail on desktop, bottom tab bar on mobile)
/// - Consistent nav bar with actions (TDesign-styled)
/// - Optional floating action button
/// - Loading overlay support
class AppScaffold extends StatefulWidget {
  /// Creates an app scaffold.
  const AppScaffold({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.body,
    this.selectedIndex = 0,
    this.onNavigationChanged,
    this.navigationItems = const [],
    this.showNavigation = false,
    this.isLoading = false,
  });

  /// The title displayed in the nav bar.
  final String title;

  /// Optional leading widget for the nav bar (e.g., back button).
  final Widget? leading;

  /// Actions to display in the nav bar.
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final useRail = screenWidth >= 600 && widget.showNavigation;

    Widget content = Scaffold(
      backgroundColor: tdTheme.bgColorPage,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TDNavBar(
          title: widget.title,
          leftBarItems: widget.leading != null
              ? [
                  TDNavBarItem(
                    iconWidget: widget.leading!,
                    action: () {},
                  ),
                ]
              : null,
          rightBarItems: _buildRightBarItems(),
          backgroundColor: tdTheme.bgColorContainer,
          useDefaultBack: false,
        ),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar:
          !useRail && widget.showNavigation && widget.navigationItems.isNotEmpty
              ? _buildBottomTabBar(tdTheme)
              : null,
    );

    if (useRail) {
      content = Row(
        children: [
          _buildNavigationRail(tdTheme),
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

  /// Build right-side action items as TDNavBarItem list.
  List<TDNavBarItem>? _buildRightBarItems() {
    if (widget.actions == null || widget.actions!.isEmpty) return null;

    return widget.actions!.map((action) {
      if (action is TDButton) {
        return TDNavBarItem(
          iconWidget: action,
          action: action.onTap,
        );
      }
      // For generic widgets, wrap them directly in an iconWidget
      return TDNavBarItem(
        iconWidget: action,
        action: () {},
      );
    }).toList();
  }

  /// Build the bottom tab bar using TDBottomTabBar.
  Widget _buildBottomTabBar(TDThemeData tdTheme) {
    final tabs = widget.navigationItems
        .map((item) => TDBottomTabBarTabConfig(
              selectedIcon: Icon(
                item.selectedIcon ?? item.icon,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              unselectedIcon: Icon(
                item.icon,
                size: 24,
                color: tdTheme.textColorSecondary,
              ),
              tabText: item.label,
              onTap: () {
                final index = widget.navigationItems.indexOf(item);
                if (index != -1) {
                  setState(() => _selectedIndex = index);
                  widget.onNavigationChanged?.call(index);
                }
              },
            ))
        .toList();

    return TDBottomTabBar(
      TDBottomTabBarBasicType.iconText,
      currentIndex: _selectedIndex,
      navigationTabs: tabs,
      backgroundColor: tdTheme.bgColorContainer,
      selectedBgColor: tdTheme.brandLightColor,
    );
  }

  /// Build the side navigation rail with TDesign styling.
  Widget _buildNavigationRail(TDThemeData tdTheme) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        widget.onNavigationChanged?.call(index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: tdTheme.bgColorContainer,
      selectedIconTheme: IconThemeData(
        color: tdTheme.brandNormalColor,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: tdTheme.textColorSecondary,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: tdTheme.brandNormalColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: tdTheme.textColorSecondary,
        fontSize: 12,
      ),
      destinations: widget.navigationItems
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ))
          .toList(),
    );
  }
}

/// Represents a navigation item in the scaffold.
///
/// Supports both Material [Icons] and [TDIcons] icon types.
class NavigationItem {
  /// Creates a navigation item.
  const NavigationItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  /// The icon to display (supports [Icons] or [TDIcons]).
  final IconData icon;

  /// The label text.
  final String label;

  /// Optional icon when selected (defaults to [icon]).
  final IconData? selectedIcon;
}
