class GenerationCreated {
  const GenerationCreated({
    required this.jobId,
    required this.status,
    required this.message,
    required this.statusUrl,
    required this.resultUrl,
    required this.audioDescriptionUrl,
    required this.audioDescriptionMetadataUrl,
  });

  factory GenerationCreated.fromJson(Map<String, dynamic> json) {
    return GenerationCreated(
      jobId: _requiredString(json, 'job_id'),
      status: _requiredString(json, 'status'),
      message: _requiredString(json, 'message'),
      statusUrl: _requiredString(json, 'status_url'),
      resultUrl: _requiredString(json, 'result_url'),
      audioDescriptionUrl: _requiredString(json, 'audio_description_url'),
      audioDescriptionMetadataUrl: _requiredString(
        json,
        'audio_description_metadata_url',
      ),
    );
  }

  final String jobId;
  final String status;
  final String message;
  final String statusUrl;
  final String resultUrl;
  final String audioDescriptionUrl;
  final String audioDescriptionMetadataUrl;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Campo obrigatório ausente: $key');
}
