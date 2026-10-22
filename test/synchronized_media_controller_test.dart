import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/features/player/synchronized_media_controller.dart';

void main() {
  test('corrige somente drift acima do limite configurado', () {
    expect(
      SynchronizedMediaController.requiresDriftCorrection(
        videoPosition: const Duration(seconds: 10),
        audioPosition: const Duration(seconds: 10, milliseconds: 200),
        threshold: const Duration(milliseconds: 250),
      ),
      isFalse,
    );
    expect(
      SynchronizedMediaController.requiresDriftCorrection(
        videoPosition: const Duration(seconds: 10),
        audioPosition: const Duration(seconds: 9, milliseconds: 600),
        threshold: const Duration(milliseconds: 250),
      ),
      isTrue,
    );
  });

  test('drift usa diferença absoluta para áudio adiantado ou atrasado', () {
    final ahead = SynchronizedMediaController.requiresDriftCorrection(
      videoPosition: const Duration(seconds: 5),
      audioPosition: const Duration(seconds: 6),
      threshold: const Duration(milliseconds: 250),
    );
    final behind = SynchronizedMediaController.requiresDriftCorrection(
      videoPosition: const Duration(seconds: 6),
      audioPosition: const Duration(seconds: 5),
      threshold: const Duration(milliseconds: 250),
    );
    expect(ahead, isTrue);
    expect(behind, isTrue);
  });
}
