import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/money.dart';
import 'account_mapper.dart';

abstract interface class AccountsRepository {
  Stream<List<FinancialAccount>> watch(String householdId);
  Future<FinancialAccount> save(FinancialAccount account);
  Future<void> archive(String accountId);
}

class MockAccountsRepository implements AccountsRepository {
  final _controller = StreamController<List<FinancialAccount>>.broadcast();
  late final List<FinancialAccount> _items = [
    FinancialAccount(
      id: 'account-main',
      householdId: DemoData.householdId,
      name: 'Cuenta principal',
      currency: DemoData.currency,
      openingBalance: const Money(minorUnits: 0, currency: DemoData.currency),
      openingBalanceAt: DateTime(2000),
      isDefault: true,
    ),
  ];

  @override
  Stream<List<FinancialAccount>> watch(String householdId) async* {
    yield _for(householdId);
    yield* _controller.stream.map((_) => _for(householdId));
  }

  List<FinancialAccount> _for(String householdId) => List.unmodifiable(
    _items.where((item) => item.householdId == householdId).toList(),
  );

  @override
  Future<FinancialAccount> save(FinancialAccount account) async {
    final saved = account.id.isEmpty
        ? account.copyWith(
            id: 'account-${DateTime.now().microsecondsSinceEpoch}',
          )
        : account;
    final index = _items.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _items.add(saved);
    } else {
      _items[index] = saved;
    }
    _controller.add(_items);
    return saved;
  }

  @override
  Future<void> archive(String accountId) async {
    final index = _items.indexWhere((item) => item.id == accountId);
    if (index >= 0) _items[index] = _items[index].copyWith(isArchived: true);
    _controller.add(_items);
  }

  void dispose() => unawaited(_controller.close());
}

class SupabaseAccountsRepository implements AccountsRepository {
  SupabaseAccountsRepository(this.client);
  final SupabaseClient client;

  @override
  Stream<List<FinancialAccount>> watch(String householdId) => client
      .from('accounts')
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('created_at')
      .map((rows) => rows.map(AccountMapper.fromRow).toList());

  @override
  Future<FinancialAccount> save(FinancialAccount account) async {
    final query = client.from('accounts');
    final row = account.id.isEmpty
        ? await query.insert(AccountMapper.toRow(account)).select().single()
        : await query
              .update(AccountMapper.toRow(account))
              .eq('id', account.id)
              .select()
              .single();
    return AccountMapper.fromRow(row);
  }

  @override
  Future<void> archive(String accountId) async {
    await client
        .from('accounts')
        .update({'is_archived': true, 'is_default': false})
        .eq('id', accountId);
  }
}
