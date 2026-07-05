import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leakless/src/core/l10n/app_localizations.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/transactions/application/categories_providers.dart';
import 'package:leakless/src/features/transactions/data/categories_repository.dart';
import 'package:leakless/src/features/transactions/presentation/category_form_sheet.dart';

/// The form pops itself on success, so it is pushed as its own route.
Widget _harness(
  _FakeCategoriesRepository repository, {
  TransactionCategory? category,
}) => ProviderScope(
  overrides: [
    categoriesRepositoryProvider.overrideWithValue(repository),
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
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    Scaffold(body: CategoryFormSheet(category: category)),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('category-save-button')));
  await tester.tap(find.byKey(const Key('category-save-button')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('rejects an empty name and does not save', (tester) async {
    final repository = _FakeCategoriesRepository();
    await tester.pumpWidget(_harness(repository));
    await _openForm(tester);

    await _tapSave(tester);

    expect(find.text('Ingresa un nombre.'), findsOneWidget);
    expect(repository.created, isNull);
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('creates a category with the chosen icon and pops', (
    tester,
  ) async {
    final repository = _FakeCategoriesRepository();
    await tester.pumpWidget(_harness(repository));
    await _openForm(tester);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Mascotas',
    );
    await tester.ensureVisible(find.byKey(const Key('category-icon-gift')));
    await tester.tap(find.byKey(const Key('category-icon-gift')));
    await tester.pump();
    await _tapSave(tester);

    expect(repository.created?.name, 'Mascotas');
    expect(repository.created?.iconName, 'gift');
    expect(repository.created?.colorHex, categoryPaletteHex.first);
    expect(find.byType(CategoryFormSheet), findsNothing);
  });

  testWidgets('prefills the fields when editing and updates', (tester) async {
    final repository = _FakeCategoriesRepository();
    const category = TransactionCategory(
      id: 'category-1',
      householdId: 'household-1',
      name: 'Mascotas',
      iconName: 'gift',
      colorHex: '#34C7A5',
    );
    await tester.pumpWidget(_harness(repository, category: category));
    await _openForm(tester);

    expect(find.text('Mascotas'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Veterinario',
    );
    await _tapSave(tester);

    expect(repository.updated?.name, 'Veterinario');
    expect(repository.updated?.colorHex, '#34C7A5');
    expect(find.byType(CategoryFormSheet), findsNothing);
  });

  testWidgets('shows an inline error when saving fails', (tester) async {
    final repository = _FakeCategoriesRepository(failSave: true);
    await tester.pumpWidget(_harness(repository));
    await _openForm(tester);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Mascotas',
    );
    await _tapSave(tester);

    expect(
      find.text('No pudimos completar la operación. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  test('categoryColorFromHex parses #RRGGBB and rejects garbage', () {
    expect(categoryColorFromHex('#4E9BFA'), const Color(0xFF4E9BFA));
    expect(categoryColorFromHex('34C7A5'), const Color(0xFF34C7A5));
    expect(categoryColorFromHex(null), isNull);
    expect(categoryColorFromHex('#12'), isNull);
    expect(categoryColorFromHex('not-a-color'), isNull);
  });
}

class _FakeCategoriesRepository implements CategoriesRepository {
  _FakeCategoriesRepository({this.failSave = false});

  final bool failSave;
  TransactionCategory? created;
  TransactionCategory? updated;

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async =>
      const [];

  @override
  Future<TransactionCategory> create(TransactionCategory category) async {
    if (failSave) throw StateError('save failed');
    return created = category.copyWith(id: 'category-created');
  }

  @override
  Future<TransactionCategory> update(TransactionCategory category) async {
    if (failSave) throw StateError('save failed');
    return updated = category;
  }

  @override
  Future<void> delete(String categoryId) async {}
}
