import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/shared/widgets/glass_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  // Only the AppColors extension is needed by GlassCard; avoid google_fonts.
  theme: ThemeData(extensions: const [AppColors.light]),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('GlassCard', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _wrap(const GlassCard(child: Text('hola'))),
      );
      expect(find.text('hola'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('invokes onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          GlassCard(
            onTap: () => tapped++,
            child: const Text('tap'),
          ),
        ),
      );
      await tester.tap(find.text('tap'));
      expect(tapped, 1);
    });
  });
}
