import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/router/app_routes.dart';
import 'package:leakless/src/features/household/application/invitation_links.dart';

void main() {
  const upperToken =
      'ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789';
  const normalizedToken =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  test('builds and parses the centralized custom-scheme invitation URI', () {
    final uri = InvitationLinks.invitationUri(upperToken);

    expect(uri.scheme, InvitationLinks.scheme);
    expect(uri.host, InvitationLinks.host);
    expect(uri.path, AppRoutes.invitation);
    expect(InvitationLinks.tokenFromUri(uri), normalizedToken);
  });

  test(
    'accepts a router-relative invite and rejects unrelated or bad links',
    () {
      expect(
        InvitationLinks.tokenFromUri(
          Uri.parse('${AppRoutes.invitation}?token=$upperToken'),
        ),
        normalizedToken,
      );
      expect(
        InvitationLinks.tokenFromUri(Uri.parse('/dashboard?token=$upperToken')),
        isNull,
      );
      expect(
        InvitationLinks.tokenFromUri(
          Uri.parse('other://app/invite?token=$upperToken'),
        ),
        isNull,
      );
      expect(InvitationLinks.normalizeToken('short'), isNull);
    },
  );
}
