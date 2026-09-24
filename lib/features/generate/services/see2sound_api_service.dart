import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/audio_description_metadata.dart';
import '../models/generation_created.dart';
import '../models/generation_status.dart';

typedef TemporaryDirectoryProvider = Future<Directory> Function();

class See2SoundApiService {
  See2SoundApiService({
    http.Client? client,
    Uri Function(String path)? uriBuilder,
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
  }) : _client = client ?? http.Client(),
       _uriBuilder = uriBuilder ?? ApiConfig.uri,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  final http.Client _client;
  final Uri Function(String path) _uriBuilder;
  final TemporaryDirectoryProvider _temporaryDirectoryProvider;

  Future<bool> healthCheck() async {
    final response = await _get('/health');
    final json = _decodeObject(response);
    return json['status'] == 'ok';
  }

  Future<GenerationCreated> createGeneration({
    required String videoPath,
    required String filename,
    double frameIntervalSeconds = 1,
    String whisperLanguage = 'pt',
    bool runSpectra = true,
    bool runNarrative = true,
    bool runTts = true,
  }) async {
    final request =
        http.MultipartRequest('POST', _uriBuilder('/api/v1/generations'))
          ..fields.addAll({
            'frame_interval_seconds': frameIntervalSeconds.toString(),
            'whisper_language': whisperLanguage,
            'run_spectra': runSpectra.toString(),
            'run_narrative': runNarrative.toString(),
            'run_tts': runTts.toString(),
          })
          ..files.add(
            await http.MultipartFile.fromPath(
              'video',
              videoPath,
              filename: filename,
            ),
          );

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      _ensureSuccess(response, expectedStatuses: const {202});
      return GenerationCreated.fromJson(_decodeObject(response));
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(
        'Não foi possível conectar ao servidor.',
        cause: error,
      );
    }
  }

  Future<GenerationSnapshot> getGenerationStatus(String jobId) async {
    final response = await _get('/api/v1/generations/$jobId');
    return GenerationSnapshot.fromJson(_decodeObject(response));
  }

  Future<Map<String, dynamic>> getGenerationResult(String jobId) async {
    final response = await _get('/api/v1/generations/$jobId/result');
    return _decodeObject(response);
  }

  Future<AudioDescriptionMetadata> getAudioDescriptionMetadata(
    String jobId,
  ) async {
    final response = await _get(
      '/api/v1/generations/$jobId/audio-description/metadata',
    );
    return AudioDescriptionMetadata.fromJson(_decodeObject(response));
  }

  Future<String> downloadAudioDescription(String jobId) async {
    final response = await _get('/api/v1/generations/$jobId/audio-description');
    final directory = await _temporaryDirectoryProvider();
    final file = File('${directory.path}/${jobId}_audiodescription.wav');
    try {
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    } on Object catch (error) {
      throw ApiException(
        'Não foi possível salvar a audiodescrição no cache.',
        cause: error,
      );
    }
  }

  Future<http.Response> _get(String path) async {
    try {
      final response = await _client.get(_uriBuilder(path));
      _ensureSuccess(response);
      return response;
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(
        'Não foi possível conectar ao servidor.',
        cause: error,
      );
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('A resposta não é um objeto JSON.');
    } on FormatException catch (error) {
      throw ApiException(
        'O servidor retornou uma resposta inválida.',
        cause: error,
      );
    }
  }

  void _ensureSuccess(
    http.Response response, {
    Set<int> expectedStatuses = const {200},
  }) {
    if (expectedStatuses.contains(response.statusCode)) return;

    String? detail;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final rawDetail = decoded['detail'];
        if (rawDetail is String) {
          detail = rawDetail;
        } else if (rawDetail != null) {
          detail = rawDetail.toString();
        }
      }
    } on FormatException {
      // A mensagem amigável por status abaixo continua sendo utilizada.
    }

    throw ApiException(
      detail ?? _messageForStatus(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _messageForStatus(int statusCode) {
    return switch (statusCode) {
      400 => 'A solicitação enviada é inválida.',
      404 => 'Geração não encontrada.',
      409 => 'A geração ainda não terminou.',
      413 => 'O vídeo excede o tamanho permitido.',
      415 => 'Formato de vídeo não suportado.',
      >= 500 => 'O servidor não conseguiu concluir a solicitação.',
      _ => 'Não foi possível concluir a solicitação.',
    };
  }

  void close() => _client.close();
}
