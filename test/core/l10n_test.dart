import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/l10n/l10n.dart';

void main() {
  const locales = ['es', 'en', 'pt'];

  Set<String> keysOf(String locale) {
    final file = File('lib/src/core/l10n/app_$locale.arb');
    final map = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    // '@'-prefixed entries are metadata ('@@locale', '@key' descriptions).
    return map.keys.where((key) => !key.startsWith('@')).toSet();
  }

  test('every locale has exactly the template keys', () {
    final template = keysOf('es');
    expect(template, isNotEmpty);
    for (final locale in locales) {
      expect(
        keysOf(locale),
        template,
        reason: 'app_$locale.arb keys differ from the es template',
      );
    }
  });

  test('lookup resolves every supported locale with translated values', () {
    expect(
      lookupAppLocalizations(const Locale('es')).transactionTypeExpense,
      'Gasto',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).transactionTypeExpense,
      'Expense',
    );
    expect(
      lookupAppLocalizations(const Locale('pt')).transactionTypeExpense,
      'Despesa',
    );
  });

  test('plural messages render for one and many', () {
    final es = lookupAppLocalizations(const Locale('es'));
    expect(es.settingsMembersCount(1), '1 miembro');
    expect(es.settingsMembersCount(2), '2 miembros');
  });
}
