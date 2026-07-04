import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/features/household/data/household_mapper.dart';
import 'package:leakless/src/features/household/data/household_repository.dart';

void main() {
  test('household mapper reads the persisted setup state', () {
    final household = HouseholdMapper.fromRow({
      'id': 'household',
      'name': 'Casa Norte',
      'owner_id': 'owner',
      'currency': 'CAD',
      'setup_completed': true,
    });

    expect(household.setupCompleted, isTrue);
    expect(household.currency, 'CAD');
  });

  test('mock configuration normalizes values and completes setup', () async {
    final repository = MockHouseholdRepository();

    final configured = await repository.configureHousehold(
      householdId: 'demo-household',
      name: '  Casa Norte  ',
      currency: 'cad',
    );

    expect(configured.name, 'Casa Norte');
    expect(configured.currency, 'CAD');
    expect(configured.setupCompleted, isTrue);
    expect(await repository.fetchCurrentHousehold(), configured);
  });
}
