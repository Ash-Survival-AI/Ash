// Coverage for the pref-driven onboarding/disclaimer gate in
// `_AshAppState._maybeSkipOnboarding()` (lib/app.dart). This is the
// safety-critical branch: it decides whether a returning user must
// re-acknowledge the safety disclaimer, and whether they land on the model
// picker (which can kick off a multi-GB re-download) or straight in the app.
//
// Everything below `_maybeSkipOnboarding` in `initState` (`_loadPacks`,
// `_kickOffWarmUpIfReady`, `_refreshInstalledLlmModels`) also runs against
// these fakes, since they're unconditional widget lifecycle calls — the
// fakes are just enough to let AshApp boot without touching any real
// plugin channel (speech, TTS, flutter_gemma, HTTP).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ash/app.dart';
import 'package:ash/screens/safety_disclaimer_screen.dart';
import 'package:ash/screens/model_pick_screen.dart';
import 'package:ash/screens/home_screen.dart';
import 'package:ash/services/inference_service.dart';
import 'package:ash/services/inference_settings.dart';
import 'package:ash/services/llm_model.dart';
import 'package:ash/services/voice_service.dart';

const _kOnboardingDone = 'onboarding_carousel_done';

/// Minimal fake — every method returns an inert default. The only knob that
/// matters for this test is [installedModels]: which [LlmModel]s
/// `getModelStatus` reports as present on disk, which is exactly what
/// `_anyModelOnDisk()` / `_maybeSkipOnboarding()` consult.
class FakeInferenceService implements InferenceService {
  FakeInferenceService({this.installedModels = const {}});

  final Set<LlmModel> installedModels;

  @override
  LlmModel activeLlmModel = LlmModel.gemma4E2B;

  @override
  Future<void> setActiveLlmModel(LlmModel model) async {
    activeLlmModel = model;
  }

  @override
  Future<ModelStatus> getModelStatus({LlmModel? model}) async {
    final m = model ?? activeLlmModel;
    return ModelStatus(isInstalled: installedModels.contains(m));
  }

  @override
  Future<void> installModel({
    LlmModel? model,
    String? token,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {}

  @override
  Future<void> deleteModel({LlmModel? model}) async {}

  @override
  AcceleratorChoice accelerator = AcceleratorChoice.gpu;

  @override
  Future<void> setAccelerator(AcceleratorChoice choice) async {
    accelerator = choice;
  }

  @override
  bool speculativeDecoding = true;

  @override
  Future<void> setSpeculativeDecoding(bool enabled) async {
    speculativeDecoding = enabled;
  }

  @override
  Future<void> warmUp() async {}

  @override
  bool isWarm = false;

  @override
  bool hasVision = false;

  @override
  bool isLoadingVision = false;

  @override
  Future<void> closeEngine() async {}

  @override
  Future<void> resetChatSession() async {}

  @override
  Stream<InferenceChunk> query({
    required String chatId,
    required String prompt,
    Uint8List? imageBytes,
    List<HistoryTurn> priorHistory = const [],
    InferenceSettings settings = InferenceSettings.defaults,
    bool liveMode = false,
  }) {
    return const Stream<InferenceChunk>.empty();
  }

  @override
  Future<void> stop() async {}

  @override
  bool isGenerating = false;

  @override
  ReconfigureNeeds reconfigureNeedsFor({
    required String chatId,
    required InferenceSettings settings,
    required bool needsVision,
  }) {
    return const ReconfigureNeeds();
  }

  @override
  Future<void> applySettings({
    required String chatId,
    required InferenceSettings settings,
    List<HistoryTurn> priorHistory = const [],
  }) async {}

  @override
  Future<void> importPack(String packId) async {}

  @override
  Future<void> importPackFromUrl(
    String packId,
    String url, {
    void Function(double progress)? onProgress,
  }) async {}

  @override
  Future<void> uninstallPack(String packId) async {}

  @override
  void setLens(Set<String>? lensPackIds) {}

  @override
  Future<void> importAllPacks() async {}

  @override
  Future<Set<String>> installedPackIds() async => const <String>{};

  @override
  Future<List<LibraryChunk>> readPack(String packId) async => const [];

  @override
  Future<List<PackRanking>> rankByQuery({
    required String query,
    required Map<String, String> texts,
  }) async =>
      const [];
}

/// Minimal fake — AshApp never calls into voice I/O during boot, so every
/// member here is unreachable in this test and just needs to type-check.
class FakeVoiceService implements VoiceService {
  @override
  Future<VoiceStatus> getStatus() async => const VoiceStatus(
        sttReady: false,
        ttsReady: false,
        micPermitted: false,
      );

  @override
  Future<void> startRecording() async {}

  @override
  Future<String> stopAndTranscribe() async => '';

  @override
  Future<void> cancelRecording() async {}

  @override
  bool isRecording = false;

  @override
  Stream<String> get partialStream => const Stream<String>.empty();

  @override
  Stream<String> get finalStream => const Stream<String>.empty();

  @override
  Stream<String> get errorStream => const Stream<String>.empty();

  @override
  Future<void> feedTtsChunk(String chunk) async {}

  @override
  Future<void> flushTts() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  bool isSpeaking = false;

  @override
  Stream<bool> get speakingStream => const Stream<bool>.empty();

  @override
  Future<List<VoiceOption>> getAvailableVoices() async => const [];

  @override
  VoiceOption? currentVoice;

  @override
  Future<void> setVoice(VoiceOption voice) async {}

  @override
  double speechRate = 0.5;

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Duration listeningPatience = const Duration(seconds: 5);

  @override
  Future<void> setListeningPatience(Duration value) async {}

  @override
  Future<void> previewVoice(VoiceOption voice, String text) async {}

  @override
  Future<void> dispose() async {}
}

/// Pumps [AshApp] and lets its `initState` chain settle.
///
/// `_loadPacks()` reads a real asset (`assets/rag/packs/packs_registry.json`)
/// via `rootBundle.loadString`, which is genuine (non-fake-clock) I/O.
/// `testWidgets` normally runs inside a fake-async zone where only faked
/// Timers/microtasks advance on `pump()`, so that real I/O future never
/// resolves and `pumpAndSettle()` times out waiting on the perpetual
/// `CircularProgressIndicator` the "packs not loaded yet" branch shows.
/// `tester.runAsync()` steps outside that fake zone for the real await, then
/// a normal `pump()` flushes the resulting frame.
Future<void> _pumpApp(
  WidgetTester tester, {
  required InferenceService service,
  required VoiceService voiceService,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(AshApp(service: service, voiceService: voiceService));
    // Give _maybeSkipOnboarding's awaited SharedPreferences/service calls and
    // _loadPacks' real asset read time to resolve.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'onboarding done, disclaimer not yet accepted -> disclaimer is shown',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        _kOnboardingDone: true,
        // kPrefSafetyDisclaimerAccepted deliberately absent — simulates a
        // user upgrading from a build that predates the disclaimer gate.
      });

      await _pumpApp(
        tester,
        service: FakeInferenceService(installedModels: {LlmModel.gemma4E2B}),
        voiceService: FakeVoiceService(),
      );

      expect(find.byType(SafetyDisclaimerScreen), findsOneWidget);
      expect(find.byType(ModelPickScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets(
    'onboarding done + disclaimer accepted + model installed -> main (no re-pick)',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        _kOnboardingDone: true,
        kPrefSafetyDisclaimerAccepted: true,
      });

      await _pumpApp(
        tester,
        service: FakeInferenceService(installedModels: {LlmModel.gemma4E2B}),
        voiceService: FakeVoiceService(),
      );

      // Must land in the main app, never back at the model picker — a
      // returning user with a model on disk should never be routed
      // somewhere that can only trigger a fresh multi-GB download.
      expect(find.byType(ModelPickScreen), findsNothing);
      expect(find.byType(SafetyDisclaimerScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding done + disclaimer accepted + no model on disk -> model pick',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        _kOnboardingDone: true,
        kPrefSafetyDisclaimerAccepted: true,
      });

      await _pumpApp(
        tester,
        service: FakeInferenceService(installedModels: const {}),
        voiceService: FakeVoiceService(),
      );

      expect(find.byType(ModelPickScreen), findsOneWidget);
      expect(find.byType(SafetyDisclaimerScreen), findsNothing);
    },
  );
}
