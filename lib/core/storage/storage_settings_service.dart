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
      await _verifyWritable(directory);

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

  Future<Directory> requireWritableDirectory() async {
    await initialize();
    final path = _directoryPath;
    if (path == null || path.isEmpty) {
      throw const StorageSettingsException(
        'Escolha uma pasta para salvar suas audiodescrições antes de continuar.',
      );
    }
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw const StorageSettingsException(
        'A pasta configurada não foi encontrada. Escolha outra pasta nas configurações.',
      );
    }
    await _verifyWritable(directory);
    return directory;
  }

  Future<void> _verifyWritable(Directory directory) async {
    final separator = Platform.pathSeparator;
    final probe = File(
      '${directory.path}$separator.see2sound-write-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await probe.writeAsBytes(const [0], flush: true);
      await probe.delete();
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Pasta sem permissão de escrita: $error');
      debugPrint('$stackTrace');
      if (await probe.exists()) {
        try {
          await probe.delete();
        } catch (cleanupError, cleanupStackTrace) {
          debugPrint(
            '[See2Sound] Falha ao remover arquivo de teste: $cleanupError',
          );
          debugPrint('$cleanupStackTrace');
        }
      }
      throw StorageSettingsException(
        'A pasta selecionada não permite salvar arquivos. Verifique a permissão ou escolha outra pasta.',
        error,
      );
    }
  }
}
