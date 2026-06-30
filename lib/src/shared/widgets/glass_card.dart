import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A frosted "liquid glass" surface: a translucent fill over a real backdrop
/// blur, a refraction border and a diffuse shadow.
///
/// This is the visual primitive every other card-like surface is built on, so
/// the glass look stays consistent app-wide (quality rule #2/#14).
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.borderRadius = AppRadii.cardRadius,
    this.blur = 25,
    this.strong = false,
    this.onTap,
    this.borderColor,
    this.gradientGlow,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Backdrop blur sigma. 25 matches the design's `backdrop-filter: blur(25px)`.
  final double blur;

  /// Use the more opaque fill for surfaces that need stronger contrast.
  final bool strong;

  final VoidCallback? onTap;

  /// Overrides the default refraction border (e.g. amber when a budget warns).
  final Color? borderColor;

  /// Optional colored glow around the card (used for alert states).
  final Color? gradientGlow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: AppGradients.glassSheen(colors),
        border: Border.all(
          color: borderColor ?? colors.glassBorder,
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: gradientGlow != null
            ? AppShadows.glow(gradientGlow!)
            : AppShadows.card(colors),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: ColoredBox(
            color: strong ? colors.glassFillStrong : colors.glassFill,
            child: onTap == null
                ? content
                : _Tappable(
                    onTap: onTap!,
                    borderRadius: borderRadius,
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: context.colors.goalSoft,
        highlightColor: context.colors.goalSoft,
        child: child,
      ),
    );
  }
}
