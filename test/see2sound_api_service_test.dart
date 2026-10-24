import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:see2sound_app/core/network/api_exception.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';
import 'package:see2sound_app/features/generate/services/see2sound_api_service.dart';

void main() {
  Uri testUri(String path) => Uri.parse('http://api.test$path');
  final wavBytes = Uint8List.fromList([
    0x52,
    0x49,
    0x46,
    0x46,
    4,
    0,
    0,
    0,
    0x57,
    0x41,
    0x56,
    0x45,
    1,
    2,
    3,
    4,
  ]);

  test('healthCheck reconhece backend disponível', () async {
    final service = See2SoundApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response(
          '{"status":"ok","service":"See2Sound API","version":"0.1.0"}',
          200,
        );
      }),
      uriBuilder: testUri,
    );

    expect(await service.healthCheck(), isTrue);
    service.close();
  });

  test('converte detail da FastAPI em ApiException legível', () async {
    final service = See2SoundApiService(
      client: MockClient((_) async {
        return http.Response(
          '{"detail":"Formato de vídeo não suportado."}',
          415,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      uriBuilder: testUri,
    );

    await expectLater(
      service.getGenerationStatus('job-123'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 415)
            .having(
              (error) => error.message,
              'message',
              'Formato de vídeo não suportado.',
            ),
      ),
    );
    service.close();
  });

  test('timeout de conexão retorna erro tratável', () async {
    final service = See2SoundApiService(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{"status":"ok"}', 200);
      }),
      uriBuilder: testUri,
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(service.healthCheck(), throwsA(isA<ApiException>()));
    service.close();
  });

  test('erros técnicos do servidor não são apresentados ao usuário', () async {
    final service = See2SoundApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"detail":"Traceback secret /srv/internal.py"}',
          500,
        ),
      ),
      uriBuilder: testUri,
    );
    await expectLater(
      service.healthCheck(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensagem',
          isNot(contains('Traceback')),
        ),
      ),
    );
    service.close();
  });

  test('arquivo ausente não inicia requisição de upload', () async {
    var calls = 0;
    final service = See2SoundApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 202);
      }),
      uriBuilder: testUri,
    );
    await expectLater(
      service.createGeneration(
        videoPath: '/arquivo-inexistente.mp4',
        filename: 'video.mp4',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 0);
    service.close();
  });

  test('envia vídeo multipart e aceita HTTP 202', () async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-upload-',
    );
    final video = File('${directory.path}${Platform.pathSeparator}video.mp4');
    await video.writeAsBytes([1, 2, 3]);
    final service = See2SoundApiService(
      client: MockClient.streaming((request, bodyStream) async {
        final body = await bodyStream.toBytes();
        final bodyText = String.fromCharCodes(body);
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/generations');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(bodyText, contains('name="video"; filename="video.mp4"'));
        expect(bodyText, contains('name="frame_interval_seconds"'));
        expect(bodyText, contains('name="run_narrative"'));
        return http.StreamedResponse(
          Stream.value(
            Uint8List.fromList(
              '{"job_id":"job-202","status":"queued","message":"Recebido","status_url":"/status","result_url":"/result","audio_description_url":"/audio","audio_description_metadata_url":"/metadata"'
                      '}'
                  .codeUnits,
            ),
          ),
          202,
        );
      }),
      uriBuilder: testUri,
    );

    try {
      final created = await service.createGeneration(
        videoPath: video.path,
        filename: 'video.mp4',
      );
      expect(created.jobId, 'job-202');
      expect(created.status, 'queued');
    } finally {
      service.close();
      await directory.delete(recursive: true);
    }
  });

  test('getGenerationStatus retorna completed', () async {
    final service = See2SoundApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"job_id":"job-1","status":"completed","options":{}}',
          200,
        ),
      ),
      uriBuilder: testUri,
    );

    final status = await service.getGenerationStatus('job-1');
    expect(status.status, GenerationStatus.completed);
    service.close();
  });

  test('getGenerationStatus retorna failed com mensagem', () async {
    final service = See2SoundApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"job_id":"job-1","status":"failed","error":"Falha no TTS","options":{}}',
          200,
        ),
      ),
      uriBuilder: testUri,
    );

    final status = await service.getGenerationStatus('job-1');
    expect(status.status, GenerationStatus.failed);
    expect(status.error, 'Falha no TTS');
    service.close();
  });

  test('salva a audiodescrição na pasta configurada', () async {
    final destinationDirectory = await Directory.systemTemp.createTemp(
      'see2sound-storage-test-',
    );
    final service = See2SoundApiService(
      client: MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/generations/job-123/audio-description',
        );
        return http.Response.bytes(
          wavBytes,
          200,
          headers: {'content-type': 'audio/wav'},
        );
      }),
      uriBuilder: testUri,
    );

    try {
      final filePath = await service.downloadAudioDescription(
        'job-123',
        destinationDirectoryPath: destinationDirectory.path,
        originalFilename: 'video teste.mp4',
      );
      final file = File(filePath);

      expect(
        filePath,
        '${destinationDirectory.path}${Platform.pathSeparator}'
        'video teste_audiodescription.wav',
      );
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), wavBytes);
    } finally {
      service.close();
      await destinationDirectory.delete(recursive: true);
    }
  });

  test('não sobrescreve uma audiodescrição com o mesmo nome', () async {
    final destinationDirectory = await Directory.systemTemp.createTemp(
      'see2sound-duplicate-test-',
    );
    final original = File(
      '${destinationDirectory.path}${Platform.pathSeparator}'
      'video_audiodescription.wav',
    );
    await original.writeAsBytes([1]);
    final service = See2SoundApiService(
      client: MockClient(
        (_) async => http.Response.bytes(
          wavBytes,
          200,
          headers: {'content-type': 'audio/wav'},
        ),
      ),
      uriBuilder: testUri,
    );

    try {
      final filePath = await service.downloadAudioDescription(
        'job-456',
        destinationDirectoryPath: destinationDirectory.path,
        originalFilename: 'video.mp4',
      );

      expect(filePath, endsWith('video_audiodescription_2.wav'));
      expect(await original.readAsBytes(), [1]);
      expect(await File(filePath).readAsBytes(), wavBytes);
    } finally {
      service.close();
      await destinationDirectory.delete(recursive: true);
    }
  });

  test('rejeita resposta que não é WAV antes de criar arquivo', () async {
    final directory = await Directory.systemTemp.createTemp(
      'see2sound-invalid-',
    );
    final service = See2SoundApiService(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('{"detail":"não é áudio"}'),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      uriBuilder: testUri,
    );

    try {
      await expectLater(
        service.downloadAudioDescription(
          'job-1',
          destinationDirectoryPath: directory.path,
          originalFilename: 'video.mp4',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(directory.listSync(), isEmpty);
    } finally {
      service.close();
      await directory.delete(recursive: true);
    }
  });
  for (final incomplete in [true, false]) {
    test(
      'limpa download ${incomplete ? "incompleto" : "interrompido"} sem registrar WAV',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'see2sound-partial-',
        );
        final service = See2SoundApiService(
          client: MockClient.streaming((_, body) async {
            await body.drain<void>();
            return http.StreamedResponse(
              incomplete
                  ? Stream.value(wavBytes)
                  : Stream<List<int>>.fromIterable([wavBytes]).asyncExpand((
                      chunk,
                    ) async* {
                      yield chunk;
                      throw const SocketException('conexão interrompida');
                    }),
              200,
              contentLength: incomplete ? wavBytes.length + 10 : null,
              headers: {'content-type': 'audio/wav'},
            );
          }),
          uriBuilder: testUri,
        );
        try {
          await expectLater(
            service.downloadAudioDescription(
              'job',
              destinationDirectoryPath: directory.path,
              originalFilename: 'video.mp4',
            ),
            throwsA(isA<ApiException>()),
          );
          expect(await directory.list().toList(), isEmpty);
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }

  test('mantém host do job e usa novo host na próxima verificação', () async {
    final directory = await Directory.systemTemp.createTemp('see2sound-host-');
    final video = File('${directory.path}/video.mp4');
    await video.writeAsBytes([1]);
    var host = 'first.test';
    final uris = <Uri>[];
    final service = See2SoundApiService(
      uriBuilder: (path) => Uri.parse('http://$host/prefix$path'),
      client: MockClient((request) async {
        uris.add(request.url);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'job_id': 'job',
              'status': 'queued',
              'message': 'Recebido',
              'status_url': '/status',
              'result_url': '/result',
              'audio_description_url': '/audio',
              'audio_description_metadata_url': '/metadata',
            }),
            202,
          );
        }
        if (request.url.path.endsWith('/health')) {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('{"job_id":"job","status":"queued"}', 200);
      }),
    );
    try {
      await service.createGeneration(
        videoPath: video.path,
        filename: 'video.mp4',
      );
      host = 'second.test';
      await service.getGenerationStatus('job');
      expect(uris.last.host, 'first.test');
      expect(uris.last.path, '/prefix/api/v1/generations/job');
      await service.healthCheck();
      expect(uris.last.host, 'second.test');
    } finally {
      service.close();
      await directory.delete(recursive: true);
    }
  });
}
