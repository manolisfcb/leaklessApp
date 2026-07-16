import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leakless/src/core/l10n/app_localizations.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/income_source.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/income_sources/application/income_sources_providers.dart';
import 'package:leakless/src/features/income_sources/data/income_sources_repository.dart';
import 'package:leakless/src/features/income_sources/presentation/income_entry_sheet.dart';

Widget _harness(IncomeSourcesRepository repository) => ProviderScope(
  overrides: [
    incomeSourcesRepositoryProvider.overrideWithValue(repository),
    currentHouseholdProvider.overrideWith(
      (ref) async => const Household(
        id: 'household-1',
        name: 'Casa',
        ownerId: 'user-1',
        currency: 'CAD',
      ),
    ),
  ],
  child: MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: const Scaffold(body: IncomeEntrySheet()),
  ),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'keeps a newly created source selectable while the stream is stale',
    (tester) async {
      final repository = _StaleIncomeSourcesRepository();
      await tester.pumpWidget(_harness(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva fuente'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Freelance',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Guardar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Freelance'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownMenuItem<String> &&
              widget.value == 'source-new',
        ),
        findsOneWidget,
      );
    },
  );
}

class _StaleIncomeSourcesRepository implements IncomeSourcesRepository {
  static const _existing = IncomeSource(
    id: 'source-existing',
    householdId: 'household-1',
    name: 'Salario',
    defaultCurrency: 'CAD',
  );

  @override
  Stream<List<IncomeSource>> watch(String householdId) =>
      Stream.value(const [_existing]);

  @override
  Future<IncomeSource> save(IncomeSource source) async =>
      source.copyWith(id: 'source-new');

  @override
  Future<void> archive(String sourceId) async {}
}
