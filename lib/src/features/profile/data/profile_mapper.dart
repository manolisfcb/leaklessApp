import '../../../domain/models/user_profile.dart';

/// Translates between the Supabase `profiles` row shape (snake_case) and the
/// domain [UserProfile].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7), same as `TransactionMapper`.
abstract final class ProfileMapper {
  ProfileMapper._();

  static UserProfile fromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    displayName: (row['display_name'] as String?) ?? '',
    householdId: row['household_id'] as String?,
    avatarUrl: row['avatar_url'] as String?,
    currency: (row['currency'] as String?) ?? 'USD',
    createdAt: _parseDate(row['created_at']),
    updatedAt: _parseDate(row['updated_at']),
  );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
