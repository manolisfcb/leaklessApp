import 'package:freezed_annotation/freezed_annotation.dart';

part 'entitlement.freezed.dart';
part 'entitlement.g.dart';

/// The user's premium access, derived from RevenueCat.
///
/// Lives in the domain (not tied to `purchases_flutter`) so the UI and use
/// cases reason about access without importing the SDK (quality rule #7).
@freezed
abstract class Entitlement with _$Entitlement {
  const factory Entitlement({
    required bool isActive,
    String? productId,
    DateTime? expirationDate,
    @Default(false) bool willRenew,
  }) = _Entitlement;
  const Entitlement._();

  factory Entitlement.fromJson(Map<String, dynamic> json) =>
      _$EntitlementFromJson(json);

  /// The default "free tier" entitlement.
  static const Entitlement free = Entitlement(isActive: false);

  bool get isPremium => isActive;
}
