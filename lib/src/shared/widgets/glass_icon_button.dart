import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A circular frosted-glass icon button used for compact actions
/// (month selector chevrons, sheet close, settings rows…).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconColor,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: size,
          width: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.glassFill,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Icon(
            icon,
            size: size * 0.46,
            color: iconColor ?? colors.textPrimary,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onPressed, child: button),
      ),
    );
  }
}
