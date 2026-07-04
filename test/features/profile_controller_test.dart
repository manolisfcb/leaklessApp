import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/errors/app_exception.dart';
import 'package:leakless/src/domain/models/user_profile.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/profile/application/profile_providers.dart';
import 'package:leakless/src/features/profile/data/profile_repository.dart';

void main() {
  test('updateProfile lands the fresh profile and refreshes scope', () async {
    final repository = _FakeProfileRepository();
    var memberBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        householdMembersProvider.overrideWith((ref) async {
          memberBuilds++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(householdMembersProvider.future);

    final saved = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(displayName: 'Marien', currency: 'EUR');

    expect(saved?.displayName, 'Marien');
    expect(saved?.currency, 'EUR');
    expect(container.read(profileControllerProvider).value?.displayName, 'Marien');

    // Member representation is invalidated so it re-reads the new name/avatar.
    await container.read(householdMembersProvider.future);
    expect(memberBuilds, 2);
  });

  test('uploadAvatar lands the updated profile', () async {
    final repository = _FakeProfileRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(profileControllerProvider.notifier)
        .uploadAvatar(bytes: Uint8List(4), fileExtension: 'jpg');

    expect(saved?.avatarUrl, 'https://cdn/avatar.jpg');
  });

  test('errors surface in state without throwing into the UI', () async {
    final repository = _FakeProfileRepository(fail: true);
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(displayName: '');

    expect(saved, isNull);
    final state = container.read(profileControllerProvider);
    expect(state.hasError, isTrue);
    expect((state.error! as ServerException).code, 'invalid_display_name');
  });
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.fail = false});

  final bool fail;
  UserProfile _profile = const UserProfile(id: 'me', displayName: 'Manuel');

  @override
  Future<UserProfile?> fetchCurrentProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
  }) async {
    if (fail) {
      throw const ServerException('bad name', code: 'invalid_display_name');
    }
    _profile = _profile.copyWith(
      displayName: displayName ?? _profile.displayName,
      currency: currency ?? _profile.currency,
    );
    return _profile;
  }

  @override
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    _profile = _profile.copyWith(avatarUrl: 'https://cdn/avatar.$fileExtension');
    return _profile;
  }
}
