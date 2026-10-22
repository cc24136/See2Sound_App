class ApiConfig {
  const ApiConfig._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'SEE2SOUND_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Informe um endereço válido, começando com http:// ou https://.',
      );
    }
    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return withoutTrailingSlash;
  }

  static Uri uri(String path, {String? baseUrl}) {
    final normalizedBase = normalizeBaseUrl(baseUrl ?? defaultBaseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
