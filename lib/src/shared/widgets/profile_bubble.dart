import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A circular profile avatar used for household members.
///
/// Shows the member photo when [imageUrl] is provided, otherwise the
/// [initials] on a tinted glass background. When [active] is true a soft glow
/// ring is drawn — the design uses this to signal recent activity on the
/// "couple thread".
class ProfileBubble extends StatelessWidget {
  const ProfileBubble({
    required this.initials,
    this.imageUrl,
    this.size = 56,
    this.active = false,
    this.ringColor,
    super.key,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final bool active;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ring = ringColor ?? colors.goal;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.glassSheen(colors),
        border: Border.all(
          color: active ? ring : colors.glassBorder,
          width: active ? 2 : 1,
        ),
        boxShadow: active ? AppShadows.glow(ring) : AppShadows.card(colors),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              initials,
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            )
          : null,
    );
  }
}
