import 'dart:io';

import 'package:flutter/services.dart';

/// Result from a mushroom-specific vision model.
///
/// The bundled iNaturalist model is a limited visual candidate-label model, not
/// a certified mushroom edibility classifier. Keeping this as a small interface
/// makes the model call explicit in the inference path, while preventing the
/// LLM from inventing detector results.
abstract interface class MushroomVisionAnalyzer {
  Future<MushroomVisionFinding> analyze(Uint8List imageBytes);
}

class NoopMushroomVisionAnalyzer implements MushroomVisionAnalyzer {
  const NoopMushroomVisionAnalyzer();

  @override
  Future<MushroomVisionFinding> analyze(Uint8List imageBytes) async {
    return const MushroomVisionFinding(
      modelName: 'none',
      modelAvailable: false,
      observations: [
        'No certified offline mushroom edibility classifier is bundled in this build.',
      ],
      limitations: [
        'Do not infer edibility, toxicity, or species certainty from this tool.',
        'Use the photo only for visible feature triage and next-step guidance.',
      ],
    );
  }
}

class INaturalistMushroomVisionAnalyzer implements MushroomVisionAnalyzer {
  const INaturalistMushroomVisionAnalyzer();

  static const _channel = MethodChannel('ash/mushroom_vision');
  static const _modelName = 'iNaturalist Small Vision v25.01.15';

  static const _fungiTaxaByClassId = <int, ({String name, String note})>{
    39: (
      name: 'Xanthoria parietina',
      note:
          'lichen label in the public iNaturalist model, not an edibility signal',
    ),
    53: (
      name: 'Amanita muscaria',
      note: 'toxic mushroom warning signal; do not eat',
    ),
    113: (
      name: 'Flavoparmelia caperata',
      note:
          'lichen label in the public iNaturalist model, not an edibility signal',
    ),
    212: (
      name: 'Schizophyllum commune',
      note:
          'fungus label in the public iNaturalist model, not an edibility signal',
    ),
    248: (
      name: 'Tremella mesenterica',
      note:
          'fungus label in the public iNaturalist model, not an edibility signal',
    ),
    322: (
      name: 'Parmelia sulcata',
      note:
          'lichen label in the public iNaturalist model, not an edibility signal',
    ),
    485: (
      name: 'Fuligo septica',
      note:
          'slime mold label in the public iNaturalist model, not an edibility signal',
    ),
  };

  @override
  Future<MushroomVisionFinding> analyze(Uint8List imageBytes) async {
    if (!Platform.isIOS) {
      return const MushroomVisionFinding(
        modelName: _modelName,
        modelAvailable: false,
        observations: [
          'The bundled iNaturalist CoreML classifier runs on iOS only.',
        ],
        limitations: [
          'Do not infer edibility, toxicity, or species certainty from this tool.',
          'Use the photo only for visible feature triage and next-step guidance.',
        ],
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'analyze',
        {
          'imageBytes': imageBytes,
          'topK': 20,
        },
      );
      if (result == null || result['modelAvailable'] != true) {
        return MushroomVisionFinding(
          modelName: _modelName,
          modelAvailable: false,
          observations: [
            'The bundled iNaturalist CoreML classifier did not run.',
            if (result?['error'] case final String error) error,
          ],
          limitations: const [
            'Do not infer edibility, toxicity, or species certainty from this tool.',
            'Use the photo only for visible feature triage and next-step guidance.',
          ],
        );
      }

      final top = (result['top'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => (
                classId: (m['classId'] as num).toInt(),
                score: (m['score'] as num).toDouble(),
              ))
          .toList();
      final fungiCandidates = [
        for (final candidate in top)
          if (_fungiTaxaByClassId[candidate.classId] case final taxon?)
            (
              classId: candidate.classId,
              score: candidate.score,
              name: taxon.name,
              note: taxon.note,
            ),
      ];

      final observations = <String>[
        'Ran $_modelName, the public MIT-licensed iNaturalist small vision model with 507 leaf taxa.',
        'Its public fungi coverage is very narrow, so it can only provide limited candidate-label signals.',
      ];

      if (fungiCandidates.isEmpty) {
        observations.add(
          'No fungi/lichen/slime-mold label from the public iNaturalist subset appeared in the top ${top.length} visual candidates; this does not rule out a mushroom.',
        );
      } else {
        for (final candidate in fungiCandidates.take(3)) {
          observations.add(
            'Limited iNaturalist candidate: ${candidate.name} '
            '(class ${candidate.classId}, ${(candidate.score * 100).toStringAsFixed(1)}% model score) — ${candidate.note}.',
          );
        }
      }

      return MushroomVisionFinding(
        modelName: _modelName,
        modelAvailable: true,
        observations: observations,
        limitations: const [
          'This is not an edible/poisonous classifier and must not be used to decide whether to eat a mushroom.',
          'The public iNaturalist small model is a limited taxa model; many mushrooms are not represented.',
          'Image-only predictions can miss lookalikes, age, habitat, substrate, spore print, odor, location, and other expert identification evidence.',
        ],
      );
    } catch (e) {
      return MushroomVisionFinding(
        modelName: _modelName,
        modelAvailable: false,
        observations: [
          'The bundled iNaturalist CoreML classifier failed to run: $e',
        ],
        limitations: const [
          'Do not infer edibility, toxicity, or species certainty from this tool.',
          'Use the photo only for visible feature triage and next-step guidance.',
        ],
      );
    }
  }
}

class MushroomVisionFinding {
  const MushroomVisionFinding({
    required this.modelName,
    required this.modelAvailable,
    required this.observations,
    required this.limitations,
  });

  final String modelName;
  final bool modelAvailable;
  final List<String> observations;
  final List<String> limitations;

  String toPromptBlock() {
    final sb = StringBuffer()
      ..writeln('Mushroom vision analyzer:')
      ..writeln('- Model: $modelName')
      ..writeln('- Available: ${modelAvailable ? 'yes' : 'no'}');
    for (final item in observations) {
      sb.writeln('- Observation: $item');
    }
    for (final item in limitations) {
      sb.writeln('- Limitation: $item');
    }
    return sb.toString().trimRight();
  }
}

abstract final class MushroomSafety {
  static const packId = 'mushroom-safety';

  static const starterPrompt =
      'I found a wild mushroom. Help me assess the risk. I can attach photos '
      'of the cap, underside, stem, base, and where it was growing.';

  static final RegExp _mushroomTerms = RegExp(
    r'\b(mushroom|mushrooms|fungus|fungi|fungal|toadstool|gill|gills|spore|spores|amanita|death cap|destroying angel|morel|false morel|chanterelle|bolete|puffball|forage|foraged|foraging)\b',
    caseSensitive: false,
  );

  static final RegExp _safetyTerms = RegExp(
    r'\b(edible|eat|eating|ate|eaten|safe|unsafe|poison|poisonous|poisoning|toxic|toxicity|deadly|fatal|lookalike|identify|identification|id|cook|cooking|taste|tasted|ingest|ingested|swallow|swallowed|sick|symptom|symptoms)\b',
    caseSensitive: false,
  );

  static final RegExp _imageEdibilityTerms = RegExp(
    r'\b(is this edible|can i eat|safe to eat|poisonous|toxic|foraged this|cook this)\b',
    caseSensitive: false,
  );

  static bool shouldActivate({
    required String prompt,
    required bool usesImage,
    bool lensActive = false,
  }) {
    final text = prompt.trim();
    if (lensActive) return true;
    if (text.isEmpty) return false;

    final hasMushroomTerm = _mushroomTerms.hasMatch(text);
    final hasSafetyTerm = _safetyTerms.hasMatch(text);
    if (hasMushroomTerm && (hasSafetyTerm || usesImage)) return true;

    // Image + edibility questions are usually foraging/plant ID questions.
    // Apply the same conservative rule: never bless unknown wild food from a
    // photo. If the image is not a mushroom, the model can say so.
    return usesImage && _imageEdibilityTerms.hasMatch(text);
  }

  static String augmentPrompt({
    required String prompt,
    required bool usesImage,
    MushroomVisionFinding? visionFinding,
  }) {
    final userPrompt = prompt.trim().isEmpty
        ? (usesImage
            ? 'Assess this photo for mushroom safety.'
            : 'Help me assess mushroom safety.')
        : prompt.trim();
    final sb = StringBuffer()
      ..writeln('Mushroom safety operating context:')
      ..writeln(
          '- Do not tell the user that a wild mushroom is safe, edible, or okay to eat from a photo or LLM identification alone.')
      ..writeln(
          '- Treat every unknown wild mushroom as unsafe to eat until a qualified local mushroom expert confirms it in person.')
      ..writeln(
          '- If anyone already ate a wild mushroom, especially a child or pet, tell them to call Poison Help at 1-800-222-1222 in the U.S. or local poison control/emergency services now.')
      ..writeln(
          '- Do not rely on cooking, peeling, drying, taste, smell, color, or animal nibbling as safety tests.')
      ..writeln(
          '- For visual triage, describe only visible traits and uncertainty. Ask for cap top, underside, stem, base/volva, bruising, habitat, location, date, spore print, and multiple specimens.')
      ..writeln(
          '- Mention dangerous lookalike groups only as possibilities, never as a confident species verdict, unless the user supplies enough expert-level evidence.')
      ..writeln(
          '- For symptoms such as vomiting, diarrhea, confusion, sweating, seizures, jaundice, severe pain, or delayed illness after eating mushrooms, prioritize urgent medical/poison-center help.');

    if (usesImage) {
      sb
        ..writeln()
        ..writeln((visionFinding ?? _noAnalyzerFinding).toPromptBlock());
    }

    sb
      ..writeln()
      ..writeln('User question:')
      ..write(userPrompt);
    return sb.toString();
  }

  static const systemRules =
      'Mushroom safety mode is active. Never certify a wild mushroom as '
      'safe or edible from an image, a description, or a model guess. Give '
      'practical risk triage: do not eat it, preserve the specimen/photos, '
      'collect missing identification details, and call Poison Help or local '
      'emergency services if ingestion happened or symptoms are present. '
      'Use cautious language such as "possibly", "consistent with", and '
      '"cannot rule out".';

  static const liveSystemRules =
      'Mushroom safety mode is active. Speak plainly and briefly. Never say '
      'a wild mushroom is safe to eat from a photo or description. If it was '
      'eaten, tell the user to call Poison Help at 1-800-222-1222 in the '
      'U.S. or local poison control now. Otherwise say not to eat it and ask '
      'for the key identifying details.';

  static const visionSystemAddendum =
      ' If the image appears to show wild mushrooms or foraged food, do not '
      'declare it safe to eat. Treat it as visual triage only and recommend '
      'expert identification before consumption.';

  static const _noAnalyzerFinding = MushroomVisionFinding(
    modelName: 'none',
    modelAvailable: false,
    observations: [
      'No certified offline mushroom edibility classifier is bundled in this build.',
    ],
    limitations: [
      'Do not infer edibility, toxicity, or species certainty from this tool.',
      'Use the photo only for visible feature triage and next-step guidance.',
    ],
  );
}
