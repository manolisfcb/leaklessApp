import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/models/entitlement.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Wraps RevenueCat (`purchases_flutter`) and exposes the user's [Entitlement]
/// in domain terms, so the UI never imports the SDK (quality rule #5/#7).
///
/// No-ops to the free tier when no RevenueCat key is configured.
class PurchasesService {
  PurchasesService(this._config);

  final AppConfig _config;
  final _log = AppLogger.of('Purchases');
  bool _configured = false;

  bool get _enabled => _config.hasRevenueCat;

  /// Configures the SDK once. Safe to call repeatedly.
  Future<void> configure() async {
    if (!_enabled || _configured) return;
    await Purchases.configure(
      PurchasesConfiguration(_config.revenueCatKeyForPlatform),
    );
    _configured = true;
    _log.info('RevenueCat configured.');
  }

  /// Fetches the current entitlement (free tier when not configured).
  Future<Entitlement> currentEntitlement() async {
    if (!_enabled) return Entitlement.free;
    await configure();
    final info = await Purchases.getCustomerInfo();
    return _map(info);
  }

  /// Subscribes to entitlement changes; returns a disposer to unsubscribe.
  void Function() listen(void Function(Entitlement) onChange) {
    if (!_enabled) return () {};
    void callback(CustomerInfo info) => onChange(_map(info));
    Purchases.addCustomerInfoUpdateListener(callback);
    return () => Purchases.removeCustomerInfoUpdateListener(callback);
  }

  Entitlement _map(CustomerInfo info) {
    final active = info.entitlements.active.values;
    if (active.isEmpty) return Entitlement.free;
    final entitlement = active.first;
    return Entitlement(
      isActive: entitlement.isActive,
      productId: entitlement.productIdentifier,
      willRenew: entitlement.willRenew,
      expirationDate: entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!),
    );
  }
}
