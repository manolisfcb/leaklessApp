import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Organic gradients used across the Liquid Glass UI.
abstract final class AppGradients {
  AppGradients._();

  /// Full-screen background wash behind the frosted glass.
  static LinearGradient background(AppColors colors) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [colors.backgroundTop, colors.backgroundBottom],
  );

  /// The blue→green "liquid" used inside the hydrometer and progress fills.
  static LinearGradient liquid(AppColors colors) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [colors.goal, colors.income],
  );

  /// Refraction sheen across the top of a glass surface.
  static LinearGradient glassSheen(AppColors colors) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colors.glassHighlight, colors.glassFill],
    stops: const [0.0, 0.6],
  );

  /// A soft fill gradient for one of the four accent colors.
  static LinearGradient accent(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, const Color(0xFFFFFFFF), 0.25)!],
  );
}
