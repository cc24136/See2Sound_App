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
    final wavBytes = Uint8List.fromList([82, 73, 70, 70, 1, 2, 3, 4]);
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
      client: MockClient((_) async => http.Response.bytes([2, 3], 200)),
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
      expect(await File(filePath).readAsBytes(), [2, 3]);
    } finally {
      service.close();
      await destinationDirectory.delete(recursive: true);
    }
  });
}
