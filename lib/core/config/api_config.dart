class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'SEE2SOUND_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Uri uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
