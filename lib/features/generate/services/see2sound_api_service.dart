import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/audio_description_metadata.dart';
import '../models/generation_created.dart';
import '../models/generation_result.dart';
import '../models/generation_status.dart';

class See2SoundApiService {
  See2SoundApiService({
    http.Client? client,
    Uri Function(String path)? uriBuilder,
    this.requestTimeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client(),
       _uriBuilder = uriBuilder ?? ApiConfig.uri;

  final http.Client _client;
  final Uri Function(String path) _uriBuilder;
  final Duration requestTimeout;
  final Duration uploadTimeout;
  Uri? _jobBase;

  Uri _uri(String path) {
    final base = _jobBase;
    return base == null
        ? _uriBuilder(path)
        : base.replace(path: '${base.path}$path');
  }

  Future<bool> healthCheck() async {
    _jobBase = null;
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
    try {
      final file = File(videoPath);
      if (!await file.exists() || await file.length() == 0) {
        throw const ApiException(
          'O vídeo não está disponível ou está vazio. Selecione outro arquivo.',
          statusCode: 400,
        );
      }
    } on FileSystemException catch (error) {
      throw ApiException(
        'Não foi possível ler o vídeo selecionado.',
        statusCode: 400,
        cause: error,
      );
    }
    final endpoint = _uriBuilder('/api/v1/generations');
    _jobBase = endpoint.replace(
      path: endpoint.path.substring(
        0,
        endpoint.path.length - '/api/v1/generations'.length,
      ),
    );
    final request = http.MultipartRequest('POST', _uri('/api/v1/generations'))
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
      final streamed = await _client.send(request).timeout(uploadTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(uploadTimeout);
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

  Future<GenerationResult> getGenerationResult(String jobId) async {
    final response = await _get('/api/v1/generations/$jobId/result');
    return GenerationResult.fromJson(_decodeObject(response));
  }

  Future<List<int>> downloadArtifact(String jobId, String artifactName) async {
    final encodedName = Uri.encodeComponent(artifactName);
    final response = await _get(
      '/api/v1/generations/$jobId/artifacts/$encodedName',
    );
    return response.bodyBytes;
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
    File? partialFile;
    try {
      final response = await _client
          .send(
            http.Request(
              'GET',
              _uri('/api/v1/generations/$jobId/audio-description'),
            ),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        _ensureSuccess(
          await http.Response.fromStream(response).timeout(requestTimeout),
        );
      }
      final contentType = response.headers['content-type']?.toLowerCase();
      if (contentType != null && !contentType.startsWith('audio/')) {
        await response.stream.take(0).drain<void>();
        throw const FormatException('O servidor não retornou áudio.');
      }
      final destinationDirectory = Directory(destinationDirectoryPath);
      if (!await destinationDirectory.exists()) {
        await response.stream.take(0).drain<void>();
        throw const ApiException(
          'A pasta configurada para armazenamento não foi encontrada.',
        );
      }
      final file = await _availableAudioFile(
        destinationDirectory,
        _safeFileStem(originalFilename),
      );
      partialFile = File('${file.path}.part');
      final sink = partialFile.openWrite();
      final header = <int>[];
      var received = 0;
      final elapsed = Stopwatch()..start();
      var streamCompleted = false;
      try {
        // Stream directly to disk: long WAV files must not be buffered in RAM.
        await sink.addStream(
          response.stream.timeout(requestTimeout).map((chunk) {
            if (elapsed.elapsed > uploadTimeout) {
              throw TimeoutException('Download excedeu o limite de tempo.');
            }
            if (header.length < 12) {
              header.addAll(chunk.take(12 - header.length));
            }
            received += chunk.length;
            return chunk;
          }),
        );
        await sink.flush();
        streamCompleted = true;
      } finally {
        if (streamCompleted) {
          await sink.close();
        } else {
          // Preserve the original connection error if addStream already closed the sink.
          try {
            await sink.close();
          } catch (_) {}
        }
      }
      if (!_hasWavHeader(header)) {
        throw const FormatException('Áudio vazio ou cabeçalho WAV inválido.');
      }
      final expectedLength = response.contentLength;
      if (expectedLength != null && received != expectedLength) {
        throw const FormatException('Download de áudio incompleto.');
      }
      if (await file.exists()) {
        throw const FileSystemException('O arquivo de destino já existe.');
      }
      await partialFile.rename(file.path);
      partialFile = null;
      return file.path;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        'O download demorou mais que o esperado. Tente recuperar o resultado novamente.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        'A conexão foi interrompida durante o download. Tente novamente.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw ApiException(
        'O servidor enviou um áudio inválido ou incompleto. Tente recuperar o resultado novamente.',
        cause: error,
      );
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Falha ao salvar áudio: $error');
      debugPrint('$stackTrace');
      throw ApiException(
        'Não foi possível salvar a audiodescrição na pasta configurada. Verifique a permissão de escrita.',
        cause: error,
      );
    } finally {
      if (partialFile != null) {
        try {
          if (await partialFile.exists()) await partialFile.delete();
        } catch (error) {
          debugPrint('[See2Sound] Falha ao limpar download parcial: $error');
        }
      }
    }
  }

  bool _hasWavHeader(List<int> bytes) {
    if (bytes.length < 12) return false;
    return bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45;
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
      final response = await _client.get(_uri(path)).timeout(requestTimeout);
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

    throw ApiException(
      _messageForStatus(response.statusCode),
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
      422 =>
        'Não foi possível validar o vídeo. Verifique o arquivo e tente novamente.',
      >= 500 => 'O servidor não conseguiu concluir a solicitação.',
      _ => 'Não foi possível concluir a solicitação.',
    };
  }

  void close() => _client.close();
}
