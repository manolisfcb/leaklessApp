import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/income_source.dart';
import '../../household/application/household_providers.dart';
import '../data/income_sources_repository.dart';

final incomeSourcesRepositoryProvider = Provider<IncomeSourcesRepository>((
  ref,
) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseIncomeSourcesRepository(ref.watch(supabaseClientProvider));
  }
  final repository = MockIncomeSourcesRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final incomeSourcesProvider = StreamProvider<List<IncomeSource>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref.watch(incomeSourcesRepositoryProvider).watch(household.id);
});

class IncomeSourcesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<IncomeSource?> save(IncomeSource source) async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(incomeSourcesRepositoryProvider)
          .save(source);
      state = const AsyncData(null);
      ref.invalidate(incomeSourcesProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> archive(String id) async {
    state = const AsyncLoading();
    try {
      await ref.read(incomeSourcesRepositoryProvider).archive(id);
      state = const AsyncData(null);
      ref.invalidate(incomeSourcesProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final incomeSourcesControllerProvider =
    NotifierProvider<IncomeSourcesController, AsyncValue<void>>(
      IncomeSourcesController.new,
    );
