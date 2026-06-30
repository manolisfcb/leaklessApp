import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'quick_entry_sheet.dart';

/// Full-screen variant of Quick Entry, used for deep links / push actions. The
/// primary entry point is the bottom sheet launched from the dashboard FAB.
class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Registro rápido')),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: QuickEntrySheet(),
      ),
    );
  }
}
