import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import '../painters/node_painter.dart';
import '../providers/graph_provider.dart';

/// Image export service for ER diagrams
class ERDiagramExporter {
  /// Export ER diagram to PNG file
  static Future<ExportResult> exportToPNG({
    required ERGraphState graphState,
    required BuildContext context,
    required bool isDarkMode,
    double padding = 50.0,
    int pixelRatio = 2,
    String? outputPath,
  }) async {
    try {
      // Calculate bounds for export
      final bounds = _calculateExportBounds(graphState, padding);

      // Create recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Set up background
      final bgPaint = Paint()
        ..color = isDarkMode ? const Color(0xFF1A202C) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, bounds.width, bounds.height), bgPaint);

      // Draw nodes
      _drawNodesForExport(canvas, graphState, bounds, isDarkMode);

      // Draw edges
      _drawEdgesForExport(canvas, graphState, bounds, isDarkMode);

      // Create image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (bounds.width * pixelRatio).toInt(),
        (bounds.height * pixelRatio).toInt(),
      );

      // Get byte data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return ExportResult.error('Failed to generate image data');
      }

      // Prompt for save location if not provided
      String? targetPath = outputPath;
      if (targetPath == null) {
        targetPath = await _promptSavePath();
        if (targetPath == null) {
          return ExportResult.cancelled();
        }
      }

      // Write file
      final file = File(targetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return ExportResult.success(path: targetPath);
    } catch (e) {
      return ExportResult.error('Export failed: $e');
    }
  }

  /// Export to memory (for preview or clipboard)
  static Future<Uint8List?> exportToBytes({
    required ERGraphState graphState,
    required bool isDarkMode,
    double padding = 50.0,
    int pixelRatio = 2,
  }) async {
    try {
      final bounds = _calculateExportBounds(graphState, padding);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Set up background
      final bgPaint = Paint()
        ..color = isDarkMode ? const Color(0xFF1A202C) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, bounds.width, bounds.height), bgPaint);

      // Draw nodes and edges
      _drawNodesForExport(canvas, graphState, bounds, isDarkMode);
      _drawEdgesForExport(canvas, graphState, bounds, isDarkMode);

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (bounds.width * pixelRatio).toInt(),
        (bounds.height * pixelRatio).toInt(),
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Export from a RepaintBoundary widget
  static Future<ExportResult> exportFromWidget({
    required GlobalKey repaintKey,
    String? outputPath,
    int pixelRatio = 2,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        return ExportResult.error('Could not find render object');
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return ExportResult.error('Failed to generate image data');
      }

      // Prompt for save location if not provided
      String? targetPath = outputPath;
      if (targetPath == null) {
        targetPath = await _promptSavePath();
        if (targetPath == null) {
          return ExportResult.cancelled();
        }
      }

      // Write file
      final file = File(targetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return ExportResult.success(path: targetPath);
    } catch (e) {
      return ExportResult.error('Export failed: $e');
    }
  }

  /// Calculate bounds for export
  static Size _calculateExportBounds(ERGraphState graphState, double padding) {
    if (graphState.nodes.isEmpty) {
      return Size(400 + padding * 2, 300 + padding * 2);
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in graphState.nodes) {
      final entity = node.entity;
      final size = entity != null
          ? NodePainter.calculateNodeSize(entity)
          : const Size(NodePainter.defaultWidth, NodePainter.minHeight);

      minX = math.min(minX, node.x);
      minY = math.min(minY, node.y);
      maxX = math.max(maxX, node.x + size.width);
      maxY = math.max(maxY, node.y + size.height);
    }

    // Add padding
    final width = maxX - minX + padding * 2;
    final height = maxY - minY + padding * 2;

    // Minimum size
    return Size(math.max(400, width), math.max(300, height));
  }

  /// Draw nodes for export
  static void _drawNodesForExport(
    Canvas canvas,
    ERGraphState graphState,
    Size bounds,
    bool isDarkMode,
  ) {
    if (graphState.nodes.isEmpty) return;

    // Calculate min values
    double minX = double.infinity;
    double minY = double.infinity;

    for (final node in graphState.nodes) {
      minX = math.min(minX, node.x);
      minY = math.min(minY, node.y);
    }

    for (final node in graphState.nodes) {
      final adjustedNode = node.copyWith(
        data: node.data.copyWith(x: node.x - minX + 50, y: node.y - minY + 50),
      );

      NodePainter.paint(
        canvas: canvas,
        node: adjustedNode,
        scale: 1.0,
        isDarkMode: isDarkMode,
      );
    }
  }

  /// Draw edges for export
  static void _drawEdgesForExport(
    Canvas canvas,
    ERGraphState graphState,
    Size bounds,
    bool isDarkMode,
  ) {
    if (graphState.nodes.isEmpty) return;

    // Calculate min values
    double minX = double.infinity;
    double minY = double.infinity;

    for (final node in graphState.nodes) {
      minX = math.min(minX, node.x);
      minY = math.min(minY, node.y);
    }

    for (final edge in graphState.edges) {
      final sourceNode = graphState.getNode(edge.source);
      final targetNode = graphState.getNode(edge.target);

      if (sourceNode == null || targetNode == null) continue;

      final adjustedSourceNode = sourceNode.copyWith(
        data: sourceNode.data.copyWith(x: sourceNode.x - minX + 50, y: sourceNode.y - minY + 50),
      );

      final adjustedTargetNode = targetNode.copyWith(
        data: targetNode.data.copyWith(x: targetNode.x - minX + 50, y: targetNode.y - minY + 50),
      );

      _drawExportEdge(
        canvas,
        adjustedSourceNode,
        adjustedTargetNode,
        isDarkMode,
      );
    }
  }

  /// Draw single edge for export
  static void _drawExportEdge(
    Canvas canvas,
    ERGraphNode sourceNode,
    ERGraphNode targetNode,
    bool isDarkMode,
  ) {
    final sourceRect = NodePainter.getNodeRect(sourceNode);
    final targetRect = NodePainter.getNodeRect(targetNode);

    final sourceCenter = sourceRect.center;
    final targetCenter = targetRect.center;

    // Calculate edge points
    final dx = targetCenter.dx - sourceCenter.dx;
    final dy = targetCenter.dy - sourceCenter.dy;

    double t;
    if (dx.abs() * (targetRect.height / 2) > dy.abs() * (targetRect.width / 2)) {
      t = (targetRect.width / 2) / dx.abs();
    } else {
      t = (targetRect.height / 2) / dy.abs();
    }

    final sourcePoint = Offset(
      sourceCenter.dx + dx * t,
      sourceCenter.dy + dy * t,
    );
    final targetPoint = Offset(
      targetCenter.dx - dx * t,
      targetCenter.dy - dy * t,
    );

    // Draw line
    final linePaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(sourcePoint, targetPoint, linePaint);

    // Draw arrow
    final arrowSize = 10.0;
    final angle = math.atan2(targetPoint.dy - sourcePoint.dy, targetPoint.dx - sourcePoint.dx);

    final arrowPath = Path();
    arrowPath.moveTo(targetPoint.dx, targetPoint.dy);
    arrowPath.lineTo(
      targetPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
      targetPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(
      targetPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
      targetPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  /// Prompt user for save location
  static Future<String?> _promptSavePath() async {
    final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['png'],
      dialogTitle: 'Export ER Diagram',
      fileName: 'er_diagram.png',
    );
    return result;
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final bool cancelled;
  final String? path;
  final String? error;

  ExportResult._({
    required this.success,
    this.cancelled = false,
    this.path,
    this.error,
  });

  factory ExportResult.success({required String path}) {
    return ExportResult._(success: true, path: path);
  }

  factory ExportResult.error(String error) {
    return ExportResult._(success: false, error: error);
  }

  factory ExportResult.cancelled() {
    return ExportResult._(success: false, cancelled: true);
  }
}
