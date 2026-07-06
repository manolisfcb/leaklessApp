import 'package:json_annotation/json_annotation.dart';

/// A member's role within a household.
enum MemberRole {
  @JsonValue('owner')
  owner,
  @JsonValue('member')
  member;

  bool get isOwner => this == MemberRole.owner;
}
