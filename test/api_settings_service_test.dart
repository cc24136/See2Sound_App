import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/config/api_config.dart';
import 'package:see2sound_app/core/config/api_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('valida, normaliza e persiste endereço da API', () async {
    final settings = ApiSettingsService();
    await settings.initialize();
    await settings.setBaseUrl(' http://192.168.1.20:8000/ ');

    expect(settings.baseUrl, 'http://192.168.1.20:8000');
    expect(
      settings.uri('/health').toString(),
      'http://192.168.1.20:8000/health',
    );

    final restored = ApiSettingsService();
    await restored.initialize();
    expect(restored.baseUrl, 'http://192.168.1.20:8000');
  });

  test('rejeita endereço sem http ou https', () async {
    final settings = ApiSettingsService();
    await settings.initialize();

    await expectLater(
      settings.setBaseUrl('192.168.1.20:8000'),
      throwsA(isA<ApiSettingsException>()),
    );
  });

  test('usa SEE2SOUND_API_URL como fonte padrão', () {
    expect(
      ApiConfig.uri('/health').toString(),
      '${ApiConfig.defaultBaseUrl}/health',
    );
  });
}
