import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/user_profile.dart';
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
