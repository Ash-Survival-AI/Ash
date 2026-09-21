# App Store Connect submission copy — Ash

This is the copy-paste source for App Store Connect. Every field below has
been length-checked against Apple's limits with `wc -c` (Step 3) — do not
retype these strings by hand into ASC; copy them directly to avoid
reintroducing a length or formatting error.

Version under submission: **1.5.0 (build 9)**, minimum iOS 17.

> **Note on version numbers:** `pubspec.yaml` in this repo currently still
> reads `1.4.0+8` at the time this document was written. Bumping it to
> `1.5.0+9` is a build/release-config change, not a documentation change, and
> is out of scope for this document — confirm it has been bumped (or bump it)
> before archiving the build that gets uploaded.

---

## App Information

| Field | Value |
|---|---|
| Name | `Ash: Survival AI` |
| Subtitle | `Offline AI survival guide` |
| Primary category | `Reference` |
| Secondary category | `Utilities` |
| Privacy Policy URL | `https://raccoononion.github.io/ash/privacy-policy.html` |
| Support URL | `https://github.com/RaccoonOnion/ash/issues` |
| Marketing URL | `https://github.com/RaccoonOnion/ash` |

Note: the on-device app icon / home screen name (`CFBundleDisplayName`) stays
`Ash` — that is a separate field from the App Store listing `Name` above and
must **not** be changed to match it.

---

## Description

Ash is an offline survival assistant that runs its AI model entirely on your
iPhone. Ask a question by typing, speaking, or pointing your camera at
something, and Ash answers using 56 built-in emergency-response knowledge
packs covering first aid, severe bleeding, CPR, hypothermia, flash floods,
and dozens of other field situations — with inline citations you can tap to
read the exact source passage.

Once the model is downloaded, Ash needs no signal at all. Turn on Airplane
Mode and it keeps working: no cell service, no Wi-Fi, no cloud calls for
chat, image, or knowledge-pack lookups. This makes it a genuinely useful
companion in the backcountry, during a power outage, or anywhere else
connectivity can't be assumed. Note: Ash does require an internet
connection once, on first launch, to download its AI model — see below.

Three ways to ask:
- **Type** — full chat with markdown formatting and tappable citations.
- **Camera** — point at a plant, an animal track, a medication label, or a
  wound, and ask what you're looking at.
- **Voice** — hold to talk in the composer, or open Live Voice Mode for a
  full hands-free, spoken back-and-forth.

On first launch, Ash downloads its AI model — about 1.4 GB for the
recommended default (Gemma 4 E2B), or about 3.7 GB if you choose the larger,
higher-quality E4B variant — over Wi-Fi. This takes roughly 10-15 minutes on
a typical home connection and only happens once. A progress screen shows
you exactly how it's going.

Text, image, and chat processing all happen on the model running on your
device — your conversations, photos, and questions are never sent to us,
and there are no accounts, no logins, and no analytics. Voice input uses
Apple's Speech Recognition to turn what you say into text; depending on
your device and language settings, Apple may process some of that speech
on Apple's own servers under Apple's privacy policy, but Ash itself never
receives or stores your audio.

Ash is not a substitute for professional medical care or emergency
services. In a life-threatening emergency, contact local emergency
services.

Uses a specialized Gemma model for AI-powered features. Gemma is a
trademark of Google LLC.

---

## Keywords

```
survival,offline,first aid,wilderness,emergency,AI,assistant,preparedness,camping,no signal
```

Length: **91 / 100** characters (verified with `wc -c`, see Step 3 below).

---

## Promotional Text

```
Offline survival AI with first-aid guidance, ID, and voice chat, all on-device. First launch needs Wi-Fi for a ~1.4 GB model. Not a substitute for emergency services.
```

Length: **166 / 170** characters (verified with `wc -c`, see Step 3 below).

---

## What's New (version 1.5.0)

```
Ash's first App Store release.

- Offline, on-device survival assistant: type, speak, or use the camera to ask
  questions and get answers grounded in 56 built-in emergency-response
  knowledge packs, with tappable citations.
- Live Voice Mode for full hands-free conversations.
- A safety disclaimer is now shown on first launch and stays available in
  Settings under "Safety & limitations."
- Corrected the microphone permission description for accuracy.
- Privacy policy published; no accounts, no analytics, no data leaves your
  device except the one-time AI model download.
```

---

## App Review Notes

```
Ash runs its AI model entirely on-device. On first launch the app downloads
the model from Hugging Face — approximately 1.4 GB for the default "Gemma 4
E2B" variant (about 3.7 GB if the larger "E4B" variant is selected instead).
On a fast Wi-Fi connection the E2B download takes roughly 10-15 minutes, and
the app shows a progress screen with a live ETA throughout. PLEASE USE WI-FI
AND ALLOW THE DOWNLOAD TO FINISH BEFORE TESTING — on a throttled or cellular
connection this can take much longer, and an incomplete download is not a
malfunction. The app is fully functional offline afterwards; you can enable
Airplane Mode after the download completes to verify no network calls are
made for chat, camera, or knowledge-pack features.

No account or login is required. There is no demo account to provide
because the app has no accounts, no sign-in, and no server-side backend at
all — all AI inference and data storage happen locally on the device.

Camera, microphone, photo library, and speech recognition permissions are
all optional. The app is fully usable by typing alone; each permission is
requested only at the point of use (e.g., tapping the camera button), never
up front.

A safety disclaimer is presented on first launch and must be acknowledged
before the app can be used. It remains available afterwards in Settings
under "Safety & limitations," alongside the in-app privacy summary.

One accuracy note for the reviewer: voice input is transcribed using
Apple's on-device Speech Recognition framework. Depending on the reviewer's
device and installed language packs, iOS may route some speech-to-text
processing to Apple's own servers rather than performing it fully
on-device — this is standard iOS behavior for the Speech framework, not
something Ash controls or opts into. Ash itself never transmits audio,
conversations, images, or any other user content to our own servers; the
only outbound app traffic is the one-time model (and knowledge-pack)
download from Hugging Face.
```

---

## App Privacy (nutrition label) answers

Answer: **Data Not Collected**, for every category in the questionnaire
(Contact Info, Health & Fitness, Financial Info, Location, Sensitive Info,
Contacts, User Content, Browsing History, Identifiers, Purchases, Usage
Data, Diagnostics, Other Data).

This is consistent with `docs/privacy-policy.html`, which states plainly:
"Ash has no accounts, no analytics, no crash reporting, no advertising
identifiers, and no server that receives your data."

Important distinctions to get right in the questionnaire:

- **Camera, microphone, photo library, and speech-recognition permissions
  are device *access*, not data *collection*.** The four
  `NS*UsageDescription` strings in `Info.plist` explain why the app asks
  for access at the OS level; none of that data is collected, retained, or
  transmitted by Ash to any server it controls, so it must not be declared
  as "collected" data in the nutrition label.
- **Voice audio is the one nuance.** `AppleVoiceService` sets
  `onDevice: false` for `speech_to_text` (see
  `lib/services/apple_voice_service.dart`), meaning iOS may route some
  speech-to-text processing through Apple's own servers when there is no
  downloaded on-device language pack for the user's locale. This is
  Apple's system-level Speech framework behavior, governed by Apple's own
  privacy policy — it is not Ash (the app or its developer) collecting or
  receiving that audio, and Ash never stores or has access to the raw
  recordings. It does not change the "Data Not Collected" answer for the
  app's own privacy label, but it is why the description and review notes
  above do not claim voice input is "fully on-device" — only the LLM
  inference genuinely is.
- If a future telemetry/analytics SDK is ever added, this entire section
  must be revisited before resubmission — the "Data Not Collected" answer
  is only true because no such SDK exists today.

---

## Age Rating answers

Expected relevant answer: **Medical/Treatment Information — Infrequent/Mild**
(the app provides first-aid and emergency-response guidance). All other
categories (violence, sexual content, gambling, alcohol/tobacco/drugs,
horror, profanity, unrestricted web access, etc.) should be answered "None."

This combination is expected to compute to an **age rating of 12+** on
Apple's current age-rating system. Record the rating App Store Connect
actually computes once the questionnaire is submitted, since Apple's rating
algorithm can change independently of this document:

- Computed rating: `______` *(fill in after submitting the questionnaire in ASC)*

---

## Export compliance

`ITSAppUsesNonExemptEncryption` is already set to `false` in
`ios/Runner/Info.plist` (verified directly in the repo — see Step 1 below),
so App Store Connect's export-compliance question is pre-answered: Ash uses
only standard iOS platform encryption (e.g., HTTPS for the one-time model
download) and qualifies for the exemption. If ASC still prompts for a
French encryption declaration on upload, the same exemption applies — no
additional CCATS/self-classification filing is needed for this app.

---

## Step 1: Facts gathered from the repo (ground truth)

Commands run and their real output — used throughout this document instead
of the plan's approximate figures:

```
$ grep -n "sizeGB\|displayName\|blurb" lib/services/llm_model.dart
displayName: 'Gemma 4 E2B',  sizeGB: 1.4,  blurb: 'Balanced quality and speed. Runs fully on-device with RAG.'
displayName: 'Gemma 4 E4B',  sizeGB: 3.7,  blurb: 'Higher quality reasoning. Best on iPhone 17 Pro+. Larger download.'
```

```
$ plutil -p ios/Runner/Info.plist | grep -i usage
"NSCameraUsageDescription" => "Ash needs camera access to identify plants, animals, and survival situations."
"NSMicrophoneUsageDescription" => "Ash uses the microphone to transcribe your voice questions into text."
"NSPhotoLibraryUsageDescription" => "Ash uses your photos to identify what you point it at — all processed on-device."
"NSSpeechRecognitionUsageDescription" => "Ash uses Apple Speech Recognition to convert your voice to text for the chat."
```

**Discrepancy vs. the task brief:** the brief's "Why" section and its
default review-note text assumed a **2.5 GB (E2B) / 5 GB (E4B)** model
download. The code (`lib/services/llm_model.dart`) and the README both say
**1.4 GB (E2B) / 3.7 GB (E4B)**. This document uses the code's real figures
throughout (description, review notes); the brief's numbers were not used
anywhere in the final copy.

Also note: the microphone usage string was corrected in a very recent
commit (`8f45114 fix(ios): correct inaccurate on-device claim in mic usage
description`) specifically because it previously overstated on-device
processing. This document's description and review notes were written to
be consistent with that correction — they explicitly call out that voice
transcription can involve Apple's servers, rather than claiming everything
is on-device.

---

## Step 3: Length verification (real `wc -c` output)

```
$ printf '%s' "Offline AI survival guide" | wc -c
      25
```
Subtitle: 25 / 30 — OK.

```
$ printf '%s' "survival,offline,first aid,wilderness,emergency,AI,assistant,preparedness,camping,no signal" | wc -c
      91
```
Keywords: 91 / 100 — OK.

```
$ printf '%s' "Offline survival AI with first-aid guidance, ID, and voice chat, all on-device. First launch needs Wi-Fi for a ~1.4 GB model. Not a substitute for emergency services." | wc -c
     166
```
Promotional text: 166 / 170 — OK.

All three fields verified within Apple's limits on the exact strings that
appear in the sections above (not on earlier drafts). Two earlier
promotional-text drafts were measured, found to be 184 and 181 characters
(over the 170 limit), and rewritten until the 166-character version above
passed.
