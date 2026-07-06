import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/notifications/notification_router.dart';
import 'package:leakless/src/core/notifications/notification_service.dart';
import 'package:leakless/src/core/router/app_routes.dart';

void main() {
  const router = NotificationRouter();

  NotificationMessage message(String? type) =>
      NotificationMessage(data: type == null ? const {} : {'type': type});

  test('routes both budget alert push types to budgets', () {
    expect(router.routeFor(message('budget_alert')), AppRoutes.budgets);
    expect(router.routeFor(message('limit_reached')), AppRoutes.budgets);
  });

  test('routes recurring reminder taps to subscriptions', () {
    expect(
      router.routeFor(message('recurring_reminder')),
      AppRoutes.subscriptions,
    );
  });

  test('unknown or missing type falls back to the dashboard', () {
    expect(router.routeFor(message('something_else')), AppRoutes.dashboard);
    expect(router.routeFor(message(null)), AppRoutes.dashboard);
  });
}
