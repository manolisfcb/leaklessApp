import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Diffuse, soft shadows that make glass surfaces float above the background.
abstract final class AppShadows {
  AppShadows._();

  /// Resting elevation for glass cards.
  static List<BoxShadow> card(AppColors colors) => [
    BoxShadow(
      color: colors.shadow,
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];

  /// Stronger lift for floating elements (FAB, bottom sheets).
  static List<BoxShadow> floating(AppColors colors) => [
    BoxShadow(
      color: colors.shadow,
      blurRadius: 36,
      spreadRadius: -6,
      offset: const Offset(0, 18),
    ),
  ];

  /// Colored glow used to draw attention (e.g. alert borders).
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.45),
      blurRadius: 24,
      spreadRadius: -2,
    ),
  ];
}
