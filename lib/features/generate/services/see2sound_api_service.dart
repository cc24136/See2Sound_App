import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/audio_description_metadata.dart';
import '../models/generation_created.dart';
import '../models/generation_status.dart';

class See2SoundApiService {
  See2SoundApiService({
    http.Client? client,
    Uri Function(String path)? uriBuilder,
  }) : _client = client ?? http.Client(),
       _uriBuilder = uriBuilder ?? ApiConfig.uri;

  final http.Client _client;
  final Uri Function(String path) _uriBuilder;

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

  Future<String> downloadAudioDescription(
    String jobId, {
    required String destinationDirectoryPath,
    required String originalFilename,
  }) async {
    final response = await _get('/api/v1/generations/$jobId/audio-description');
    final bytes = response.bodyBytes;

    try {
      final destinationDirectory = Directory(destinationDirectoryPath);
      if (!await destinationDirectory.exists()) {
        throw const ApiException(
          'A pasta configurada para armazenamento não foi encontrada.',
        );
      }

      final safeStem = _safeFileStem(originalFilename);
      final file = await _availableAudioFile(destinationDirectory, safeStem);

      debugPrint('See2Sound storage directory: ${destinationDirectory.path}');
      debugPrint('See2Sound audio file: ${file.path}');
      debugPrint('See2Sound audio bytes received: ${bytes.length}');

      await file.writeAsBytes(bytes, flush: true);

      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      debugPrint('See2Sound audio file exists: $fileExists');
      debugPrint('See2Sound audio file size: $fileSize bytes');

      if (!fileExists || fileSize != bytes.length) {
        throw FileSystemException(
          'O arquivo de áudio não foi gravado completamente.',
          file.path,
        );
      }

      return file.path;
    } on ApiException {
      rethrow;
    } on Object catch (error, stackTrace) {
      debugPrint('See2Sound failed to save audio: $error');
      debugPrintStack(
        label: 'See2Sound audio save stack trace',
        stackTrace: stackTrace,
      );
      throw ApiException(
        'Não foi possível salvar a audiodescrição na pasta configurada. Verifique a permissão de escrita.',
        cause: error,
      );
    }
  }

  String _safeFileStem(String originalFilename) {
    final fileName = originalFilename.split(RegExp(r'[/\\]')).last;
    final extensionIndex = fileName.lastIndexOf('.');
    final withoutExtension = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;
    final sanitized = withoutExtension
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .trim();
    return sanitized.isEmpty ? 'audiodescription' : sanitized;
  }

  Future<File> _availableAudioFile(Directory directory, String safeStem) async {
    final separator = Platform.pathSeparator;
    final baseName = '${safeStem}_audiodescription';
    var file = File('${directory.path}$separator$baseName.wav');
    var suffix = 2;
    while (await file.exists()) {
      file = File('${directory.path}$separator${baseName}_$suffix.wav');
      suffix++;
    }
    return file;
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
