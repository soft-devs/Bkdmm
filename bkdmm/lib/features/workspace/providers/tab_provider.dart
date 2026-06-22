import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/storage_service.dart';

/// Tab types supported by the workspace
enum TabType {
  entity,
  relation,
  settings,
  module,
}

/// Represents a single tab in the workspace
class WorkspaceTab {
  final String id;
  final TabType type;
  final String title;
  final String? subtitle;
  final String? icon;
  final String? moduleId;
  final String? entityId;

  const WorkspaceTab({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.icon,
    this.moduleId,
    this.entityId,
  });

  /// Create tab for an entity
  factory WorkspaceTab.forEntity({
    required String id,
    required Entity entity,
    required String moduleId,
  }) {
    return WorkspaceTab(
      id: id,
      type: TabType.entity,
      title: entity.title,
      subtitle: entity.chnname,
      icon: 'table_chart',
      moduleId: moduleId,
      entityId: entity.id,
    );
  }

  /// Create tab for a module
  factory WorkspaceTab.forModule({
    required String id,
    required Module module,
  }) {
    return WorkspaceTab(
      id: id,
      type: TabType.module,
      title: module.name,
      subtitle: module.chnname,
      icon: 'view_module',
      moduleId: module.id,
    );
  }

  /// Create tab for settings
  factory WorkspaceTab.settings({
    required String id,
  }) {
    return WorkspaceTab(
      id: id,
      type: TabType.settings,
      title: 'Settings',
      icon: 'settings',
    );
  }

  /// Create tab for relation view
  factory WorkspaceTab.forRelation({
    required String id,
    required String moduleId,
    required String moduleName,
  }) {
    return WorkspaceTab(
      id: id,
      type: TabType.relation,
      title: 'Relations',
      subtitle: moduleName,
      icon: 'account_tree',
      moduleId: moduleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'moduleId': moduleId,
        'entityId': entityId,
      };

  factory WorkspaceTab.fromJson(Map<String, dynamic> json) {
    return WorkspaceTab(
      id: json['id'] as String,
      type: TabType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TabType.entity,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String?,
      moduleId: json['moduleId'] as String?,
      entityId: json['entityId'] as String?,
    );
  }
}

/// State for tab management
class TabState {
  final List<WorkspaceTab> tabs;
  final String? activeTabId;
  final int maxVisibleTabs;

  const TabState({
    this.tabs = const [],
    this.activeTabId,
    this.maxVisibleTabs = 10,
  });

  /// Check if there are any tabs
  bool get hasTabs => tabs.isNotEmpty;

  /// Get the active tab
  WorkspaceTab? get activeTab {
    if (activeTabId == null) return null;
    return tabs.where((t) => t.id == activeTabId).firstOrNull;
  }

  /// Get active tab index
  int get activeIndex {
    if (activeTabId == null) return -1;
    final index = tabs.indexWhere((t) => t.id == activeTabId);
    return index;
  }

  /// Check if a tab with the given ID exists
  bool hasTab(String id) => tabs.any((t) => t.id == id);

  /// Get tab by ID
  WorkspaceTab? getTab(String id) {
    return tabs.where((t) => t.id == id).firstOrNull;
  }

  /// Check if an entity tab is open
  bool isEntityOpen(String entityId) {
    return tabs.any((t) => t.entityId == entityId);
  }

  /// Check if a module tab is open
  bool isModuleOpen(String moduleId) {
    return tabs.any((t) => t.moduleId == moduleId && t.type == TabType.module);
  }

  TabState copyWith({
    List<WorkspaceTab>? tabs,
    String? activeTabId,
    int? maxVisibleTabs,
    bool clearActiveTab = false,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: clearActiveTab ? null : (activeTabId ?? this.activeTabId),
      maxVisibleTabs: maxVisibleTabs ?? this.maxVisibleTabs,
    );
  }

  Map<String, dynamic> toJson() => {
        'tabs': tabs.map((t) => t.toJson()).toList(),
        'activeTabId': activeTabId,
      };

  factory TabState.fromJson(Map<String, dynamic> json) {
    return TabState(
      tabs: (json['tabs'] as List?)
              ?.map((t) => WorkspaceTab.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      activeTabId: json['activeTabId'] as String?,
    );
  }

  static const TabState empty = TabState();
}

/// Notifier for managing tabs
class TabNotifier extends StateNotifier<TabState> {
  static const String _storageKey = 'workspace_tabs';
  int _idCounter = 0;

  TabNotifier() : super(const TabState()) {
    _loadTabs();
  }

  /// Generate a unique tab ID
  String _generateId() {
    _idCounter++;
    return 'tab_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  /// Load tabs from storage
  Future<void> _loadTabs() async {
    try {
      final saved = StorageService.getString(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        state = TabState.fromJson(json);
      }
    } catch (_) {
      // Ignore errors loading tabs
    }
  }

  /// Save tabs to storage
  Future<void> _saveTabs() async {
    try {
      final json = state.toJson();
      await StorageService.setString(_storageKey, jsonEncode(json));
    } catch (_) {
      // Ignore errors saving tabs
    }
  }

  /// Open a new tab or focus existing one
  void openTab(WorkspaceTab tab) {
    // Check if tab already exists
    final existingIndex = state.tabs.indexWhere((t) => t.id == tab.id);
    if (existingIndex >= 0) {
      // Focus existing tab
      state = state.copyWith(activeTabId: tab.id);
      return;
    }

    // Add new tab
    final newTabs = [...state.tabs, tab];
    state = state.copyWith(
      tabs: newTabs,
      activeTabId: tab.id,
    );
    _saveTabs();
  }

  /// Open an entity in a new tab
  void openEntity(Entity entity, String moduleId) {
    final tabId = 'entity_${entity.id}';
    final tab = WorkspaceTab.forEntity(
      id: tabId,
      entity: entity,
      moduleId: moduleId,
    );
    openTab(tab);
  }

  /// Open a module in a new tab
  void openModule(Module module) {
    final tabId = 'module_${module.id}';
    final tab = WorkspaceTab.forModule(
      id: tabId,
      module: module,
    );
    openTab(tab);
  }

  /// Open relation view for a module
  void openRelation(String moduleId, String moduleName) {
    final tabId = 'relation_$moduleId';
    final tab = WorkspaceTab.forRelation(
      id: tabId,
      moduleId: moduleId,
      moduleName: moduleName,
    );
    openTab(tab);
  }

  /// Open settings tab
  void openSettings() {
    const tabId = 'settings';
    const tab = WorkspaceTab.settings(id: tabId);
    openTab(tab);
  }

  /// Close a tab by ID
  void closeTab(String tabId) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex < 0) return;

    final newTabs = state.tabs.where((t) => t.id != tabId).toList();
    String? newActiveTabId = state.activeTabId;

    // If closing the active tab, select a different one
    if (state.activeTabId == tabId) {
      if (newTabs.isEmpty) {
        newActiveTabId = null;
      } else if (tabIndex >= newTabs.length) {
        // Was last tab, select previous
        newActiveTabId = newTabs.last.id;
      } else {
        // Select the tab at the same position
        newActiveTabId = newTabs[tabIndex].id;
      }
    }

    state = state.copyWith(
      tabs: newTabs,
      activeTabId: newActiveTabId,
      clearActiveTab: newActiveTabId == null,
    );
    _saveTabs();
  }

  /// Close all tabs
  void closeAllTabs() {
    state = const TabState();
    _saveTabs();
  }

  /// Close other tabs (keep active)
  void closeOtherTabs() {
    if (state.activeTabId == null) return;
    final activeTab = state.activeTab;
    if (activeTab == null) return;

    state = state.copyWith(
      tabs: [activeTab],
    );
    _saveTabs();
  }

  /// Close tabs to the right of the active tab
  void closeTabsToRight() {
    final activeIndex = state.activeIndex;
    if (activeIndex < 0) return;

    final newTabs = state.tabs.take(activeIndex + 1).toList();
    state = state.copyWith(tabs: newTabs);
    _saveTabs();
  }

  /// Close tabs to the left of the active tab
  void closeTabsToLeft() {
    final activeIndex = state.activeIndex;
    if (activeIndex < 0) return;

    final newTabs = state.tabs.skip(activeIndex).toList();
    state = state.copyWith(tabs: newTabs);
    _saveTabs();
  }

  /// Set active tab
  void setActiveTab(String tabId) {
    if (!state.hasTab(tabId)) return;
    state = state.copyWith(activeTabId: tabId);
    _saveTabs();
  }

  /// Move to next tab
  void nextTab() {
    if (!state.hasTabs) return;
    final activeIndex = state.activeIndex;
    if (activeIndex < 0) {
      state = state.copyWith(activeTabId: state.tabs.first.id);
      return;
    }

    final nextIndex = (activeIndex + 1) % state.tabs.length;
    state = state.copyWith(activeTabId: state.tabs[nextIndex].id);
  }

  /// Move to previous tab
  void previousTab() {
    if (!state.hasTabs) return;
    final activeIndex = state.activeIndex;
    if (activeIndex < 0) {
      state = state.copyWith(activeTabId: state.tabs.first.id);
      return;
    }

    final prevIndex = (activeIndex - 1 + state.tabs.length) % state.tabs.length;
    state = state.copyWith(activeTabId: state.tabs[prevIndex].id);
  }

  /// Reorder tabs
  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.tabs.length) return;
    if (newIndex < 0 || newIndex > state.tabs.length) return;

    final newTabs = List<WorkspaceTab>.from(state.tabs);
    final item = newTabs.removeAt(oldIndex);
    newTabs.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, item);

    state = state.copyWith(tabs: newTabs);
    _saveTabs();
  }

  /// Create a new tab with unique ID
  WorkspaceTab createTab({
    required TabType type,
    required String title,
    String? subtitle,
    String? icon,
    String? moduleId,
    String? entityId,
  }) {
    return WorkspaceTab(
      id: _generateId(),
      type: type,
      title: title,
      subtitle: subtitle,
      icon: icon,
      moduleId: moduleId,
      entityId: entityId,
    );
  }

  /// Update tab title
  void updateTabTitle(String tabId, String title, {String? subtitle}) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex < 0) return;

    final tab = state.tabs[tabIndex];
    final newTabs = List<WorkspaceTab>.from(state.tabs);
    newTabs[tabIndex] = WorkspaceTab(
      id: tab.id,
      type: tab.type,
      title: title,
      subtitle: subtitle ?? tab.subtitle,
      icon: tab.icon,
      moduleId: tab.moduleId,
      entityId: tab.entityId,
    );

    state = state.copyWith(tabs: newTabs);
    _saveTabs();
  }
}

/// Provider for tab management
final tabProvider = StateNotifierProvider<TabNotifier, TabState>((ref) {
  return TabNotifier();
});

/// Provider for active tab
final activeTabProvider = Provider<WorkspaceTab?>((ref) {
  return ref.watch(tabProvider).activeTab;
});

/// Provider for tab count
final tabCountProvider = Provider<int>((ref) {
  return ref.watch(tabProvider).tabs.length;
});
