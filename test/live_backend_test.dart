import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:see2sound_app/core/network/api_exception.dart';
import 'package:see2sound_app/core/storage/storage_settings_service.dart';
import 'package:see2sound_app/features/generate/controllers/generation_controller.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';
import 'package:see2sound_app/features/generate/services/see2sound_api_service.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';

// Opt in explicitly: this suite uploads a real video and runs the real pipeline.
void main() {
  final enabled = Platform.environment['SEE2SOUND_LIVE_TEST'] == '1';
  final base =
      Platform.environment['SEE2SOUND_LIVE_API_URL'] ?? 'http://127.0.0.1:8000';
  Uri uri(String path) => Uri.parse('$base$path');

  test('backend real: saúde e erro de geração inexistente', () async {
    final api = See2SoundApiService(uriBuilder: uri);
    try {
      expect(await api.healthCheck(), isTrue);
      await expectLater(
        api.getGenerationStatus('see2sound-audit-missing-job'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'HTTP status', 404),
        ),
      );
    } finally {
      api.close();
    }
  }, skip: !enabled);

  final failedJob = Platform.environment['SEE2SOUND_LIVE_FAILED_JOB_ID'];
  test(
    'backend real: falha existente retorna erros HTTP tratáveis',
    () async {
      final api = See2SoundApiService(uriBuilder: uri);
      final directory = await Directory.systemTemp.createTemp(
        'see2sound-live-failure-',
      );
      try {
        final snapshot = await api.getGenerationStatus(failedJob!);
        expect(snapshot.status, GenerationStatus.failed);
        for (final operation in <Future<Object?> Function()>[
          () => api.getGenerationResult(failedJob),
          () => api.getAudioDescriptionMetadata(failedJob),
          () => api.downloadAudioDescription(
            failedJob,
            destinationDirectoryPath: directory.path,
            originalFilename: 'video.mp4',
          ),
        ]) {
          await expectLater(
            operation(),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.statusCode, 'HTTP status', 500)
                  .having(
                    (e) => e.message,
                    'mensagem amigável',
                    isNot(contains('FileNotFoundError')),
                  ),
            ),
          );
        }
        expect(await directory.list().toList(), isEmpty);
      } finally {
        api.close();
        await directory.delete(recursive: true);
      }
    },
    skip: !enabled || failedJob == null,
  );

  test(
    'backend real: upload, processamento, WAV e recuperação da biblioteca',
    () async {
      final videoPath = Platform.environment['SEE2SOUND_LIVE_VIDEO_PATH'];
      expect(
        videoPath,
        isNotNull,
        reason: 'Defina SEE2SOUND_LIVE_VIDEO_PATH com uma amostra real.',
      );
      expect(await File(videoPath!).exists(), isTrue);
      SharedPreferences.setMockInitialValues(
        {},
      ); // Isolate local preferences only; all HTTP is real.
      final directory = await Directory.systemTemp.createTemp(
        'see2sound-live-backend-',
      );
      final storage = StorageSettingsService();
      final library = LibraryService();
      final api = See2SoundApiService(uriBuilder: uri);
      final observerApi = See2SoundApiService(uriBuilder: uri);
      final controller = GenerationController(
        apiService: api,
        storageSettingsService: storage,
        libraryService: library,
        pollInterval: const Duration(seconds: 2),
        maxMonitoringDuration: const Duration(minutes: 15),
      );
      final elapsed = Stopwatch()..start();
      final states = <String>[];
      final evidence = <String, Object?>{
        'api': base,
        'sample': File(videoPath).uri.pathSegments.last,
        'passed': false,
      };
      final terminal = Completer<void>();
      controller.addListener(() {
        final state = controller.state.name;
        if (states.isEmpty || states.last != state) {
          states.add(state);
          // ignore: avoid_print
          print(
            'LIVE state=$state elapsed=${elapsed.elapsed.inSeconds}s job=${controller.jobId ?? "pending"}',
          );
        }
        if (!controller.isBusy &&
            controller.state != GenerationUiState.idle &&
            !terminal.isCompleted) {
          terminal.complete();
        }
      });
      try {
        await storage.setDirectoryPath(directory.path);
        await library.initialize();
        await controller.startGeneration(
          videoPath: videoPath,
          filename: File(videoPath).uri.pathSegments.last,
        );
        await terminal.future.timeout(const Duration(minutes: 16));
        evidence['job_id'] = controller.jobId;
        evidence['states'] = states;
        evidence['final_state'] = controller.state.name;
        if (controller.jobId != null) {
          final snapshot = await observerApi.getGenerationStatus(
            controller.jobId!,
          );
          evidence['backend_status'] = snapshot.status.name;
          if (snapshot.status == GenerationStatus.failed) {
            expect(controller.state, GenerationUiState.error);
            expect(controller.isBusy, isFalse);
            expect(library.items, isEmpty);
            expect(
              controller.errorMessage,
              isNot(contains('FileNotFoundError')),
            );
            evidence['failure_handled_without_stuck_loading'] = true;
          }

          expect(
            snapshot.status,
            GenerationStatus.completed,
            reason:
                'O pipeline real não concluiu; consulte o job_id registrado.',
          );
        }
        expect(
          controller.state,
          GenerationUiState.ready,
          reason:
              'A amostra precisa gerar um WAV real: ${controller.statusMessage}',
        );
        final path = controller.audioPath!;
        final file = File(path);
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(44));
        expect(ascii.decode(bytes.take(4).toList()), 'RIFF');
        expect(ascii.decode(bytes.skip(8).take(4).toList()), 'WAVE');
        expect(controller.metadata, isNotNull);
        expect(controller.metadata!.jobId, controller.jobId);
        expect(
          controller.metadata!.insertedDescriptions,
          greaterThan(0),
          reason: 'Validar audiodescrição realmente inserida.',
        );
        final restored = LibraryService();
        try {
          await restored.initialize();
          expect(restored.items, hasLength(1));
          expect(restored.items.single.jobId, controller.jobId);
          expect(restored.items.single.originalVideoPath, videoPath);
          expect(restored.items.single.audioDescriptionPath, path);
        } finally {
          restored.dispose();
        }
        expect(
          await directory.list().any((entry) => entry.path.endsWith('.part')),
          isFalse,
        );
        evidence['wav_bytes'] = bytes.length;
        evidence['descriptions_total'] = controller.metadata!.totalDescriptions;
        evidence['descriptions_inserted'] =
            controller.metadata!.insertedDescriptions;
        evidence['library_restored'] = true;
        evidence['passed'] = true;
      } finally {
        evidence['elapsed_seconds'] = elapsed.elapsed.inSeconds;
        evidence['states'] = states;
        evidence['final_state'] = controller.state.name;
        evidence['job_id'] = controller.jobId;
        final evidencePath =
            Platform.environment['SEE2SOUND_LIVE_EVIDENCE_PATH'];
        if (evidencePath != null) {
          await File(
            evidencePath,
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
        }
        controller.dispose();
        observerApi.close();
        storage.dispose();
        library.dispose();
        // Delete only the temporary directory created by this test.
        await directory.delete(recursive: true);
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 17)),
  );
}
