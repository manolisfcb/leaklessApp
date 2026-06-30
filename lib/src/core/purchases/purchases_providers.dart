import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entitlement.dart';
import '../config/config_providers.dart';
import 'purchases_service.dart';

/// The RevenueCat service (free tier until a key is configured).
final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => PurchasesService(ref.watch(appConfigProvider)),
);

/// The user's current premium [Entitlement], updating live with RevenueCat.
final entitlementProvider = StreamProvider<Entitlement>((ref) {
  final service = ref.watch(purchasesServiceProvider);
  final controller = StreamController<Entitlement>();

  unawaited(
    service.currentEntitlement().then(controller.add).catchError(
          (Object _) => controller.add(Entitlement.free),
        ),
  );
  final unsubscribe = service.listen(controller.add);

  ref.onDispose(() {
    unsubscribe();
    unawaited(controller.close());
  });
  return controller.stream;
});

/// Convenience flag for gating premium features in the UI.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(entitlementProvider).asData?.value.isPremium ?? false,
);
