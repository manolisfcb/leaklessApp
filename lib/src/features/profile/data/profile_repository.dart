import '../../../core/dev/demo_data.dart';
import '../../../domain/models/user_profile.dart';

/// Reads/writes the signed-in user's [UserProfile].
abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();
}

/// Mock profile backed by [DemoData]. Swap for a Supabase implementation
/// (querying the `profiles` table) once the backend is configured.
class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<UserProfile?> fetchCurrentProfile() async => DemoData.profile;
}
