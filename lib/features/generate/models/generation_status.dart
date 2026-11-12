enum GenerationStatus {
  queued,
  processing,
  completed,
  failed;

  factory GenerationStatus.fromJson(Object? value) {
    return switch (value) {
      'queued' => GenerationStatus.queued,
      'processing' => GenerationStatus.processing,
      'completed' => GenerationStatus.completed,
      'failed' => GenerationStatus.failed,
      _ => throw FormatException('Status de geração desconhecido: $value'),
    };
  }
}

class GenerationSnapshot {
  const GenerationSnapshot({
    required this.jobId,
    required this.status,
    required this.originalFilename,
    required this.createdAt,
    required this.startedAt,
    required this.finishedAt,
    required this.error,
    required this.options,
    this.progressPercent,
    this.stage,
    this.stageLabel,
    this.stageCurrent,
    this.stageTotal,
  });

  factory GenerationSnapshot.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return GenerationSnapshot(
      jobId: json['job_id'] as String? ?? '',
      status: GenerationStatus.fromJson(json['status']),
      originalFilename: json['original_filename'] as String?,
      createdAt: json['created_at'] as String?,
      startedAt: json['started_at'] as String?,
      finishedAt: json['finished_at'] as String?,
      error: _errorMessage(json['error']),
      options: rawOptions is Map<String, dynamic> ? rawOptions : const {},
      progressPercent: validProgressPercent(json['progress_percent']),
      stage: _nonEmptyString(json['stage']),
      stageLabel: _nonEmptyString(json['stage_label']),
      stageCurrent: _stageCount(json['stage_current']),
      stageTotal: _stageCount(json['stage_total']),
    );
  }

  final String jobId;
  final GenerationStatus status;
  final String? originalFilename;
  final String? createdAt;
  final String? startedAt;
  final String? finishedAt;
  final String? error;
  final Map<String, dynamic> options;
  final double? progressPercent;
  final String? stage;
  final String? stageLabel;
  final int? stageCurrent;
  final int? stageTotal;

  // Ignore malformed values without interrupting monitoring.
  static double? validProgressPercent(Object? value) {
    if (value is! num || !value.isFinite || value < 0 || value > 100) {
      return null;
    }
    return value.toDouble();
  }

  static int? _stageCount(Object? value) =>
      value is num &&
          value.isFinite &&
          value >= 0 &&
          value == value.roundToDouble()
      ? value.toInt()
      : null;

  static String? _nonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

String? _errorMessage(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    final message = value['message'] ?? value['detail'] ?? value['error'];
    if (message != null) return message.toString();
  }
  return value.toString();
}
