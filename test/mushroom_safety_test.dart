import 'package:ash/services/mushroom_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MushroomSafety.shouldActivate', () {
    test('activates for mushroom edibility text', () {
      expect(
        MushroomSafety.shouldActivate(
          prompt: 'Is this mushroom edible?',
          usesImage: false,
        ),
        isTrue,
      );
    });

    test('activates for image edibility questions', () {
      expect(
        MushroomSafety.shouldActivate(
          prompt: 'Can I eat this?',
          usesImage: true,
        ),
        isTrue,
      );
    });

    test('activates when ingestion is already described', () {
      expect(
        MushroomSafety.shouldActivate(
          prompt: 'My kid ate a mushroom from the yard',
          usesImage: false,
        ),
        isTrue,
      );
    });

    test('does not activate for general fungi curiosity', () {
      expect(
        MushroomSafety.shouldActivate(
          prompt: 'Why do mushrooms grow after rain?',
          usesImage: false,
        ),
        isFalse,
      );
    });
  });

  test('augmented prompt forbids photo-only edibility claims', () {
    final prompt = MushroomSafety.augmentPrompt(
      prompt: 'Is this safe to eat?',
      usesImage: true,
    );

    expect(prompt, contains('Do not tell the user'));
    expect(prompt, contains('Poison Help'));
    expect(prompt, contains('No offline mushroom edibility classifier'));
  });
}
