import 'package:flutter/material.dart';

import '../../domain/models/transaction_category.dart';

/// Resolves the accent color used to represent a category in charts/legends
/// (e.g. the dashboard's category donut).
abstract final class CategoryColors {
  CategoryColors._();

  /// Deterministic fallback hues used when a category has no (valid)
  /// [TransactionCategory.colorHex]. Colorblind-safe order validated with the
  /// `dataviz` skill (worst adjacent CVD ΔE 16.2 @ deuteranopia); indexed by
  /// slice position — not by category id — so a category's color stays
  /// stable relative to its neighbors in a given chart.
  static const List<Color> _fallbackPalette = [
    Color(0xFF3082FF), // blue
    Color(0xFFFF8B3D), // orange
    Color(0xFF00D09C), // mint
    Color(0xFFFF5A79), // coral
    Color(0xFF7C5CFC), // violet
    Color(0xFF1BAF7A), // teal
    Color(0xFFD99400), // amber
    Color(0xFFE8598A), // pink
  ];

  /// The color for [category] at [index] (its position within the chart/list
  /// being rendered). Prefers the category's own [TransactionCategory.colorHex];
  /// falls back to a stable palette slot otherwise.
  static Color forCategory(TransactionCategory? category, int index) {
    final parsed = _tryParseHex(category?.colorHex);
    if (parsed != null) return parsed;
    return _fallbackPalette[index % _fallbackPalette.length];
  }

  static Color? _tryParseHex(String? hex) {
    if (hex == null) return null;
    final digits = hex.replaceFirst('#', '');
    if (digits.length != 6) return null;
    final value = int.tryParse(digits, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
