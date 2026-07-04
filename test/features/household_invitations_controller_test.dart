import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/errors/app_exception.dart';
import 'package:leakless/src/domain/enums/household_invitation_status.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/household_invitation.dart';
import 'package:leakless/src/domain/models/household_member.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/household/data/household_repository.dart';
import 'package:leakless/src/features/profile/application/profile_providers.dart';

void main() {
  test('accept refreshes household, members, and profile scope', () async {
    final repository = _FakeHouseholdRepository();
    var profileBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith((ref) async {
          profileBuilds++;
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);

    expect((await container.read(currentHouseholdProvider.future))?.id, 'old');
    expect(
      (await container.read(
        householdMembersProvider.future,
      )).single.householdId,
      'old',
    );
    await container.read(currentProfileProvider.future);

    final result = await container
        .read(householdInvitationsControllerProvider.notifier)
        .accept('valid-token');

    expect(result?.status, HouseholdInvitationStatus.accepted);
    expect(
      container.read(householdInvitationsControllerProvider).value?.householdId,
      'shared',
    );
    expect(
      (await container.read(currentHouseholdProvider.future))?.id,
      'shared',
    );
    expect(
      (await container.read(
        householdMembersProvider.future,
      )).single.householdId,
      'shared',
    );
    await container.read(currentProfileProvider.future);
    expect(profileBuilds, 2);
  });

  test(
    'controller exposes repository errors without throwing into UI',
    () async {
      final repository = _FakeHouseholdRepository(failAcceptance: true);
      final container = ProviderContainer(
        overrides: [householdRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(householdInvitationsControllerProvider.notifier)
          .accept('bad-token');

      expect(result, isNull);
      final state = container.read(householdInvitationsControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error! as ServerException).code,
        'invalid_invitation_token',
      );
    },
  );
}

class _FakeHouseholdRepository implements HouseholdRepository {
  _FakeHouseholdRepository({this.failAcceptance = false});

  final bool failAcceptance;
  var _householdId = 'old';

  @override
  Future<Household?> fetchCurrentHousehold() async => Household(
    id: _householdId,
    name: _householdId == 'old' ? 'Mi casa' : 'Casa compartida',
    ownerId: 'owner',
  );

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async => [
    HouseholdMember(
      id: 'member-$householdId',
      householdId: householdId,
      userId: 'user',
      displayName: 'User',
    ),
  ];

  @override
  Future<Household> configureHousehold({
    required String householdId,
    required String name,
    required String currency,
  }) async => Household(
    id: householdId,
    name: name,
    ownerId: 'owner',
    currency: currency,
    setupCompleted: true,
  );

  @override
  Future<HouseholdInvitation> createInvitation({
    required String householdId,
    required String email,
    Duration expiresIn = const Duration(days: 7),
  }) async => HouseholdInvitation(
    id: 'invitation',
    householdId: householdId,
    invitedEmail: email,
    status: HouseholdInvitationStatus.pending,
    token: 'valid-token',
  );

  @override
  Future<HouseholdInvitation> inspectInvitation(String token) async =>
      HouseholdInvitation(
        id: 'invitation',
        householdId: _householdId,
        status: HouseholdInvitationStatus.pending,
      );

  @override
  Future<HouseholdInvitation> cancelInvitation(String invitationId) async =>
      HouseholdInvitation(
        id: invitationId,
        householdId: _householdId,
        status: HouseholdInvitationStatus.cancelled,
      );

  @override
  Future<HouseholdInvitation> acceptInvitation(String token) async {
    if (failAcceptance) {
      throw const ServerException(
        'Invalid invitation token',
        code: 'invalid_invitation_token',
      );
    }
    _householdId = 'shared';
    return const HouseholdInvitation(
      id: 'invitation',
      householdId: 'shared',
      status: HouseholdInvitationStatus.accepted,
    );
  }
}
