import '../../../core/dev/demo_data.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_member.dart';

/// Reads the current household and its members.
abstract interface class HouseholdRepository {
  Future<Household?> fetchCurrentHousehold();
  Future<List<HouseholdMember>> fetchMembers(String householdId);
}

/// Mock household backed by [DemoData]. Replace with a Supabase implementation
/// (joining `households` + `household_members`) when the backend is wired.
class MockHouseholdRepository implements HouseholdRepository {
  const MockHouseholdRepository();

  @override
  Future<Household?> fetchCurrentHousehold() async => DemoData.household;

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async =>
      DemoData.members;
}
