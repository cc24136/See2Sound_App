import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/features/player/player_page.dart';
import 'package:see2sound_app/shared/widgets/video_viewport.dart';

void main() {
  testWidgets(
    'arquivo ausente apresenta erro acessível, tentativa novamente e viewport 16:9',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('see2sound-player-error-'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: PlayerPage(
              videoPath: '${directory.path}/ausente.mp4',
              audioPath: '${directory.path}/ausente.wav',
              filename: 'Teste',
              highContrast: false,
              visualFocus: true,
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.textContaining('não foi encontrado'), findsOneWidget);
        final retry = find.widgetWithText(FilledButton, 'Tentar novamente');
        expect(retry, findsOneWidget);
        expect(
          tester
              .getSemantics(retry)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        final viewport = tester.getSize(find.byType(VideoViewport));
        expect(viewport.aspectRatio, closeTo(16 / 9, 0.0001));
        await tester.tap(retry);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.textContaining('não foi encontrado'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    },
  );
}
