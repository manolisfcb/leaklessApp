import '../router/app_routes.dart';
import 'notification_service.dart';

/// Translates a push payload into an in-app destination.
///
/// Push messages carry a `type` (and optional ids) in their `data` map; this
/// maps that to a route path the app can navigate to. Pure & dependency-free so
/// it is trivially testable.
class NotificationRouter {
  const NotificationRouter();

  /// Returns the route path for [message], or `null` to stay where we are.
  String? routeFor(NotificationMessage message) {
    final type = message.data['type'] as String?;
    return switch (type) {
      'transaction_created' => AppRoutes.transactions,
      'budget_alert' => AppRoutes.budgets,
      'goal_contribution' => AppRoutes.goals,
      'limit_reached' => AppRoutes.budgets,
      'recurring_reminder' => AppRoutes.subscriptions,
      _ => AppRoutes.dashboard,
    };
  }
}
