import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/financial_account.dart';
import '../../household/application/household_providers.dart';
import '../data/accounts_repository.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseAccountsRepository(ref.watch(supabaseClientProvider));
  }
  final repository = MockAccountsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final accountsProvider = StreamProvider<List<FinancialAccount>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref.watch(accountsRepositoryProvider).watch(household.id);
});

final activeAccountsProvider = Provider<AsyncValue<List<FinancialAccount>>>(
  (ref) => ref
      .watch(accountsProvider)
      .whenData((items) => items.where((item) => !item.isArchived).toList()),
);

class AccountsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(FinancialAccount account) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(accountsRepositoryProvider).save(account),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace ?? StackTrace.current)
        : const AsyncData(null);
    if (!result.hasError) ref.invalidate(accountsProvider);
    return !result.hasError;
  }

  Future<bool> archive(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(accountsRepositoryProvider).archive(id),
    );
    state = result;
    if (!result.hasError) ref.invalidate(accountsProvider);
    return !result.hasError;
  }
}

final accountsControllerProvider =
    NotifierProvider<AccountsController, AsyncValue<void>>(
      AccountsController.new,
    );
