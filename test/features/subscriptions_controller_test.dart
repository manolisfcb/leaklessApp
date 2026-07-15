import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/finance_enums.dart';
import 'package:leakless/src/domain/models/financial_account.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/subscription_item.dart';
import 'package:leakless/src/features/accounts/application/accounts_providers.dart';
import 'package:leakless/src/features/subscriptions/application/subscriptions_providers.dart';
import 'package:leakless/src/features/subscriptions/data/subscriptions_repository.dart';

void main() {
  test('save creates a subscription for the active household', () async {
    final repository = _FakeSubscriptionsRepository();
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
        activeAccountsProvider.overrideWithValue(
          AsyncData([_account(currency: 'USD')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(subscriptionsControllerProvider.notifier)
        .save(
          name: '  Rent  ',
          amountMinorUnits: 120000,
          frequency: SubscriptionFrequency.monthly,
          nextChargeAt: DateTime(2026, 8, 1),
          reminderEnabled: true,
          reminderDaysBefore: 3,
        );

    expect(saved, isTrue);
    expect(repository.created, isNotNull);
    expect(repository.created!.name, 'Rent');
    expect(repository.created!.amount.minorUnits, 120000);
    expect(repository.created!.frequency, SubscriptionFrequency.monthly);
    expect(repository.created!.reminderEnabled, isTrue);
    expect(repository.created!.reminderDaysBefore, 3);
    expect(container.read(subscriptionsControllerProvider).hasError, isFalse);
  });

  test('save updates when a subscription id is supplied', () async {
    final repository = _FakeSubscriptionsRepository();
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
        activeAccountsProvider.overrideWithValue(
          AsyncData([_account(currency: 'USD')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(subscriptionsControllerProvider.notifier)
        .save(
          subscriptionId: 'sub-existing',
          name: 'Gym',
          amountMinorUnits: 3000,
        );

    expect(saved, isTrue);
    expect(repository.updated?.id, 'sub-existing');
    expect(repository.created, isNull);
  });

  test('changing billing currency preserves the usual debit account', () async {
    final repository = _FakeSubscriptionsRepository();
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
        activeAccountsProvider.overrideWithValue(
          AsyncData([_account(currency: 'USD')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(subscriptionsControllerProvider.notifier)
        .save(
          subscriptionId: 'sub-existing',
          name: 'Rent',
          amountMinorUnits: 185000,
          currency: 'CAD',
          accountId: 'account-usd-default',
        );

    expect(saved, isTrue);
    expect(repository.updated?.amount.currency, 'CAD');
    expect(repository.updated?.accountId, 'account-usd-default');
  });

  test('delete returns false and exposes repository failures', () async {
    final repository = _FakeSubscriptionsRepository(failDelete: true);
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final deleted = await container
        .read(subscriptionsControllerProvider.notifier)
        .delete('sub-bad');

    expect(deleted, isFalse);
    expect(container.read(subscriptionsControllerProvider).hasError, isTrue);
  });

  test('mock repository emits create, update, and delete changes', () async {
    final repository = MockSubscriptionsRepository();
    addTearDown(repository.dispose);
    final initial = await repository.fetchForHousehold('demo-household');
    final events = <List<SubscriptionItem>>[];
    final subscription = repository
        .watchForHousehold('demo-household')
        .listen(events.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    final created = await repository.create(
      initial.first.copyWith(id: '', name: 'Disney+'),
    );
    await repository.update(created.copyWith(name: 'Disney Plus'));
    await repository.delete(created.id);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(4));
    expect(events[1].any((item) => item.id == created.id), isTrue);
    expect(
      events[2].singleWhere((item) => item.id == created.id).name,
      'Disney Plus',
    );
    expect(events[3].any((item) => item.id == created.id), isFalse);
  });

  test('advanceNextCharge persists the rolled-forward date', () async {
    final repository = MockSubscriptionsRepository();
    addTearDown(repository.dispose);
    final initial = await repository.fetchForHousehold('demo-household');
    final target = initial.firstWhere((item) => item.nextChargeAt != null);

    final stale = await repository.update(
      target.copyWith(
        frequency: SubscriptionFrequency.monthly,
        nextChargeAt: DateTime(2026, 1, 10),
      ),
    );
    final advanced = await repository.advanceNextCharge(
      stale,
      now: DateTime(2026, 3, 15),
    );

    expect(advanced.nextChargeAt, DateTime(2026, 4, 10));
    final reloaded = await repository.fetchForHousehold('demo-household');
    expect(
      reloaded.singleWhere((item) => item.id == target.id).nextChargeAt,
      DateTime(2026, 4, 10),
    );
  });
}

FinancialAccount _account({required String currency}) => FinancialAccount(
  id: 'account-${currency.toLowerCase()}-default',
  householdId: 'demo-household',
  name: '$currency account',
  currency: currency,
  openingBalance: Money(minorUnits: 0, currency: currency),
  openingBalanceAt: DateTime(2026),
  isDefault: true,
);

class _FakeSubscriptionsRepository implements SubscriptionsRepository {
  _FakeSubscriptionsRepository({this.failDelete = false});

  final bool failDelete;
  SubscriptionItem? created;
  SubscriptionItem? updated;

  @override
  Future<SubscriptionItem> create(SubscriptionItem item) async {
    created = item;
    return item.copyWith(id: 'created-sub');
  }

  @override
  Future<void> delete(String subscriptionId) async {
    if (failDelete) throw StateError('delete failed');
  }

  @override
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId) async =>
      const [];

  @override
  Future<SubscriptionItem> update(SubscriptionItem item) async {
    updated = item;
    return item;
  }

  @override
  Stream<List<SubscriptionItem>> watchForHousehold(String householdId) =>
      const Stream.empty();

  @override
  Future<SubscriptionItem> advanceNextCharge(
    SubscriptionItem item, {
    DateTime? now,
  }) async => item;
}
