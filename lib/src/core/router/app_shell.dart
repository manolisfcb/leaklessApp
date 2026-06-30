import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/quick_entry/presentation/quick_entry_sheet.dart';
import '../../shared/widgets/widgets.dart';
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
      floatingActionButton: _QuickEntryButton(
        onPressed: () => GlassBottomSheet.show<void>(
          context,
          title: 'Registro rápido',
          builder: (_) => const QuickEntrySheet(),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
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

const _items = <_NavItem>[
  _NavItem(CupertinoIcons.house_fill, 'Inicio'),
  _NavItem(CupertinoIcons.list_bullet, 'Historial'),
  _NavItem(CupertinoIcons.chart_bar_alt_fill, 'Presupuestos'),
  _NavItem(CupertinoIcons.flag_fill, 'Metas'),
  _NavItem(CupertinoIcons.gear_alt_fill, 'Ajustes'),
];

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: ClipRRect(
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavButton(
                      item: _items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
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
