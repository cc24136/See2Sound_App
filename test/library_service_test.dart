import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/storage/storage_settings_service.dart';
import 'package:see2sound_app/features/library/models/audio_description_library_item.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persiste e restaura a pasta de armazenamento', () async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-settings-test-',
    );
    try {
      final service = StorageSettingsService();
      await service.initialize();
      await service.setDirectoryPath(directory.path);

      final restored = StorageSettingsService();
      await restored.initialize();
      expect(restored.directoryPath, directory.path);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('persiste itens e evita duplicação pelo jobId', () async {
    final service = LibraryService();
    await service.initialize();
    final item = AudioDescriptionLibraryItem(
      id: 'job-1',
      originalFilename: 'video.mp4',
      originalVideoPath: '/videos/video.mp4',
      audioDescriptionPath: '/audios/video_audiodescription.wav',
      createdAt: DateTime(2026, 10, 1),
      duration: const Duration(seconds: 15),
      jobId: 'job-1',
    );

    await service.addItem(item);
    await service.addItem(
      item.copyWith(
        audioDescriptionPath: '/audios/video_audiodescription_2.wav',
      ),
    );

    expect(service.items, hasLength(1));
    expect(
      service.items.single.audioDescriptionPath,
      endsWith('video_audiodescription_2.wav'),
    );

    final restored = LibraryService();
    await restored.initialize();
    expect(restored.items, hasLength(1));
    expect(restored.items.single.duration, const Duration(seconds: 15));
  });

  test('trata JSON corrompido sem quebrar a biblioteca', () async {
    SharedPreferences.setMockInitialValues({
      'see2sound.audio_description_library': '{json inválido',
    });
    final service = LibraryService();

    await service.initialize();

    expect(service.items, isEmpty);
    expect(service.loadError, isNotNull);
  });

  test('renomeia o WAV e atualiza o registro persistido', () async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-library-test-',
    );
    final source = File(
      '${directory.path}${Platform.pathSeparator}original.wav',
    );
    await source.writeAsBytes([1, 2, 3]);
    final service = LibraryService();
    await service.initialize();
    final item = AudioDescriptionLibraryItem(
      id: 'job-2',
      originalFilename: 'video.mp4',
      originalVideoPath: '/videos/video.mp4',
      audioDescriptionPath: source.path,
      createdAt: DateTime(2026, 10, 1),
      jobId: 'job-2',
    );
    await service.addItem(item);

    try {
      final renamed = await service.renameAudioFile(item, 'novo nome.wav');
      expect(renamed.audioDescriptionPath, endsWith('novo nome.wav'));
      expect(await File(renamed.audioDescriptionPath).exists(), isTrue);
      expect(await source.exists(), isFalse);
      expect(
        service.items.single.audioDescriptionPath,
        renamed.audioDescriptionPath,
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
