import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class ApiSettingsException implements Exception {
  const ApiSettingsException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class ApiSettingsService extends ChangeNotifier {
  static const _baseUrlKey = 'see2sound.api_base_url';

  String _baseUrl = ApiConfig.defaultBaseUrl;
  bool _initialized = false;

  String get baseUrl => _baseUrl;
  bool get initialized => _initialized;
  bool get usesBuildDefault => _baseUrl == ApiConfig.defaultBaseUrl;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_baseUrlKey);
      _baseUrl = stored == null || stored.trim().isEmpty
          ? ApiConfig.defaultBaseUrl
          : ApiConfig.normalizeBaseUrl(stored);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao carregar endereço da API: $error');
      debugPrint('$stackTrace');
      _baseUrl = ApiConfig.defaultBaseUrl;
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setBaseUrl(String value) async {
    try {
      final normalized = ApiConfig.normalizeBaseUrl(value);
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(_baseUrlKey, normalized)) {
        throw StateError('SharedPreferences recusou a gravação.');
      }
      _baseUrl = normalized;
      _initialized = true;
      notifyListeners();
    } on FormatException catch (error) {
      throw ApiSettingsException(error.message, error);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao salvar endereço da API: $error');
      debugPrint('$stackTrace');
      throw ApiSettingsException(
        'Não foi possível salvar o endereço do servidor.',
        error,
      );
    }
  }

  Uri uri(String path) => ApiConfig.uri(path, baseUrl: _baseUrl);
}
