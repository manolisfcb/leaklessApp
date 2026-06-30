import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../domain/models/household_member.dart';
import '../../../../shared/widgets/widgets.dart';

/// The "frente a frente" couple section: two profile bubbles joined by a glowing
/// thread that signals shared, real-time activity.
class CoupleHeader extends StatelessWidget {
  const CoupleHeader({required this.members, super.key});

  final List<HouseholdMember> members;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (members.isEmpty) return const SizedBox.shrink();
    final first = members.first;
    final second = members.length > 1 ? members[1] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Member(member: first),
        if (second != null) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: AppGradients.liquid(colors),
                  borderRadius: AppRadii.pillRadius,
                  boxShadow: AppShadows.glow(colors.goal),
                ),
              ),
            ),
          ),
          _Member(member: second),
        ],
      ],
    );
  }
}

class _Member extends StatelessWidget {
  const _Member({required this.member});
  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileBubble(initials: member.initials, active: true),
        AppSpacing.gapXs,
        Text(member.displayName, style: AppTypography.labelSmall),
      ],
    );
  }
}
