import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics/analytics_service.dart';
import 'monitoring/crash_reporter.dart';

/// Crash & error reporting (Crashlytics-backed, no-op until configured).
final crashReporterProvider = Provider<CrashReporter>((ref) => CrashReporter());

/// App analytics (Firebase-backed, no-op until configured).
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
