import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/transaction.dart';
import '../../household/application/household_providers.dart';
import '../data/transactions_repository.dart';

/// Real (Supabase) or mock repository, chosen by config.
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseTransactionsRepository(ref.watch(supabaseClientProvider));
  }
  final repo = MockTransactionsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live transactions for the active household.
final transactionsStreamProvider = StreamProvider<List<Transaction>>((
  ref,
) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(transactionsRepositoryProvider)
      .watchForHousehold(household.id)
      .map(sortTransactionsNewestFirst);
});

/// Canonical transaction order for every consumer (History, Dashboard and
/// Insights). Keeping it here makes the UI independent from PostgREST/Realtime
/// ordering details and also sorts mock/test repository emissions consistently.
List<Transaction> sortTransactionsNewestFirst(List<Transaction> transactions) {
  final sorted = [...transactions];
  sorted.sort((a, b) {
    final byOccurrence = b.occurredAt.compareTo(a.occurredAt);
    if (byOccurrence != 0) return byOccurrence;
    final byCreation = (b.createdAt ?? b.occurredAt).compareTo(
      a.createdAt ?? a.occurredAt,
    );
    if (byCreation != 0) return byCreation;
    return b.id.compareTo(a.id);
  });
  return sorted;
}

/// Filters applied on the history screen.
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.accountId,
    this.currency,
    this.incomeSourceId,
    this.responsible,
    this.categoryId,
    this.priority,
    this.uncategorizedOnly = false,
  });

  final TransactionType? type;
  final String? accountId;
  final String? currency;
  final String? incomeSourceId;

  final ResponsibleType? responsible;
  final String? categoryId;
  final TransactionPriority? priority;

  /// When true, matches expenses with no category and ignores [categoryId]
  /// (the two are mutually exclusive).
  final bool uncategorizedOnly;

  bool get isActive =>
      type != null ||
      accountId != null ||
      currency != null ||
      incomeSourceId != null ||
      responsible != null ||
      categoryId != null ||
      priority != null ||
      uncategorizedOnly;

  bool matches(Transaction tx) {
    if (type != null && tx.type != type) return false;
    if (accountId != null && tx.accountId != accountId) return false;
    if (currency != null && tx.amount.currency != currency) return false;
    if (incomeSourceId != null && tx.incomeSourceId != incomeSourceId) {
      return false;
    }
    if (responsible != null && tx.responsible != responsible) return false;
    if (uncategorizedOnly) {
      if (tx.categoryId != null) return false;
    } else if (categoryId != null && tx.categoryId != categoryId) {
      return false;
    }
    if (priority != null && tx.priority != priority) return false;
    return true;
  }

  TransactionFilter copyWith({
    TransactionType? type,
    String? accountId,
    String? currency,
    String? incomeSourceId,
    ResponsibleType? responsible,
    String? categoryId,
    TransactionPriority? priority,
    bool? uncategorizedOnly,
    bool clearResponsible = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearType = false,
    bool clearAccount = false,
    bool clearCurrency = false,
    bool clearIncomeSource = false,
  }) => TransactionFilter(
    type: clearType ? null : (type ?? this.type),
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    currency: clearCurrency ? null : (currency ?? this.currency),
    incomeSourceId: clearIncomeSource
        ? null
        : (incomeSourceId ?? this.incomeSourceId),
    responsible: clearResponsible ? null : (responsible ?? this.responsible),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    priority: clearPriority ? null : (priority ?? this.priority),
    uncategorizedOnly: uncategorizedOnly ?? this.uncategorizedOnly,
  );
}

/// Holds the active filter; the UI toggles chips through this.
class TransactionFilterController extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void toggleType(TransactionType value) => state = state.copyWith(
    type: state.type == value ? null : value,
    clearType: state.type == value,
  );

  void toggleCurrency(String value) => state = state.copyWith(
    currency: state.currency == value ? null : value,
    clearCurrency: state.currency == value,
  );

  void toggleAccount(String value) => state = state.copyWith(
    accountId: state.accountId == value ? null : value,
    clearAccount: state.accountId == value,
  );

  void toggleIncomeSource(String value) => state = state.copyWith(
    incomeSourceId: state.incomeSourceId == value ? null : value,
    clearIncomeSource: state.incomeSourceId == value,
  );

  void toggleResponsible(ResponsibleType value) => state = state.copyWith(
    responsible: state.responsible == value ? null : value,
    clearResponsible: state.responsible == value,
  );

  void togglePriority(TransactionPriority value) => state = state.copyWith(
    priority: state.priority == value ? null : value,
    clearPriority: state.priority == value,
  );

  void toggleCategory(String value) => state = state.copyWith(
    categoryId: state.categoryId == value ? null : value,
    clearCategory: state.categoryId == value,
    uncategorizedOnly: false,
  );

  void toggleUncategorized() => state = state.uncategorizedOnly
      ? state.copyWith(uncategorizedOnly: false)
      : TransactionFilter(
          type: state.type,
          accountId: state.accountId,
          currency: state.currency,
          incomeSourceId: state.incomeSourceId,
          responsible: state.responsible,
          priority: state.priority,
          uncategorizedOnly: true,
        );

  /// Sets the uncategorized-only filter regardless of its current state, for
  /// entry points (e.g. the insights CTA) that always want it enabled.
  void showUncategorizedOnly() => state = TransactionFilter(
    type: state.type,
    accountId: state.accountId,
    currency: state.currency,
    incomeSourceId: state.incomeSourceId,
    responsible: state.responsible,
    priority: state.priority,
    uncategorizedOnly: true,
  );

  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterController, TransactionFilter>(
      TransactionFilterController.new,
    );

/// Transactions after applying the active filter.
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final filter = ref.watch(transactionFilterProvider);
  return ref
      .watch(transactionsStreamProvider)
      .whenData(
        (list) => list
            .where((tx) => tx.transferDirection != TransferDirection.incoming)
            .where(filter.matches)
            .toList(),
      );
});

/// Mutations for existing transactions. The database trigger recomputes the
/// affected monthly budget after a deletion.
class TransactionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> delete(String transactionId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(transactionsRepositoryProvider).delete(transactionId),
    );
    state = result;
    if (result.hasError) return false;
    ref.invalidate(transactionsStreamProvider);
    return true;
  }
}

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, AsyncValue<void>>(
      TransactionsController.new,
    );
