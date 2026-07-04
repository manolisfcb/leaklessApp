import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/user_profile.dart';
import '../../household/application/household_providers.dart';
import '../data/profile_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [householdRepositoryProvider].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
  }
  return MockProfileRepository();
});

/// The signed-in user's profile.
final currentProfileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).fetchCurrentProfile(),
);

/// Drives edits to the signed-in user's profile (name, currency, avatar) and
/// exposes their loading/error state to the UI. Mirrors the
/// [HouseholdSetupController] pattern: methods never throw into the widget,
/// they land the failure in [state] and return `null`.
class ProfileController extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() => const AsyncData(null);

  Future<UserProfile?> updateProfile({
    String? displayName,
    String? currency,
  }) => _run(
    () => ref.read(profileRepositoryProvider).updateProfile(
      displayName: displayName,
      currency: currency,
    ),
  );

  Future<UserProfile?> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) => _run(
    () => ref.read(profileRepositoryProvider).uploadAvatar(
      bytes: bytes,
      fileExtension: fileExtension,
    ),
  );

  Future<UserProfile?> _run(Future<UserProfile> Function() action) async {
    state = const AsyncLoading();
    try {
      final profile = await action();
      // Keep `profiles` and the member representation (settings header, couple
      // thread) in sync — both read the profile's name/avatar.
      ref.invalidate(currentProfileProvider);
      ref.invalidate(householdMembersProvider);
      state = AsyncData(profile);
      return profile;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<UserProfile?>>(
      ProfileController.new,
    );
