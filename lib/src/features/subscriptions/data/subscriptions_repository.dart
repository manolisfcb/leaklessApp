import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/subscription_item.dart';
import 'subscription_mapper.dart';

/// Reads and edits the household's recurring subscriptions.
abstract interface class SubscriptionsRepository {
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId);
  Stream<List<SubscriptionItem>> watchForHousehold(String householdId);
  Future<SubscriptionItem> create(SubscriptionItem item);
  Future<SubscriptionItem> update(SubscriptionItem item);
  Future<void> delete(String subscriptionId);

  /// Rolls [item]'s `next_charge_at` forward by its [SubscriptionItem.frequency]
  /// until it lands strictly after [now] (default: `DateTime.now()`), then
  /// persists it. Used by the local reminder scheduler when a charge date has
  /// already passed, so reminders keep firing across months without a server.
  /// Items without a `next_charge_at` are returned unchanged.
  Future<SubscriptionItem> advanceNextCharge(
    SubscriptionItem item, {
    DateTime? now,
  });
}

/// Computes the advanced copy of [item] shared by every repository. Kept as a
/// free function so the date math lives in one place regardless of backend.
SubscriptionItem advanceSubscriptionCharge(
  SubscriptionItem item, {
  DateTime? now,
}) {
  final current = item.nextChargeAt;
  if (current == null) return item;
  final threshold = now ?? DateTime.now();
  var next = current;
  // Guard against a pathological loop; a decade of missed weekly charges is far
  // more than any real gap between app launches.
  var guard = 0;
  while (!next.isAfter(threshold) && guard < 600) {
    next = item.frequency.nextChargeAfter(next);
    guard++;
  }
  return item.copyWith(nextChargeAt: next);
}

/// Stateful in-memory subscriptions with the same live-update behavior as
/// Supabase, so mock mode exercises the full CRUD + reminder flow.
class MockSubscriptionsRepository implements SubscriptionsRepository {
  MockSubscriptionsRepository() : _items = DemoData.subscriptions();

  final List<SubscriptionItem> _items;
  final _controller = StreamController<List<SubscriptionItem>>.broadcast();

  List<SubscriptionItem> _forHousehold(String householdId) {
    final subscriptions = _items
        .where((item) => item.householdId == householdId)
        .toList();
    subscriptions.sort((a, b) {
      final aDate = a.nextChargeAt;
      final bDate = b.nextChargeAt;
      if (aDate == null) return bDate == null ? 0 : 1; // nulls last
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return List.unmodifiable(subscriptions);
  }

  @override
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId) async =>
      _forHousehold(householdId);

  @override
  Stream<List<SubscriptionItem>> watchForHousehold(String householdId) async* {
    yield _forHousehold(householdId);
    yield* _controller.stream.map((_) => _forHousehold(householdId));
  }

  @override
  Future<SubscriptionItem> create(SubscriptionItem item) async {
    final now = DateTime.now();
    final saved = item.copyWith(
      id: item.id.isEmpty ? 'sub-${now.microsecondsSinceEpoch}' : item.id,
      createdAt: item.createdAt ?? now,
      updatedAt: now,
    );
    _items.add(saved);
    _emit();
    return saved;
  }

  @override
  Future<SubscriptionItem> update(SubscriptionItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      throw StateError('Subscription ${item.id} does not exist.');
    }
    final saved = item.copyWith(
      createdAt: _items[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _items[index] = saved;
    _emit();
    return saved;
  }

  @override
  Future<void> delete(String subscriptionId) async {
    _items.removeWhere((item) => item.id == subscriptionId);
    _emit();
  }

  @override
  Future<SubscriptionItem> advanceNextCharge(
    SubscriptionItem item, {
    DateTime? now,
  }) async {
    final advanced = advanceSubscriptionCharge(item, now: now);
    if (advanced.nextChargeAt == item.nextChargeAt) return item;
    return update(advanced);
  }

  void _emit() => _controller.add(List.unmodifiable(_items));

  void dispose() => unawaited(_controller.close());
}

/// Supabase-backed subscription reads and edits, scoped to the active
/// household.
///
/// RLS already restricts `subscriptions` to the user's household; the explicit
/// `household_id` filter keeps this correct if a user ever belongs to more than
/// one, and mirrors the `transactions` pattern. Ordered by the soonest upcoming
/// charge (nulls last, Postgres default for ascending order).
class SupabaseSubscriptionsRepository implements SubscriptionsRepository {
  SupabaseSubscriptionsRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('subscriptions');

  @override
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _table
          .select()
          .eq('household_id', householdId)
          .order('next_charge_at', ascending: true);
      return rows.map(SubscriptionMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException(
        'Failed to load subscriptions',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Stream<List<SubscriptionItem>> watchForHousehold(String householdId) => _table
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('next_charge_at', ascending: true)
      .map((rows) => rows.map(SubscriptionMapper.fromRow).toList());

  @override
  Future<SubscriptionItem> create(SubscriptionItem item) async {
    try {
      final row = await _table
          .insert(SubscriptionMapper.toInsert(item))
          .select()
          .single();
      return SubscriptionMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to create subscription',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<SubscriptionItem> update(SubscriptionItem item) async {
    try {
      final row = await _table
          .update(SubscriptionMapper.toUpdate(item))
          .eq('id', item.id)
          .select()
          .single();
      return SubscriptionMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to update subscription',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> delete(String subscriptionId) async {
    try {
      await _table.delete().eq('id', subscriptionId);
    } catch (e, s) {
      throw ServerException(
        'Failed to delete subscription',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<SubscriptionItem> advanceNextCharge(
    SubscriptionItem item, {
    DateTime? now,
  }) async {
    final advanced = advanceSubscriptionCharge(item, now: now);
    if (advanced.nextChargeAt == item.nextChargeAt) return item;
    return update(advanced);
  }
}
