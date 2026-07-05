import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/l10n/category_names.dart';
import 'package:leakless/src/core/l10n/l10n.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';

void main() {
  const translations = {
    'groceries': ['Supermercado', 'Groceries', 'Supermercado'],
    'dining': ['Restaurantes', 'Dining', 'Restaurantes'],
    'transport': ['Transporte', 'Transport', 'Transporte'],
    'leisure': ['Ocio', 'Leisure', 'Lazer'],
    'subscriptions': ['Suscripciones', 'Subscriptions', 'Assinaturas'],
    'savings': ['Ahorro', 'Savings', 'Poupança'],
    'essentials': ['Gastos esenciales', 'Essentials', 'Despesas essenciais'],
    'education': ['Estudios', 'Education', 'Educação'],
    'emergency_fund': [
      'Reserva de emergencia',
      'Emergency fund',
      'Reserva de emergência',
    ],
    'health': ['Salud', 'Health', 'Saúde'],
  };
  const locales = [Locale('es'), Locale('en'), Locale('pt')];

  test('all seeded slugs resolve in Spanish, English, and Portuguese', () {
    for (final entry in translations.entries) {
      final category = TransactionCategory(
        id: entry.key,
        name: 'Raw name',
        slug: entry.key,
        iconName: 'cart',
      );
      for (var i = 0; i < locales.length; i++) {
        expect(
          categoryDisplayName(category, lookupAppLocalizations(locales[i])),
          entry.value[i],
          reason: '${entry.key} in ${locales[i].languageCode}',
        );
      }
    }
  });

  test('custom and unknown categories preserve their raw names', () {
    const custom = TransactionCategory(
      id: 'custom',
      name: 'Mascotas',
      iconName: 'gift',
    );
    const unknown = TransactionCategory(
      id: 'unknown',
      name: 'Otro',
      slug: 'unknown',
      iconName: 'gift',
    );
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(categoryDisplayName(custom, l10n), 'Mascotas');
    expect(categoryDisplayName(unknown, l10n), 'Otro');
  });
}
