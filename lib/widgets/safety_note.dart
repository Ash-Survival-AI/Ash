import 'package:flutter/material.dart';
import '../theme/ash_theme.dart';

/// One-line persistent reminder shown under the chat composer. Deliberately
/// quiet — it must be legible without competing with the composer itself.
class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ash(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        'Ash can be wrong — not a substitute for professional help. '
        'In an emergency, contact emergency services.',
        textAlign: TextAlign.center,
        style: TextStyle(color: c.textDim, fontSize: 11, height: 1.35),
      ),
    );
  }
}
