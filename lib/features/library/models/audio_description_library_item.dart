class AudioDescriptionLibraryItem {
  const AudioDescriptionLibraryItem({
    required this.id,
    required this.originalFilename,
    required this.originalVideoPath,
    this.playbackVideoPath,
    required this.audioDescriptionPath,
    required this.createdAt,
    this.duration,
    this.jobId,
  });

  factory AudioDescriptionLibraryItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final id = json['id'];
    final originalFilename = json['original_filename'];
    final originalVideoPath = json['original_video_path'];
    final audioDescriptionPath = json['audio_description_path'];

    final createdAt = DateTime.tryParse(
      json['created_at'] as String? ?? '',
    );

    if (id is! String ||
        id.isEmpty ||
        originalFilename is! String ||
        originalFilename.trim().isEmpty ||
        originalVideoPath is! String ||
        originalVideoPath.trim().isEmpty ||
        audioDescriptionPath is! String ||
        audioDescriptionPath.trim().isEmpty ||
        createdAt == null) {
      throw const FormatException(
        'Registro de audiodescrição inválido.',
      );
    }

    final durationMilliseconds = json['duration_ms'];

    return AudioDescriptionLibraryItem(
      id: id,
      originalFilename: originalFilename,
      originalVideoPath: originalVideoPath,
      playbackVideoPath:
          json['playback_video_path'] as String?,
      audioDescriptionPath: audioDescriptionPath,
      createdAt: createdAt,
      duration:
          durationMilliseconds is int &&
              durationMilliseconds >= 0
          ? Duration(
              milliseconds: durationMilliseconds,
            )
          : null,
      jobId: json['job_id'] as String?,
    );
  }

  final String id;
  final String originalFilename;

  final String originalVideoPath;

  // Vídeo com pausas incorporadas.
  // É null quando o vídeo original pode ser usado.
  final String? playbackVideoPath;

  final String audioDescriptionPath;
  final DateTime createdAt;
  final Duration? duration;
  final String? jobId;

  AudioDescriptionLibraryItem copyWith({
    String? originalFilename,
    String? originalVideoPath,
    String? playbackVideoPath,
    String? audioDescriptionPath,
    Duration? duration,
  }) {
    return AudioDescriptionLibraryItem(
      id: id,
      originalFilename:
          originalFilename ?? this.originalFilename,
      originalVideoPath:
          originalVideoPath ?? this.originalVideoPath,
      playbackVideoPath:
          playbackVideoPath ?? this.playbackVideoPath,
      audioDescriptionPath:
          audioDescriptionPath ?? this.audioDescriptionPath,
      createdAt: createdAt,
      duration: duration ?? this.duration,
      jobId: jobId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_filename': originalFilename,
    'original_video_path': originalVideoPath,
    'playback_video_path': playbackVideoPath,
    'audio_description_path': audioDescriptionPath,
    'created_at': createdAt.toIso8601String(),
    'duration_ms': duration?.inMilliseconds,
    'job_id': jobId,
  };
}