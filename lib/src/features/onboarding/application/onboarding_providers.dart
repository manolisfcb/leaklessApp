import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs/prefs_providers.dart';

/// Tracks whether the user has completed onboarding (persisted in prefs).
class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding_completed';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }

  /// Test/dev helper to replay onboarding.
  Future<void> reset() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = false;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
