import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/shared/widgets/glass_bottom_sheet.dart';

// No title is passed so AppTypography (google_fonts) stays out of the test,
// mirroring glass_card_test.dart.
// The MediaQuery override sits inside the Scaffold because Scaffold strips
// viewInsets from what its body sees; real sheets live in the Navigator
// overlay, where insets do reach them.
Widget _wrap(Widget sheet, {double bottomInset = 0}) => MaterialApp(
  theme: ThemeData(extensions: const [AppColors.light]),
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: EdgeInsets.only(bottom: bottomInset)),
        child: Align(alignment: Alignment.bottomCenter, child: sheet),
      ),
    ),
  ),
);

Finder _sheetSurface() => find
    .descendant(of: find.byType(GlassBottomSheet), matching: find.byType(ClipRRect))
    .first;

void main() {
  group('GlassBottomSheet', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _wrap(const GlassBottomSheet(child: Text('hola'))),
      );
      expect(find.text('hola'), findsOneWidget);
    });

    testWidgets('lifts above the keyboard when viewInsets grow', (tester) async {
      const sheet = GlassBottomSheet(child: Text('contenido'));

      await tester.pumpWidget(_wrap(sheet));
      final restingBottom = tester.getBottomLeft(_sheetSurface()).dy;

      await tester.pumpWidget(_wrap(sheet, bottomInset: 260));
      await tester.pumpAndSettle();

      final padding = tester.widget<AnimatedPadding>(
        find.descendant(
          of: find.byType(GlassBottomSheet),
          matching: find.byType(AnimatedPadding),
        ),
      );
      expect(padding.padding, const EdgeInsets.only(bottom: 260));

      final liftedBottom = tester.getBottomLeft(_sheetSurface()).dy;
      expect(liftedBottom, restingBottom - 260);
    });

    testWidgets('caps its height at 92% of the screen', (tester) async {
      await tester.pumpWidget(
        _wrap(const GlassBottomSheet(child: SizedBox(height: 2000))),
      );

      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      final sheetHeight = tester.getSize(_sheetSurface()).height;
      expect(sheetHeight, moreOrLessEquals(screenHeight * 0.92));
    });
  });
}
