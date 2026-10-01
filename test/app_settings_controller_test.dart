import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/settings/app_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persiste e restaura preferências de acessibilidade', () async {
    final settings = AppSettingsController();
    await settings.initialize();

    await settings.setHighContrast(true);
    await settings.setVisualFocus(false);
    await settings.setReduceMotion(true);
    await settings.setSimplifiedInterface(true);
    await settings.setInterfaceNarration(true);
    await settings.setNarrationVolume(0.8);
    await settings.setSpeechSpeed(1.25);
    await settings.setTextSize(AppTextSize.extraLarge);

    final restored = AppSettingsController();
    await restored.initialize();

    expect(restored.highContrast, isTrue);
    expect(restored.visualFocus, isFalse);
    expect(restored.reduceMotion, isTrue);
    expect(restored.simplifiedInterface, isTrue);
    expect(restored.interfaceNarration, isTrue);
    expect(restored.narrationVolume, 0.8);
    expect(restored.speechSpeed, 1.25);
    expect(restored.textSize, AppTextSize.extraLarge);
  });

  test('usa padrões acessíveis quando não há preferências salvas', () async {
    final settings = AppSettingsController();
    await settings.initialize();

    expect(settings.highContrast, isFalse);
    expect(settings.visualFocus, isTrue);
    expect(settings.reduceMotion, isFalse);
    expect(settings.textSize, AppTextSize.standard);
  });
}
