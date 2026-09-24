import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/features/generate/models/audio_description_metadata.dart';
import 'package:see2sound_app/features/generate/models/generation_created.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';

void main() {
  test('faz parse de GenerationCreated', () {
    final model = GenerationCreated.fromJson(const {
      'job_id': 'job-123',
      'status': 'queued',
      'message': 'Vídeo recebido.',
      'status_url': '/api/v1/generations/job-123',
      'result_url': '/api/v1/generations/job-123/result',
      'audio_description_url': '/api/v1/generations/job-123/audio-description',
      'audio_description_metadata_url':
          '/api/v1/generations/job-123/audio-description/metadata',
    });

    expect(model.jobId, 'job-123');
    expect(model.status, 'queued');
    expect(model.audioDescriptionUrl, contains('audio-description'));
  });

  test('faz parse de GenerationStatus completed', () {
    expect(GenerationStatus.fromJson('completed'), GenerationStatus.completed);
  });

  test('faz parse de GenerationStatus failed', () {
    expect(GenerationStatus.fromJson('failed'), GenerationStatus.failed);
  });

  test('faz parse do snapshot de status', () {
    final snapshot = GenerationSnapshot.fromJson(const {
      'job_id': 'job-123',
      'status': 'processing',
      'original_filename': 'video.mp4',
      'created_at': '2026-09-24T10:00:00Z',
      'started_at': '2026-09-24T10:00:01Z',
      'finished_at': null,
      'error': null,
      'options': {'run_tts': true},
    });

    expect(snapshot.status, GenerationStatus.processing);
    expect(snapshot.originalFilename, 'video.mp4');
    expect(snapshot.options['run_tts'], isTrue);
  });

  test('faz parse de AudioDescriptionMetadata e preserva cues', () {
    final metadata = AudioDescriptionMetadata.fromJson(const {
      'job_id': 'job-123',
      'status': 'completed',
      'total_descriptions': 4,
      'inserted_descriptions': 3,
      'skipped_descriptions': 1,
      'cues': [
        {
          'index': 0,
          'text': 'Uma pessoa observa o mar.',
          'scene_start_time': 0.0,
          'scene_end_time': 2.8,
          'pause_start': 0.0,
          'pause_end': 4.1,
          'playback_start': 0.6,
          'playback_end': 2.7,
          'tts_duration': 2.1,
          'inserted': true,
          'skip_reason': null,
        },
      ],
      'audio_url': '/api/v1/generations/job-123/audio-description',
    });

    expect(metadata.status, GenerationStatus.completed);
    expect(metadata.totalDescriptions, 4);
    expect(metadata.cues, hasLength(1));
    expect(metadata.cues.single.text, 'Uma pessoa observa o mar.');
    expect(metadata.cues.single.inserted, isTrue);
  });
}
