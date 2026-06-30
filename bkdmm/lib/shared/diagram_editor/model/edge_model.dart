import 'dart:ui';
import '../core/diagram_edge.dart';
import '../core/diagram_node.dart';

/// Edge model base class
///
/// Concrete implementation of [DiagramEdge] providing source/target/anchor management.
/// Can be extended for specific diagram types or used directly for generic edges.
class EdgeModel implements DiagramEdge {
  @override
  final String id;

  @override
  final String sourceAnchorId;

  @override
  final String targetAnchorId;

  @override
  final String type;

  @override
  final String? label;

  @override
  final bool isSelectable;

  /// Custom data associated with this edge
  final dynamic _data;

  /// Edge style configuration
  final EdgeStyle _style;

  /// Source end marker
  final EdgeMarker? _sourceMarker;

  /// Target end marker
  final EdgeMarker? _targetMarker;

  /// Control points for custom edge routing
  ///
  /// These are intermediate points between source and target
  /// used for orthogonal or custom routing
  final List<Offset> controlPoints;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  DateTime modifiedAt;

  EdgeModel({
    required this.id,
    required this.sourceAnchorId,
    required this.targetAnchorId,
    required this.type,
    this.label,
    this.isSelectable = true,
    dynamic data,
    EdgeStyle? style,
    EdgeMarker? sourceMarker,
    EdgeMarker? targetMarker,
    this.controlPoints = const [],
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : _data = data,
        _style = style ?? const EdgeStyle(),
        _sourceMarker = sourceMarker,
        _targetMarker = targetMarker,
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  @override
  String get sourceNodeId => sourceAnchorId.split(':').first;

  @override
  String get targetNodeId => targetAnchorId.split(':').first;

  @override
  dynamic getData() => _data;

  @override
  EdgeStyle getStyle() => _style;

  @override
  EdgeMarker? getSourceMarker() => _sourceMarker;

  @override
  EdgeMarker? getTargetMarker() => _targetMarker;

  /// Check if this edge connects the same nodes as another edge
  bool connectsSameNodes(EdgeModel other) {
    return (sourceNodeId == other.sourceNodeId &&
            targetNodeId == other.targetNodeId) ||
        (sourceNodeId == other.targetNodeId &&
            targetNodeId == other.sourceNodeId);
  }

  /// Check if this edge has the exact same connection as another edge
  bool hasSameConnection(EdgeModel other) {
    return sourceAnchorId == other.sourceAnchorId &&
        targetAnchorId == other.targetAnchorId;
  }

  /// Check if edge is a self-loop (connects node to itself)
  bool get isSelfLoop => sourceNodeId == targetNodeId;

  /// Get edge direction from source to target
  EdgeDirection getDirection(Offset sourcePos, Offset targetPos) {
    final dx = targetPos.dx - sourcePos.dx;
    final dy = targetPos.dy - sourcePos.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? EdgeDirection.right : EdgeDirection.left;
    } else {
      return dy > 0 ? EdgeDirection.down : EdgeDirection.up;
    }
  }

  /// Calculate the bounding box for this edge
  Rect calculateBounds() {
    // This would need anchor positions to calculate properly
    // For now, return zero rect
    if (controlPoints.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in controlPoints) {
      minX = minX < point.dx ? minX : point.dx;
      minY = minY < point.dy ? minY : point.dy;
      maxX = maxX > point.dx ? maxX : point.dx;
      maxY = maxY > point.dy ? maxY : point.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Create a copy with modified properties
  EdgeModel copyWith({
    String? id,
    String? sourceAnchorId,
    String? targetAnchorId,
    String? type,
    String? label,
    bool? isSelectable,
    dynamic data,
    EdgeStyle? style,
    EdgeMarker? sourceMarker,
    EdgeMarker? targetMarker,
    List<Offset>? controlPoints,
  }) {
    return EdgeModel(
      id: id ?? this.id,
      sourceAnchorId: sourceAnchorId ?? this.sourceAnchorId,
      targetAnchorId: targetAnchorId ?? this.targetAnchorId,
      type: type ?? this.type,
      label: label ?? this.label,
      isSelectable: isSelectable ?? this.isSelectable,
      data: data ?? _data,
      style: style ?? _style,
      sourceMarker: sourceMarker ?? _sourceMarker,
      targetMarker: targetMarker ?? _targetMarker,
      controlPoints: controlPoints ?? this.controlPoints,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
    );
  }

  /// Create a reversed edge (swap source and target)
  EdgeModel reversed() {
    return EdgeModel(
      id: id,
      sourceAnchorId: targetAnchorId,
      targetAnchorId: sourceAnchorId,
      type: type,
      label: label,
      isSelectable: isSelectable,
      data: _data,
      style: _style,
      sourceMarker: _targetMarker,
      targetMarker: _sourceMarker,
      controlPoints: controlPoints.reversed.toList(),
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceAnchorId': sourceAnchorId,
      'targetAnchorId': targetAnchorId,
      'type': type,
      'label': label,
      'isSelectable': isSelectable,
      'style': _style.toJson(),
      'controlPoints':
          controlPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory EdgeModel.fromJson(Map<String, dynamic> json) {
    return EdgeModel(
      id: json['id'] as String,
      sourceAnchorId: json['sourceAnchorId'] as String,
      targetAnchorId: json['targetAnchorId'] as String,
      type: json['type'] as String,
      label: json['label'] as String?,
      isSelectable: json['isSelectable'] as bool? ?? true,
      style: json['style'] != null
          ? EdgeStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      controlPoints: (json['controlPoints'] as List<dynamic>?)
              ?.map((p) => Offset(
                  (p as Map<String, dynamic>)['x'] as double,
                  p['y'] as double))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EdgeModel &&
        other.id == id &&
        other.sourceAnchorId == sourceAnchorId &&
        other.targetAnchorId == targetAnchorId;
  }

  @override
  int get hashCode => Object.hash(id, sourceAnchorId, targetAnchorId);

  @override
  String toString() {
    return 'EdgeModel(id: $id, source: $sourceAnchorId, target: $targetAnchorId, type: $type)';
  }
}

/// Edge direction enumeration
enum EdgeDirection {
  up,
  down,
  left,
  right,
}

/// Anchor reference for storing anchor connection information
class AnchorReference {
  /// Node ID this anchor belongs to
  final String nodeId;

  /// Anchor key within the node
  final String anchorKey;

  /// Full anchor ID (nodeId:anchorKey)
  final String anchorId;

  /// Anchor direction
  final AnchorDirection direction;

  /// Anchor type
  final AnchorType type;

  const AnchorReference({
    required this.nodeId,
    required this.anchorKey,
    required this.anchorId,
    required this.direction,
    this.type = AnchorType.node,
  });

  /// Parse from anchor ID string
  factory AnchorReference.fromId(String anchorId) {
    final parts = anchorId.split(':');
    if (parts.length < 2) {
      throw ArgumentError('Invalid anchor ID format: $anchorId');
    }

    final nodeId = parts[0];
    final anchorKey = parts.sublist(1).join(':');

    // Try to parse direction from anchor key
    AnchorDirection direction = AnchorDirection.right;
    if (parts.length >= 2) {
      final lastPart = parts.last;
      for (final d in AnchorDirection.values) {
        if (d.name == lastPart) {
          direction = d;
          break;
        }
      }
    }

    return AnchorReference(
      nodeId: nodeId,
      anchorKey: anchorKey,
      anchorId: anchorId,
      direction: direction,
    );
  }

  @override
  String toString() => anchorId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnchorReference && other.anchorId == anchorId;
  }

  @override
  int get hashCode => anchorId.hashCode;
}

/// Edge endpoint information
class EdgeEndpoint {
  /// Reference to the anchor
  final AnchorReference anchor;

  /// Position in scene coordinates
  final Offset position;

  /// Marker at this endpoint
  final EdgeMarker? marker;

  const EdgeEndpoint({
    required this.anchor,
    required this.position,
    this.marker,
  });

  @override
  String toString() => 'EdgeEndpoint(${anchor.anchorId} at $position)';
}

/// Edge routing information
///
/// Describes how the edge path should be drawn between endpoints
class EdgeRouting {
  /// Routing algorithm used
  final EdgeRoutingType type;

  /// Control points for the path
  final List<Offset> points;

  /// Total path length
  final double length;

  const EdgeRouting({
    required this.type,
    this.points = const [],
    this.length = 0.0,
  });

  /// Create a straight line routing
  factory EdgeRouting.straight(Offset start, Offset end) {
    return EdgeRouting(
      type: EdgeRoutingType.straight,
      points: [start, end],
      length: (end - start).distance,
    );
  }

  /// Create a curved (bezier) routing
  factory EdgeRouting.curved(Offset start, Offset end, {double factor = 0.3}) {
    final dx = (end.dx - start.dx) * factor;
    final control1 = Offset(start.dx + dx, start.dy);
    final control2 = Offset(end.dx - dx, end.dy);

    return EdgeRouting(
      type: EdgeRoutingType.bezier,
      points: [start, control1, control2, end],
      length: _estimateBezierLength(start, control1, control2, end),
    );
  }

  /// Create an orthogonal (manhattan) routing
  factory EdgeRouting.orthogonal(
    Offset start,
    Offset end,
    EdgeDirection startDirection,
    EdgeDirection endDirection,
  ) {
    final points = _computeOrthogonalPath(start, end, startDirection, endDirection);
    double length = 0;
    for (int i = 0; i < points.length - 1; i++) {
      length += (points[i + 1] - points[i]).distance;
    }

    return EdgeRouting(
      type: EdgeRoutingType.orthogonal,
      points: points,
      length: length,
    );
  }

  /// Estimate bezier curve length
  static double _estimateBezierLength(
      Offset p0, Offset p1, Offset p2, Offset p3) {
    // Use chord length as approximation
    final chord = (p3 - p0).distance;
    final controlNet = (p1 - p0).distance + (p2 - p1).distance + (p3 - p2).distance;
    return (chord + controlNet) / 2;
  }

  /// Compute orthogonal path between two points
  static List<Offset> _computeOrthogonalPath(
    Offset start,
    Offset end,
    EdgeDirection startDirection,
    EdgeDirection endDirection,
  ) {
    final points = <Offset>[start];

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    // Simple L-shaped or Z-shaped routing
    if (startDirection == EdgeDirection.left ||
        startDirection == EdgeDirection.right) {
      // Horizontal first
      if (dy.abs() > 0.1) {
        final midX = start.dx + dx / 2;
        points.add(Offset(midX, start.dy));
        points.add(Offset(midX, end.dy));
      }
    } else {
      // Vertical first
      if (dx.abs() > 0.1) {
        final midY = start.dy + dy / 2;
        points.add(Offset(start.dx, midY));
        points.add(Offset(end.dx, midY));
      }
    }

    points.add(end);
    return points;
  }

  /// Check if the path intersects with a rectangle
  bool intersects(Rect rect) {
    for (int i = 0; i < points.length - 1; i++) {
      if (_lineIntersectsRect(points[i], points[i + 1], rect)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a line segment intersects with a rectangle
  static bool _lineIntersectsRect(Offset p1, Offset p2, Rect rect) {
    // Simple bounding box check
    final lineRect = Rect.fromPoints(p1, p2);
    return lineRect.overlaps(rect);
  }
}

/// Edge routing type enumeration
enum EdgeRoutingType {
  /// Straight line
  straight,

  /// Bezier curve
  bezier,

  /// Orthogonal (manhattan) routing
  orthogonal,

  /// Custom routing with arbitrary control points
  custom,
}
