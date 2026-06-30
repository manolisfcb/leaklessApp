import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// The user's editable profile, one row per auth user.
///
/// JSON here uses plain camelCase (for local caching); translation to/from the
/// Supabase `profiles` table is the job of the data-layer mappers, keeping the
/// domain free of backend naming (quality rule #7).
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    String? householdId,
    String? avatarUrl,
    @Default('USD') String currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfile;
  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Initials shown on the profile bubble when there is no avatar.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
