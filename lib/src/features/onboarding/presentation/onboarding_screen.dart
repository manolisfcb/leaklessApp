import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/onboarding_providers.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color Function(AppColors) color;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    icon: CupertinoIcons.drop_fill,
    color: _expense,
    title: 'Detecta las fugas de dinero',
    body:
        'Esos pequeños gastos hormiga que se escapan sin darte cuenta. leakless '
        'los hace visibles para que recuperes el control.',
  ),
  _Slide(
    icon: CupertinoIcons.person_2_fill,
    color: _goal,
    title: 'Controlen los gastos en pareja',
    body:
        'Un libro de cuentas compartido y en tiempo real. Si uno gasta, ambos '
        'lo saben al instante.',
  ),
  _Slide(
    icon: CupertinoIcons.flag_fill,
    color: _income,
    title: 'Ahorren juntos con metas claras',
    body:
        'Definan metas, vean el progreso líquido llenarse y celebren cada '
        'aporte hacia el futuro que quieren.',
  ),
];

Color _expense(AppColors c) => c.expense;
Color _goal(AppColors c) => c.goal;
Color _income(AppColors c) => c.income;

/// First-run onboarding carousel (Liquid Glass).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _next() async {
    if (_isLast) {
      await ref.read(onboardingCompletedProvider.notifier).complete();
      if (mounted) context.go(AppRoutes.auth);
      return;
    }
    await _controller.nextPage(
      duration: AppDurations.medium,
      curve: AppDurations.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await ref
                      .read(onboardingCompletedProvider.notifier)
                      .complete();
                  if (context.mounted) context.go(AppRoutes.auth);
                },
                child: Text(
                  'Saltar',
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _PageDots(count: _slides.length, active: _page),
            AppSpacing.gapXl,
            GlassButton(
              label: _isLast ? 'Comenzar' : 'Siguiente',
              icon: _isLast ? CupertinoIcons.checkmark_alt : null,
              onPressed: _next,
            ),
            AppSpacing.gapXxl,
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = slide.color(colors);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.accent(color),
            boxShadow: AppShadows.glow(color),
          ),
          child: Icon(slide.icon, size: 64, color: Colors.white),
        ),
        AppSpacing.gapXxl,
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: AppTypography.displaySmall,
        ),
        AppSpacing.gapMd,
        Text(
          slide.body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: i == active ? 24 : 8,
            decoration: BoxDecoration(
              color: i == active ? colors.primary : colors.disabled,
              borderRadius: AppRadii.pillRadius,
            ),
          ),
      ],
    );
  }
}
