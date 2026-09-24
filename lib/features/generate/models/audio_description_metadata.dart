import 'generation_status.dart';

class AudioDescriptionMetadata {
  const AudioDescriptionMetadata({
    required this.jobId,
    required this.status,
    required this.totalDescriptions,
    required this.insertedDescriptions,
    required this.skippedDescriptions,
    required this.cues,
    required this.audioUrl,
  });

  factory AudioDescriptionMetadata.fromJson(Map<String, dynamic> json) {
    final rawCues = json['cues'];
    return AudioDescriptionMetadata(
      jobId: json['job_id'] as String? ?? '',
      status: GenerationStatus.fromJson(json['status']),
      totalDescriptions: _asInt(json['total_descriptions']),
      insertedDescriptions: _asInt(json['inserted_descriptions']),
      skippedDescriptions: _asInt(json['skipped_descriptions']),
      cues: rawCues is List
          ? rawCues
                .whereType<Map>()
                .map(
                  (cue) => AudioDescriptionCue.fromJson(
                    Map<String, dynamic>.from(cue),
                  ),
                )
                .toList(growable: false)
          : const [],
      audioUrl: json['audio_url'] as String? ?? '',
    );
  }

  final String jobId;
  final GenerationStatus status;
  final int totalDescriptions;
  final int insertedDescriptions;
  final int skippedDescriptions;
  final List<AudioDescriptionCue> cues;
  final String audioUrl;
}

class AudioDescriptionCue {
  const AudioDescriptionCue({
    required this.index,
    required this.text,
    required this.sceneStartTime,
    required this.sceneEndTime,
    required this.pauseStart,
    required this.pauseEnd,
    required this.playbackStart,
    required this.playbackEnd,
    required this.ttsDuration,
    required this.inserted,
    required this.skipReason,
  });

  factory AudioDescriptionCue.fromJson(Map<String, dynamic> json) {
    return AudioDescriptionCue(
      index: _asInt(json['index']),
      text: json['text'] as String? ?? '',
      sceneStartTime: _asDouble(json['scene_start_time']),
      sceneEndTime: _asDouble(json['scene_end_time']),
      pauseStart: _asDouble(json['pause_start']),
      pauseEnd: _asDouble(json['pause_end']),
      playbackStart: _asDouble(json['playback_start']),
      playbackEnd: _asDouble(json['playback_end']),
      ttsDuration: _asDouble(json['tts_duration']),
      inserted: json['inserted'] as bool? ?? false,
      skipReason: json['skip_reason'] as String?,
    );
  }

  final int index;
  final String text;
  final double sceneStartTime;
  final double sceneEndTime;
  final double pauseStart;
  final double pauseEnd;
  final double playbackStart;
  final double playbackEnd;
  final double ttsDuration;
  final bool inserted;
  final String? skipReason;
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;
double _asDouble(Object? value) => value is num ? value.toDouble() : 0;
