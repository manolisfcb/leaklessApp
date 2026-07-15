import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/shared/widgets/donut_chart.dart';

List<DonutSlice> _slices(int count) => [
  for (var i = 0; i < count; i++)
    (
      value: (i + 1).toDouble(),
      color: Colors.primaries[i % Colors.primaries.length],
    ),
];

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('DonutChart', () {
    testWidgets('renders a single slice as a full ring without error', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(DonutChart(slices: _slices(1))));

      expect(tester.takeException(), isNull);
      expect(find.byType(DonutChart), findsOneWidget);
    });

    testWidgets('renders 3 slices without error', (tester) async {
      await tester.pumpWidget(_wrap(DonutChart(slices: _slices(3))));

      expect(tester.takeException(), isNull);
      expect(find.byType(DonutChart), findsOneWidget);
    });

    testWidgets('renders 8 slices without error', (tester) async {
      await tester.pumpWidget(_wrap(DonutChart(slices: _slices(8))));

      expect(tester.takeException(), isNull);
      expect(find.byType(DonutChart), findsOneWidget);
    });

    testWidgets('renders an optional center widget', (tester) async {
      await tester.pumpWidget(
        _wrap(DonutChart(slices: _slices(3), center: const Text('total'))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('total'), findsOneWidget);
    });
  });
}
