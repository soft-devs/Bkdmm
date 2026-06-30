/// Behavior 注册表
///
/// 管理所有 Behavior（行为模块），提供优先级排序的行为分发机制。
/// 与 HandlerRegistry 不同，Behavior 是更高层次的抽象，可以包含多个 Handler。
library;

/// 行为模块抽象基类
///
/// Behavior 是可复用的、自包含的交互行为单元。
/// 每个 Behavior 可以包含一个或多个 Handler，并管理其生命周期。
///
/// 行为示例：
/// - SelectionBehavior: 处理节点选择、框选
/// - DragBehavior: 处理节点拖拽
/// - ConnectionBehavior: 处理连线创建
/// - PanBehavior: 处理画布平移
abstract class Behavior {
  /// 行为唯一标识
  final String id;

  /// 行为名称（用于调试和显示）
  final String name;

  /// 行为优先级
  ///
  /// 数值越小优先级越高，越先被处理。
  /// 推荐优先级范围：
  /// - 10-19: 锚点交互（如连线）
  /// - 20-29: 节点交互（如拖拽）
  /// - 30-39: 边交互
  /// - 40-49: 选择/框选
  /// - 50-59: 编辑操作
  /// - 90-99: 画布操作（如平移、缩放）
  final int priority;

  /// 是否启用
  bool _enabled = true;

  /// 是否已初始化
  bool _initialized = false;

  Behavior({
    required this.id,
    required this.name,
    this.priority = 100,
  });

  /// 是否启用
  bool get enabled => _enabled;

  /// 是否已初始化
  bool get initialized => _initialized;

  /// 启用行为
  void enable() {
    _enabled = true;
  }

  /// 禁用行为
  void disable() {
    _enabled = false;
  }

  /// 初始化行为
  ///
  /// 在行为首次注册时调用，用于初始化资源。
  void init() {
    if (_initialized) return;
    onInit();
    _initialized = true;
  }

  /// 销毁行为
  ///
  /// 在行为从注册表移除时调用，用于释放资源。
  void dispose() {
    if (!_initialized) return;
    onDispose();
    _initialized = false;
  }

  /// 子类实现：初始化逻辑
  /// 注意：此方法仅供子类重写，不应在外部直接调用。
  void onInit() {}

  /// 子类实现：销毁逻辑
  /// 注意：此方法仅供子类重写，不应在外部直接调用。
  void onDispose() {}

  /// 重置行为状态
  ///
  /// 当交互结束或取消时调用。
  void reset() {}

  @override
  String toString() => 'Behavior($id, name=$name, priority=$priority, enabled=$enabled)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Behavior && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Behavior 注册表
///
/// 管理所有 Behavior 的注册、启用、禁用和优先级排序。
/// 支持按 ID 查找、按优先级遍历等操作。
///
/// 用法示例：
/// ```dart
/// final registry = BehaviorRegistry();
/// registry.register(SelectionBehavior());
/// registry.register(DragBehavior());
///
/// // 按优先级遍历启用的行为
/// for (final behavior in registry.enabledBehaviors) {
///   behavior.handle(event);
/// }
/// ```
class BehaviorRegistry {
  /// 已注册的行为映射（ID -> Behavior）
  final Map<String, Behavior> _behaviors = {};

  /// 按优先级排序的行为列表缓存
  List<Behavior>? _sortedBehaviorsCache;

  /// 当前活跃的行为（正在处理某个交互）
  Behavior? _activeBehavior;

  /// 是否已排序
  bool _isSorted = false;

  /// 注册行为
  ///
  /// 如果已存在相同 ID 的行为，将抛出 [ArgumentError]。
  void register(Behavior behavior) {
    if (_behaviors.containsKey(behavior.id)) {
      throw ArgumentError('Behavior with id "${behavior.id}" already registered');
    }

    _behaviors[behavior.id] = behavior;
    behavior.init();
    _invalidateCache();
  }

  /// 注册多个行为
  void registerAll(List<Behavior> behaviors) {
    for (final behavior in behaviors) {
      register(behavior);
    }
  }

  /// 移除行为
  ///
  /// 返回被移除的行为，如果不存在则返回 null。
  Behavior? remove(String id) {
    final behavior = _behaviors.remove(id);
    if (behavior != null) {
      behavior.dispose();
      _invalidateCache();
    }
    return behavior;
  }

  /// 获取行为
  Behavior? get(String id) => _behaviors[id];

  /// 检查行为是否存在
  bool has(String id) => _behaviors.containsKey(id);

  /// 启用行为
  void enable(String id) {
    final behavior = _behaviors[id];
    if (behavior != null) {
      behavior.enable();
      _invalidateCache();
    }
  }

  /// 禁用行为
  void disable(String id) {
    final behavior = _behaviors[id];
    if (behavior != null) {
      behavior.disable();
      _invalidateCache();
    }
  }

  /// 切换行为启用状态
  void toggle(String id) {
    final behavior = _behaviors[id];
    if (behavior != null) {
      if (behavior.enabled) {
        behavior.disable();
      } else {
        behavior.enable();
      }
      _invalidateCache();
    }
  }

  /// 清空所有行为
  void clear() {
    for (final behavior in _behaviors.values) {
      behavior.dispose();
    }
    _behaviors.clear();
    _activeBehavior = null;
    _invalidateCache();
  }

  /// 获取所有行为（按优先级排序）
  List<Behavior> get behaviors {
    _ensureSortedCache();
    return List.unmodifiable(_sortedBehaviorsCache!);
  }

  /// 获取所有启用的行为（按优先级排序）
  List<Behavior> get enabledBehaviors {
    return behaviors.where((b) => b.enabled).toList();
  }

  /// 获取当前活跃行为
  Behavior? get activeBehavior => _activeBehavior;

  /// 设置活跃行为
  void setActiveBehavior(Behavior? behavior) {
    _activeBehavior = behavior;
  }

  /// 清除活跃行为
  void clearActiveBehavior() {
    _activeBehavior = null;
  }

  /// 重置所有行为状态
  void resetAll() {
    _activeBehavior = null;
    for (final behavior in _behaviors.values) {
      behavior.reset();
    }
  }

  /// 获取行为数量
  int get length => _behaviors.length;

  /// 检查是否为空
  bool get isEmpty => _behaviors.isEmpty;

  /// 检查是否不为空
  bool get isNotEmpty => _behaviors.isNotEmpty;

  /// 遍历所有行为（按优先级）
  void forEach(void Function(Behavior behavior) action) {
    for (final behavior in behaviors) {
      action(behavior);
    }
  }

  /// 遍历所有启用的行为（按优先级）
  void forEachEnabled(void Function(Behavior behavior) action) {
    for (final behavior in enabledBehaviors) {
      action(behavior);
    }
  }

  /// 查找满足条件的行为
  Behavior? find(bool Function(Behavior behavior) test) {
    for (final behavior in behaviors) {
      if (test(behavior)) {
        return behavior;
      }
    }
    return null;
  }

  /// 查找启用的行为中满足条件的
  Behavior? findEnabled(bool Function(Behavior behavior) test) {
    for (final behavior in enabledBehaviors) {
      if (test(behavior)) {
        return behavior;
      }
    }
    return null;
  }

  /// 按优先级范围过滤行为
  List<Behavior> filterByPriorityRange(int minPriority, int maxPriority) {
    return behaviors
        .where((b) => b.priority >= minPriority && b.priority <= maxPriority)
        .toList();
  }

  /// 确保排序缓存有效
  void _ensureSortedCache() {
    if (_sortedBehaviorsCache == null || !_isSorted) {
      _sortedBehaviorsCache = _behaviors.values.toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      _isSorted = true;
    }
  }

  /// 使缓存失效
  void _invalidateCache() {
    _sortedBehaviorsCache = null;
    _isSorted = false;
  }

  @override
  String toString() {
    return 'BehaviorRegistry(behaviors: ${behaviors.map((b) => b.name).join(', ')})';
  }
}

/// Behavior 注册表工厂
///
/// 用于创建预配置的 Behavior 注册表。
class BehaviorRegistryFactory {
  /// 创建默认 Behavior 注册表
  static BehaviorRegistry createDefault() {
    return BehaviorRegistry();
  }

  /// 创建 ER 图 Behavior 注册表
  ///
  /// [enableConnection] - 是否启用连线行为
  /// [enableDrag] - 是否启用拖拽行为
  /// [enableSelection] - 是否启用选择行为
  /// [enablePan] - 是否启用平移行为
  static BehaviorRegistry createERDiagram({
    bool enableConnection = true,
    bool enableDrag = true,
    bool enableSelection = true,
    bool enablePan = true,
  }) {
    final registry = BehaviorRegistry();

    // TODO: 在具体实现中添加 Behavior
    // 示例：
    // if (enableSelection) {
    //   registry.register(SelectionBehavior(priority: 40));
    // }
    // if (enableDrag) {
    //   registry.register(DragBehavior(priority: 20));
    // }
    // if (enableConnection) {
    //   registry.register(ConnectionBehavior(priority: 10));
    // }
    // if (enablePan) {
    //   registry.register(PanBehavior(priority: 90));
    // }

    return registry;
  }

  /// 创建流程图 Behavior 注册表
  static BehaviorRegistry createFlowchart() {
    final registry = BehaviorRegistry();

    // TODO: 在具体实现中添加流程图 Behavior

    return registry;
  }

  /// 创建只读模式 Behavior 注册表
  ///
  /// 只读模式只启用平移和缩放，禁用编辑操作。
  static BehaviorRegistry createReadOnly() {
    final registry = BehaviorRegistry();

    // TODO: 添加只读模式的 Behavior
    // registry.register(PanBehavior(priority: 90));
    // registry.register(ZoomBehavior(priority: 91));

    return registry;
  }
}

/// Behavior 优先级常量
///
/// 定义各类型行为的推荐优先级范围。
abstract class BehaviorPriority {
  /// 锚点交互（10-19）
  static const int anchorMin = 10;
  static const int anchorMax = 19;

  /// 节点交互（20-29）
  static const int nodeMin = 20;
  static const int nodeMax = 29;

  /// 边交互（30-39）
  static const int edgeMin = 30;
  static const int edgeMax = 39;

  /// 选择/框选（40-49）
  static const int selectionMin = 40;
  static const int selectionMax = 49;

  /// 编辑操作（50-59）
  static const int editMin = 50;
  static const int editMax = 59;

  /// 画布操作（90-99）
  static const int canvasMin = 90;
  static const int canvasMax = 99;
}
