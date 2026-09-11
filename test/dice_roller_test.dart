import 'package:flamingo/features/dice_roller/dice_roller_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NB: pumpAndSettle never settles here — the screen runs infinite pulse
  // and particle animations. Fixed-duration pumps instead.
  testWidgets('die sides and count selectors update state on tap',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DiceRollerScreen()));
    await tester.pump();

    // default: d6 · 1 die
    expect(find.text('d6 · 1 die'), findsOneWidget);

    // tap d20 chip
    await tester.tap(find.text('d20'));
    await tester.pump();
    expect(find.text('d20 · 1 die'), findsOneWidget);

    // tap ×4 chip
    await tester.tap(find.text('×4'));
    await tester.pump();
    expect(find.text('d20 · 4 dice'), findsOneWidget);

    // tap d4 chip
    await tester.tap(find.text('d4'));
    await tester.pump();
    expect(find.text('d4 · 4 dice'), findsOneWidget);
  });
}
