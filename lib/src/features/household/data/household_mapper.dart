import '../../../domain/enums/member_role.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_member.dart';

/// Translates between the Supabase `households` / `household_members` row shapes
/// (snake_case) and the domain models.
///
/// This is the only place that knows those tables' column names, keeping the
/// domain backend-agnostic (quality rule #7). Enum `.name`s deliberately match
/// the DB string values (see the migration).
abstract final class HouseholdMapper {
  HouseholdMapper._();

  static Household fromRow(Map<String, dynamic> row) => Household(
    id: row['id'] as String,
    name: row['name'] as String,
    ownerId: row['owner_id'] as String,
    currency: (row['currency'] as String?) ?? 'USD',
    createdAt: _parseDate(row['created_at']),
    updatedAt: _parseDate(row['updated_at']),
  );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Maps `household_members` rows to [HouseholdMember].
abstract final class HouseholdMemberMapper {
  HouseholdMemberMapper._();

  static HouseholdMember fromRow(Map<String, dynamic> row) => HouseholdMember(
    id: row['id'] as String,
    householdId: row['household_id'] as String,
    userId: row['user_id'] as String,
    displayName: (row['display_name'] as String?) ?? '',
    role: _enumByName(MemberRole.values, row['role'], MemberRole.member),
    avatarUrl: row['avatar_url'] as String?,
    createdAt: _parseDate(row['created_at']),
  );

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    final name = raw as String?;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
