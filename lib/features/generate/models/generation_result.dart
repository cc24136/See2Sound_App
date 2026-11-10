import 'generation_status.dart';

class GenerationResult {
  const GenerationResult({
    required this.jobId,
    required this.status,
    required this.narrativeTimeline,
    required this.hasVoiceEngine,
    required this.hasAudioDescription,
    required this.artifactUrls,
    this.playbackDuration,
  });

  factory GenerationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawResult = json['result'];

    final result = rawResult is Map
        ? Map<String, dynamic>.from(rawResult)
        : const <String, dynamic>{};

    final rawNarrative = result['narrative'];

    final narrative = rawNarrative is Map
        ? Map<String, dynamic>.from(rawNarrative)
        : const <String, dynamic>{};

    final rawTimeline = narrative['timeline'];

    final timeline = rawTimeline is List
        ? rawTimeline
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList(growable: false)
        : const <Map<String, dynamic>>[];

    final rawVoiceEngine = result['voice_engine'];

    final voiceEngine = rawVoiceEngine is Map
        ? Map<String, dynamic>.from(rawVoiceEngine)
        : null;

    final rawArtifactUrls = json['artifact_urls'];

    final artifactUrls = rawArtifactUrls is Map
        ? rawArtifactUrls.map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          )
        : const <String, String>{};

    final audioPath = voiceEngine?['modified_audio_path'];

    final rawPlayback = result['playback'];

    final playback = rawPlayback is Map
        ? Map<String, dynamic>.from(rawPlayback)
        : const <String, dynamic>{};

    final rawPlaybackSeconds = playback['duration_seconds'];

    return GenerationResult(
      jobId: json['job_id'] as String? ?? '',
      status: GenerationStatus.fromJson(json['status']),
      narrativeTimeline: timeline,
      hasVoiceEngine: voiceEngine != null,
      hasAudioDescription:
          (audioPath is String && audioPath.isNotEmpty) ||
          artifactUrls.containsKey('audio_description'),
      artifactUrls: artifactUrls,
      playbackDuration:
          rawPlaybackSeconds is num &&
              rawPlaybackSeconds.toDouble().isFinite &&
              rawPlaybackSeconds >= 0
          ? Duration(
              milliseconds: (
                rawPlaybackSeconds * 1000
              ).round(),
            )
          : null,
    );
  }

  final String jobId;
  final GenerationStatus status;
  final List<Map<String, dynamic>> narrativeTimeline;
  final bool hasVoiceEngine;
  final bool hasAudioDescription;
  final Map<String, String> artifactUrls;
  final Duration? playbackDuration;

  int get narrativeDescriptionCount {
    return narrativeTimeline.where((item) {
      final skipped = item['skipped'];
      final description = item['description'];

      return skipped != true &&
          description is String &&
          description.trim().isNotEmpty;
    }).length;
  }
}