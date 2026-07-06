import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';

/// Placeholder for the financial insights dashboard (Fase 7). Replaced with
/// the real metric cards in T20.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassScaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: AppEmptyState(
        icon: CupertinoIcons.chart_pie,
        title: l10n.insightsComingSoonTitle,
        message: l10n.insightsComingSoonMessage,
      ),
    );
  }
}
