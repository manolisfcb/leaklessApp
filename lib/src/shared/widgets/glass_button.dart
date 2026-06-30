import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Visual emphasis for a [GlassButton].
enum GlassButtonVariant {
  /// Solid accent fill (primary call to action).
  filled,

  /// Translucent frosted glass (secondary).
  glass,
}

/// The standard leakless button: a pill that is either a solid accent or a
/// frosted glass surface, with an optional leading icon.
class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.filled,
    this.accent,
    this.expand = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;

  /// Accent color for the [GlassButtonVariant.filled] background / glass text.
  final Color? accent;

  /// Whether the button stretches to the full available width.
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = accent ?? colors.primary;
    final isFilled = variant == GlassButtonVariant.filled;
    final enabled = onPressed != null && !loading;
    final foreground = isFilled ? Colors.white : accentColor;

    final child = AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: enabled ? 1 : 0.5,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              AppSpacing.gapSm,
            ],
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );

    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.lg,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadii.pillRadius,
        child: isFilled
            ? Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.pillRadius,
                  gradient: AppGradients.accent(accentColor),
                  boxShadow: AppShadows.glow(accentColor),
                ),
                child: child,
              )
            : ClipRRect(
                borderRadius: AppRadii.pillRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      color: colors.glassFill,
                      borderRadius: AppRadii.pillRadius,
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: child,
                  ),
                ),
              ),
      ),
    );
  }
}
