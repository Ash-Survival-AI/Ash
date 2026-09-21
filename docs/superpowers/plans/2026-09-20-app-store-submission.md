# App Store Submission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every gap between the shipping TestFlight build of Ash and a submittable App Store release — privacy policy, safety disclaimer, export-compliance metadata, listing copy, screenshots, and the final upload.

**Architecture:** The build pipeline is already proven (`docs/testflight-publishing.md`). This plan adds three in-app changes (a non-skippable safety-disclaimer gate, Settings links, a persistent chat disclaimer), one Info.plist key, one hosted static page, and two documentation artifacts that feed the App Store Connect forms. Tasks 1, 4, 5 and 6 are independent; Task 3 depends on Task 2; Task 7 depends on all of them.

**Tech Stack:** Flutter 3.6+ / Dart 3.6, `shared_preferences` ^2.3.0, `url_launcher` ^6.3.1 (both already dependencies — add no new packages), `flutter_test`, GitHub Pages, Transporter, App Store Connect.

**Spec:** This document. No separate spec exists; the requirements were derived from a working-session audit of the repo against Apple's submission requirements and are captured in Global Constraints plus each task's rationale.

## Global Constraints

- Bundle ID is `com.yunxiang.ash`, team `DJD849Y8Q6` (Yunxiang Yan). Collaborator team is `V9Q67SYWWQ` (Yao Xiao).
- App Store listing name is **`Ash: Survival AI`**. The on-device icon name stays `Ash` (`CFBundleDisplayName`). Never change `CFBundleDisplayName` to match the listing.
- Every user-facing surface that describes the AI must carry the Gemma attribution verbatim: `Uses a specialized Gemma model for AI-powered features. Gemma is a trademark of Google LLC.`
- Canonical repo URL: `https://github.com/RaccoonOnion/ash`. Canonical Pages origin: `https://raccoononion.github.io/ash/`.
- Add **no new pub dependencies**. `shared_preferences` and `url_launcher` are already in `pubspec.yaml` and are the only ones these tasks need.
- All new UI uses the existing theme accessor `ash(context)` from `lib/theme/ash_theme.dart` and the existing widgets `Glass` (`lib/widgets/glass.dart`), `PrimaryBtn` / `GhostBtn` (`lib/widgets/buttons.dart`), `SectionLabel` (`lib/widgets/chips.dart`). Do not introduce a new design vocabulary.
- **Never** re-add `com.apple.developer.kernel.increased-debugging-memory-limit` to `ios/Runner/Runner.entitlements`. It is debug-only and App Store rejects it (stripped in commit `8d79ad2`). The two entitlements that must stay are `extended-virtual-addressing` and `increased-memory-limit`.
- Minimum iOS is 17. Current version is `1.4.0+8` in `pubspec.yaml`; the App Store build will be `1.5.0+9` (bumped in Task 7).
- Ash gives survival / first-aid guidance. Every safety string must state it is **not** a substitute for professional medical care or emergency services, and must tell the user to contact emergency services when reachable. This is Apple Guideline 1.4.1 exposure and the single largest rejection risk.
- Commit after every task. Conventional-commit prefixes, matching existing history (`feat:`, `fix:`, `docs:`, `chore:`).

---

## File Structure

**Created:**
- `docs/privacy-policy.html` — static privacy policy served by GitHub Pages. Plain HTML (no Jekyll front matter) so Pages copies it verbatim.
- `lib/screens/safety_disclaimer_screen.dart` — the non-skippable acknowledgement gate. One responsibility: render the disclaimer and report acceptance upward.
- `lib/widgets/safety_note.dart` — the one-line persistent disclaimer shown under the chat composer. Separate file because it is consumed by a screen that is already 991 lines.
- `test/safety_disclaimer_screen_test.dart` — widget tests for the gate.
- `test/safety_note_test.dart` — widget test for the persistent note.
- `docs/app-store-submission.md` — the runbook + every string that goes into App Store Connect forms.
- `docs/app-store-screenshots.md` — screenshot capture procedure and the shot list.

**Modified:**
- `lib/models/app_state.dart:1` — add `disclaimer` to `AppStage`.
- `lib/app.dart` — stage wiring: the switch expression at `:1322`, `_maybeSkipOnboarding()` at `:366`, and a new `_markDisclaimerAccepted()` next to `_markOnboardingDone()` at `:403`.
- `lib/screens/settings_screen.dart` — About section at `:185-205`; new handlers next to `_openGitHub()` at `:550`.
- `lib/screens/chat_screen.dart` — insert `SafetyNote` above the composer.
- `ios/Runner/Info.plist` — add `ITSAppUsesNonExemptEncryption`.
- `pubspec.yaml:4` — version bump (Task 7).
- `README.md` — App Store badge + privacy policy link (Task 7).

---

### Task 1: Privacy policy page on GitHub Pages

**Why this is first:** App Store Connect will not accept a submission without a privacy policy URL. Nothing in the repo has one today. This is the only hard blocker in the plan; everything else is rejection-risk reduction.

**Files:**
- Create: `docs/privacy-policy.html`
- Verify: live URL `https://raccoononion.github.io/ash/privacy-policy.html`

**Interfaces:**
- Produces: the canonical privacy-policy URL `https://raccoononion.github.io/ash/privacy-policy.html`, consumed by Task 3 (Settings row), Task 5 (ASC listing form), and Task 7 (README).

- [ ] **Step 1: Confirm the facts the policy must state**

Before writing a word, verify each claim against the code so the policy is accurate rather than boilerplate. Run:

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
grep -rniE "http://|https://" lib --include=*.dart | grep -vE "github.com|apache.org|^\s*//" | sort -u
```

Expected: the only outbound hosts are HuggingFace (model/pack download) and GitHub (the About link). If you find an analytics SDK, a crash reporter, or any telemetry endpoint, **stop and report it** — the policy and Task 5's nutrition label both change materially, and the plan's "collects nothing" premise is wrong.

- [ ] **Step 2: Write the policy page**

Create `docs/privacy-policy.html`. No Jekyll front matter — a bare `.html` file is copied verbatim by Pages, which avoids the `.md`-to-`.html` rename ambiguity.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ash — Privacy Policy</title>
<style>
  :root { color-scheme: light dark; }
  body {
    max-width: 44rem; margin: 0 auto; padding: 2rem 1.25rem;
    font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }
  h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
  .updated { color: #888; font-size: 0.9rem; margin-top: 0; }
  h2 { font-size: 1.15rem; margin-top: 2rem; }
  code { font-size: 0.9em; }
</style>
</head>
<body>
<h1>Ash — Privacy Policy</h1>
<p class="updated">Last updated: 20 September 2026</p>

<p>Ash is an offline survival assistant. It runs its AI model entirely on your
device. This policy explains what that means for your data.</p>

<h2>What we collect</h2>
<p><strong>Nothing.</strong> Ash has no accounts, no analytics, no crash
reporting, no advertising identifiers, and no server that receives your data.
We — the developers of Ash — never see your conversations, photos, voice, or
usage.</p>

<h2>What stays on your device</h2>
<ul>
  <li><strong>Conversations.</strong> Your questions and Ash's answers are
  stored in a local database on your device and are never uploaded. Deleting
  them (Settings &rarr; Clear conversations) removes them permanently.</li>
  <li><strong>Photos and camera images.</strong> Images you give Ash are
  processed by the on-device model. They are not uploaded anywhere.</li>
  <li><strong>Voice.</strong> Speech is converted to text on your device using
  Apple's Speech Recognition. Depending on your device and iOS settings, Apple
  may process some speech recognition on Apple's servers under
  <a href="https://www.apple.com/legal/privacy/">Apple's privacy policy</a>;
  Ash never receives or stores audio recordings.</li>
  <li><strong>Settings.</strong> Preferences such as your chosen model and
  voice settings are stored locally.</li>
</ul>

<h2>Network connections Ash makes</h2>
<p>Ash connects to the network for exactly one purpose: downloading the AI
model and knowledge packs you choose to install, from
<a href="https://huggingface.co">Hugging Face</a>. These are ordinary file
downloads. No conversation content, image, or personal data is ever sent with
them. After downloading, Ash works with no network connection at all.</p>

<h2>Children</h2>
<p>Ash is not directed at children and collects no data from anyone.</p>

<h2>Changes</h2>
<p>If this policy changes, the updated version will be posted at this URL with
a new "last updated" date.</p>

<h2>Contact</h2>
<p>Questions or concerns:
<a href="https://github.com/RaccoonOnion/ash/issues">open an issue on GitHub</a>.</p>

<hr>
<p><small>Uses a specialized Gemma model for AI-powered features. Gemma is a
trademark of Google LLC.</small></p>
</body>
</html>
```

If Step 1 found any outbound host beyond HuggingFace and GitHub, do not write this file as-is — report the discrepancy instead.

- [ ] **Step 3: Commit the page**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add docs/privacy-policy.html
git commit -m "docs: add privacy policy page for App Store submission"
git push origin main
```

- [ ] **Step 4: Enable GitHub Pages from /docs on main**

```bash
gh api -X POST repos/RaccoonOnion/ash/pages \
  -f 'source[branch]=main' -f 'source[path]=/docs' 2>&1 | head -20
```

If it returns `409 Conflict`, Pages is already enabled — confirm the source is correct instead:

```bash
gh api repos/RaccoonOnion/ash/pages --jq '{status, html_url, source}'
```

If the source is not `main` + `/docs`, update it:

```bash
gh api -X PUT repos/RaccoonOnion/ash/pages \
  -f 'source[branch]=main' -f 'source[path]=/docs'
```

If `gh` is not authenticated, stop and tell the user to run `gh auth login` — do not attempt to enable Pages through any other channel.

- [ ] **Step 5: Verify the URL actually serves**

Pages takes 1-3 minutes to build after first enablement. Poll:

```bash
for i in $(seq 1 20); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' \
    https://raccoononion.github.io/ash/privacy-policy.html)
  echo "attempt $i: HTTP $CODE"
  [ "$CODE" = "200" ] && break
  sleep 15
done
curl -s https://raccoononion.github.io/ash/privacy-policy.html | grep -c "Privacy Policy"
```

Expected: `HTTP 200` and a grep count of at least 1. A 404 after 20 attempts means the Pages build failed — check `gh api repos/RaccoonOnion/ash/pages/builds/latest --jq '.status, .error'` and report.

**Done when:** `https://raccoononion.github.io/ash/privacy-policy.html` returns 200 with the policy text.

---

### Task 2: Non-skippable safety disclaimer gate

**Why:** Ash answers survival and first-aid questions. `grep` over `lib/` finds no user-facing disclaimer anywhere — the only related string is a model instruction at `lib/services/gemma_inference_service.dart:1695`. Apple Guideline 1.4.1 (physical harm) is the top rejection risk for AI-generated medical guidance. The existing onboarding carousel has a **Skip** button (`lib/screens/onboarding_screen.dart:74`), so the disclaimer cannot be a carousel slide — it must be its own gate with an explicit affirmative action.

**Files:**
- Create: `lib/screens/safety_disclaimer_screen.dart`
- Create: `test/safety_disclaimer_screen_test.dart` (the repo has no `test/` directory yet — this creates it)
- Modify: `lib/models/app_state.dart:1`
- Modify: `lib/app.dart` — switch expression at `:1322-1356`, `_maybeSkipOnboarding()` at `:366`, new helper beside `_markOnboardingDone()` at `:403`

**Interfaces:**
- Consumes: `ash(BuildContext) -> AshColors` from `lib/theme/ash_theme.dart`; `PrimaryBtn({required String label, VoidCallback? onTap, bool enabled})` from `lib/widgets/buttons.dart`; `Glass({double radius, EdgeInsets padding, required Widget child})` from `lib/widgets/glass.dart`.
- Produces:
  - `AppStage.disclaimer` — new enum value in `lib/models/app_state.dart`.
  - `class SafetyDisclaimerScreen extends StatefulWidget` with `const SafetyDisclaimerScreen({super.key, required VoidCallback onAccept, bool isReview = false})`. `isReview: true` renders it as a read-only re-display (dismiss instead of accept) for Task 3's Settings row.
  - `const String kPrefSafetyDisclaimerAccepted = 'safety_disclaimer_accepted_v1';` — exported from `safety_disclaimer_screen.dart`, consumed by `lib/app.dart`.

- [ ] **Step 1: Write the failing widget tests**

Create `test/safety_disclaimer_screen_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter test test/safety_disclaimer_screen_test.dart
```

Expected: FAIL — `Error: Couldn't resolve the package 'ash'` or `Target of URI doesn't exist: 'package:ash/screens/safety_disclaimer_screen.dart'`. That is the correct first failure; the file does not exist yet.

- [ ] **Step 3: Implement the screen**

Create `lib/screens/safety_disclaimer_screen.dart`:

```dart
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
```

Note the `enabled: canProceed` / `onTap: canProceed ? ... : null` pairing — `PrimaryBtn` takes both, and passing a live `onTap` with `enabled: false` would let the first test's tap through.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter test test/safety_disclaimer_screen_test.dart
```

Expected: `+4: All tests passed!`

- [ ] **Step 5: Add the enum value**

Modify `lib/models/app_state.dart` line 1:

```dart
enum AppStage { onboarding, disclaimer, modelPick, downloading, main }
```

- [ ] **Step 6: Verify the exhaustive switch now fails to compile**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter analyze lib/app.dart 2>&1 | head -20
```

Expected: an error at `lib/app.dart:1322` about the switch expression not handling `AppStage.disclaimer`. This is the guard rail working — Dart's exhaustive switch makes it impossible to forget the wiring.

- [ ] **Step 7: Wire the stage into `lib/app.dart`**

7a. Add the import beside the other screen imports (near `lib/app.dart:15`):

```dart
import 'screens/safety_disclaimer_screen.dart';
```

7b. Change the onboarding case in the switch expression at `lib/app.dart:1323-1328` so it routes to the disclaimer instead of straight to model pick, and add the new case:

```dart
          AppStage.onboarding => OnboardingScreen(
              onDone: () {
                _markOnboardingDone();
                _setStage(AppStage.disclaimer);
              },
            ),
          AppStage.disclaimer => SafetyDisclaimerScreen(
              onAccept: () {
                _markDisclaimerAccepted();
                _setStage(AppStage.modelPick);
              },
            ),
```

7c. Add the persistence helper immediately after `_markOnboardingDone()` (which ends at `lib/app.dart:410`):

```dart
  Future<void> _markDisclaimerAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefSafetyDisclaimerAccepted, true);
    } catch (e) {
      debugPrint('[ash] mark disclaimer accepted failed: $e');
    }
  }
```

7d. Update `_maybeSkipOnboarding()` (`lib/app.dart:366-388`) so an existing user who has seen the carousel but never accepted the disclaimer lands on the gate rather than sailing past it. Replace the body between `final done = ...` and the `setState`:

```dart
      final done = prefs.getBool(_kPrefOnboardingDone) ?? false;
      if (!done || !mounted) return;

      // Carousel seen. The disclaimer is a separate, non-skippable gate:
      // users upgrading from a build that predates it have the onboarding
      // flag but not the acceptance flag, and must still acknowledge.
      final accepted =
          prefs.getBool(kPrefSafetyDisclaimerAccepted) ?? false;
      if (!accepted) {
        if (!mounted) return;
        setState(() => _stage = AppStage.disclaimer);
        return;
      }

      final hasModel = await _anyModelOnDisk();
      if (!mounted) return;
      setState(() {
        _stage = hasModel ? AppStage.main : AppStage.modelPick;
      });
```

- [ ] **Step 8: Verify analyze is clean and all tests pass**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -5
```

Expected: `No issues found!` and all tests passing. Pre-existing analyzer warnings unrelated to these files are acceptable — note them in your report but do not fix them in this task.

- [ ] **Step 9: Verify the gate by hand on a simulator**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
xcrun simctl list devices available | grep -i "iphone" | head -5
flutter run -d <simulator-id>
```

Then, in the running app, delete and reinstall (or wipe prefs) to reach a first-launch state, and confirm: the carousel's **Skip** lands on the disclaimer (not past it), the accept button is inert until the checkbox is ticked, and relaunching does **not** show the disclaimer again. If a simulator is unavailable in your environment, say so explicitly in your report rather than claiming the manual check passed.

- [ ] **Step 10: Commit**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add test/safety_disclaimer_screen_test.dart \
        lib/screens/safety_disclaimer_screen.dart \
        lib/models/app_state.dart lib/app.dart
git commit -m "feat(safety): add non-skippable safety disclaimer gate

Apple Guideline 1.4.1 requires a clear disclaimer for an app giving
survival and first-aid guidance. Adds AppStage.disclaimer between
onboarding and model pick, gated on safety_disclaimer_accepted_v1 so
upgrading users see it too."
```

**Done when:** `flutter test` passes, `flutter analyze` is clean, and a fresh install cannot reach the main app without ticking the acknowledgement.

---

### Task 3: Persistent disclaimer + Settings links

**Why:** A one-time gate satisfies the letter of 1.4.1; reviewers look for the reminder to be reachable at the point of use too. This also adds the Privacy Policy row that Apple expects to find in-app, not only on the listing.

**Depends on:** Task 2 (imports `SafetyDisclaimerScreen` and `kPrefSafetyDisclaimerAccepted`).

**Files:**
- Create: `lib/widgets/safety_note.dart`
- Create: `test/safety_note_test.dart`
- Modify: `lib/screens/chat_screen.dart` (composer area, around `:727`)
- Modify: `lib/screens/settings_screen.dart` (About section `:185-205`; handlers beside `_openGitHub()` at `:550`)

**Interfaces:**
- Consumes: `SafetyDisclaimerScreen({required VoidCallback onAccept, bool isReview})` from Task 2; `_buildRow(AshColors c, {required String label, String? sublabel, String? value, bool? toggle, ValueChanged<bool>? onToggle, bool chevron, bool danger, VoidCallback? onTap})` and `_divider(AshColors c)`, both private to `lib/screens/settings_screen.dart`.
- Produces: `class SafetyNote extends StatelessWidget` with `const SafetyNote({super.key})`.

- [ ] **Step 1: Write the failing test**

Create `test/safety_note_test.dart`:

```dart
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
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter test test/safety_note_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:ash/widgets/safety_note.dart'`.

- [ ] **Step 3: Implement the widget**

Create `lib/widgets/safety_note.dart`:

```dart
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
```

- [ ] **Step 4: Run it to verify it passes**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter test test/safety_note_test.dart
```

Expected: `+1: All tests passed!`

- [ ] **Step 5: Place the note under the chat composer**

`lib/screens/chat_screen.dart` is 991 lines; the composer sits in a `Padding` with `bottom: 28 + MediaQuery.of(context).viewInsets.bottom` at `:727`. Read `:700-780` first to find the `Column` that wraps the composer row, then add `const SafetyNote()` as the last child of that column, directly beneath the composer.

Add the import beside the other widget imports at the top of the file:

```dart
import '../widgets/safety_note.dart';
```

If the composer is not inside a `Column`, wrap it in one rather than restructuring the surrounding layout:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    <existing composer widget>,
    const SafetyNote(),
  ],
)
```

- [ ] **Step 6: Add the two Settings rows**

In `lib/screens/settings_screen.dart`, the About section currently holds `View on GitHub` and `Version` (`:185-205`). Replace that `Column`'s children with:

```dart
                    children: [
                      _buildRow(
                        c,
                        label: 'Safety & limitations',
                        chevron: true,
                        onTap: _openSafetyDisclaimer,
                      ),
                      _divider(c),
                      _buildRow(
                        c,
                        label: 'Privacy policy',
                        chevron: true,
                        onTap: _openPrivacyPolicy,
                      ),
                      _divider(c),
                      _buildRow(
                        c,
                        label: 'View on GitHub',
                        chevron: true,
                        onTap: _openGitHub,
                      ),
                      _divider(c),
                      _buildRow(
                        c,
                        label: 'Version',
                        value: '1.4.0',
                      ),
                    ],
```

Leave the `Version` row's hardcoded `'1.4.0'` alone for now — Task 7 bumps it to `'1.5.0'` alongside the `pubspec.yaml` version, keeping both in one commit.

- [ ] **Step 7: Add the two handlers**

In the same file, immediately after `_openGitHub()` (which ends at `:558`):

```dart
  void _openPrivacyPolicy() async {
    final uri =
        Uri.parse('https://raccoononion.github.io/ash/privacy-policy.html');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  void _openSafetyDisclaimer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SafetyDisclaimerScreen(
          isReview: true,
          onAccept: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
```

And add the import at the top of `lib/screens/settings_screen.dart`:

```dart
import 'safety_disclaimer_screen.dart';
```

- [ ] **Step 8: Verify**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -5
```

Expected: `No issues found!` and all 5 tests passing. Then run on a simulator and confirm the Settings rows open the browser and the review-mode disclaimer, and that the note renders under the composer without overflowing when the keyboard is up.

- [ ] **Step 9: Commit**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add lib/widgets/safety_note.dart test/safety_note_test.dart \
        lib/screens/chat_screen.dart lib/screens/settings_screen.dart
git commit -m "feat(safety): persistent chat disclaimer + privacy/safety rows in Settings"
```

**Done when:** the reminder is visible under the composer and Settings offers both `Safety & limitations` and `Privacy policy`.

---

### Task 4: Export compliance key in Info.plist

**Why:** `ios/Runner/Info.plist` has no `ITSAppUsesNonExemptEncryption` key (verified: `grep -c` returns 0). Without it, every single build sits in App Store Connect as "Missing Compliance" until someone answers the encryption question by hand — see `docs/testflight-publishing.md` step K. Ash uses only standard Apple APIs for HTTPS, which is the exempt case.

**Files:**
- Modify: `ios/Runner/Info.plist`

**Interfaces:** none — standalone.

- [ ] **Step 1: Confirm the key is absent and the claim is true**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
grep -c ITSAppUsesNonExemptEncryption ios/Runner/Info.plist
grep -rniE "crypto|encrypt|cipher|AES|RSA" lib --include=*.dart | grep -viE "https|//" | head
```

Expected: `0` for the first command. The second should surface no custom cryptography. If it surfaces a bundled crypto implementation, **stop** — `false` would be the wrong answer and the export-compliance question needs a human decision.

- [ ] **Step 2: Add the key**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
plutil -insert ITSAppUsesNonExemptEncryption -bool false ios/Runner/Info.plist
```

- [ ] **Step 3: Verify the plist is still valid and the key reads back**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
plutil -lint ios/Runner/Info.plist
plutil -extract ITSAppUsesNonExemptEncryption raw ios/Runner/Info.plist
git diff --stat ios/Runner/Info.plist
```

Expected: `OK`, then `false`, then a one-line diff. If `plutil` reformatted the whole file (it can rewrite XML whitespace), inspect `git diff` and confirm only the intended key changed — if the diff is large, revert with `git checkout ios/Runner/Info.plist` and add the key by hand instead:

```xml
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add ios/Runner/Info.plist
git commit -m "chore(ios): declare ITSAppUsesNonExemptEncryption=false

Ash uses only standard Apple HTTPS APIs. Declaring this in Info.plist
removes the per-build Missing Compliance step in App Store Connect."
```

**Done when:** `plutil -extract ITSAppUsesNonExemptEncryption raw ios/Runner/Info.plist` prints `false` and the plist lints OK.

---

### Task 5: App Store listing copy and review notes

**Why:** Two distinct rejection risks live here. First, per `docs/testflight-publishing.md` step M, a fresh install downloads a 2.5 GB (E2B) or 5 GB (E4B) model from HuggingFace before the app is usable — a reviewer on a throttled network who sees a stalled progress bar files a Guideline 2.1 "App Completeness" rejection unless the review notes explain it. Second, the App Privacy nutrition label is a separate questionnaire from the policy URL and must agree with the four `NSxxxUsageDescription` strings already in `Info.plist`.

**Files:**
- Create: `docs/app-store-submission.md`

**Interfaces:**
- Consumes: the privacy-policy URL from Task 1.
- Produces: `docs/app-store-submission.md`, the copy source for Task 7's form-filling.

- [ ] **Step 1: Gather the facts the notes must be accurate about**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
grep -n "sizeGB\|displayName\|blurb" lib/services/llm_model.dart | head -20
plutil -p ios/Runner/Info.plist | grep -i usage
```

Use the real model sizes and the real usage strings in the document — do not restate the approximate figures from this plan if the code says otherwise.

- [ ] **Step 2: Write the submission document**

Create `docs/app-store-submission.md` containing all of the following sections, filled with the exact strings that will be pasted into App Store Connect:

**Section: App Information**
- Name: `Ash: Survival AI`
- Subtitle (30 char max): `Offline AI survival guide` (verified 25 chars)
- Primary category: `Reference`. Secondary: `Utilities`.
- Privacy Policy URL: `https://raccoononion.github.io/ash/privacy-policy.html`
- Support URL: `https://github.com/RaccoonOnion/ash/issues`
- Marketing URL: `https://github.com/RaccoonOnion/ash`

**Section: Description** — write 3-5 paragraphs covering: works with no signal, on-device AI (nothing leaves the device), three input modes (type / voice / camera), knowledge packs, and the first-launch model download stated plainly and up front. Close with the safety line (`Ash is not a substitute for professional medical care or emergency services.`) and the Gemma attribution verbatim from Global Constraints.

**Section: Keywords** (100 char max, comma-separated, no spaces after commas) — e.g. `survival,offline,first aid,wilderness,emergency,AI,assistant,preparedness,camping,no signal` (verified 91 chars). If you change it, re-count and record the count in the doc.

**Section: Promotional Text** (170 char max).

**Section: What's New** (for 1.5.0).

**Section: App Review Notes** — the highest-value part. Must state:
> Ash runs its AI model entirely on-device. On first launch the app downloads the model from Hugging Face — approximately 2.5 GB for the default E2B variant. On a fast Wi-Fi connection this takes roughly 5-15 minutes, and the app shows a progress screen throughout. **Please use Wi-Fi and allow the download to finish before testing.** The app is fully functional offline afterwards; you can enable Airplane Mode to verify.
>
> No account or login is required. There is no demo account because there are no accounts at all.
>
> Camera, microphone, photo library, and speech recognition are all optional — the app is usable by typing alone. Each is requested only at the point of use.
>
> A safety disclaimer is presented on first launch and must be acknowledged before the app can be used; it remains available in Settings under "Safety & limitations".

**Section: App Privacy (nutrition label) answers** — record the exact answers to give in the ASC questionnaire. Based on the audit, the answer is **"Data Not Collected"** for every category. Note explicitly: camera/photo/mic/speech permissions are *device access*, not *data collection*, and must not be declared as collected data because none of it leaves the device or reaches the developer. If Task 1 Step 1 found any telemetry, this section must change to match.

**Section: Age Rating answers** — record each questionnaire answer. Expect to declare **Medical/Treatment Information — Infrequent/Mild** (the app gives first-aid guidance), which lands the rating around 12+. Record the final computed rating once the form is filled.

**Section: Export compliance** — `ITSAppUsesNonExemptEncryption=false` is now in `Info.plist` (Task 4), so the question is pre-answered. Note that the French declaration prompt, if shown, is also answered by the exempt status.

- [ ] **Step 3: Verify every length-limited field actually fits**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
# Replace each string with the one you wrote:
printf '%s' "Offline AI survival guide" | wc -c   # subtitle, must be <= 30
printf '%s' "<your keywords string>" | wc -c       # must be <= 100
printf '%s' "<your promo text>" | wc -c            # must be <= 170
```

Expected: each count within its limit. App Store Connect silently truncates or rejects otherwise.

- [ ] **Step 4: Commit**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add docs/app-store-submission.md
git commit -m "docs: add App Store listing copy, review notes, and privacy answers"
```

**Done when:** every App Store Connect text field has a written, length-verified value in the document, and the review notes explain the first-launch download.

---

### Task 6: Screenshots

**Why:** App Store Connect requires at least one 6.9" iPhone screenshot; the 6.5" set is strongly recommended for older-device display. Missing screenshots block submission just as surely as a missing policy URL.

**Files:**
- Create: `docs/app-store-screenshots.md`
- Create: `build/screenshots/` (gitignored output — do not commit the PNGs)

**Interfaces:**
- Consumes: the app at the state produced by Tasks 2 and 3 (screenshots must show the shipping UI, disclaimer included where relevant).

- [ ] **Step 1: Confirm the required simulator devices exist**

```bash
xcrun simctl list devices available | grep -E "iPhone 16 Pro Max|iPhone 15 Plus|iPhone 16 Plus"
```

6.9" is iPhone 16 Pro Max (1320 × 2868). 6.5" is iPhone 11 Pro Max / XS Max (1242 × 2688), commonly substituted by iPhone 15 Plus at 6.7". If no 6.9" simulator is installed, report that the user needs to add it via Xcode → Settings → Platforms rather than silently shipping a smaller size.

- [ ] **Step 2: Decide the shot list before capturing**

Six shots, in listing order — write them into `docs/app-store-screenshots.md` first:
1. Home / empty state with example prompts — establishes what the app is.
2. A chat answering a real survival question, citations visible.
3. Camera identification in progress (the lens sheet).
4. Live voice screen.
5. Knowledge packs grid.
6. An offline proof — the same chat working with Airplane Mode on.

Do not screenshot the safety disclaimer as a marketing shot; it belongs in the app, not the listing.

- [ ] **Step 3: Capture**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
mkdir -p build/screenshots
DEVICE="iPhone 16 Pro Max"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
flutter run -d "$DEVICE" --release
# Drive the app to each state, then for each one:
xcrun simctl io "$DEVICE" screenshot build/screenshots/01-home.png
```

Note: the model download must complete on the simulator before shots 2-6 are possible. Plan for that wait, and use the E2B variant to keep it short.

- [ ] **Step 4: Verify the pixel dimensions Apple requires**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
for f in build/screenshots/*.png; do
  echo "$f: $(sips -g pixelWidth -g pixelHeight "$f" | tail -2 | tr -d ' \n')"
done
```

Expected: `1320 × 2868` for every 6.9" shot. Anything else will be rejected at upload.

- [ ] **Step 5: Confirm `build/` is gitignored, then commit only the doc**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git check-ignore -v build/screenshots/01-home.png
git add docs/app-store-screenshots.md
git commit -m "docs: add App Store screenshot shot list and capture procedure"
```

Expected: `git check-ignore` confirms the PNGs are ignored — `/build/` is on line 33 of `.gitignore`, so this should pass. If it does not, **stop** — do not commit 6 large PNGs into the repo; report the gitignore gap instead.

**Done when:** six correctly-sized PNGs exist in `build/screenshots/` and the procedure is documented.

---

### Task 7: Version bump, build, upload, submit

**Why:** Final assembly. Everything above feeds this.

**Depends on:** Tasks 1-6.

**Files:**
- Modify: `pubspec.yaml:4`, `lib/screens/settings_screen.dart` (Version row), `README.md`

- [ ] **Step 1: Bump the version in both places**

`pubspec.yaml` line 4: `version: 1.5.0+9`. Apple rejects duplicate build numbers, and `+8` is already uploaded.

`lib/screens/settings_screen.dart` Version row: `value: '1.5.0'`.

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
grep -n "^version:" pubspec.yaml
grep -n "value: '1.5.0'" lib/screens/settings_screen.dart
```

- [ ] **Step 2: Full verification before building**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter analyze 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Both must be clean. Do not proceed to a 10-minute build on a red test suite.

- [ ] **Step 3: Commit the bump**

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add pubspec.yaml lib/screens/settings_screen.dart
git commit -m "chore: bump to 1.5.0+9 for App Store submission"
```

- [ ] **Step 4: Build, patch frameworks, upload**

Follow `docs/testflight-publishing.md` steps G through J exactly — that runbook is verified and this plan does not restate it. In short:

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
flutter build ipa --release --export-method=app-store
# Step H: check MinimumOSVersion mismatches
# Step I (if mismatched):
TEAM_ID=DJD849Y8Q6 \
SIGNING_IDENTITY="Apple Distribution: Yunxiang Yan (DJD849Y8Q6)" \
./ios/fix_framework_plists.sh
# Step J: drag build/ios/ipa-fixed/ash.ipa into Transporter
```

Upload `build/ios/ipa-fixed/ash.ipa`, **not** `build/ios/ipa/ash.ipa`.

- [ ] **Step 5: Fill the App Store Connect listing**

Paste every field from `docs/app-store-submission.md`, upload the screenshots from `build/screenshots/`, and complete the App Privacy and Age Rating questionnaires using the recorded answers. This is manual work in the ASC web UI — a subagent cannot do it.

- [ ] **Step 6: Submit for review, then update the README**

Once submitted, add the App Store badge and privacy-policy link to `README.md` beside the existing TestFlight section (`README.md:24-38`):

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git add README.md
git commit -m "docs: link App Store listing and privacy policy from README"
git push origin main
```

**Done when:** the build shows "Waiting for Review" in App Store Connect.

---

## Execution notes for subagent dispatch

- **Parallel-safe:** Tasks 1, 4, 5 and 6 touch disjoint files and can run concurrently.
- **Sequential:** Task 3 needs Task 2's symbols. Task 7 needs everything.
- **Task 6 caveat:** screenshots should ideally be captured *after* Tasks 2-3 land so the shipping UI is what the listing shows. If run in parallel, re-check shot 1 afterwards for the composer's new `SafetyNote`.
- **Human-only:** Task 5 Step 5 (ASC form filling), Task 7 Steps 4-6 (Transporter upload, ASC submission). A subagent prepares the inputs; a person clicks the buttons.
