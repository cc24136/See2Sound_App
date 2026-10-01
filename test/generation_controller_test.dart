import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/storage/storage_settings_service.dart';
import 'package:see2sound_app/features/generate/controllers/generation_controller.dart';
import 'package:see2sound_app/features/generate/models/audio_description_metadata.dart';
import 'package:see2sound_app/features/generate/models/generation_created.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';
import 'package:see2sound_app/features/generate/services/see2sound_api_service.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('bloqueia geração quando não há pasta configurada', () async {
    final storage = StorageSettingsService();
    final library = LibraryService();
    final api = _FakeApiService();
    final controller = GenerationController(
      apiService: api,
      storageSettingsService: storage,
      libraryService: library,
    );

    await controller.startGeneration(
      videoPath: '/videos/video.mp4',
      filename: 'video.mp4',
    );

    expect(controller.state, GenerationUiState.error);
    expect(controller.requiresStorageConfiguration, isTrue);
    expect(api.createCalls, 0);
    controller.dispose();
  });

  test('registra item antes de mudar para ready', () async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-controller-test-',
    );
    final storage = StorageSettingsService();
    await storage.initialize();
    await storage.setDirectoryPath(directory.path);
    final library = LibraryService();
    await library.initialize();
    final api = _FakeApiService();
    final controller = GenerationController(
      apiService: api,
      storageSettingsService: storage,
      libraryService: library,
    );

    try {
      await controller.startGeneration(
        videoPath: '/videos/video.mp4',
        filename: 'video.mp4',
      );

      expect(controller.state, GenerationUiState.ready);
      expect(
        controller.audioPath,
        '${directory.path}${Platform.pathSeparator}video.wav',
      );
      expect(library.items, hasLength(1));
      expect(library.items.single.jobId, 'job-1');
      expect(library.items.single.originalVideoPath, '/videos/video.mp4');
      expect(api.destinationDirectoryPath, directory.path);
    } finally {
      controller.dispose();
      await directory.delete(recursive: true);
    }
  });
}

class _FakeApiService extends See2SoundApiService {
  int createCalls = 0;
  String? destinationDirectoryPath;

  @override
  Future<GenerationCreated> createGeneration({
    required String videoPath,
    required String filename,
    double frameIntervalSeconds = 1,
    String whisperLanguage = 'pt',
    bool runSpectra = true,
    bool runNarrative = true,
    bool runTts = true,
  }) async {
    createCalls++;
    return const GenerationCreated(
      jobId: 'job-1',
      status: 'queued',
      message: 'Recebido',
      statusUrl: '/status',
      resultUrl: '/result',
      audioDescriptionUrl: '/audio',
      audioDescriptionMetadataUrl: '/metadata',
    );
  }

  @override
  Future<GenerationSnapshot> getGenerationStatus(String jobId) async {
    return const GenerationSnapshot(
      jobId: 'job-1',
      status: GenerationStatus.completed,
      originalFilename: 'video.mp4',
      createdAt: null,
      startedAt: null,
      finishedAt: null,
      error: null,
      options: {},
    );
  }

  @override
  Future<AudioDescriptionMetadata> getAudioDescriptionMetadata(
    String jobId,
  ) async {
    return const AudioDescriptionMetadata(
      jobId: 'job-1',
      status: GenerationStatus.completed,
      totalDescriptions: 1,
      insertedDescriptions: 1,
      skippedDescriptions: 0,
      cues: [],
      audioUrl: '/audio',
    );
  }

  @override
  Future<String> downloadAudioDescription(
    String jobId, {
    required String destinationDirectoryPath,
    required String originalFilename,
  }) async {
    this.destinationDirectoryPath = destinationDirectoryPath;
    return '$destinationDirectoryPath${Platform.pathSeparator}video.wav';
  }

  @override
  void close() {}
}
