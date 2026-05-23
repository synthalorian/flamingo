import 'package:flutter_test/flutter_test.dart';

import 'package:flamingo/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    // Verify the home screen is rendered
    expect(find.text('FLAMINGO'), findsWidgets);
  });
}
