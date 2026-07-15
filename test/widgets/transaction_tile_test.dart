import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leakless/src/core/l10n/app_localizations.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/transactions/presentation/widgets/transaction_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the expense date when requested by History', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'transaction-1',
      householdId: 'household-1',
      amount: const Money(minorUnits: 15787, currency: 'USD'),
      type: TransactionType.expense,
      priority: TransactionPriority.necessity,
      responsible: ResponsibleType.me,
      occurredAt: DateTime(2026, 7, 15, 12),
      description: 'Costco Wholesale',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TransactionTile(transaction: transaction, showDate: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Costco Wholesale'), findsOneWidget);
    expect(find.text('Jul 15, 2026'), findsOneWidget);
    expect(find.text('Necessity · You'), findsOneWidget);
  });

  testWidgets('keeps the Dashboard variant compact', (tester) async {
    final transaction = Transaction(
      id: 'transaction-1',
      householdId: 'household-1',
      amount: const Money(minorUnits: 500, currency: 'USD'),
      type: TransactionType.expense,
      priority: TransactionPriority.necessity,
      responsible: ResponsibleType.me,
      occurredAt: DateTime(2026, 7, 15, 12),
      description: 'Essentials',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: TransactionTile(transaction: transaction)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jul 15, 2026'), findsNothing);
  });
}
