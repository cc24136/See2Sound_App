import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_description_library_item.dart';

class LibraryException implements Exception {
  const LibraryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class LibraryService extends ChangeNotifier {
  static const _itemsKey = 'see2sound.audio_description_library';

  SharedPreferences? _preferences;
  List<AudioDescriptionLibraryItem> _items = const [];
  bool _initialized = false;
  String? _loadError;

  List<AudioDescriptionLibraryItem> get items => List.unmodifiable(_items);
  bool get isInitialized => _initialized;
  String? get loadError => _loadError;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _preferences = await SharedPreferences.getInstance();
      final savedJson = _preferences!.getString(_itemsKey);
      if (savedJson == null || savedJson.isEmpty) {
        _items = const [];
      } else {
        final decoded = jsonDecode(savedJson);
        if (decoded is! List) {
          throw const FormatException('A biblioteca não contém uma lista.');
        }
        _items = decoded.map((item) {
          if (item is! Map) {
            throw const FormatException(
              'A biblioteca contém um registro inválido.',
            );
          }
          return AudioDescriptionLibraryItem.fromJson(
            Map<String, dynamic>.from(item),
          );
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _loadError = null;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao carregar biblioteca: $error');
      debugPrint('$stackTrace');
      _items = const [];
      _loadError =
          'Não foi possível carregar a biblioteca salva. Os dados podem estar corrompidos.';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> addItem(AudioDescriptionLibraryItem item) async {
    await _ensureInitialized();
    final existingIndex = _items.indexWhere(
      (existing) =>
          existing.id == item.id ||
          (item.jobId != null && existing.jobId == item.jobId),
    );
    final updated = List<AudioDescriptionLibraryItem>.from(_items);
    if (existingIndex >= 0) {
      updated[existingIndex] = item;
    } else {
      updated.insert(0, item);
    }
    await _persist(updated);
  }

  Future<void> removeFromLibrary(String id) async {
    await _ensureInitialized();
    await _persist(_items.where((item) => item.id != id).toList());
  }

  Future<AudioDescriptionLibraryItem> renameAudioFile(
    AudioDescriptionLibraryItem item,
    String requestedName,
  ) async {
    final source = File(item.audioDescriptionPath);
    if (!await source.exists()) {
      throw const LibraryException(
        'O arquivo de audiodescrição não foi encontrado.',
      );
    }

    final safeStem = _safeStem(requestedName);
    if (safeStem.isEmpty) {
      throw const LibraryException('Informe um nome válido para o arquivo.');
    }
    if (_fileName(source.path).toLowerCase() == '$safeStem.wav'.toLowerCase()) {
      return item;
    }

    final parent = source.parent;
    final targetPath = await _uniquePath(parent, '$safeStem.wav');
    File? renamed;
    try {
      renamed = await source.rename(targetPath);
      final updatedItem = item.copyWith(audioDescriptionPath: renamed.path);
      await _replaceItem(updatedItem);
      return updatedItem;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao renomear audiodescrição: $error');
      debugPrint('$stackTrace');
      if (renamed != null && await renamed.exists()) {
        try {
          await renamed.rename(source.path);
        } catch (rollbackError, rollbackStackTrace) {
          debugPrint(
            '[See2Sound] Erro ao restaurar arquivo após falha: $rollbackError',
          );
          debugPrint('$rollbackStackTrace');
        }
      }
      throw LibraryException(
        'Não foi possível renomear a audiodescrição.',
        error,
      );
    }
  }

  Future<String> copyAudioFile(
    AudioDescriptionLibraryItem item,
    String destinationDirectoryPath,
  ) async {
    final source = File(item.audioDescriptionPath);
    final destinationDirectory = Directory(destinationDirectoryPath);
    if (!await source.exists()) {
      throw const LibraryException(
        'O arquivo de audiodescrição não foi encontrado.',
      );
    }
    if (!await destinationDirectory.exists()) {
      throw const LibraryException('A pasta de destino não foi encontrada.');
    }

    try {
      final targetPath = await _uniquePath(
        destinationDirectory,
        _fileName(source.path),
      );
      final copied = await source.copy(targetPath);
      return copied.path;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao copiar audiodescrição: $error');
      debugPrint('$stackTrace');
      throw LibraryException(
        'Não foi possível copiar a audiodescrição.',
        error,
      );
    }
  }

  Future<void> deleteAudioFileAndRemove(
    AudioDescriptionLibraryItem item,
  ) async {
    final file = File(item.audioDescriptionPath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
      await removeFromLibrary(item.id);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao excluir audiodescrição: $error');
      debugPrint('$stackTrace');
      throw LibraryException(
        'Não foi possível excluir a audiodescrição.',
        error,
      );
    }
  }

  Future<void> _replaceItem(AudioDescriptionLibraryItem item) async {
    final updated = _items
        .map((existing) => existing.id == item.id ? item : existing)
        .toList();
    await _persist(updated);
  }

  Future<void> _persist(List<AudioDescriptionLibraryItem> items) async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
      final saved = await preferences.setString(_itemsKey, encoded);
      if (!saved) {
        throw const LibraryException('Falha ao persistir a biblioteca.');
      }
      _preferences = preferences;
      _items = List.unmodifiable(items);
      _loadError = null;
      notifyListeners();
    } on LibraryException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao persistir biblioteca: $error');
      debugPrint('$stackTrace');
      throw LibraryException('Não foi possível atualizar a biblioteca.', error);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  String _safeStem(String requestedName) {
    var name = requestedName.trim();
    if (name.toLowerCase().endsWith('.wav')) {
      name = name.substring(0, name.length - 4);
    }
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .trim();
  }

  Future<String> _uniquePath(Directory directory, String fileName) async {
    final separator = Platform.pathSeparator;
    final extensionIndex = fileName.lastIndexOf('.');
    final stem = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;
    final extension = extensionIndex > 0
        ? fileName.substring(extensionIndex)
        : '';
    var candidate = '${directory.path}$separator$fileName';
    var suffix = 2;
    while (await File(candidate).exists()) {
      candidate = '${directory.path}$separator${stem}_$suffix$extension';
      suffix++;
    }
    return candidate;
  }

  String _fileName(String path) => path.split(RegExp(r'[/\\]')).last;
}
