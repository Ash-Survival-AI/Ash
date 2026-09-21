import 'package:flutter/material.dart';
import '../theme/ash_theme.dart';
import '../widgets/glass.dart';
import '../widgets/buttons.dart';

/// SharedPreferences key recording that the user accepted the safety
/// disclaimer. Versioned — bump the suffix if the wording changes
/// materially enough that prior acceptance shouldn't carry over.
const String kPrefSafetyDisclaimerAccepted = 'safety_disclaimer_accepted_v1';

/// Blocking safety acknowledgement shown once, after onboarding and before
/// the user can reach the app. Deliberately has no Skip affordance: the
/// onboarding carousel is skippable, this is not.
///
/// With [isReview] true it becomes a read-only re-display for the Settings
/// screen — no checkbox, and the button just closes it.
class SafetyDisclaimerScreen extends StatefulWidget {
  const SafetyDisclaimerScreen({
    super.key,
    required this.onAccept,
    this.isReview = false,
  });

  final VoidCallback onAccept;
  final bool isReview;

  @override
  State<SafetyDisclaimerScreen> createState() => _SafetyDisclaimerScreenState();
}

class _SafetyDisclaimerScreenState extends State<SafetyDisclaimerScreen> {
  bool _acked = false;

  static const _points = [
    (
      icon: Icons.medical_services_outlined,
      title: 'Not a substitute for professional care',
      body:
          'Ash is not a doctor, paramedic, or rescue service. Its guidance is '
          'general information, not medical advice, diagnosis, or treatment.',
    ),
    (
      icon: Icons.emergency_outlined,
      title: 'Call for help whenever you can',
      body:
          'If someone is seriously hurt or in danger, contact emergency '
          'services first. Use Ash only when professional help is '
          'unavailable or while you wait for it.',
    ),
    (
      icon: Icons.warning_amber_outlined,
      title: 'AI answers can be wrong',
      body:
          'Ash runs a small AI model on your device. It can be confidently '
          'incorrect. Use your own judgement, and never rely on it alone in '
          'a life-threatening situation.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = ash(context);
    final canProceed = widget.isReview || _acked;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Before you\nrely on Ash.',
                style: TextStyle(
                  color: c.text,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    for (final p in _points) ...[
                      Glass(
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(p.icon, color: c.accent, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.body,
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              if (!widget.isReview) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  key: const Key('safety-ack-checkbox'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _acked = !_acked),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _acked ? c.accent : Colors.transparent,
                          border: Border.all(
                            color: _acked ? c.accent : c.borderStrong,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: _acked
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I understand Ash is not a substitute for '
                          'professional or emergency help.',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              PrimaryBtn(
                label: widget.isReview ? 'Close' : 'I understand',
                enabled: canProceed,
                onTap: canProceed ? widget.onAccept : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
