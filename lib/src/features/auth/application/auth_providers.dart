import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/app_user.dart';
import '../data/auth_repository.dart';

/// Picks the real or fake [AuthRepository] depending on whether Supabase is
/// configured & initialized.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
  }
  final repo = FakeAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Streams the signed-in [AppUser] (or null). Drives route redirects.
final authStateChangesProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The current user, synchronously, once known.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateChangesProvider).asData?.value,
);

/// Whether someone is signed in.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
);
