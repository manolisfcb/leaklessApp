import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// The standard centered loading indicator, tinted with the brand primary.
class AppLoader extends StatelessWidget {
  const AppLoader({this.message, this.size = 32, super.key});

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapMd,
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
