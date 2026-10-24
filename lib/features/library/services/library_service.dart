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
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static const _itemsKey = 'see2sound.audio_description_library';
  Future<void>? _initialization;
  Future<void> _mutations = Future<void>.value();
  String? _recoveryJson;

  Future<T> _mutate<T>(Future<T> Function() operation) {
    final result = _mutations.then((_) => operation());
    _mutations = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  SharedPreferences? _preferences;
  List<AudioDescriptionLibraryItem> _items = const [];
  bool _initialized = false;
  String? _loadError;

  List<AudioDescriptionLibraryItem> get items => List.unmodifiable(_items);
  bool get isInitialized => _initialized;
  String? get loadError => _loadError;

  Future<void> initialize() => _initialization ??= _load();

  Future<void> _load() async {
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
        final recovered = <AudioDescriptionLibraryItem>[];
        var invalid = false;
        for (final record in decoded) {
          try {
            if (record is! Map) {
              throw const FormatException('Registro inválido');
            }
            final item = AudioDescriptionLibraryItem.fromJson(
              Map<String, dynamic>.from(record),
            );
            if (recovered.any(
              (existing) =>
                  existing.id == item.id ||
                  (item.jobId != null && existing.jobId == item.jobId),
            )) {
              invalid = true;
              continue;
            }
            recovered.add(item);
          } catch (_) {
            invalid = true;
          }
        }
        _items = recovered..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (invalid) {
          _recoveryJson = savedJson;
          _loadError =
              'Alguns registros salvos não puderam ser carregados. Os registros válidos foram recuperados.';
          return;
        }
      }
      _loadError = null;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao carregar biblioteca: $error');
      debugPrint('$stackTrace');
      _recoveryJson = _preferences?.getString(_itemsKey);
      _items = const [];
      _loadError =
          'Não foi possível carregar a biblioteca salva. Os dados podem estar corrompidos.';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> addItem(AudioDescriptionLibraryItem item) =>
      _mutate(() => _addItem(item));

  Future<void> _addItem(AudioDescriptionLibraryItem item) async {
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

  Future<void> removeFromLibrary(String id) =>
      _mutate(() => _removeFromLibrary(id));

  Future<void> _removeFromLibrary(String id) async {
    await _ensureInitialized();
    await _persist(_items.where((item) => item.id != id).toList());
  }

  Future<AudioDescriptionLibraryItem> updateItemPaths(
    AudioDescriptionLibraryItem item, {
    String? originalVideoPath,
    String? audioDescriptionPath,
  }) => _mutate(
    () => _updateItemPaths(
      item,
      originalVideoPath: originalVideoPath,
      audioDescriptionPath: audioDescriptionPath,
    ),
  );

  Future<AudioDescriptionLibraryItem> _updateItemPaths(
    AudioDescriptionLibraryItem item, {
    String? originalVideoPath,
    String? audioDescriptionPath,
  }) async {
    await _ensureInitialized();
    final updated = item.copyWith(
      originalVideoPath: originalVideoPath,
      audioDescriptionPath: audioDescriptionPath,
    );
    await _replaceItem(updated);
    return updated;
  }

  Future<AudioDescriptionLibraryItem> renameAudioFile(
    AudioDescriptionLibraryItem item,
    String requestedName,
  ) => _mutate(() => _renameAudioFile(item, requestedName));

  Future<AudioDescriptionLibraryItem> _renameAudioFile(
    AudioDescriptionLibraryItem item,
    String requestedName,
  ) async {
    await _ensureInitialized();
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
  ) => _mutate(() => _copyAudioFile(item, destinationDirectoryPath));

  Future<String> _copyAudioFile(
    AudioDescriptionLibraryItem item,
    String destinationDirectoryPath,
  ) async {
    await _ensureInitialized();
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

  Future<void> deleteAudioFileAndRemove(AudioDescriptionLibraryItem item) =>
      _mutate(() => _deleteAudioFileAndRemove(item));

  Future<void> _deleteAudioFileAndRemove(
    AudioDescriptionLibraryItem item,
  ) async {
    await _ensureInitialized();
    final file = File(item.audioDescriptionPath);
    File? staged;
    var removed = false;
    try {
      if (_items.any(
        (other) =>
            other.id != item.id &&
            other.audioDescriptionPath == item.audioDescriptionPath,
      )) {
        throw const LibraryException(
          'Este áudio também é usado por outro registro. Remova apenas o item da biblioteca.',
        );
      }
      if (await file.exists()) {
        staged = await file.rename(
          '${file.path}.deleting-${DateTime.now().microsecondsSinceEpoch}',
        );
      }
      await _removeFromLibrary(item.id);
      removed = true;
      await staged?.delete();
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao excluir audiodescrição: $error');
      debugPrint('$stackTrace');
      try {
        if (staged != null && await staged.exists()) {
          await staged.rename(file.path);
        }
        if (removed) await _addItem(item);
      } catch (rollbackError) {
        debugPrint('[See2Sound] Falha ao restaurar exclusão: $rollbackError');
      }
      if (error is LibraryException) rethrow;
      throw LibraryException(
        'Não foi possível excluir a audiodescrição.',
        error,
      );
    }
  }

  Future<void> _replaceItem(AudioDescriptionLibraryItem item) async {
    if (!_items.any((existing) => existing.id == item.id)) {
      throw const LibraryException(
        'Este registro não está mais na biblioteca.',
      );
    }
    final updated = _items
        .map((existing) => existing.id == item.id ? item : existing)
        .toList();
    await _persist(updated);
  }

  Future<void> _persist(List<AudioDescriptionLibraryItem> items) async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      // Preserve the original data before repairing a partially readable history.
      if (_recoveryJson != null) {
        final backupKey =
            '$_itemsKey.recovery.${DateTime.now().microsecondsSinceEpoch}';
        if (!await preferences.setString(backupKey, _recoveryJson!)) {
          throw const LibraryException(
            'Não foi possível preservar o histórico anterior. Tente novamente.',
          );
        }
        _recoveryJson = null;
      }
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
