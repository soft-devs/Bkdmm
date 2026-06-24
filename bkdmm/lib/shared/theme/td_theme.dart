import 'package:flutter/material.dart';

/// Theme colors for diagram editors.
///
/// Provides consistent color values for light and dark modes
/// across all diagram types (ER diagrams, flowcharts, etc.)
class TDAppTheme {
  TDAppTheme._();

  // Node header colors
  static const Color _nodeHeaderLight = Color(0xFF1976D2);
  static const Color _nodeHeaderDark = Color(0xFF2563EB);

  // Node background colors
  static const Color _nodeBgLight = Colors.white;
  static const Color _nodeBgSelectedLight = Color(0xFFE3F2FD);
  static const Color _nodeBgDark = Color(0xFF2D3748);
  static const Color _nodeBgSelectedDark = Color(0xFF1E3A5F);

  // Edge colors
  static const Color _edgeLight = Color(0xFF757575);
  static const Color _edgeDark = Color(0xFFBDBDBD);

  // Selection border colors
  static const Color _selectionBorderLight = Color(0xFF2196F3);
  static const Color _selectionBorderDark = Color(0xFF64B5F6);

  // Highlight border color
  static const Color _highlightBorder = Color(0xFFFFA726);

  // Anchor colors
  static const Color _anchorPrimary = Color(0xFFFFB300);
  static const Color _anchorNormal = Color(0xFF4CAF50);

  // Grid colors
  static const Color _gridLight = Color(0xFFE0E0E0);
  static const Color _gridDark = Color(0xFF424242);

  /// Gets the node header color for the current theme mode.
  static Color getNodeHeaderColor(bool isDark) {
    return isDark ? _nodeHeaderDark : _nodeHeaderLight;
  }

  /// Gets the node background color for the current theme mode.
  ///
  /// [isDark] - Whether dark mode is active
  /// [isSelected] - Whether the node is selected
  static Color getNodeBgColor(bool isDark, bool isSelected) {
    if (isDark) {
      return isSelected ? _nodeBgSelectedDark : _nodeBgDark;
    }
    return isSelected ? _nodeBgSelectedLight : _nodeBgLight;
  }

  /// Gets the edge color for the current theme mode.
  static Color getEdgeColor(bool isDark) {
    return isDark ? _edgeDark : _edgeLight;
  }

  /// Gets the selection border color for the current theme mode.
  static Color getSelectionBorderColor(bool isDark) {
    return isDark ? _selectionBorderDark : _selectionBorderLight;
  }

  /// Gets the highlight border color.
  static Color getHighlightBorderColor() {
    return _highlightBorder;
  }

  /// Gets the anchor color based on whether it's a primary key.
  ///
  /// [isPrimaryKey] - Whether the anchor represents a primary key field
  static Color getAnchorColor(bool isPrimaryKey) {
    return isPrimaryKey ? _anchorPrimary : _anchorNormal;
  }

  /// Gets the grid color for the current theme mode.
  static Color getGridColor(bool isDark) {
    return isDark ? _gridDark : _gridLight;
  }
}
