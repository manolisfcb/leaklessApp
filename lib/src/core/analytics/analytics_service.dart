import 'package:firebase_analytics/firebase_analytics.dart';

import '../firebase/firebase_initializer.dart';

/// App analytics, backed by Firebase Analytics.
///
/// Safe no-ops when Firebase is not configured. Keep event names centralized
/// here as the surface grows so they stay consistent.
class AnalyticsService {
  AnalyticsService();

  bool get _enabled => FirebaseInitializer.isReady;

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: params);
  }

  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> setUserId(String? id) async {
    if (!_enabled) return;
    await _analytics.setUserId(id: id);
  }

  // --- Domain events ---------------------------------------------------------

  Future<void> transactionCreated() => logEvent('transaction_created');
  Future<void> goalContribution() => logEvent('goal_contribution');
}
