import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextSize {
  small('Pequeno', 0.9),
  standard('Padrão', 1),
  large('Grande', 1.15),
  extraLarge('Muito grande', 1.3);

  const AppTextSize(this.label, this.scale);

  final String label;
  final double scale;
}

class AppSettingsController extends ChangeNotifier {
  static const _prefix = 'see2sound.accessibility.';

  bool _initialized = false;
  bool _highContrast = false;
  bool _visualFocus = true;
  bool _reduceMotion = false;
  bool _simplifiedInterface = false;
  bool _interfaceNarration = false;
  double _narrationVolume = 0.6;
  double _speechSpeed = 1;
  AppTextSize _textSize = AppTextSize.standard;

  bool get initialized => _initialized;
  bool get highContrast => _highContrast;
  bool get visualFocus => _visualFocus;
  bool get reduceMotion => _reduceMotion;
  bool get simplifiedInterface => _simplifiedInterface;
  bool get interfaceNarration => _interfaceNarration;
  double get narrationVolume => _narrationVolume;
  double get speechSpeed => _speechSpeed;
  AppTextSize get textSize => _textSize;

  Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _highContrast = preferences.getBool('${_prefix}highContrast') ?? false;
      _visualFocus = preferences.getBool('${_prefix}visualFocus') ?? true;
      _reduceMotion = preferences.getBool('${_prefix}reduceMotion') ?? false;
      _simplifiedInterface =
          preferences.getBool('${_prefix}simplifiedInterface') ?? false;
      _interfaceNarration =
          preferences.getBool('${_prefix}interfaceNarration') ?? false;
      _narrationVolume =
          (preferences.getDouble('${_prefix}narrationVolume') ?? 0.6).clamp(
            0,
            1,
          );
      _speechSpeed = (preferences.getDouble('${_prefix}speechSpeed') ?? 1)
          .clamp(0.75, 1.5);
      final storedTextSize = preferences.getString('${_prefix}textSize');
      _textSize = AppTextSize.values.firstWhere(
        (value) => value.name == storedTextSize,
        orElse: () => AppTextSize.standard,
      );
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao carregar preferências: $error');
      debugPrint('$stackTrace');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setHighContrast(bool value) =>
      _setBool('highContrast', value, () => _highContrast = value);
  Future<void> setVisualFocus(bool value) =>
      _setBool('visualFocus', value, () => _visualFocus = value);
  Future<void> setReduceMotion(bool value) =>
      _setBool('reduceMotion', value, () => _reduceMotion = value);
  Future<void> setSimplifiedInterface(bool value) => _setBool(
    'simplifiedInterface',
    value,
    () => _simplifiedInterface = value,
  );
  Future<void> setInterfaceNarration(bool value) =>
      _setBool('interfaceNarration', value, () => _interfaceNarration = value);

  Future<void> setNarrationVolume(double value) async {
    _narrationVolume = value.clamp(0, 1);
    notifyListeners();
    await _persistDouble('narrationVolume', _narrationVolume);
  }

  Future<void> setSpeechSpeed(double value) async {
    _speechSpeed = value.clamp(0.75, 1.5);
    notifyListeners();
    await _persistDouble('speechSpeed', _speechSpeed);
  }

  Future<void> setTextSize(AppTextSize value) async {
    _textSize = value;
    notifyListeners();
    await _persist(
      (preferences) => preferences.setString('${_prefix}textSize', value.name),
    );
  }

  Future<void> _setBool(String key, bool value, VoidCallback update) async {
    update();
    notifyListeners();
    await _persist((preferences) => preferences.setBool('$_prefix$key', value));
  }

  Future<void> _persistDouble(String key, double value) {
    return _persist(
      (preferences) => preferences.setDouble('$_prefix$key', value),
    );
  }

  Future<void> _persist(
    Future<bool> Function(SharedPreferences preferences) operation,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await operation(preferences);
      if (!saved) throw StateError('SharedPreferences recusou a gravação.');
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao persistir preferência: $error');
      debugPrint('$stackTrace');
    }
  }
}
