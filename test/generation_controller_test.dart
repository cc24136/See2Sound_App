import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/network/api_exception.dart';
import 'package:see2sound_app/core/storage/storage_settings_service.dart';
import 'package:see2sound_app/features/generate/controllers/generation_controller.dart';
import 'package:see2sound_app/features/generate/models/audio_description_metadata.dart';
import 'package:see2sound_app/features/generate/models/generation_created.dart';
import 'package:see2sound_app/features/generate/models/generation_result.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';
import 'package:see2sound_app/features/generate/services/see2sound_api_service.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';
import 'package:see2sound_app/features/library/models/audio_description_library_item.dart';
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

  test('acompanha queued, processing e completed e registra o WAV', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(
        statuses: const [
          GenerationStatus.queued,
          GenerationStatus.processing,
          GenerationStatus.completed,
        ],
      ),
    );
    final states = <GenerationUiState>[];
    harness.controller.addListener(() => states.add(harness.controller.state));

    try {
      await harness.start();
      await _waitFor(() => harness.controller.state == GenerationUiState.ready);

      expect(
        states,
        containsAllInOrder([
          GenerationUiState.uploading,
          GenerationUiState.queued,
          GenerationUiState.processing,
          GenerationUiState.downloadingAudio,
          GenerationUiState.ready,
        ]),
      );
      expect(harness.library.items, hasLength(1));
      expect(harness.api.downloadCalls, 1);
    } finally {
      await harness.dispose();
    }
  });

  test('transição failed encerra polling e não baixa áudio', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(
        statuses: const [GenerationStatus.processing, GenerationStatus.failed],
      ),
    );
    try {
      await harness.start();
      await _waitFor(() => harness.controller.state == GenerationUiState.error);
      expect(
        harness.controller.errorMessage,
        'A geração falhou no servidor. Tente novamente.',
      );
      expect(harness.api.downloadCalls, 0);
    } finally {
      await harness.dispose();
    }
  });

  test('timeline vazia é conclusão válida sem download', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(
        result: const GenerationResult(
          jobId: 'job-1',
          status: GenerationStatus.completed,
          narrativeTimeline: [],
          hasVoiceEngine: false,
          hasAudioDescription: false,
          artifactUrls: {},
        ),
      ),
    );
    try {
      await harness.start();
      expect(
        harness.controller.state,
        GenerationUiState.completedWithoutDescriptions,
      );
      expect(harness.api.downloadCalls, 0);
      expect(harness.library.items, isEmpty);
    } finally {
      await harness.dispose();
    }
  });

  test(
    'timeline existente sem voice engine termina sem faixa de áudio',
    () async {
      final harness = await _ControllerHarness.create(
        api: _FakeApiService(
          result: GenerationResult(
            jobId: 'job-1',
            status: GenerationStatus.completed,
            narrativeTimeline: const [
              {'description': 'Uma pessoa caminha.', 'skipped': false},
            ],
            hasVoiceEngine: false,
            hasAudioDescription: false,
            artifactUrls: const {},
          ),
        ),
      );
      try {
        await harness.start();
        expect(
          harness.controller.state,
          GenerationUiState.completedWithoutAudio,
        );
        expect(harness.api.downloadCalls, 0);
      } finally {
        await harness.dispose();
      }
    },
  );

  test('recupera polling após falha temporária sem criar outro job', () async {
    final api = _FakeApiService(
      statusErrorsBeforeSuccess: 1,
      statuses: const [GenerationStatus.completed],
    );
    final harness = await _ControllerHarness.create(api: api);
    try {
      await harness.start();
      await _waitFor(() => harness.controller.state == GenerationUiState.ready);
      expect(api.createCalls, 1);
      expect(api.statusCalls, 2);
      expect(api.downloadCalls, 1);
    } finally {
      await harness.dispose();
    }
  });

  test('gera novamente quando o mesmo vídeo é selecionado', () async {
    final api = _FakeApiService();
    final harness = await _ControllerHarness.create(api: api);
    try {
      await harness.start();
      expect(harness.controller.state, GenerationUiState.ready);

      await harness.start();
      expect(harness.controller.state, GenerationUiState.ready);

      expect(api.createCalls, 2);
      expect(api.downloadCalls, 2);
      expect(harness.library.items, hasLength(2));
      expect(
        harness.library.items.map((item) => item.jobId),
        containsAll(<String>['job-1', 'job-2']),
      );
    } finally {
      await harness.dispose();
    }
  });

  test('duplo envio durante validação da pasta cria somente um job', () async {
    final harness = await _ControllerHarness.create(api: _FakeApiService());
    try {
      await Future.wait([harness.start(), harness.start()]);
      expect(harness.api.createCalls, 1);
    } finally {
      await harness.dispose();
    }
  });

  test('cancelar outra seleção preserva resultado pronto', () async {
    final harness = await _ControllerHarness.create(api: _FakeApiService());
    try {
      await harness.start();
      final audio = harness.controller.audioPath;
      harness.controller.beginSelection();
      harness.controller.selectionCancelled();
      expect(harness.controller.state, GenerationUiState.ready);
      expect(harness.controller.audioPath, audio);
    } finally {
      await harness.dispose();
    }
  });

  test('falha 503 ao finalizar recupera mesmo job sem outro upload', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(resultErrorsBeforeSuccess: 1),
    );
    try {
      await harness.start();
      expect(harness.controller.state, GenerationUiState.error);
      await harness.controller.retry();
      expect(harness.controller.state, GenerationUiState.ready);
      expect(harness.api.createCalls, 1);
    } finally {
      await harness.dispose();
    }
  });

  test('falha na biblioteca recupera WAV baixado sem reprocessar', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(),
      library: _FailOnceLibrary(),
    );
    try {
      await harness.start();
      expect(harness.controller.state, GenerationUiState.error);
      await harness.controller.retry();
      expect(harness.controller.state, GenerationUiState.ready);
      expect(harness.api.createCalls, 1);
      expect(harness.api.downloadCalls, 1);
      expect(harness.library.items, hasLength(1));
    } finally {
      await harness.dispose();
    }
  });

  test(
    'limite de acompanhamento encerra carregamento com erro recuperável',
    () async {
      final harness = await _ControllerHarness.create(
        api: _FakeApiService(),
        maxMonitoringDuration: Duration.zero,
      );
      try {
        await harness.start();
        expect(harness.controller.state, GenerationUiState.error);
        expect(harness.controller.isBusy, isFalse);
        expect(harness.controller.errorMessage, contains('demorando'));
        expect(harness.api.createCalls, 1);
      } finally {
        await harness.dispose();
      }
    },
  );

  test('falha persistente de conexão permite retomar o mesmo job', () async {
    final harness = await _ControllerHarness.create(
      api: _FakeApiService(statusErrorsBeforeSuccess: 1),
      maxConsecutivePollErrors: 1,
    );
    try {
      await harness.start();
      expect(harness.controller.state, GenerationUiState.error);
      expect(harness.controller.isBusy, isFalse);
      await harness.controller.retry();
      expect(harness.controller.state, GenerationUiState.ready);
      expect(harness.api.createCalls, 1);
    } finally {
      await harness.dispose();
    }
  });

  test('dispose impede operação antiga de alterar estado', () async {
    final api = _FakeApiService(statusDelay: const Duration(milliseconds: 30));
    final harness = await _ControllerHarness.create(api: api);
    final future = harness.start();
    harness.controller.dispose();
    await future;
    expect(api.downloadCalls, 0);
    await harness.directory.delete(recursive: true);
  });
}

class _ControllerHarness {
  _ControllerHarness({
    required this.directory,
    required this.library,
    required this.api,
    required this.controller,
  });

  static Future<_ControllerHarness> create({
    required _FakeApiService api,
    LibraryService? library,
    Duration maxMonitoringDuration = const Duration(minutes: 30),
    int maxConsecutivePollErrors = 5,
  }) async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-controller-test-',
    );
    final storage = StorageSettingsService();
    await storage.initialize();
    await storage.setDirectoryPath(directory.path);
    library ??= LibraryService();
    await library.initialize();
    final controller = GenerationController(
      apiService: api,
      storageSettingsService: storage,
      libraryService: library,
      pollInterval: const Duration(milliseconds: 1),
      maxMonitoringDuration: maxMonitoringDuration,
      maxConsecutivePollErrors: maxConsecutivePollErrors,
    );
    return _ControllerHarness(
      directory: directory,
      library: library,
      api: api,
      controller: controller,
    );
  }

  final Directory directory;
  final LibraryService library;
  final _FakeApiService api;
  final GenerationController controller;

  Future<void> start() => controller.startGeneration(
    videoPath: '/videos/video.mp4',
    filename: 'video.mp4',
  );

  Future<void> dispose() async {
    controller.dispose();
    await directory.delete(recursive: true);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Tempo excedido aguardando estado do controller.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

class _FakeApiService extends See2SoundApiService {
  _FakeApiService({
    List<GenerationStatus>? statuses,
    GenerationResult? result,
    this.statusErrorsBeforeSuccess = 0,
    this.resultErrorsBeforeSuccess = 0,
    this.statusDelay = Duration.zero,
  }) : _statuses = List.of(statuses ?? const [GenerationStatus.completed]),
       _result =
           result ??
           GenerationResult(
             jobId: 'job-1',
             status: GenerationStatus.completed,
             narrativeTimeline: const [
               {'description': 'Uma pessoa caminha.', 'skipped': false},
             ],
             hasVoiceEngine: true,
             hasAudioDescription: true,
             artifactUrls: const {'audio_description': '/audio'},
           );

  final List<GenerationStatus> _statuses;
  final GenerationResult _result;
  final int statusErrorsBeforeSuccess;
  final Duration statusDelay;
  int resultErrorsBeforeSuccess;
  int createCalls = 0;
  int statusCalls = 0;
  int downloadCalls = 0;

  @override
  Future<bool> healthCheck() async => true;

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
    return GenerationCreated(
      jobId: 'job-$createCalls',
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
    statusCalls++;
    if (statusDelay > Duration.zero) await Future<void>.delayed(statusDelay);
    if (statusCalls <= statusErrorsBeforeSuccess) {
      throw const ApiException('Conexão temporariamente indisponível.');
    }
    final index = (statusCalls - statusErrorsBeforeSuccess - 1).clamp(
      0,
      _statuses.length - 1,
    );
    final status = _statuses[index];
    return GenerationSnapshot(
      jobId: jobId,
      status: status,
      originalFilename: 'video.mp4',
      createdAt: null,
      startedAt: null,
      finishedAt: null,
      error: status == GenerationStatus.failed ? 'Falha no TTS' : null,
      options: const {},
    );
  }

  @override
  Future<GenerationResult> getGenerationResult(String jobId) async {
    if (resultErrorsBeforeSuccess-- > 0) {
      throw const ApiException('Servidor ocupado', statusCode: 503);
    }
    return GenerationResult(
      jobId: jobId,
      status: _result.status,
      narrativeTimeline: _result.narrativeTimeline,
      hasVoiceEngine: _result.hasVoiceEngine,
      hasAudioDescription: _result.hasAudioDescription,
      artifactUrls: _result.artifactUrls,
    );
  }

  @override
  Future<AudioDescriptionMetadata> getAudioDescriptionMetadata(
    String jobId,
  ) async {
    return AudioDescriptionMetadata(
      jobId: jobId,
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
    downloadCalls++;
    final path =
        '$destinationDirectoryPath${Platform.pathSeparator}$jobId-video.wav';
    await File(path).writeAsBytes([1, 2, 3]);
    return path;
  }

  @override
  void close() {}
}

class _FailOnceLibrary extends LibraryService {
  bool failNext = true;
  @override
  Future<void> addItem(AudioDescriptionLibraryItem item) async {
    if (failNext) {
      failNext = false;
      throw const LibraryException('Falha de gravação');
    }
    await super.addItem(item);
  }
}
