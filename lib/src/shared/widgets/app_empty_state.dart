import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'glass_button.dart';

/// A friendly empty/placeholder state with an icon, message and optional CTA.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.goalSoft,
              ),
              child: Icon(icon, size: 40, color: colors.primary),
            ),
            AppSpacing.gapXl,
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            if (message != null) ...[
              AppSpacing.gapSm,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapXl,
              GlassButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
