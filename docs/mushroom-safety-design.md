# Mushroom Safety Design

Ash should help with mushroom risk triage, not certify edibility.

## Product Principle

Unknown wild mushrooms are treated as unsafe until a qualified local expert
identifies the specimen. The app can describe visible traits, ask for better
evidence, warn about dangerous lookalikes, and route ingestion cases to poison
control or emergency care. It must not say a wild mushroom is safe to eat from a
photo, an LLM answer, or a computer vision suggestion.

## Research Notes

- CDC reports that accidental poisonous mushroom ingestion can cause severe
  illness and death, and says wild mushrooms should not be consumed unless an
  expert identifies them:
  https://www.cdc.gov/mmwr/volumes/70/wr/mm7010a1.htm
- Poison Help says to immediately call 1-800-222-1222 if someone eats wild
  mushrooms, because only experts can distinguish poisonous from safe
  mushrooms:
  https://poisonhelp.hrsa.gov/faq/plants
- iNaturalist publishes only a small public model subset for on-device testing;
  its full species models are not public, and the public files are species
  recognition assets rather than edibility detectors:
  https://github.com/inaturalist/model-files
- FungiCLEF 2024 is the closest research direction for an eventual CV tool. It
  benchmarks fungi species recognition, uses image plus metadata, and explicitly
  evaluates poisonous/edible confusion. That is still a candidate classifier
  problem, not a consumer-safe "eat this" oracle:
  https://ceur-ws.org/Vol-3740/paper-185.pdf

## Current PR

- Adds a mushroom safety mode in `GemmaInferenceService`.
- Detects mushroom/edibility/ingestion prompts and image edibility questions.
- Adds a Home entry point that opens a chat scoped to the Mushroom Safety pack;
  that lens also activates mushroom safety mode for generic image prompts.
- Injects a safety operating context before Gemma answers.
- Calls a `MushroomVisionAnalyzer` seam before image answers. The current
  implementation intentionally reports that no certified offline mushroom
  classifier is bundled, so the LLM cannot invent a model result.
- Adds an essential `Mushroom Safety` RAG pack for poison-control triage,
  evidence gathering, myths, symptoms, children, pets, lookalikes, and CV
  limitations.
- Adds tests for activation and prompt augmentation.

## Future CV Model Bar

A real mushroom CV model should ship only after it meets these constraints:

- Offline/mobile inference target with known model weights, taxonomy, license,
  and reproducible evaluation.
- Species or genus predictions calibrated with abstention. Unknown/open-set
  species must be expected, not treated as errors at the edge.
- Poisonous/edible confusion must be evaluated with asymmetric cost. False
  "edible" outputs are the primary hazard.
- Metadata support for location, season, habitat, substrate, and multiple
  photos.
- Output contract must be "candidate IDs and visible traits", never "safe to
  eat".
