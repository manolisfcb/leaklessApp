import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/transaction.dart';
import 'transaction_mapper.dart';

/// Reads/writes household transactions, with realtime updates between members.
abstract interface class TransactionsRepository {
  Future<List<Transaction>> fetchForHousehold(String householdId);
  Stream<List<Transaction>> watchForHousehold(String householdId);
  Future<Transaction> add(Transaction transaction);
}

/// In-memory repository so the app is fully usable before the backend exists.
/// `add` mutates the list and emits, so a new quick-entry instantly appears in
/// the history and dashboard — matching the real realtime behavior.
class MockTransactionsRepository implements TransactionsRepository {
  MockTransactionsRepository() : _items = DemoData.transactions();

  final List<Transaction> _items;
  final _controller = StreamController<List<Transaction>>.broadcast();

  List<Transaction> get _sorted =>
      [..._items]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<List<Transaction>> fetchForHousehold(String householdId) async =>
      _sorted;

  @override
  Stream<List<Transaction>> watchForHousehold(String householdId) async* {
    yield _sorted;
    yield* _controller.stream;
  }

  @override
  Future<Transaction> add(Transaction transaction) async {
    final saved = transaction.id.isEmpty
        ? transaction.copyWith(
            id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
            createdAt: DateTime.now(),
          )
        : transaction;
    _items.add(saved);
    _controller.add(_sorted);
    return saved;
  }

  void dispose() => unawaited(_controller.close());
}

/// Supabase-backed repository using realtime streams + the [TransactionMapper].
class SupabaseTransactionsRepository implements TransactionsRepository {
  SupabaseTransactionsRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('transactions');

  @override
  Future<List<Transaction>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _table
          .select()
          .eq('household_id', householdId)
          .order('occurred_at', ascending: false);
      return rows.map(TransactionMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException(
        'Failed to load transactions',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Stream<List<Transaction>> watchForHousehold(String householdId) => _table
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('occurred_at', ascending: false)
      .map((rows) => rows.map(TransactionMapper.fromRow).toList());

  @override
  Future<Transaction> add(Transaction transaction) async {
    try {
      final row = await _table
          .insert(TransactionMapper.toInsert(transaction))
          .select()
          .single();
      return TransactionMapper.fromRow(row);
    } on PostgrestException catch (e, s) {
      throw ServerException(
        'Failed to save transaction',
        code: e.code,
        cause: e,
        stackTrace: s,
      );
    } catch (e, s) {
      throw ServerException(
        'Failed to save transaction',
        cause: e,
        stackTrace: s,
      );
    }
  }
}
