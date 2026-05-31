import AVFoundation
import CoreML
import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Audio session control channel. flutter_tts on iOS only calls
    // AVAudioSession.setActive(false) when an utterance finishes naturally
    // (didFinish delegate). When TTS is cancelled mid-utterance — which is
    // what live-mode interrupt does — the session stays active in
    // playAndRecord mode. After a few interrupt cycles the session state
    // corrupts AVAudioEngine.inputNode, causing speech_to_text's next
    // listenForSpeech to SIGSEGV inside AVAudioNode outputFormatForBus:.
    // Dart calls this channel after stopSpeaking to force a clean release.
    let audioChannel = FlutterMethodChannel(
      name: "ash/audio_session",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    audioChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "deactivate":
        do {
          try AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
          result(true)
        } catch {
          // Swift error (not NSException). Safe to surface to Dart.
          result(FlutterError(
            code: "deactivate_failed",
            message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let mushroomVisionBridge = MushroomVisionBridge()
    let mushroomVisionChannel = FlutterMethodChannel(
      name: "ash/mushroom_vision",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    mushroomVisionChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "analyze":
        guard
          let args = call.arguments as? [String: Any],
          let bytes = args["imageBytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(
            code: "bad_args",
            message: "Expected imageBytes as FlutterStandardTypedData.",
            details: nil))
          return
        }
        let topK = args["topK"] as? Int ?? 20
        mushroomVisionBridge.analyze(imageData: bytes.data, topK: topK) {
          result($0)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private final class MushroomVisionBridge {
  private static let modelResource = "INatVision_Small_2_fact256_8bit"
  private let queue = DispatchQueue(label: "ash.mushroom_vision")
  private var cachedModel: VNCoreMLModel?

  func analyze(
    imageData: Data,
    topK: Int,
    completion: @escaping (Any) -> Void
  ) {
    queue.async { [weak self] in
      guard let self = self else { return }
      let response = self.runAnalysis(imageData: imageData, topK: topK)
      DispatchQueue.main.async {
        completion(response)
      }
    }
  }

  private func runAnalysis(imageData: Data, topK: Int) -> [String: Any] {
    do {
      let model = try loadModel()
      let request = VNCoreMLRequest(model: model)
      request.imageCropAndScaleOption = .centerCrop
      let handler = VNImageRequestHandler(data: imageData, options: [:])
      try handler.perform([request])

      guard
        let feature = request.results?.first as? VNCoreMLFeatureValueObservation,
        let values = feature.featureValue.multiArrayValue
      else {
        return unavailable("CoreML model did not return a multi-array output.")
      }

      let scores = softmax(read(values))
      let limit = max(1, min(topK, scores.count))
      let top = scores.indices
        .sorted { scores[$0] > scores[$1] }
        .prefix(limit)
        .map { ["classId": $0, "score": scores[$0]] }

      return [
        "modelName": "iNaturalist Small Vision v25.01.15",
        "modelAvailable": true,
        "outputCount": scores.count,
        "top": Array(top),
      ]
    } catch {
      return unavailable(error.localizedDescription)
    }
  }

  private func loadModel() throws -> VNCoreMLModel {
    if let cachedModel {
      return cachedModel
    }
    guard let url = Bundle.main.url(
      forResource: Self.modelResource,
      withExtension: "mlmodelc"
    ) else {
      throw NSError(
        domain: "AshMushroomVision",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "iNaturalist CoreML model is not bundled."])
    }

    let config = MLModelConfiguration()
    config.computeUnits = .all
    let mlModel = try MLModel(contentsOf: url, configuration: config)
    let visionModel = try VNCoreMLModel(for: mlModel)
    cachedModel = visionModel
    return visionModel
  }

  private func read(_ array: MLMultiArray) -> [Double] {
    var values: [Double] = []
    values.reserveCapacity(array.count)
    for i in 0..<array.count {
      values.append(array[i].doubleValue)
    }
    return values
  }

  private func softmax(_ values: [Double]) -> [Double] {
    guard let maxValue = values.max() else { return [] }
    let exps = values.map { Foundation.exp($0 - maxValue) }
    let total = exps.reduce(0, +)
    guard total > 0 else { return Array(repeating: 0, count: values.count) }
    return exps.map { $0 / total }
  }

  private func unavailable(_ reason: String) -> [String: Any] {
    [
      "modelName": "iNaturalist Small Vision v25.01.15",
      "modelAvailable": false,
      "error": reason,
    ]
  }
}
