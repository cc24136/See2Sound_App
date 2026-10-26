import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/accessibility/interface_narration_service.dart';
import 'package:see2sound_app/core/settings/app_settings_controller.dart';
import 'package:see2sound_app/features/library/library_page.dart';
import 'package:see2sound_app/features/library/models/audio_description_library_item.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AudioDescriptionLibraryItem item(String id, String audio) =>
    AudioDescriptionLibraryItem(
      id: id,
      originalFilename: '$id.mp4',
      originalVideoPath: '$audio.mp4',
      audioDescriptionPath: audio,
      createdAt: DateTime(2026, 10, 25),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'exclui seleção, persiste e mantém arquivos não selecionados e vídeos',
    () async {
      final dir = await Directory.systemTemp.createTemp('see2sound-bulk-');
      final service = LibraryService();
      try {
        for (final id in ['um', 'dois', 'tres']) {
          final entry = item(id, '${dir.path}/$id.wav');
          await File(entry.audioDescriptionPath).writeAsBytes([1, 2]);
          await File(entry.originalVideoPath).writeAsBytes([3, 4]);
          await service.addItem(entry);
        }
        final failures = await service.deleteAudioFilesAndRemove([
          'um',
          'dois',
          'um',
        ]);
        expect(failures, isEmpty);
        expect(service.items.single.id, 'tres');
        expect(await File('${dir.path}/um.wav').exists(), isFalse);
        expect(await File('${dir.path}/dois.wav').exists(), isFalse);
        expect(await File('${dir.path}/tres.wav').exists(), isTrue);
        expect(await File('${dir.path}/um.wav.mp4').exists(), isTrue);
        final restored = LibraryService();
        await restored.initialize();
        expect(restored.items.single.id, 'tres');
        restored.dispose();
      } finally {
        service.dispose();
        await dir.delete(recursive: true);
      }
    },
  );

  test('falha em arquivo compartilhado não interrompe outros itens', () async {
    final dir = await Directory.systemTemp.createTemp(
      'see2sound-bulk-partial-',
    );
    final service = LibraryService();
    try {
      final shared = File('${dir.path}/compartilhado.wav');
      await shared.writeAsBytes([1]);
      await service.addItem(item('um', shared.path));
      await service.addItem(item('dois', shared.path));
      await service.addItem(item('ausente', '${dir.path}/ausente.wav'));
      final failures = await service.deleteAudioFilesAndRemove([
        'um',
        'ausente',
      ]);
      expect(failures.keys, ['um']);
      expect(
        service.items.map((entry) => entry.id),
        containsAll(['um', 'dois']),
      );
      expect(service.items, hasLength(2));
      expect(await shared.exists(), isTrue);
    } finally {
      service.dispose();
      await dir.delete(recursive: true);
    }
  });

  testWidgets(
    'seleção, busca, cancelamento e confirmação da exclusão múltipla',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('see2sound-bulk-ui-'),
      ))!;
      final service = LibraryService();
      final settings = AppSettingsController();
      await service.addItem(item('um', '${dir.path}/um.wav'));
      await service.addItem(item('dois', '${dir.path}/dois.wav'));
      await service.addItem(item('tres', '${dir.path}/tres.wav'));
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LibraryPage(
                highContrast: false,
                visualFocus: true,
                libraryService: service,
                reduceMotion: true,
                simplifiedInterface: false,
                narrationService: InterfaceNarrationService(settings),
                onNewVideo: () {},
              ),
            ),
          ),
        );
        await tester.tap(find.text('Selecionar audiodescrições'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('um')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'dois');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Selecionar todas as visíveis'));
        await tester.pumpAndSettle();
        expect(find.text('2 selecionadas'), findsOneWidget);
        await tester.tap(find.text('Excluir selecionadas'));
        await tester.pumpAndSettle();
        expect(find.text('Excluir 2 audiodescrições?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(service.items, hasLength(3));
        expect(find.text('2 selecionadas'), findsOneWidget);
        await tester.tap(find.text('Excluir selecionadas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
        for (
          var attempt = 0;
          attempt < 20 && service.items.length > 1;
          attempt++
        ) {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          });
          await tester.pumpAndSettle();
        }
        expect(service.items.single.id, 'tres');
        expect(find.text('2 audiodescrições excluídas.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        service.dispose();
        settings.dispose();
        await tester.runAsync(() => dir.delete(recursive: true));
      }
    },
  );
}
