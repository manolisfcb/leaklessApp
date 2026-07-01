import '../../domain/domain.dart';

/// Sample content used by the mock repositories until the Supabase backend is
/// wired. Centralized here so no two repositories duplicate fixtures
/// (quality rule #1). Safe to delete once real data flows.
abstract final class DemoData {
  DemoData._();

  static const String householdId = 'demo-household';
  static const String currency = 'USD';

  static final DateTime _now = DateTime.now();
  static DateTime _daysAgo(int d) => _now.subtract(Duration(days: d));

  static const Household household = Household(
    id: householdId,
    name: 'Nuestra casa',
    ownerId: 'demo-me',
    currency: currency,
  );

  static const List<HouseholdMember> members = [
    HouseholdMember(
      id: 'demo-me',
      householdId: householdId,
      userId: 'demo-me',
      displayName: 'Manuel',
      role: MemberRole.owner,
    ),
    HouseholdMember(
      id: 'demo-partner',
      householdId: householdId,
      userId: 'demo-partner',
      displayName: 'Marien',
    ),
  ];

  static const UserProfile profile = UserProfile(
    id: 'demo-me',
    displayName: 'Manuel',
    householdId: householdId,
    currency: currency,
  );

  static const List<TransactionCategory> categories = [
    TransactionCategory(
      id: 'cat-groceries',
      name: 'Supermercado',
      iconName: 'cart',
      isDefault: true,
    ),
    TransactionCategory(
      id: 'cat-dining',
      name: 'Restaurantes',
      iconName: 'restaurant',
      isDefault: true,
    ),
    TransactionCategory(
      id: 'cat-transport',
      name: 'Transporte',
      iconName: 'car',
      isDefault: true,
    ),
    TransactionCategory(
      id: 'cat-leisure',
      name: 'Ocio',
      iconName: 'movie',
      isDefault: true,
    ),
    TransactionCategory(
      id: 'cat-subscriptions',
      name: 'Suscripciones',
      iconName: 'subscriptions',
      isDefault: true,
    ),
    TransactionCategory(
      id: 'cat-savings',
      name: 'Ahorro',
      iconName: 'savings',
      isDefault: true,
    ),
  ];

  static List<Transaction> transactions() => [
    Transaction(
      id: 'tx-1',
      householdId: householdId,
      amount: Money.fromMajor(24.5, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.ant,
      responsible: ResponsibleType.partner,
      categoryId: 'cat-transport',
      responsibleMemberId: 'demo-partner',
      description: 'Uber al centro',
      occurredAt: _daysAgo(0),
    ),
    Transaction(
      id: 'tx-2',
      householdId: householdId,
      amount: Money.fromMajor(86.2, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.necessity,
      responsible: ResponsibleType.shared,
      categoryId: 'cat-groceries',
      responsibleMemberId: 'demo-me',
      description: 'Compra semanal',
      occurredAt: _daysAgo(1),
    ),
    Transaction(
      id: 'tx-3',
      householdId: householdId,
      amount: Money.fromMajor(15.99, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.lifestyle,
      responsible: ResponsibleType.me,
      categoryId: 'cat-subscriptions',
      responsibleMemberId: 'demo-me',
      description: 'Netflix',
      occurredAt: _daysAgo(2),
    ),
    Transaction(
      id: 'tx-4',
      householdId: householdId,
      amount: Money.fromMajor(48.0, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.lifestyle,
      responsible: ResponsibleType.partner,
      categoryId: 'cat-dining',
      responsibleMemberId: 'demo-partner',
      description: 'Cena tailandesa',
      occurredAt: _daysAgo(3),
    ),
    Transaction(
      id: 'tx-5',
      householdId: householdId,
      amount: Money.fromMajor(3.5, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.ant,
      responsible: ResponsibleType.me,
      categoryId: 'cat-dining',
      responsibleMemberId: 'demo-me',
      description: 'Café',
      occurredAt: _daysAgo(3),
    ),
    Transaction(
      id: 'tx-6',
      householdId: householdId,
      amount: Money.fromMajor(2100, currency: currency),
      type: TransactionType.income,
      priority: TransactionPriority.necessity,
      responsible: ResponsibleType.me,
      categoryId: null,
      responsibleMemberId: 'demo-me',
      description: 'Nómina',
      occurredAt: _daysAgo(5),
    ),
    Transaction(
      id: 'tx-7',
      householdId: householdId,
      amount: Money.fromMajor(300, currency: currency),
      type: TransactionType.expense,
      priority: TransactionPriority.future,
      responsible: ResponsibleType.shared,
      categoryId: 'cat-savings',
      responsibleMemberId: 'demo-me',
      description: 'Aporte fondo emergencia',
      occurredAt: _daysAgo(6),
    ),
  ];

  static List<Budget> budgets() {
    final periodStart = DateTime(_now.year, _now.month);
    return [
      Budget(
        id: 'bud-groceries',
        householdId: householdId,
        categoryId: 'cat-groceries',
        limit: Money.fromMajor(500, currency: currency),
        spent: Money.fromMajor(286, currency: currency),
        periodStart: periodStart,
      ),
      Budget(
        id: 'bud-dining',
        householdId: householdId,
        categoryId: 'cat-dining',
        limit: Money.fromMajor(250, currency: currency),
        spent: Money.fromMajor(198, currency: currency), // ~79% → warning
        periodStart: periodStart,
      ),
      Budget(
        id: 'bud-transport',
        householdId: householdId,
        categoryId: 'cat-transport',
        limit: Money.fromMajor(150, currency: currency),
        spent: Money.fromMajor(172, currency: currency), // >100% → exceeded
        periodStart: periodStart,
      ),
      Budget(
        id: 'bud-leisure',
        householdId: householdId,
        categoryId: 'cat-leisure',
        limit: Money.fromMajor(200, currency: currency),
        spent: Money.fromMajor(64, currency: currency),
        periodStart: periodStart,
      ),
    ];
  }

  static List<Goal> goals() => [
    Goal(
      id: 'goal-emergency',
      householdId: householdId,
      name: 'Fondo de emergencia',
      target: Money.fromMajor(6000, currency: currency),
      saved: Money.fromMajor(2400, currency: currency),
      deadline: _now.add(const Duration(days: 240)),
    ),
    Goal(
      id: 'goal-japan',
      householdId: householdId,
      name: 'Viaje a Japón',
      target: Money.fromMajor(4000, currency: currency),
      saved: Money.fromMajor(3600, currency: currency),
      deadline: _now.add(const Duration(days: 90)),
    ),
    Goal(
      id: 'goal-cushion',
      householdId: householdId,
      name: 'Colchón 3 meses',
      target: Money.fromMajor(9000, currency: currency),
      saved: Money.fromMajor(9000, currency: currency),
      status: GoalStatus.completed,
    ),
  ];

  static List<SubscriptionItem> subscriptions() => [
    SubscriptionItem(
      id: 'sub-netflix',
      householdId: householdId,
      name: 'Netflix',
      amount: Money.fromMajor(15.99, currency: currency),
      categoryId: 'cat-subscriptions',
      nextChargeAt: _now.add(const Duration(days: 12)),
    ),
    SubscriptionItem(
      id: 'sub-spotify',
      householdId: householdId,
      name: 'Spotify',
      amount: Money.fromMajor(9.99, currency: currency),
      categoryId: 'cat-subscriptions',
      nextChargeAt: _now.add(const Duration(days: 4)),
    ),
    SubscriptionItem(
      id: 'sub-gym',
      householdId: householdId,
      name: 'Gimnasio',
      amount: Money.fromMajor(30, currency: currency),
      categoryId: 'cat-subscriptions',
      nextChargeAt: _now.add(const Duration(days: 20)),
    ),
  ];
}
