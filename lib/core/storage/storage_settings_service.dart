import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsException implements Exception {
  const StorageSettingsException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class StorageSettingsService extends ChangeNotifier {
  static const _directoryPathKey = 'see2sound.storage_directory_path';

  SharedPreferences? _preferences;
  String? _directoryPath;
  bool _initialized = false;

  String? get directoryPath => _directoryPath;
  bool get isInitialized => _initialized;
  bool get hasDirectory =>
      _directoryPath != null && _directoryPath!.trim().isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _preferences = await SharedPreferences.getInstance();
      final savedPath = _preferences!.getString(_directoryPathKey)?.trim();
      _directoryPath = savedPath == null || savedPath.isEmpty
          ? null
          : savedPath;
      _initialized = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao carregar pasta configurada: $error');
      debugPrint('$stackTrace');
      throw StorageSettingsException(
        'Não foi possível carregar a pasta de armazenamento.',
        error,
      );
    }
  }

  Future<void> setDirectoryPath(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      throw const StorageSettingsException('Selecione uma pasta válida.');
    }

    try {
      final directory = Directory(normalizedPath);
      if (!await directory.exists()) {
        throw const StorageSettingsException(
          'A pasta selecionada não foi encontrada.',
        );
      }

      final preferences = _preferences ?? await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _directoryPathKey,
        normalizedPath,
      );
      if (!saved) {
        throw const StorageSettingsException(
          'Não foi possível persistir a pasta selecionada.',
        );
      }

      _preferences = preferences;
      _directoryPath = normalizedPath;
      _initialized = true;
      notifyListeners();
    } on StorageSettingsException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao salvar pasta configurada: $error');
      debugPrint('$stackTrace');
      throw StorageSettingsException(
        'Não foi possível salvar a pasta selecionada.',
        error,
      );
    }
  }
}
