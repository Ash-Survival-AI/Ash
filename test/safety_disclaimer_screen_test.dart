import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ash/screens/safety_disclaimer_screen.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('accept button is disabled until the checkbox is ticked',
      (tester) async {
    var accepted = false;
    await tester.pumpWidget(host(
      SafetyDisclaimerScreen(onAccept: () => accepted = true),
    ));

    // Tapping accept before acknowledging must do nothing.
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);
  });

  testWidgets('ticking the checkbox enables accept and fires onAccept',
      (tester) async {
    var accepted = false;
    await tester.pumpWidget(host(
      SafetyDisclaimerScreen(onAccept: () => accepted = true),
    ));

    await tester.tap(find.byKey(const Key('safety-ack-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });

  testWidgets('states the three required safety points', (tester) async {
    await tester.pumpWidget(host(SafetyDisclaimerScreen(onAccept: () {})));

    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .join(' ');

    expect(text, contains('not a substitute'));
    expect(text, contains('emergency services'));
    expect(text, contains('can be wrong'));
  });

  testWidgets('review mode dismisses without requiring the checkbox',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(host(
      SafetyDisclaimerScreen(onAccept: () => dismissed = true, isReview: true),
    ));

    expect(find.byKey(const Key('safety-ack-checkbox')), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });
}
