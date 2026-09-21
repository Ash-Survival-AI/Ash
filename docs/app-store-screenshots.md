# App Store screenshots — shot list and capture procedure

**This document describes a procedure that was NOT executed as part of
writing it.** No simulator was booted, no build was run, and no PNGs were
captured while producing this file — that was an explicit constraint,
because `flutter_gemma`'s native build is slow and capturing real shots
also requires a ~1.4 GB model download onto the simulator first. What
follows is accurate about the repo and the machine state at the time of
writing (verified with read-only `xcrun simctl` / `git` commands), but the
capture itself is still TODO for whoever runs this.

---

## Prerequisites (read this before running anything)

1. **A real device build isn't required — a simulator is enough** for App
   Store screenshots, but `flutter run --release` still does a full native
   compile the first time. Budget real time for this; it is not fast.
2. **The model must be downloaded onto that specific simulator instance
   before shots 2, 3, 5, and 6 are possible.** Use the smaller **Gemma 4
   E2B variant (~1.4 GB, `lib/services/llm_model.dart`)** to keep this
   short — do not use E4B (~3.7 GB) for screenshot capture. Simulators
   have no cellular radio, so this download happens over your Mac's
   network; a slow connection here is the single biggest time sink in this
   whole procedure.
3. **Simulator device availability was checked on this machine and only
   partially matches what's needed** — see the audit below. Do not assume
   `xcrun simctl boot "iPhone 16 Pro Max"` will work on a fresh checkout
   without first creating that device.
4. **"Airplane Mode" in a simulator does not disable the Mac's real network
   interface.** Toggling Settings → Airplane Mode inside iOS Simulator
   flips the UI/radio state that apps query, which is sufficient to show
   the airplane-mode toggle in a screenshot, but it does **not** actually
   sever TCP/IP the way a real device does. For shot 6 (the "offline
   proof" shot) to be a true test and not just a UI toggle, also disable
   your Mac's Wi-Fi (or use Xcode's Network Link Conditioner set to 100%
   loss) while capturing it.
5. **Do not screenshot the safety disclaimer or the model-download
   progress screen as marketing shots** — the task brief and this document
   agree these belong in the app experience, not the App Store listing.

---

## Simulator device audit (read-only, performed while writing this doc)

```
$ xcrun simctl list runtimes
== Runtimes ==
iOS 26.4 (26.4.1 - 23E254a) - com.apple.CoreSimulator.SimRuntime.iOS-26-4
```

Only **one runtime, iOS 26.4,** is installed on this machine. That's fine —
iOS 26.4 satisfies iOS 17+ minimum for every device type discussed below.

```
$ xcrun simctl list devices available
== Devices ==
-- iOS 26.4 --
    iPhone 17 Pro (...) (Shutdown)
    iPhone 17 Pro Max (...) (Shutdown)
    iPhone 17e (...) (Shutdown)
    iPhone Air (...) (Shutdown)
    iPhone 17 (...) (Booted)
    iPad Pro 13-inch (M5) / iPad Pro 11-inch (M5) / iPad mini (A17 Pro) /
    iPad Air 13-inch (M4) / iPad Air 11-inch (M4) / iPad (A16)
```

**None of `iPhone 16 Pro Max`, `iPhone 15 Plus`, or `iPhone 16 Plus` exist
as bootable device instances on this machine.** (An `iPhone 17` instance
is currently booted, left over from unrelated work — this document does
not touch it and this procedure should not assume it's usable, since it's
the wrong device class for either required screenshot size.)

The good news: the **device type definitions** for the older phones are
still present in this Xcode install (device types are bundled with Xcode,
independent of which runtimes/instances you've created):

```
$ xcrun simctl list devicetypes | grep -E "iPhone 16 Pro Max|iPhone 15 Plus|iPhone 16 Plus"
iPhone 16 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max)
iPhone 16 Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-16-Plus)
iPhone 15 Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-15-Plus)
```

So no new runtime download is needed — you just need to **create** device
instances against the iOS 26.4 runtime you already have:

```bash
xcrun simctl create "Ash Screenshots 6.9in" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4

xcrun simctl create "Ash Screenshots 6.5in" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-15-Plus \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4
```

**Important caveat on device generations:** the task brief that this
document is based on names `iPhone 16 Pro Max` / `iPhone 15 Plus` as the
canonical 6.9"/6.5" devices, and gives `1320 x 2868` as the 6.9" pixel
requirement. Those were accurate for the hardware generation current when
that guidance was written. By the time you run this (checked against a
machine that already has iPhone 17-series simulators installed), Apple may
have folded newer device classes into its screenshot-size requirements or
changed which legacy sizes it still accepts. **Before you rely on the
numbers below, re-check the live requirement** on the screenshot upload
page in App Store Connect (Media Manager for your build) or at
<https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications> —
it will tell you definitively which sizes it will currently accept, and
the capture script below verifies whatever size you tell it to expect, so
updating the target size is a one-line change, not a rewrite.

| Display class | Reference device (as of this writing) | Required pixels |
|---|---|---|
| 6.9" (required — at least one) | iPhone 16 Pro Max | `1320 x 2868` |
| 6.5"/6.7" (strongly recommended) | iPhone 15 Plus | `1290 x 2796` |

(The task brief's `1242 x 2688` figure is the *older* 6.5"-class resolution
for iPhone 11 Pro Max / XS Max; iPhone 15 Plus, which the brief also names
as an acceptable substitute, actually renders at `1290 x 2796`. Use
whichever exact device you actually boot, and let the capture script's
`sips` check catch a mismatch rather than assuming either number.)

---

## Shot list (capture in this order)

1. **Home / empty state with example prompts.** `lib/screens/home_screen.dart`,
   the `_EmptyStatePrompts` widget shown before any chat exists. Establishes
   what the app is for at a glance.
2. **A chat answering a real survival question, citations visible.** Ask
   something like "How do I stop heavy bleeding?" so it retrieves from the
   bleeding pack; wait for the reply to finish streaming so the `[1] [2]`
   citation chips are visible under the answer (`lib/widgets/citation_chips.dart`).
3. **Camera identification in progress.** Tap the camera icon
   (`Icons.camera_alt_outlined`) in the composer — this opens `CameraSheet`
   (`lib/widgets/camera_sheet.dart`). *Naming note:* the task brief calls
   this "the lens sheet," but in the code the "lens sheet" is actually a
   different feature — `lib/widgets/lens_sheet.dart`, the retrieval-scope
   picker for choosing which knowledge packs a chat searches. The camera
   capture UI is a separate, unrelated widget, `CameraSheet`. Use the
   camera icon / `CameraSheet`, not the lens-scope picker, for this shot.
4. **Live voice screen.** `lib/screens/live_voice_screen.dart` — the
   full-screen orb, mid-conversation if possible (not the idle initial
   state) so the screenshot shows the feature actually working.
5. **Knowledge packs grid.** `lib/screens/knowledge_screen.dart` — scroll
   to a state showing multiple packs/tiers, not just the top of an empty
   list.
6. **Offline proof.** The same chat screen from shot 2 (or a new question),
   with Simulator's Settings → Airplane Mode toggled on, and — per the
   prerequisite above — the Mac's real network actually disabled too, so
   the shot is true offline behavior, not just a UI toggle.

Do not include the safety-disclaimer screen or the model-download progress
screen in this set (both are real, important app screens — just not
marketing material).

---

## Capture

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash

# One-time device setup (skip if the device already exists on your machine):
xcrun simctl create "Ash Screenshots 6.9in" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4

DEVICE="Ash Screenshots 6.9in"
xcrun simctl boot "$DEVICE"

# Slow step — first native build. Do this once, then navigate freely.
flutter run -d "$DEVICE" --release

# In a separate terminal, once the app is installed and running:
# 1. On first launch, pick the Gemma 4 E2B model (not E4B) and wait for the
#    ~1.4 GB download to finish. This is the long pole — see Prerequisites.
# 2. Navigate the app to each of the six states above, one at a time.
# 3. After the UI is in the right state for a shot, capture + verify it:

tools/capture-screenshots.sh "$DEVICE" 01-home        1320x2868
tools/capture-screenshots.sh "$DEVICE" 02-chat-answer 1320x2868
tools/capture-screenshots.sh "$DEVICE" 03-camera      1320x2868
tools/capture-screenshots.sh "$DEVICE" 04-live-voice  1320x2868
tools/capture-screenshots.sh "$DEVICE" 05-knowledge   1320x2868
tools/capture-screenshots.sh "$DEVICE" 06-offline     1320x2868

# Repeat the whole flow with the 6.5"/6.7" device for the recommended
# secondary set:
xcrun simctl create "Ash Screenshots 6.5in" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-15-Plus \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4
DEVICE="Ash Screenshots 6.5in"
xcrun simctl boot "$DEVICE"
flutter run -d "$DEVICE" --release
# ... navigate, then:
tools/capture-screenshots.sh "$DEVICE" 01-home-65        1290x2796
# ...and so on for the other five.
```

`tools/capture-screenshots.sh` (see below) runs `xcrun simctl io screenshot`
and immediately checks the result's pixel dimensions with `sips`, failing
loudly (non-zero exit, PNG left in place for inspection) if they don't
match what you asked for — so a wrong device, a scaled simulator window, or
a stale ASC size requirement gets caught immediately instead of silently
producing an unusable screenshot.

Note on "unattended": the script automates the mechanical parts (capture,
dimension check, retry-friendly naming) so you don't need to hand-run
`sips` after every shot. It cannot navigate the app's UI for you — Ash has
no scripted UI-automation harness in this repo, so getting each screen into
the right state (asking a question, opening the camera sheet, etc.) is
still a manual step between script invocations.

---

## Verify dimensions (also done automatically per-shot by the script above)

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
for f in build/screenshots/*.png; do
  W=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
  H=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
  echo "$f: ${W}x${H}"
done
```

Expected: `1320x2868` for every 6.9" shot, `1290x2796` for every 6.5" shot
captured from `iPhone 15 Plus` (re-confirm both numbers against the live
ASC requirement first, per the caveat above).

---

## Commit only the doc and the script — never the PNGs

```bash
cd /Users/yoyo_openclaw_bot/yao-projects/ash
git check-ignore -v build/screenshots/01-home.png
```

`/build/` is on line 33 of `.gitignore`, so this should print a match and
exit 0. **If it does not print a match, stop — do not commit screenshot
PNGs into the repo.** Report the gitignore gap instead of working around
it.

```bash
git add docs/app-store-screenshots.md tools/capture-screenshots.sh
git commit -m "docs: add App Store screenshot shot list and capture procedure"
```

**Done when:** six correctly-sized PNGs exist in `build/screenshots/` for
the 6.9" device (required) and ideally another six for the 6.5"/6.7"
device (recommended), all verified by `tools/capture-screenshots.sh`, and
`build/` is confirmed gitignored so none of them end up in a commit.
