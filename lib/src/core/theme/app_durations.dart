import 'package:flutter/animation.dart';

/// Animation timings & curves. Subtle, fluid motion is part of the brand.
abstract final class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);

  /// Slow, organic ripple used by the liquid indicators.
  static const Duration liquid = Duration(milliseconds: 2200);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;
}
