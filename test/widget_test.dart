import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cairo_metro_guide/app.dart';

void main() {
  testWidgets('Home opens each placeholder and returns', (tester) async {
    await tester.pumpWidget(const CairoMetroApp());
    expect(find.text('Cairo Metro Guide'), findsOneWidget);

    for (final entry in {
      'Search Place': 'This feature will be implemented by Member 5.',
      'Nearest Station': 'This feature will be implemented by Member 4.',
      'Recent Trips': 'This feature will be implemented by Member 5.',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('Find Route'));
    await tester.tap(find.text('Find Route'));
    await tester.pumpAndSettle();
    expect(find.text('Route Result — Demo'), findsOneWidget);
    expect(find.text('Ticket price: Under development'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final mapButton = find.byTooltip('Show station location').first;
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();
    expect(find.text('Station Location'), findsOneWidget);
    expect(find.textContaining('Member 3'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final swapButton = find.byTooltip('Swap stations');
    await tester.ensureVisible(swapButton);
    await tester.tap(swapButton);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
