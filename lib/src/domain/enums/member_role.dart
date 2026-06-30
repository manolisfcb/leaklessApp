import 'package:json_annotation/json_annotation.dart';

/// A member's role within a household.
enum MemberRole {
  @JsonValue('owner')
  owner,
  @JsonValue('member')
  member;

  String get label => switch (this) {
    MemberRole.owner => 'Propietario',
    MemberRole.member => 'Miembro',
  };

  bool get isOwner => this == MemberRole.owner;
}
