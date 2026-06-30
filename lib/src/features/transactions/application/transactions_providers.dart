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
final transactionsStreamProvider =
    StreamProvider<List<Transaction>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref.watch(transactionsRepositoryProvider).watchForHousehold(household.id);
});

/// Filters applied on the history screen.
class TransactionFilter {
  const TransactionFilter({this.responsible, this.categoryId, this.priority});

  final ResponsibleType? responsible;
  final String? categoryId;
  final TransactionPriority? priority;

  bool get isActive =>
      responsible != null || categoryId != null || priority != null;

  bool matches(Transaction tx) {
    if (responsible != null && tx.responsible != responsible) return false;
    if (categoryId != null && tx.categoryId != categoryId) return false;
    if (priority != null && tx.priority != priority) return false;
    return true;
  }

  TransactionFilter copyWith({
    ResponsibleType? responsible,
    String? categoryId,
    TransactionPriority? priority,
    bool clearResponsible = false,
    bool clearCategory = false,
    bool clearPriority = false,
  }) => TransactionFilter(
    responsible: clearResponsible ? null : (responsible ?? this.responsible),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    priority: clearPriority ? null : (priority ?? this.priority),
  );
}

/// Holds the active filter; the UI toggles chips through this.
class TransactionFilterController extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

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
  );

  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterController, TransactionFilter>(
      TransactionFilterController.new,
    );

/// Transactions after applying the active filter.
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionsStreamProvider).whenData(
        (list) => list.where(filter.matches).toList(),
      );
});
