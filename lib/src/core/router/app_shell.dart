import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/income_sources/presentation/income_entry_sheet.dart';
import '../../features/quick_entry/presentation/quick_entry_sheet.dart';
import '../../features/transfers/presentation/transfer_entry_sheet.dart';
import '../../shared/widgets/widgets.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// The bottom-navigation scaffold that hosts the five main tabs and the central
/// quick-entry action. Each branch screen brings its own [GlassScaffold] (and
/// thus the gradient background), so this shell stays transparent.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onQuickEntry: () => _openEntryChooser(context),
      ),
    );
  }

  Future<void> _openEntryChooser(BuildContext context) async {
    final choice = await GlassBottomSheet.show<_EntryKind>(
      context,
      title: context.l10n.movementNew,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EntryChoice(
            icon: CupertinoIcons.arrow_up_circle,
            label: context.l10n.movementExpense,
            onTap: () => Navigator.pop(sheetContext, _EntryKind.expense),
          ),
          AppSpacing.gapSm,
          _EntryChoice(
            icon: CupertinoIcons.arrow_down_circle,
            label: context.l10n.movementIncome,
            onTap: () => Navigator.pop(sheetContext, _EntryKind.income),
          ),
          AppSpacing.gapSm,
          _EntryChoice(
            icon: CupertinoIcons.arrow_right_arrow_left_circle,
            label: context.l10n.movementTransfer,
            onTap: () => Navigator.pop(sheetContext, _EntryKind.transfer),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    await GlassBottomSheet.show<void>(
      context,
      title: switch (choice) {
        _EntryKind.expense => context.l10n.movementExpense,
        _EntryKind.income => context.l10n.movementIncome,
        _EntryKind.transfer => context.l10n.movementTransfer,
      },
      builder: (_) => switch (choice) {
        _EntryKind.expense => const QuickEntrySheet(),
        _EntryKind.income => const IncomeEntrySheet(),
        _EntryKind.transfer => const TransferEntrySheet(),
      },
    );
  }
}

enum _EntryKind { expense, income, transfer }

class _EntryChoice extends StatelessWidget {
  const _EntryChoice({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: context.colors.primary),
    title: Text(label, style: AppTypography.labelLarge),
    trailing: const Icon(CupertinoIcons.chevron_forward),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
    tileColor: context.colors.glassFill,
    onTap: onTap,
  );
}

class _QuickEntryButton extends StatelessWidget {
  const _QuickEntryButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.liquid(colors),
          boxShadow: AppShadows.glow(colors.goal),
        ),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onQuickEntry,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onQuickEntry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final items = <_NavItem>[
      _NavItem(CupertinoIcons.house_fill, l10n.navHome),
      _NavItem(CupertinoIcons.list_bullet, l10n.navHistory),
      _NavItem(CupertinoIcons.chart_pie_fill, l10n.navDashboard),
      _NavItem(CupertinoIcons.flag_fill, l10n.navGoals),
    ];
    Widget navButton(int i) => _NavButton(
      item: items[i],
      selected: i == currentIndex,
      onTap: () => onTap(i),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        // The quick-entry button sits above the pill (not clipped inside it)
        // so its glow isn't cut off, but stays anchored in the nav bar's own
        // reserved space instead of floating over the scrollable body.
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: AppRadii.pillRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.glassFillStrong,
                    borderRadius: AppRadii.pillRadius,
                    border: Border.all(color: colors.glassBorder),
                    boxShadow: AppShadows.card(colors),
                  ),
                  child: Row(
                    children: [
                      navButton(0),
                      navButton(1),
                      const SizedBox(width: 60),
                      navButton(2),
                      navButton(3),
                    ],
                  ),
                ),
              ),
            ),
            _QuickEntryButton(onPressed: onQuickEntry),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textTertiary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
