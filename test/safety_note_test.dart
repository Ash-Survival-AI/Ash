import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ash/widgets/safety_note.dart';

void main() {
  testWidgets('renders the one-line safety reminder', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SafetyNote()),
    ));

    expect(
      find.textContaining('not a substitute for professional help'),
      findsOneWidget,
    );
  });
}
