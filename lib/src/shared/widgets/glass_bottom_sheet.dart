import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A frosted "liquid glass" modal bottom sheet.
///
/// Use [GlassBottomSheet.show] to present any content as a blurred sheet that
/// slides up from the bottom (e.g. the Quick Entry overlay).
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  /// Presents [builder]'s content inside a [GlassBottomSheet].
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: context.colors.scrim,
      builder: (context) => GlassBottomSheet(
        title: title,
        child: Builder(builder: builder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedPadding(
      duration: AppDurations.fast,
      curve: AppDurations.emphasized,
      // Lift the sheet above the system keyboard so fields stay visible.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.sheetRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: colors.glassFillStrong,
                borderRadius: AppRadii.sheetRadius,
                border: Border.all(color: colors.glassBorder),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 44,
                          decoration: BoxDecoration(
                            color: colors.textTertiary,
                            borderRadius: AppRadii.pillRadius,
                          ),
                        ),
                      ),
                      if (title != null) ...[
                        AppSpacing.gapLg,
                        Text(title!, style: AppTypography.titleLarge),
                      ],
                      AppSpacing.gapLg,
                      Flexible(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
