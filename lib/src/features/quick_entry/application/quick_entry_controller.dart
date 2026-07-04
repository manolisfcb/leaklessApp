import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/transactions_providers.dart';

/// Handles registering a quick expense/income.
///
/// The UI only collects inputs and calls [submit]; all the work (building the
/// domain object, persisting, analytics) lives here (quality rule #4/#6). Works
/// against the mock repository until Supabase is configured.
class QuickEntryController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true on success so the sheet can close.
  Future<bool> submit({
    required int amountMinorUnits,
    required TransactionType type,
    required TransactionPriority priority,
    required ResponsibleType responsible,
    String? categoryId,
    String? description,
    DateTime? occurredAt,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) {
        throw StateError('No active household to register a transaction.');
      }
      final transaction = Transaction(
        id: '',
        householdId: household.id,
        amount: Money(minorUnits: amountMinorUnits, currency: household.currency),
        type: type,
        priority: priority,
        responsible: responsible,
        categoryId: categoryId,
        // A scanned receipt carries its own purchase date; manual entries fall
        // back to now.
        occurredAt: occurredAt ?? DateTime.now(),
        description: description,
      );
      await ref.read(transactionsRepositoryProvider).add(transaction);
      await ref.read(analyticsServiceProvider).transactionCreated();
    });
    state = result;
    return !result.hasError;
  }
}

final quickEntryControllerProvider =
    NotifierProvider<QuickEntryController, AsyncValue<void>>(
      QuickEntryController.new,
    );
