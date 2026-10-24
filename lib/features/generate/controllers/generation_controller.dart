import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_settings_service.dart';
import '../../library/models/audio_description_library_item.dart';
import '../../library/services/library_service.dart';
import '../models/audio_description_metadata.dart';
import '../models/generation_created.dart';
import '../models/generation_result.dart';
import '../models/generation_status.dart';
import '../services/see2sound_api_service.dart';

enum GenerationUiState {
  idle,
  selecting,
  uploading,
  queued,
  processing,
  downloadingAudio,
  ready,
  completedWithoutDescriptions,
  completedWithoutAudio,
  error,
}

class GenerationController extends ChangeNotifier {
  GenerationController({
    See2SoundApiService? apiService,
    required StorageSettingsService storageSettingsService,
    required LibraryService libraryService,
    this.pollInterval = const Duration(seconds: 2),
    this.maxConsecutivePollErrors = 5,
    this.maxMonitoringDuration = const Duration(minutes: 30),
  }) : _apiService = apiService ?? See2SoundApiService(),
       _storageSettingsService = storageSettingsService,
       _libraryService = libraryService;

  final See2SoundApiService _apiService;
  final StorageSettingsService _storageSettingsService;
  final LibraryService _libraryService;
  final Duration pollInterval;
  final int maxConsecutivePollErrors;

  final Duration maxMonitoringDuration;
  final Stopwatch _monitoring = Stopwatch();
  Timer? _pollTimer;
  bool _disposed = false;
  int _operationId = 0;
  int _consecutivePollErrors = 0;

  GenerationUiState _state = GenerationUiState.idle;
  String? _videoPath;
  String? _filename;
  String? _audioPath;
  String? _jobId;
  String? _errorMessage;
  String? _connectionMessage;
  String? _destinationDirectoryPath;
  String? _pendingAudioPath;
  Duration? _videoDuration;
  bool _requiresStorageConfiguration = false;
  AudioDescriptionMetadata? _metadata;
  GenerationCreated? _created;
  GenerationResult? _result;
  bool _retryCurrentJob = false;
  bool _jobCompleted = false;

  GenerationUiState get state => _state;
  String? get videoPath => _videoPath;
  String? get filename => _filename;
  String? get audioPath => _audioPath;
  String? get jobId => _jobId;
  String? get errorMessage => _errorMessage;
  String? get connectionMessage => _connectionMessage;
  bool get requiresStorageConfiguration => _requiresStorageConfiguration;
  AudioDescriptionMetadata? get metadata => _metadata;
  Duration? get videoDuration => _videoDuration;
  GenerationCreated? get created => _created;
  GenerationResult? get result => _result;

  bool get isBusy => switch (_state) {
    GenerationUiState.selecting ||
    GenerationUiState.uploading ||
    GenerationUiState.queued ||
    GenerationUiState.processing ||
    GenerationUiState.downloadingAudio => true,
    _ => false,
  };

  String get statusMessage => switch (_state) {
    GenerationUiState.idle => 'Selecione um vídeo para começar.',
    GenerationUiState.selecting => 'Selecionando vídeo...',
    GenerationUiState.uploading => 'Enviando vídeo...',
    GenerationUiState.queued => 'Vídeo enviado. Aguardando processamento...',
    GenerationUiState.processing =>
      'Analisando cenas e áudio. Gerando audiodescrição...',
    GenerationUiState.downloadingAudio => 'Baixando áudio...',
    GenerationUiState.ready => 'Pronto para reprodução.',
    GenerationUiState.completedWithoutDescriptions =>
      'Processamento concluído. Nenhuma audiodescrição foi necessária para este vídeo.',
    GenerationUiState.completedWithoutAudio =>
      'Processamento concluído, mas nenhuma faixa de áudio audiodescrita foi gerada.',
    GenerationUiState.error => _errorMessage ?? 'A geração falhou.',
  };

  GenerationUiState _stateBeforeSelection = GenerationUiState.idle;

  void beginSelection() {
    if (isBusy || _disposed) return;
    _stateBeforeSelection = _state;
    _setState(GenerationUiState.selecting);
  }

  void selectionCancelled() {
    if (_state == GenerationUiState.selecting) {
      _setState(_stateBeforeSelection);
    }
  }

  Future<void> startGeneration({
    required String videoPath,
    required String filename,
    Duration? videoDuration,
  }) async {
    if (_disposed ||
        _state == GenerationUiState.uploading ||
        _state == GenerationUiState.queued ||
        _state == GenerationUiState.processing ||
        _state == GenerationUiState.downloadingAudio) {
      return;
    }
    _pollTimer?.cancel();
    final operationId = ++_operationId;
    _videoPath = videoPath;
    _filename = filename;
    _videoDuration = videoDuration;
    _audioPath = null;
    _jobId = null;
    _metadata = null;
    _created = null;
    _result = null;
    _errorMessage = null;
    _connectionMessage = null;
    _destinationDirectoryPath = null;
    _pendingAudioPath = null;
    _requiresStorageConfiguration = false;
    _retryCurrentJob = false;
    _jobCompleted = false;
    _consecutivePollErrors = 0;
    _monitoring
      ..reset()
      ..start();
    _setState(GenerationUiState.uploading);

    try {
      final directory = await _storageSettingsService
          .requireWritableDirectory();
      if (!_isCurrent(operationId)) return;
      _destinationDirectoryPath = directory.path;
    } on StorageSettingsException catch (error) {
      if (!_isCurrent(operationId)) return;
      _requiresStorageConfiguration = true;
      _fail(error.message);
      return;
    } catch (error, stackTrace) {
      if (!_isCurrent(operationId)) return;
      debugPrint('[See2Sound] Falha ao verificar armazenamento: $error');
      debugPrint('$stackTrace');
      _requiresStorageConfiguration = true;
      _fail(
        'Não foi possível acessar a pasta de armazenamento. Escolha uma pasta nas configurações.',
      );
      return;
    }
    try {
      if (!await _apiService.healthCheck()) {
        throw const ApiException('O servidor não respondeu como esperado.');
      }
      if (!_isCurrent(operationId)) return;
      final created = await _apiService.createGeneration(
        videoPath: videoPath,
        filename: filename,
      );
      if (!_isCurrent(operationId)) return;
      _created = created;
      _jobId = created.jobId;
      _setState(GenerationUiState.queued);
      await _poll(operationId);
    } on ApiException catch (error) {
      if (_isCurrent(operationId)) {
        _fail(_friendlyMessage(error));
      }
    } on Object catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao iniciar geração: $error');
      debugPrint('$stackTrace');
      if (_isCurrent(operationId)) {
        _fail('Não foi possível iniciar a geração. Tente novamente.');
      }
    }
  }

  Future<void> retry() async {
    if (_disposed || isBusy) return;
    _monitoring
      ..reset()
      ..start();
    final jobId = _jobId;
    if (_retryCurrentJob && jobId != null) {
      _retryCurrentJob = false;
      _consecutivePollErrors = 0;
      if (_jobCompleted) {
        await _completeGeneration(jobId, _operationId);
      } else {
        _setState(GenerationUiState.processing);
        await _poll(_operationId);
      }
      return;
    }
    final videoPath = _videoPath;
    final filename = _filename;
    if (videoPath == null || filename == null) return;
    await startGeneration(
      videoPath: videoPath,
      filename: filename,
      videoDuration: _videoDuration,
    );
  }

  Future<void> _poll(int operationId) async {
    final jobId = _jobId;
    if (jobId == null || !_isCurrent(operationId)) return;
    if (_monitoring.elapsed >= maxMonitoringDuration) {
      _retryCurrentJob = true;
      _fail(
        'O processamento está demorando mais que o esperado. Tente continuar o acompanhamento em instantes.',
      );
      return;
    }

    try {
      final snapshot = await _apiService.getGenerationStatus(jobId);
      if (!_isCurrent(operationId)) return;
      _connectionMessage = null;
      _consecutivePollErrors = 0;

      switch (snapshot.status) {
        case GenerationStatus.queued:
          _setState(GenerationUiState.queued);
          _schedulePoll(operationId);
        case GenerationStatus.processing:
          _setState(GenerationUiState.processing);
          _schedulePoll(operationId);
        case GenerationStatus.completed:
          _pollTimer?.cancel();
          _jobCompleted = true;
          await _completeGeneration(jobId, operationId);
        case GenerationStatus.failed:
          _pollTimer?.cancel();
          _fail('A geração falhou no servidor. Tente novamente.');
      }
    } on ApiException catch (error) {
      if (!_isCurrent(operationId)) return;
      if (error.isConnectionError) {
        _consecutivePollErrors++;
        if (_consecutivePollErrors >= maxConsecutivePollErrors) {
          _retryCurrentJob = true;
          _fail(
            'A conexão com o servidor foi interrompida. Verifique a rede e tente continuar o acompanhamento.',
          );
          return;
        }
        _connectionMessage =
            'Conexão temporariamente indisponível. Nova tentativa $_consecutivePollErrors de $maxConsecutivePollErrors...';
        _notify();
        _schedulePoll(operationId);
      } else {
        _retryCurrentJob =
            error.statusCode == 409 ||
            (error.statusCode != null && error.statusCode! >= 500);
        _fail(_friendlyMessage(error));
      }
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(operationId)) return;
      debugPrint('[See2Sound] Erro temporário durante polling: $error');
      debugPrint('$stackTrace');
      _consecutivePollErrors++;
      if (_consecutivePollErrors >= maxConsecutivePollErrors) {
        _retryCurrentJob = true;
        _fail(
          'A conexão com o servidor foi interrompida. Verifique a rede e tente continuar o acompanhamento.',
        );
        return;
      }
      _connectionMessage =
          'Conexão temporariamente indisponível. Nova tentativa $_consecutivePollErrors de $maxConsecutivePollErrors...';
      _notify();
      _schedulePoll(operationId);
    }
  }

  void _schedulePoll(int operationId) {
    _pollTimer?.cancel();
    _pollTimer = Timer(pollInterval, () => _poll(operationId));
  }

  Future<void> _completeGeneration(String jobId, int operationId) async {
    _setState(GenerationUiState.downloadingAudio);

    try {
      _result = await _apiService.getGenerationResult(jobId);
      if (!_isCurrent(operationId)) return;
      if (_result!.narrativeDescriptionCount == 0) {
        _metadata = null;
        _setState(GenerationUiState.completedWithoutDescriptions);
        return;
      }
      if (!_result!.hasVoiceEngine || !_result!.hasAudioDescription) {
        _metadata = null;
        _setState(GenerationUiState.completedWithoutAudio);
        return;
      }

      try {
        _metadata = await _apiService.getAudioDescriptionMetadata(jobId);
      } catch (error, stackTrace) {
        debugPrint('[See2Sound] Metadata indisponível: $error');
        debugPrint('$stackTrace');
        _metadata = null;
      }
      if (!_isCurrent(operationId)) return;

      final filename = _filename;
      final videoPath = _videoPath;
      final destinationDirectoryPath = _destinationDirectoryPath;
      if (filename == null ||
          videoPath == null ||
          destinationDirectoryPath == null) {
        _fail('Não foi possível identificar os arquivos desta geração.');
        return;
      }

      final pendingPath = _pendingAudioPath;
      final downloadedAudioPath =
          pendingPath != null && await File(pendingPath).exists()
          ? pendingPath
          : await _apiService.downloadAudioDescription(
              jobId,
              destinationDirectoryPath: destinationDirectoryPath,
              originalFilename: filename,
            );
      if (!_isCurrent(operationId)) return;
      _pendingAudioPath = downloadedAudioPath;

      await _libraryService.addItem(
        AudioDescriptionLibraryItem(
          id: jobId,
          originalFilename: filename,
          originalVideoPath: videoPath,
          audioDescriptionPath: downloadedAudioPath,
          createdAt: DateTime.now(),
          duration: _videoDuration,
          jobId: jobId,
        ),
      );
      if (!_isCurrent(operationId)) return;

      _audioPath = downloadedAudioPath;
      _pendingAudioPath = null;
      _retryCurrentJob = false;
      _setState(GenerationUiState.ready);
    } on LibraryException catch (error) {
      if (_isCurrent(operationId)) {
        _retryCurrentJob = true;
        _fail(error.message);
      }
    } on ApiException catch (error) {
      if (_isCurrent(operationId)) {
        if (error.statusCode == 404 && _jobCompleted) {
          _setState(GenerationUiState.completedWithoutAudio);
        } else {
          _retryCurrentJob =
              error.statusCode == null ||
              error.statusCode == 409 ||
              (error.statusCode != null && error.statusCode! >= 500);
          _fail(
            error.statusCode == 409
                ? 'O resultado ainda não está disponível. Tente novamente em instantes.'
                : _friendlyMessage(error),
          );
        }
      }
    } on Object catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao finalizar geração: $error');
      debugPrint('$stackTrace');
      if (_isCurrent(operationId)) {
        _retryCurrentJob = true;
        _fail('Não foi possível baixar a audiodescrição.');
      }
    }
  }

  String _friendlyMessage(ApiException error) {
    final statusCode = error.statusCode;
    if (statusCode == null) {
      return error.message;
    }
    return switch (statusCode) {
      404 => 'Geração não encontrada.',
      413 => 'O vídeo excede o tamanho permitido.',
      415 => 'Formato de vídeo não suportado.',
      >= 500 => 'A geração falhou no servidor. Tente novamente.',
      _ => error.message,
    };
  }

  void _fail(String message) {
    _pollTimer?.cancel();
    _errorMessage = message;
    _connectionMessage = null;
    _setState(GenerationUiState.error);
  }

  void _setState(GenerationUiState state) {
    _state = state;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(int operationId) => !_disposed && operationId == _operationId;

  @override
  void dispose() {
    _disposed = true;
    _operationId++;
    _pollTimer?.cancel();
    _apiService.close();
    super.dispose();
  }
}
