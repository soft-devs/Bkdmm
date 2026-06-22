import 'dart:math' as math;
import 'dart:ui';

/// Simplified Dagre-like layout algorithm for hierarchical graph layout
///
/// This implementation provides a layered graph layout algorithm
/// similar to Dagre, optimized for ER diagrams.
class DagreLayout {
  /// Configuration for layout
  final DagreConfig config;

  DagreLayout({this.config = const DagreConfig()});

  /// Calculate layout positions for nodes
  ///
  /// Takes a list of node IDs and edge connections,
  /// returns a map of node IDs to their positions.
  Map<String, Offset> layout({
    required List<String> nodes,
    required List<LayoutEdge> edges,
    required Size Function(String nodeId) nodeSize,
  }) {
    if (nodes.isEmpty) return {};

    // Build graph representation
    final graph = _buildGraph(nodes, edges);

    // Assign ranks (layers) to nodes
    final ranks = _assignRanks(graph);

    // Order nodes within each rank
    final orderedRanks = _orderNodes(ranks, graph);

    // Calculate x positions within each rank
    final positions = _calculatePositions(orderedRanks, nodeSize);

    return positions;
  }

  /// Build internal graph representation
  _LayoutGraph _buildGraph(List<String> nodes, List<LayoutEdge> edges) {
    final graph = _LayoutGraph();

    // Add all nodes
    for (final nodeId in nodes) {
      graph.addNode(nodeId);
    }

    // Add all edges
    for (final edge in edges) {
      graph.addEdge(edge.source, edge.target);
    }

    return graph;
  }

  /// Assign rank (layer) to each node using longest path algorithm
  Map<String, int> _assignRanks(_LayoutGraph graph) {
    final ranks = <String, int>{};
    final visited = <String>{};

    // Find all source nodes (nodes with no incoming edges)
    final sources = graph.nodes.where((n) => !graph.hasIncomingEdges(n)).toList();

    if (sources.isEmpty) {
      // If no source nodes, pick arbitrary start nodes
      sources.addAll(graph.nodes.take(1));
    }

    // BFS to assign ranks
    final queue = <String>[...sources];
    for (final source in sources) {
      ranks[source] = 0;
      visited.add(source);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentRank = ranks[current] ?? 0;

      for (final neighbor in graph.getSuccessors(current)) {
        if (!visited.contains(neighbor)) {
          ranks[neighbor] = currentRank + 1;
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    // Handle disconnected nodes
    for (final node in graph.nodes) {
      if (!ranks.containsKey(node)) {
        ranks[node] = 0;
      }
    }

    return ranks;
  }

  /// Order nodes within each rank to minimize edge crossings
  Map<int, List<String>> _orderNodes(Map<String, int> ranks, _LayoutGraph graph) {
    // Group nodes by rank
    final rankGroups = <int, List<String>>{};
    for (final entry in ranks.entries) {
      rankGroups.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    // Sort each rank's nodes for better edge crossing minimization
    for (final rank in rankGroups.keys) {
      final nodes = rankGroups[rank]!;
      // Sort by number of edges to previous/next rank
      nodes.sort((a, b) {
        final edgesA = graph.getEdges(a).length;
        final edgesB = graph.getEdges(b).length;
        return edgesB.compareTo(edgesA);
      });
    }

    return rankGroups;
  }

  /// Calculate positions for each node
  Map<String, Offset> _calculatePositions(
    Map<int, List<String>> orderedRanks,
    Size Function(String) nodeSize,
  ) {
    final positions = <String, Offset>{};

    for (final entry in orderedRanks.entries) {
      final rank = entry.key;
      final nodes = entry.value;

      // Calculate total width for this rank
      double totalWidth = 0;
      for (final node in nodes) {
        final size = nodeSize(node);
        totalWidth += size.width;
      }
      totalWidth += (nodes.length - 1) * config.nodeSpacing;

      // Center the rank horizontally
      double currentX = -totalWidth / 2;

      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        final size = nodeSize(node);

        final x = currentX + size.width / 2;
        final y = rank * (config.rankSpacing + config.defaultNodeHeight);

        positions[node] = Offset(x, y);
        currentX += size.width + config.nodeSpacing;
      }
    }

    // Center the layout vertically
    if (positions.isNotEmpty) {
      final minY = positions.values.map((p) => p.dy).reduce(math.min);
      final maxY = positions.values.map((p) => p.dy).reduce(math.max);
      final centerY = (minY + maxY) / 2;

      // Adjust all positions to center vertically
      final adjustedPositions = <String, Offset>{};
      for (final entry in positions.entries) {
        adjustedPositions[entry.key] = Offset(entry.value.dx, entry.value.dy - centerY);
      }
      return adjustedPositions;
    }

    return positions;
  }
}

/// Configuration for Dagre layout
class DagreConfig {
  /// Horizontal spacing between nodes in same rank
  final double nodeSpacing;

  /// Vertical spacing between ranks
  final double rankSpacing;

  /// Default node width if not specified
  final double defaultNodeWidth;

  /// Default node height if not specified
  final double defaultNodeHeight;

  /// Whether to optimize for edge crossings
  final bool optimizeCrossings;

  /// Maximum number of iterations for optimization
  final int maxIterations;

  const DagreConfig({
    this.nodeSpacing = 50.0,
    this.rankSpacing = 100.0,
    this.defaultNodeWidth = 200.0,
    this.defaultNodeHeight = 150.0,
    this.optimizeCrossings = true,
    this.maxIterations = 24,
  });
}

/// Edge representation for layout
class LayoutEdge {
  final String source;
  final String target;

  const LayoutEdge({required this.source, required this.target});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayoutEdge && other.source == source && other.target == target;
  }

  @override
  int get hashCode => Object.hash(source, target);
}

/// Internal graph representation for layout algorithm
class _LayoutGraph {
  final Set<String> nodes = {};
  final Map<String, Set<String>> adjacencyList = {};
  final Map<String, Set<String>> reverseAdjacencyList = {};

  void addNode(String node) {
    nodes.add(node);
    adjacencyList.putIfAbsent(node, () => {});
    reverseAdjacencyList.putIfAbsent(node, () => {});
  }

  void addEdge(String from, String to) {
    adjacencyList.putIfAbsent(from, () => {}).add(to);
    reverseAdjacencyList.putIfAbsent(to, () => {}).add(from);
  }

  List<String> getSuccessors(String node) {
    return adjacencyList[node]?.toList() ?? [];
  }

  List<String> getPredecessors(String node) {
    return reverseAdjacencyList[node]?.toList() ?? [];
  }

  List<LayoutEdge> getEdges(String node) {
    final edges = <LayoutEdge>[];
    for (final successor in getSuccessors(node)) {
      edges.add(LayoutEdge(source: node, target: successor));
    }
    for (final predecessor in getPredecessors(node)) {
      edges.add(LayoutEdge(source: predecessor, target: node));
    }
    return edges;
  }

  bool hasIncomingEdges(String node) {
    return (reverseAdjacencyList[node]?.isNotEmpty ?? false);
  }
}

/// Extension methods for layout algorithm
extension LayoutExtensions on DagreLayout {
  /// Layout with bounds - adjusts positions to fit within specified bounds
  Map<String, Offset> layoutWithBounds({
    required List<String> nodes,
    required List<LayoutEdge> edges,
    required Size Function(String nodeId) nodeSize,
    required Size bounds,
    double padding = 50.0,
  }) {
    final positions = layout(
      nodes: nodes,
      edges: edges,
      nodeSize: nodeSize,
    );

    if (positions.isEmpty) return positions;

    // Calculate bounds of current layout
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final entry in positions.entries) {
      final size = nodeSize(entry.key);
      final pos = entry.value;
      minX = math.min(minX, pos.dx - size.width / 2);
      minY = math.min(minY, pos.dy - size.height / 2);
      maxX = math.max(maxX, pos.dx + size.width / 2);
      maxY = math.max(maxY, pos.dy + size.height / 2);
    }

    // Calculate offset to center in bounds
    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;
    final offsetX = padding - minX + (bounds.width - contentWidth - padding * 2) / 2;
    final offsetY = padding - minY + (bounds.height - contentHeight - padding * 2) / 2;

    // Apply offset
    return positions.map((key, value) => MapEntry(key, value + Offset(offsetX, offsetY)));
  }
}
