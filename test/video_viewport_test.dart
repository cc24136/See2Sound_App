import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/shared/widgets/video_viewport.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('preserva tela 16:9 e mídia sem corte em largura $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const mediaKey = ValueKey('media');
      for (final size in [
        const Size(1080, 1920),
        const Size(1920, 1080),
        const Size(1080, 1080),
        const Size(2048, 858),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: VideoViewport(
                  videoSize: size,
                  child: const ColoredBox(key: mediaKey, color: Colors.red),
                ),
              ),
            ),
          ),
        );
        final viewport = tester.getRect(find.byType(VideoViewport));
        expect(viewport.width / viewport.height, closeTo(16 / 9, 0.0001));
        final box = tester.renderObject<RenderBox>(find.byKey(mediaKey));
        final origin = box.localToGlobal(Offset.zero);
        final end = box.localToGlobal(Offset(box.size.width, box.size.height));
        final media = Rect.fromPoints(origin, end);
        expect(media.width / media.height, closeTo(size.aspectRatio, 0.0001));
        expect(media.center.dx, closeTo(viewport.center.dx, 0.001));
        expect(media.center.dy, closeTo(viewport.center.dy, 0.001));
        expect(media.width, lessThanOrEqualTo(viewport.width + 0.001));
        expect(media.height, lessThanOrEqualTo(viewport.height + 0.001));
        if (size == const Size(1080, 1920)) {
          expect(media.height, closeTo(viewport.height, 0.001));
          expect(media.left, greaterThan(viewport.left));
          expect(media.right, lessThan(viewport.right));
        }
        final background = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(VideoViewport),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(background.color, Colors.black);
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('dimensões desconhecidas ou inválidas mantêm 16:9', (
    tester,
  ) async {
    for (final size in [
      Size.zero,
      const Size(double.nan, 0),
      const Size(1, double.infinity),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoViewport(
              videoSize: size,
              child: const Text('Preparando reprodução'),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(VideoViewport));
      expect(rect.width / rect.height, closeTo(16 / 9, 0.0001));
      expect(tester.takeException(), isNull);
    }
  });
}
