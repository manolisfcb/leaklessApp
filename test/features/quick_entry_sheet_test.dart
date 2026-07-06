import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leakless/src/core/l10n/app_localizations.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/core/utils/money_formatter.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/quick_entry/presentation/quick_entry_sheet.dart';
import 'package:leakless/src/shared/widgets/glass_bottom_sheet.dart';

/// Renders the sheet inside a short viewport so the form must scroll to
/// reach the keypad, mirroring a small phone with the keyboard area open.
Widget _harness() => ProviderScope(
  overrides: [
    currentHouseholdProvider.overrideWith(
      (ref) async =>
          const Household(id: 'household-1', name: 'Casa', ownerId: 'user-1'),
    ),
  ],
  child: MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: const Scaffold(
      body: GlassBottomSheet(child: QuickEntrySheet()),
    ),
  ),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'keeps the amount visible and updated while scrolled to the keypad',
    (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(
        find.text(MoneyFormatter.format(0, currencyCode: 'USD')),
        findsOneWidget,
      );

      // Scroll the form down to bring the numeric keypad into view.
      await tester.dragUntilVisible(
        find.text('9'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      await tester.tap(find.text('9'));
      await tester.pump();
      expect(
        find.text(MoneyFormatter.format(9, currencyCode: 'USD')),
        findsOneWidget,
      );

      await tester.tap(find.text('5'));
      await tester.pump();
      final expected = MoneyFormatter.format(95, currencyCode: 'USD');
      final amountFinder = find.text(expected);
      expect(amountFinder, findsOneWidget);

      final rect = tester.getRect(amountFinder);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(viewportHeight));
    },
  );
}
