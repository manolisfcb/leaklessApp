import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Builds the leakless [ThemeData].
///
/// The visual identity (translucent glass, gradients) lives in
/// [AppColors] (a [ThemeExtension]) and the shared glass widgets; here we wire
/// the base Material theme so stock widgets inherit the brand.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light);

  static ThemeData _build(AppColors colors) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          surface: colors.surface,
          // Keep the light, fresh identity regardless of the seed's auto-tones.
        ).copyWith(
          primary: colors.primary,
          secondary: colors.income,
          error: colors.expense,
          surface: colors.surface,
          onSurface: colors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: AppTypography.textTheme(colors.textPrimary),
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: colors.divider, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: colors.textPrimary,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
      ),
      // Brand color extensions consumed via `context.colors`.
      extensions: const [AppColors.light],
    );
  }
}
