import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/app_settings_controller.dart';

class InterfaceNarrationService {
  InterfaceNarrationService(this.settings, {FlutterTts? textToSpeech})
    : _textToSpeech = textToSpeech ?? FlutterTts();

  final AppSettingsController settings;
  final FlutterTts _textToSpeech;

  Future<void> announce(BuildContext context, String message) async {
    if (!settings.interfaceNarration || !context.mounted) return;
    try {
      await _textToSpeech.stop();
      await _textToSpeech.setLanguage('pt-BR');
      await _textToSpeech.setVolume(settings.narrationVolume);
      await _textToSpeech.setSpeechRate(_engineRate(settings.speechSpeed));
      await _textToSpeech.speak(message);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro na narração da interface: $error');
      debugPrint('$stackTrace');
    }
  }

  double _engineRate(double userSpeed) {
    return switch (userSpeed) {
      <= 0.75 => 0.35,
      <= 1 => 0.5,
      <= 1.25 => 0.65,
      _ => 0.8,
    };
  }

  Future<void> stop() => _textToSpeech.stop();
}
