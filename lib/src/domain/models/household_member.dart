import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/member_role.dart';

part 'household_member.freezed.dart';
part 'household_member.g.dart';

/// A person who belongs to a [Household].
@freezed
abstract class HouseholdMember with _$HouseholdMember {
  const factory HouseholdMember({
    required String id,
    required String householdId,
    required String userId,
    required String displayName,
    @Default(MemberRole.member) MemberRole role,
    String? avatarUrl,
    DateTime? createdAt,
  }) = _HouseholdMember;
  const HouseholdMember._();

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberFromJson(json);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
