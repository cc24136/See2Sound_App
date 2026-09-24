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
