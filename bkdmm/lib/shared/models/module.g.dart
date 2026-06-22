// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) => Module(
      id: json['id'] as String,
      name: json['name'] as String,
      chnname: json['chnname'] as String,
      description: json['description'] as String?,
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => Entity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      graphCanvas:
          GraphCanvas.fromJson(json['graphCanvas'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'chnname': instance.chnname,
      'description': instance.description,
      'entities': instance.entities,
      'graphCanvas': instance.graphCanvas,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

GraphCanvas _$GraphCanvasFromJson(Map<String, dynamic> json) => GraphCanvas(
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => GraphNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      viewport: json['viewport'] == null
          ? null
          : Viewport.fromJson(json['viewport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GraphCanvasToJson(GraphCanvas instance) =>
    <String, dynamic>{
      'nodes': instance.nodes,
      'edges': instance.edges,
      'viewport': instance.viewport,
    };

GraphNode _$GraphNodeFromJson(Map<String, dynamic> json) => GraphNode(
      title: json['title'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      moduleName: json['moduleName'] as String?,
    );

Map<String, dynamic> _$GraphNodeToJson(GraphNode instance) => <String, dynamic>{
      'title': instance.title,
      'x': instance.x,
      'y': instance.y,
      'moduleName': instance.moduleName,
    };

GraphEdge _$GraphEdgeFromJson(Map<String, dynamic> json) => GraphEdge(
      source: json['source'] as String,
      target: json['target'] as String,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$GraphEdgeToJson(GraphEdge instance) => <String, dynamic>{
      'source': instance.source,
      'target': instance.target,
      'label': instance.label,
    };

Viewport _$ViewportFromJson(Map<String, dynamic> json) => Viewport(
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$ViewportToJson(Viewport instance) => <String, dynamic>{
      'scale': instance.scale,
      'offsetX': instance.offsetX,
      'offsetY': instance.offsetY,
    };
