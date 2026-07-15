import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/user_profile.dart';
import 'profile_mapper.dart';

/// Reads/writes the signed-in user's [UserProfile], including the avatar image.
abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();

  /// Updates editable fields; unspecified (`null`) fields are left untouched.
  /// Returns the fresh profile row.
  Future<UserProfile> updateProfile({String? displayName, String? currency});

  /// Uploads [bytes] to the `avatars` Storage bucket, links it on the profile
  /// and returns the updated profile. [fileExtension] is the image extension
  /// (e.g. `png`, `jpg`) used for the object name and content type.
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  });
}

/// Mock profile backed by [DemoData], with in-memory edits so the settings UI
/// reflects changes before the backend is wired (mirrors the real repository's
/// "return the fresh profile" contract).
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository();

  UserProfile _profile = DemoData.profile;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
  }) async {
    _profile = _profile.copyWith(
      displayName: displayName ?? _profile.displayName,
      currency: currency ?? _profile.currency,
      updatedAt: DateTime.now(),
    );
    return _profile;
  }

  @override
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    _profile = _profile.copyWith(
      avatarUrl: 'https://picsum.photos/seed/${_profile.id}/200',
      updatedAt: DateTime.now(),
    );
    return _profile;
  }
}

/// Supabase-backed profile reads/writes for the signed-in user.
///
/// The `profiles` row is keyed by the auth user id (RLS: `id = auth.uid()`), so
/// every method scopes to `auth.currentUser`. Avatars live in the private
/// `avatars` bucket under `<user-id>/…` (the Storage RLS policy only lets a user
/// touch their own folder).
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'avatars';

  /// TTL for the avatar's signed URL persisted in `profiles.avatar_url`. The
  /// bucket is private, so we store a signed URL rather than a public one; it
  /// refreshes on every upload. This is what the *partner* sees for this user
  /// (the member representation reads the persisted column), so it stays
  /// long-lived until the proper server-side signing lands (§1.x follow-up).
  static const _avatarUrlTtlSeconds = 60 * 60 * 24 * 365; // 1 year.

  /// TTL for the freshly-signed URL handed to the *owner's* own profile read —
  /// short, because [fetchCurrentProfile] re-signs it every time rather than
  /// relying on the year-long persisted value.
  static const _readUrlTtlSeconds = 60 * 60; // 1 hour.

  SupabaseQueryBuilder get _table => _client.from('profiles');

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _table.select().eq('id', userId).maybeSingle();
      if (row == null) return null;
      final profile = ProfileMapper.fromRow(row);
      if (profile.avatarUrl == null) return profile;
      // Don't trust the persisted (year-long) URL for our own view — resolve a
      // fresh short-lived signed URL from the object itself.
      return profile.copyWith(
        avatarUrl: await _freshAvatarUrl(userId, fallback: profile.avatarUrl),
      );
    } catch (e, s) {
      throw ServerException('Failed to load profile', cause: e, stackTrace: s);
    }
  }

  /// Re-signs the user's avatar object into a short-lived URL. Best-effort: on
  /// any failure it returns [fallback] so a signing hiccup never fails the whole
  /// profile load.
  Future<String?> _freshAvatarUrl(String userId, {String? fallback}) async {
    try {
      final objects = await _client.storage.from(_bucket).list(path: userId);
      for (final object in objects) {
        if (!object.name.startsWith('avatar.')) continue;
        return await _client.storage
            .from(_bucket)
            .createSignedUrl('$userId/${object.name}', _readUrlTtlSeconds);
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
  }) async {
    final userId = _requireUserId();
    final updates = <String, dynamic>{
      'display_name': ?displayName,
      'currency': ?currency,
    };
    if (updates.isEmpty) return _requireProfile(userId);
    try {
      final row = await _table
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return ProfileMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to update profile',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = _requireUserId();
    try {
      // Owner-scoped path so the "avatars owner manage" RLS policy allows it.
      final path = '$userId/avatar.$fileExtension';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExtension',
            ),
          );
      final signedUrl = await _client.storage
          .from(_bucket)
          .createSignedUrl(path, _avatarUrlTtlSeconds);
      final row = await _table
          .update({'avatar_url': signedUrl})
          .eq('id', userId)
          .select()
          .single();
      return ProfileMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException('Failed to upload avatar', cause: e, stackTrace: s);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthFailureException('Not signed in');
    }
    return userId;
  }

  Future<UserProfile> _requireProfile(String userId) async {
    final row = await _table.select().eq('id', userId).maybeSingle();
    if (row == null) {
      throw const NotFoundException('Profile not found');
    }
    return ProfileMapper.fromRow(row);
  }
}
