import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Matrix4;
import 'package:bkdmm/shared/diagram_editor/model/graph_model.dart';
import 'package:bkdmm/shared/diagram_editor/model/transform_model.dart';
import 'package:bkdmm/shared/diagram_editor/model/node_model.dart';
import 'package:bkdmm/shared/diagram_editor/model/edge_model.dart';

void main() {
  group('GraphModel', () {
    late GraphModel graph;

    setUp(() {
      graph = GraphModel();
    });

    tearDown(() {
      graph.dispose();
    });

    group('node operations', () {
      test('should start empty', () {
        expect(graph.nodeCount, 0);
        expect(graph.nodes.isEmpty, true);
      });

      test('should add node', () {
        final node = NodeModel(
          id: 'node-1',
          type: 'test',
          title: 'Test Node',
        );
        graph.addNode(node);

        expect(graph.nodeCount, 1);
        expect(graph.hasNode('node-1'), true);
        expect(graph.getNode('node-1'), node);
      });

      test('should throw on duplicate node id', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-1', type: 'test', title: 'Node 2');

        graph.addNode(node1);
        expect(
          () => graph.addNode(node2),
          throwsArgumentError,
        );
      });

      test('should overwrite node when overwrite is true', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-1', type: 'test', title: 'Node 2');

        graph.addNode(node1);
        graph.addNode(node2, overwrite: true);

        expect(graph.nodeCount, 1);
        expect(graph.getNode('node-1')?.title, 'Node 2');
      });

      test('should update node', () {
        final node = NodeModel(
          id: 'node-1',
          type: 'test',
          title: 'Original',
          position: const Offset(0, 0),
        );
        graph.addNode(node);

        final updated = graph.updateNode('node-1', (n) {
          return (n as NodeModel).copyWith(position: const Offset(100, 100), title: 'Updated');
        });

        expect(updated, true);
        expect(graph.getNode('node-1')?.title, 'Updated');
        expect(graph.getNode('node-1')?.position, const Offset(100, 100));
      });

      test('should return false when updating non-existent node', () {
        final updated = graph.updateNode('non-existent', (n) => n);
        expect(updated, false);
      });

      test('should remove node', () {
        final node = NodeModel(id: 'node-1', type: 'test', title: 'Node');
        graph.addNode(node);

        final result = graph.removeNode('node-1');

        expect(result.found, true);
        expect(result.node, node);
        expect(graph.nodeCount, 0);
        expect(graph.hasNode('node-1'), false);
      });

      test('should return not found when removing non-existent node', () {
        final result = graph.removeNode('non-existent');

        expect(result.found, false);
        expect(result.node, isNull);
      });

      test('should remove connected edges when removing node', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node1);
        graph.addNode(node2);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );
        graph.addEdge(edge, validateNodes: false);

        final result = graph.removeNode('node-1');

        expect(result.removedEdges.length, 1);
        expect(result.removedEdges.first.id, 'edge-1');
        expect(graph.edgeCount, 0);
      });
    });

    group('edge operations', () {
      test('should start empty', () {
        expect(graph.edgeCount, 0);
        expect(graph.edges.isEmpty, true);
      });

      test('should add edge', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node1);
        graph.addNode(node2);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );
        graph.addEdge(edge);

        expect(graph.edgeCount, 1);
        expect(graph.hasEdge('edge-1'), true);
        expect(graph.getEdge('edge-1'), edge);
      });

      test('should throw on duplicate edge id', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node1);
        graph.addNode(node2);

        final edge1 = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );
        final edge2 = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-2:left',
          targetAnchorId: 'node-1:right',
          type: 'default',
        );

        graph.addEdge(edge1);
        expect(
          () => graph.addEdge(edge2),
          throwsArgumentError,
        );
      });

      test('should throw when source node does not exist', () {
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node2);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );

        expect(
          () => graph.addEdge(edge),
          throwsArgumentError,
        );
      });

      test('should skip validation when validateNodes is false', () {
        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );

        graph.addEdge(edge, validateNodes: false);
        expect(graph.edgeCount, 1);
      });

      test('should update edge', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node1);
        graph.addNode(node2);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
          label: 'Original',
        );
        graph.addEdge(edge);

        final updated = graph.updateEdge('edge-1', (e) {
          return (e as EdgeModel).copyWith(label: 'Updated');
        });

        expect(updated, true);
        expect(graph.getEdge('edge-1')?.label, 'Updated');
      });

      test('should return false when updating non-existent edge', () {
        final updated = graph.updateEdge('non-existent', (e) => e);
        expect(updated, false);
      });

      test('should remove edge', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        graph.addNode(node1);
        graph.addNode(node2);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );
        graph.addEdge(edge);

        final removed = graph.removeEdge('edge-1');

        expect(removed, isNotNull);
        expect(removed?.id, 'edge-1');
        expect(graph.edgeCount, 0);
      });

      test('should return null when removing non-existent edge', () {
        final removed = graph.removeEdge('non-existent');
        expect(removed, isNull);
      });
    });

    group('batch operations', () {
      test('should add multiple nodes', () {
        final nodes = [
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ];

        graph.addNodes(nodes);

        expect(graph.nodeCount, 3);
      });

      test('should remove multiple nodes', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ]);

        final result = graph.removeNodes(['node-1', 'node-3']);

        expect(result.nodes.length, 2);
        expect(graph.nodeCount, 1);
        expect(graph.hasNode('node-2'), true);
      });

      test('should add multiple edges', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ]);

        final edges = [
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'default',
          ),
          EdgeModel(
            id: 'edge-2',
            sourceAnchorId: 'node-2:right',
            targetAnchorId: 'node-3:left',
            type: 'default',
          ),
        ];

        graph.addEdges(edges);

        expect(graph.edgeCount, 2);
      });

      test('should remove multiple edges', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ]);

        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'default',
          ),
          EdgeModel(
            id: 'edge-2',
            sourceAnchorId: 'node-2:right',
            targetAnchorId: 'node-3:left',
            type: 'default',
          ),
          EdgeModel(
            id: 'edge-3',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-3:left',
            type: 'default',
          ),
        ]);

        final removed = graph.removeEdges(['edge-1', 'edge-3']);

        expect(removed.length, 2);
        expect(graph.edgeCount, 1);
      });
    });

    group('connection queries', () {
      setUp(() {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ]);

        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'default',
          ),
          EdgeModel(
            id: 'edge-2',
            sourceAnchorId: 'node-2:right',
            targetAnchorId: 'node-3:left',
            type: 'default',
          ),
          EdgeModel(
            id: 'edge-3',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-3:left',
            type: 'default',
          ),
        ]);
      });

      test('should get edges for node', () {
        final edges = graph.getEdgesForNode('node-1');
        expect(edges.length, 2);

        final edgeIds = edges.map((e) => e.id).toList();
        expect(edgeIds, containsAll(['edge-1', 'edge-3']));
      });

      test('should get outgoing edges', () {
        final edges = graph.getOutgoingEdges('node-1');
        expect(edges.length, 2);

        for (final edge in edges) {
          expect(edge.sourceNodeId, 'node-1');
        }
      });

      test('should get incoming edges', () {
        final edges = graph.getIncomingEdges('node-3');
        expect(edges.length, 2);

        for (final edge in edges) {
          expect(edge.targetNodeId, 'node-3');
        }
      });

      test('should get edges between nodes', () {
        final edges = graph.getEdgesBetween('node-1', 'node-2');
        expect(edges.length, 1);
        expect(edges.first.id, 'edge-1');
      });

      test('should check if nodes are connected', () {
        expect(graph.areNodesConnected('node-1', 'node-2'), true);
        expect(graph.areNodesConnected('node-2', 'node-3'), true);
        expect(graph.areNodesConnected('node-1', 'node-3'), true);
      });

      test('should get neighbors', () {
        final neighbors = graph.getNeighbors('node-1');
        expect(neighbors.length, 2);

        final neighborIds = neighbors.map((n) => n.id).toList();
        expect(neighborIds, containsAll(['node-2', 'node-3']));
      });

      test('should get edges for anchor', () {
        final edges = graph.getEdgesForAnchor('node-1:right');
        expect(edges.length, 2);
      });

      test('should get anchor connection count', () {
        expect(graph.getAnchorConnectionCount('node-1:right'), 2);
        expect(graph.getAnchorConnectionCount('node-2:left'), 1);
      });
    });

    group('change events', () {
      test('should emit NodeAddedEvent', () async {
        final events = <GraphChangeEvent>[];
        graph.onChange.listen(events.add);

        final node = NodeModel(id: 'node-1', type: 'test', title: 'Node');
        graph.addNode(node);

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first, isA<NodeAddedEvent>());
        expect((events.first as NodeAddedEvent).node, node);
      });

      test('should emit NodeUpdatedEvent', () async {
        final node = NodeModel(id: 'node-1', type: 'test', title: 'Original');
        graph.addNode(node);

        final events = <GraphChangeEvent>[];
        graph.onChange.listen(events.add);

        graph.updateNode('node-1', (n) => (n as NodeModel).copyWith(title: 'Updated'));

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first, isA<NodeUpdatedEvent>());
        final event = events.first as NodeUpdatedEvent;
        expect(event.oldNode.title, 'Original');
        expect(event.newNode.title, 'Updated');
      });

      test('should emit NodeRemovedEvent', () async {
        final node = NodeModel(id: 'node-1', type: 'test', title: 'Node');
        graph.addNode(node);

        final events = <GraphChangeEvent>[];
        graph.onChange.listen(events.add);

        graph.removeNode('node-1');

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first, isA<NodeRemovedEvent>());
        expect((events.first as NodeRemovedEvent).node, node);
      });

      test('should emit EdgeAddedEvent', () async {
        graph.addNode(NodeModel(id: 'node-1', type: 'test', title: 'Node 1'));
        graph.addNode(NodeModel(id: 'node-2', type: 'test', title: 'Node 2'));

        final events = <GraphChangeEvent>[];
        graph.onChange.listen(events.add);

        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );
        graph.addEdge(edge);

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first, isA<EdgeAddedEvent>());
        expect((events.first as EdgeAddedEvent).edge, edge);
      });

      test('should emit BatchChangeEvent for batch operations', () async {
        final events = <GraphChangeEvent>[];
        graph.onChange.listen(events.add);

        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
        ]);

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first, isA<BatchChangeEvent>());
        final batch = events.first as BatchChangeEvent;
        expect(batch.events.length, 2);
      });
    });

    group('import/export', () {
      test('should export data', () {
        graph.addNode(NodeModel(id: 'node-1', type: 'test', title: 'Node 1'));
        graph.addNode(NodeModel(id: 'node-2', type: 'test', title: 'Node 2'));

        final data = graph.export();

        expect(data.nodes.length, 2);
        expect(data.edges.isEmpty, true);
      });

      test('should import data', () {
        final node1 = NodeModel(id: 'node-1', type: 'test', title: 'Node 1');
        final node2 = NodeModel(id: 'node-2', type: 'test', title: 'Node 2');
        final edge = EdgeModel(
          id: 'edge-1',
          sourceAnchorId: 'node-1:right',
          targetAnchorId: 'node-2:left',
          type: 'default',
        );

        final data = GraphData(
          nodes: {'node-1': node1, 'node-2': node2},
          edges: {'edge-1': edge},
        );

        graph.import(data);

        expect(graph.nodeCount, 2);
        expect(graph.edgeCount, 1);
      });

      test('should import without clearing', () {
        graph.addNode(NodeModel(id: 'existing', type: 'test', title: 'Existing'));

        final newNode = NodeModel(id: 'new', type: 'test', title: 'New');
        graph.import(
          GraphData(nodes: {'new': newNode}, edges: {}),
          clear: false,
        );

        expect(graph.nodeCount, 2);
        expect(graph.hasNode('existing'), true);
        expect(graph.hasNode('new'), true);
      });

      test('should copy from another model', () {
        final other = GraphModel();
        other.addNode(NodeModel(id: 'node-1', type: 'test', title: 'Node 1'));

        graph.copyFrom(other);

        expect(graph.nodeCount, 1);
        expect(graph.hasNode('node-1'), true);

        other.dispose();
      });
    });

    group('clear', () {
      test('should clear all nodes and edges', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
        ]);

        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'default',
          ),
        ]);

        graph.clear();

        expect(graph.nodeCount, 0);
        expect(graph.edgeCount, 0);
      });
    });

    group('GraphModelExtension', () {
      test('should find nodes by predicate', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'type-a', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'type-b', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'type-a', title: 'Node 3'),
        ]);

        final found = graph.findNodes((n) => n.type == 'type-a');

        expect(found.length, 2);
        expect(found.map((n) => n.id), containsAll(['node-1', 'node-3']));
      });

      test('should find edges by predicate', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
          NodeModel(id: 'node-3', type: 'test', title: 'Node 3'),
        ]);

        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'type-a',
          ),
          EdgeModel(
            id: 'edge-2',
            sourceAnchorId: 'node-2:right',
            targetAnchorId: 'node-3:left',
            type: 'type-b',
          ),
        ]);

        final found = graph.findEdges((e) => e.type == 'type-a');

        expect(found.length, 1);
        expect(found.first.id, 'edge-1');
      });

      test('should get node and edge ids', () {
        graph.addNode(NodeModel(id: 'node-1', type: 'test', title: 'Node'));
        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-1:left',
            type: 'default',
          ),
        ], validateNodes: false);

        expect(graph.nodeIds, {'node-1'});
        expect(graph.edgeIds, {'edge-1'});
      });

      test('should calculate content bounds', () {
        graph.addNodes([
          NodeModel(
            id: 'node-1',
            type: 'test',
            title: 'Node 1',
            position: const Offset(0, 0),
            size: const Size(100, 60),
          ),
          NodeModel(
            id: 'node-2',
            type: 'test',
            title: 'Node 2',
            position: const Offset(200, 100),
            size: const Size(100, 60),
          ),
        ]);

        final bounds = graph.calculateContentBounds(padding: 0);

        expect(bounds.left, 0);
        expect(bounds.top, 0);
        expect(bounds.right, 300);
        expect(bounds.bottom, 160);
      });

      test('should return zero bounds for empty graph', () {
        final bounds = graph.calculateContentBounds();
        expect(bounds, Rect.zero);
      });

      test('should get stats', () {
        graph.addNodes([
          NodeModel(id: 'node-1', type: 'test', title: 'Node 1'),
          NodeModel(id: 'node-2', type: 'test', title: 'Node 2'),
        ]);

        graph.addEdges([
          EdgeModel(
            id: 'edge-1',
            sourceAnchorId: 'node-1:right',
            targetAnchorId: 'node-2:left',
            type: 'default',
          ),
        ]);

        final stats = graph.stats;

        expect(stats.nodeCount, 2);
        expect(stats.edgeCount, 1);
        expect(stats.avgConnectionsPerNode, closeTo(1.0, 0.01));
      });
    });
  });

  group('GraphData', () {
    test('should create empty data', () {
      expect(GraphData.empty.isEmpty, true);
      expect(GraphData.empty.nodes.isEmpty, true);
      expect(GraphData.empty.edges.isEmpty, true);
    });

    test('should check isEmpty and isNotEmpty', () {
      final empty = GraphData(nodes: {}, edges: {});
      expect(empty.isEmpty, true);
      expect(empty.isNotEmpty, false);

      final withNodes = GraphData(
        nodes: {'id': NodeModel(id: 'id', type: 'test', title: 'Node')},
        edges: {},
      );
      expect(withNodes.isEmpty, false);
      expect(withNodes.isNotEmpty, true);
    });
  });

  group('RemoveNodeResult', () {
    test('should create not found result', () {
      const result = RemoveNodeResult.notFound();

      expect(result.found, false);
      expect(result.node, isNull);
      expect(result.removedEdges.isEmpty, true);
    });

    test('should create result with node and edges', () {
      final node = NodeModel(id: 'node-1', type: 'test', title: 'Node');
      final edge = EdgeModel(
        id: 'edge-1',
        sourceAnchorId: 'node-1:right',
        targetAnchorId: 'node-2:left',
        type: 'default',
      );

      final result = RemoveNodeResult(node: node, removedEdges: [edge]);

      expect(result.found, true);
      expect(result.node, node);
      expect(result.removedEdges.length, 1);
    });
  });

  group('BatchRemoveResult', () {
    test('should create with nodes and edges', () {
      final node = NodeModel(id: 'node-1', type: 'test', title: 'Node');
      final edge = EdgeModel(
        id: 'edge-1',
        sourceAnchorId: 'node-1:right',
        targetAnchorId: 'node-2:left',
        type: 'default',
      );

      final result = BatchRemoveResult(nodes: [node], edges: [edge]);

      expect(result.nodes.length, 1);
      expect(result.edges.length, 1);
    });
  });

  group('GraphStats', () {
    test('should calculate avgConnectionsPerNode', () {
      const stats = GraphStats(
        nodeCount: 4,
        edgeCount: 3,
        anchorConnectionCounts: {},
      );

      // avg = (3 edges * 2 endpoints) / 4 nodes = 1.5
      expect(stats.avgConnectionsPerNode, closeTo(1.5, 0.01));
    });

    test('should handle zero nodes', () {
      const stats = GraphStats(
        nodeCount: 0,
        edgeCount: 0,
        anchorConnectionCounts: {},
      );

      expect(stats.avgConnectionsPerNode, 0);
    });

    test('should calculate maxAnchorConnections', () {
      const stats = GraphStats(
        nodeCount: 2,
        edgeCount: 3,
        anchorConnectionCounts: {'a1': 2, 'a2': 5, 'a3': 1},
      );

      expect(stats.maxAnchorConnections, 5);
    });
  });

  group('TransformModel', () {
    group('construction', () {
      test('should create with default values', () {
        const transform = TransformModel();

        expect(transform.zoom, 1.0);
        expect(transform.panOffset, Offset.zero);
        expect(transform.minZoom, 0.1);
        expect(transform.maxZoom, 5.0);
      });

      test('should create with custom values', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(100, 50),
          minZoom: 0.2,
          maxZoom: 10.0,
        );

        expect(transform.zoom, 2.0);
        expect(transform.panOffset, const Offset(100, 50));
        expect(transform.minZoom, 0.2);
        expect(transform.maxZoom, 10.0);
      });

      test('should have identity constant', () {
        expect(TransformModel.identity.zoom, 1.0);
        expect(TransformModel.identity.panOffset, Offset.zero);
        expect(TransformModel.identity.isIdentity, true);
      });

      test('should detect identity', () {
        expect(const TransformModel().isIdentity, true);
        expect(const TransformModel(zoom: 2.0).isIdentity, false);
        expect(const TransformModel(panOffset: Offset(10, 10)).isIdentity, false);
      });
    });

    group('coordinate conversion', () {
      test('should convert scene to screen', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(100, 50),
        );

        // screen = scene * zoom + panOffset
        // (50, 25) * 2 + (100, 50) = (200, 100)
        final screen = transform.toScreen(const Offset(50, 25));

        expect(screen.dx, 200);
        expect(screen.dy, 100);
      });

      test('should convert screen to scene', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(100, 50),
        );

        // scene = (screen - panOffset) / zoom
        // (200, 100) - (100, 50) = (100, 50) / 2 = (50, 25)
        final scene = transform.toScene(const Offset(200, 100));

        expect(scene.dx, 50);
        expect(scene.dy, 25);
      });

      test('should be inverse operations', () {
        const transform = TransformModel(
          zoom: 1.5,
          panOffset: Offset(30, 40),
        );

        const originalScene = Offset(100, 200);
        final screen = transform.toScreen(originalScene);
        final backToScene = transform.toScene(screen);

        expect(backToScene.dx, closeTo(originalScene.dx, 0.001));
        expect(backToScene.dy, closeTo(originalScene.dy, 0.001));
      });

      test('should scale size', () {
        const transform = TransformModel(zoom: 2.0);
        const size = Size(100, 50);

        final scaled = transform.scaleSize(size);

        expect(scaled.width, 200);
        expect(scaled.height, 100);
      });

      test('should scale distance', () {
        const transform = TransformModel(zoom: 2.0);

        expect(transform.scaleDistance(100), 200);
        expect(transform.unscaleDistance(200), 100);
      });

      test('should convert rectangles', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(10, 20),
        );

        const sceneRect = Rect.fromLTWH(0, 0, 100, 50);
        final screenRect = transform.toScreenRect(sceneRect);

        expect(screenRect.left, 10);
        expect(screenRect.top, 20);
        expect(screenRect.width, 200);
        expect(screenRect.height, 100);

        final backToScene = transform.toSceneRect(screenRect);
        expect(backToScene.left, closeTo(sceneRect.left, 0.001));
        expect(backToScene.top, closeTo(sceneRect.top, 0.001));
        expect(backToScene.width, closeTo(sceneRect.width, 0.001));
        expect(backToScene.height, closeTo(sceneRect.height, 0.001));
      });
    });

    group('transform operations', () {
      test('should pan by delta', () {
        const transform = TransformModel(panOffset: Offset(100, 50));
        final panned = transform.pan(const Offset(10, 20));

        expect(panned.panOffset, const Offset(110, 70));
        expect(panned.zoom, 1.0);
      });

      test('should set pan offset', () {
        const transform = TransformModel(panOffset: Offset(100, 50));
        final newTransform = transform.withPanOffset(const Offset(200, 100));

        expect(newTransform.panOffset, const Offset(200, 100));
        expect(newTransform.zoom, 1.0);
      });

      test('should zoom to level with center', () {
        const transform = TransformModel(
          zoom: 1.0,
          panOffset: Offset(100, 100),
        );

        // Zoom to 2x at center (200, 200)
        final zoomed = transform.zoomTo(2.0, const Offset(200, 200));

        expect(zoomed.zoom, 2.0);
        // Center point should remain at same screen position
        final centerScene = zoomed.toScene(const Offset(200, 200));
        final originalCenterScene = transform.toScene(const Offset(200, 200));
        expect(centerScene.dx, closeTo(originalCenterScene.dx, 0.001));
        expect(centerScene.dy, closeTo(originalCenterScene.dy, 0.001));
      });

      test('should clamp zoom to min/max', () {
        const transform = TransformModel(minZoom: 0.5, maxZoom: 3.0);

        expect(transform.zoomTo(0.1, Offset.zero).zoom, 0.5);
        expect(transform.zoomTo(5.0, Offset.zero).zoom, 3.0);
      });

      test('should return same transform when zoom unchanged', () {
        const transform = TransformModel(zoom: 2.0);
        final result = transform.zoomTo(2.0, const Offset(100, 100));

        expect(identical(result, transform), true);
      });

      test('should zoom by factor with viewport center', () {
        const transform = TransformModel(zoom: 1.0);
        const viewportSize = Size(800, 600);

        final zoomed = transform.zoomBy(2.0, viewportSize);

        expect(zoomed.zoom, 2.0);
      });

      test('should set zoom with viewport center', () {
        const transform = TransformModel(zoom: 1.0);
        const viewportSize = Size(800, 600);

        final newTransform = transform.withZoom(2.0, viewportSize);

        expect(newTransform.zoom, 2.0);
      });

      test('should set zoom range', () {
        const transform = TransformModel(zoom: 2.0);
        final constrained = transform.withZoomRange(0.5, 3.0);

        expect(constrained.minZoom, 0.5);
        expect(constrained.maxZoom, 3.0);
      });

      test('should clamp zoom when setting range', () {
        const transform = TransformModel(zoom: 5.0);
        final constrained = transform.withZoomRange(0.5, 3.0);

        expect(constrained.zoom, 3.0);
      });
    });

    group('view fitting', () {
      test('should fit content to viewport', () {
        const contentBounds = Rect.fromLTWH(0, 0, 400, 300);
        const viewportSize = Size(800, 600);
        const padding = 50.0;

        final transform = const TransformModel().fitContent(
          contentBounds,
          viewportSize,
          padding: padding,
        );

        // Content width with padding: 400 + 50*2 = 500
        // Content height with padding: 300 + 50*2 = 400
        // scaleX = 800/500 = 1.6, scaleY = 600/400 = 1.5
        // Uses min scale to fit: 1.5
        expect(transform.zoom, 1.5);
      });

      test('should respect min/max zoom when fitting', () {
        const contentBounds = Rect.fromLTWH(0, 0, 10000, 10000);
        const viewportSize = Size(800, 600);

        final transform = const TransformModel(minZoom: 0.5, maxZoom: 3.0)
            .fitContent(contentBounds, viewportSize);

        // Would be 800/10000 = 0.08, clamped to 0.5
        expect(transform.zoom, 0.5);
      });

      test('should return identity for zero bounds', () {
        final transform = const TransformModel().fitContent(Rect.zero, const Size(800, 600));

        expect(transform.isIdentity, true);
      });

      test('should return identity for zero viewport', () {
        const contentBounds = Rect.fromLTWH(0, 0, 400, 300);
        final transform = const TransformModel().fitContent(contentBounds, Size.zero);

        expect(transform.isIdentity, true);
      });

      test('should center on scene point', () {
        const viewportSize = Size(800, 600);
        const scenePoint = Offset(100, 200);
        const zoom = 2.0;

        final transform = const TransformModel(zoom: zoom).centerOn(scenePoint, viewportSize);

        // The scene point should be at viewport center
        final screenCenter = transform.toScreen(scenePoint);
        expect(screenCenter.dx, closeTo(viewportSize.width / 2, 0.001));
        expect(screenCenter.dy, closeTo(viewportSize.height / 2, 0.001));
      });

      test('should reset to identity', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(100, 100),
        );

        final reset = transform.reset();

        expect(reset.zoom, 1.0);
        expect(reset.panOffset, Offset.zero);
        expect(reset.minZoom, transform.minZoom);
        expect(reset.maxZoom, transform.maxZoom);
      });
    });

    group('matrix conversion', () {
      test('should convert to Matrix4', () {
        const transform = TransformModel(
          zoom: 2.0,
          panOffset: Offset(100, 50),
        );

        final matrix = transform.toMatrix4();

        // Verify the matrix values
        expect(matrix.entry(0, 0), 2.0); // scale X
        expect(matrix.entry(1, 1), 2.0); // scale Y
        expect(matrix.entry(0, 3), 100); // translate X
        expect(matrix.entry(1, 3), 50); // translate Y
      });

      test('should create from Matrix4', () {
        final matrix = Matrix4.identity()
          ..translate(100.0, 50.0)
          ..scale(2.0, 2.0);

        final transform = TransformModel.fromMatrix4(matrix);

        expect(transform.zoom, 2.0);
        expect(transform.panOffset.dx, closeTo(100, 0.001));
        expect(transform.panOffset.dy, closeTo(50, 0.001));
      });

      test('should clamp zoom when creating from Matrix4', () {
        final matrix = Matrix4.identity()..scale(10.0, 10.0);

        final transform = TransformModel.fromMatrix4(
          matrix,
          minZoom: 0.5,
          maxZoom: 5.0,
        );

        expect(transform.zoom, 5.0);
      });
    });

    group('interpolation', () {
      test('should lerp between transforms', () {
        const a = TransformModel(zoom: 1.0, panOffset: Offset(0, 0));
        const b = TransformModel(zoom: 2.0, panOffset: Offset(100, 100));

        final mid = TransformModel.lerp(a, b, 0.5);

        expect(mid.zoom, 1.5);
        expect(mid.panOffset.dx, 50);
        expect(mid.panOffset.dy, 50);
      });

      test('should return a when t <= 0', () {
        const a = TransformModel(zoom: 1.0);
        const b = TransformModel(zoom: 2.0);

        expect(TransformModel.lerp(a, b, 0).zoom, 1.0);
        expect(TransformModel.lerp(a, b, -0.5).zoom, 1.0);
      });

      test('should return b when t >= 1', () {
        const a = TransformModel(zoom: 1.0);
        const b = TransformModel(zoom: 2.0);

        expect(TransformModel.lerp(a, b, 1).zoom, 2.0);
        expect(TransformModel.lerp(a, b, 1.5).zoom, 2.0);
      });
    });

    group('copy and equality', () {
      test('should copy with new values', () {
        const original = TransformModel(zoom: 1.0, panOffset: Offset(0, 0));
        final copy = original.copyWith(zoom: 2.0, panOffset: const Offset(100, 50));

        expect(copy.zoom, 2.0);
        expect(copy.panOffset, const Offset(100, 50));
        expect(copy.minZoom, original.minZoom);
        expect(copy.maxZoom, original.maxZoom);
      });

      test('should compare equality', () {
        const a = TransformModel(zoom: 2.0, panOffset: Offset(100, 50));
        const b = TransformModel(zoom: 2.0, panOffset: Offset(100, 50));
        const c = TransformModel(zoom: 2.0, panOffset: Offset(100, 51));

        expect(a == b, true);
        expect(a == c, false);
      });

      test('should compare with identical', () {
        const a = TransformModel();
        expect(a == a, true);
      });

      test('should have consistent hashCode', () {
        const a = TransformModel(zoom: 2.0, panOffset: Offset(100, 50));
        const b = TransformModel(zoom: 2.0, panOffset: Offset(100, 50));

        expect(a.hashCode, b.hashCode);
      });

      test('should have toString', () {
        const transform = TransformModel(zoom: 2.0, panOffset: Offset(100, 50));
        final str = transform.toString();

        expect(str, contains('TransformModel'));
        expect(str, contains('2.00'));
        expect(str, contains('Offset'));
      });
    });
  });

  group('TransformConstraints', () {
    test('should create with default values', () {
      const constraints = TransformConstraints();

      expect(constraints.minZoom, 0.1);
      expect(constraints.maxZoom, 5.0);
      expect(constraints.panBounds, isNull);
    });

    test('should have static constants', () {
      expect(TransformConstraints.unconstrained.minZoom, 0.1);
      expect(TransformConstraints.defaults.minZoom, 0.1);
    });

    test('should constrain transform zoom', () {
      const constraints = TransformConstraints(minZoom: 0.5, maxZoom: 3.0);
      const transform = TransformModel(zoom: 5.0);

      final constrained = constraints.constrain(transform);

      expect(constrained.zoom, 3.0);
    });

    test('should constrain pan when panBounds set', () {
      const constraints = TransformConstraints(
        panBounds: Rect.fromLTWH(0, 0, 1000, 1000),
      );
      const transform = TransformModel(
        panOffset: Offset(-100, -100),
        zoom: 1.0,
      );

      final constrained = constraints.constrain(transform);

      // With zoom 1.0 and panOffset (-100, -100), the sceneTopLeft would be (-100, -100)
      // which is outside bounds (0, 0) to (1000, 1000), so it should be clamped
      // The constrain method adjusts panOffset to keep viewport within bounds
      expect(constrained.panOffset.dx >= -100, true);
      expect(constrained.panOffset.dy >= -100, true);
    });
  });
}
