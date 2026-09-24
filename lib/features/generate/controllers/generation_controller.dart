import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/audio_description_metadata.dart';
import '../models/generation_created.dart';
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
  error,
}

class GenerationController extends ChangeNotifier {
  GenerationController({
    See2SoundApiService? apiService,
    this.pollInterval = const Duration(seconds: 2),
  }) : _apiService = apiService ?? See2SoundApiService();

  final See2SoundApiService _apiService;
  final Duration pollInterval;

  Timer? _pollTimer;
  bool _disposed = false;
  int _operationId = 0;

  GenerationUiState _state = GenerationUiState.idle;
  String? _videoPath;
  String? _filename;
  String? _audioPath;
  String? _jobId;
  String? _errorMessage;
  String? _connectionMessage;
  AudioDescriptionMetadata? _metadata;
  GenerationCreated? _created;

  GenerationUiState get state => _state;
  String? get videoPath => _videoPath;
  String? get filename => _filename;
  String? get audioPath => _audioPath;
  String? get jobId => _jobId;
  String? get errorMessage => _errorMessage;
  String? get connectionMessage => _connectionMessage;
  AudioDescriptionMetadata? get metadata => _metadata;
  GenerationCreated? get created => _created;

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
    GenerationUiState.error => _errorMessage ?? 'A geração falhou.',
  };

  void beginSelection() {
    if (isBusy) return;
    _setState(GenerationUiState.selecting);
  }

  void selectionCancelled() {
    if (_state == GenerationUiState.selecting) {
      _setState(GenerationUiState.idle);
    }
  }

  Future<void> startGeneration({
    required String videoPath,
    required String filename,
  }) async {
    _pollTimer?.cancel();
    final operationId = ++_operationId;
    _videoPath = videoPath;
    _filename = filename;
    _audioPath = null;
    _jobId = null;
    _metadata = null;
    _created = null;
    _errorMessage = null;
    _connectionMessage = null;
    _setState(GenerationUiState.uploading);

    try {
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
    } on Object {
      if (_isCurrent(operationId)) {
        _fail('Não foi possível iniciar a geração. Tente novamente.');
      }
    }
  }

  Future<void> retry() async {
    final videoPath = _videoPath;
    final filename = _filename;
    if (videoPath == null || filename == null) return;
    await startGeneration(videoPath: videoPath, filename: filename);
  }

  Future<void> _poll(int operationId) async {
    final jobId = _jobId;
    if (jobId == null || !_isCurrent(operationId)) return;

    try {
      final snapshot = await _apiService.getGenerationStatus(jobId);
      if (!_isCurrent(operationId)) return;
      _connectionMessage = null;

      switch (snapshot.status) {
        case GenerationStatus.queued:
          _setState(GenerationUiState.queued);
          _schedulePoll(operationId);
        case GenerationStatus.processing:
          _setState(GenerationUiState.processing);
          _schedulePoll(operationId);
        case GenerationStatus.completed:
          _pollTimer?.cancel();
          await _completeGeneration(jobId, operationId);
        case GenerationStatus.failed:
          _pollTimer?.cancel();
          _fail(snapshot.error ?? 'A geração falhou no servidor.');
      }
    } on ApiException catch (error) {
      if (!_isCurrent(operationId)) return;
      if (error.isConnectionError) {
        _connectionMessage =
            'Conexão temporariamente indisponível. Tentando novamente...';
        _notify();
        _schedulePoll(operationId);
      } else {
        _fail(_friendlyMessage(error));
      }
    } on Object {
      if (!_isCurrent(operationId)) return;
      _connectionMessage =
          'Conexão temporariamente indisponível. Tentando novamente...';
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
      _metadata = await _apiService.getAudioDescriptionMetadata(jobId);
    } on Object {
      // Metadata enriquece a interface, mas não bloqueia a reprodução.
      _metadata = null;
    }
    if (!_isCurrent(operationId)) return;

    try {
      _audioPath = await _apiService.downloadAudioDescription(jobId);
      if (!_isCurrent(operationId)) return;
      _setState(GenerationUiState.ready);
    } on ApiException catch (error) {
      if (_isCurrent(operationId)) {
        _fail(
          error.statusCode == 409
              ? 'A audiodescrição ainda não está disponível.'
              : 'Não foi possível baixar a audiodescrição. ${error.message}',
        );
      }
    } on Object {
      if (_isCurrent(operationId)) {
        _fail('Não foi possível baixar a audiodescrição.');
      }
    }
  }

  String _friendlyMessage(ApiException error) {
    final statusCode = error.statusCode;
    if (statusCode == null) {
      return 'Não foi possível conectar ao servidor.';
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
