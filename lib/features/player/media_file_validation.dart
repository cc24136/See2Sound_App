import 'dart:io';
import 'dart:typed_data';

class PlaybackFileException implements Exception {
  const PlaybackFileException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Resolves a readable local file, without manually escaping a Windows URI.
Future<File> validatePlaybackFile(String path, {required bool audio}) async {
  final label = audio ? 'áudio da audiodescrição' : 'vídeo original';
  if (path.trim().isEmpty) {
    throw PlaybackFileException('A localização do $label não foi informada.');
  }
  try {
    final file = path.startsWith('file:')
        ? File.fromUri(Uri.parse(path))
        : File(path).absolute;
    if (!await file.exists()) {
      throw PlaybackFileException(
        'O $label não foi encontrado. Localize o arquivo novamente na biblioteca.',
      );
    }
    final resolved = File(await file.resolveSymbolicLinks());
    final handle = await resolved.open();
    try {
      final length = await handle.length();
      if (length == 0) {
        throw PlaybackFileException('O arquivo de $label está vazio.');
      }
      if (audio) {
        await _validateWav(handle, length);
      } else {
        await handle.read(1); // Verify actual read access, not just existence.
      }
    } finally {
      await handle.close();
    }
    return resolved;
  } on PlaybackFileException {
    rethrow;
  } on FileSystemException {
    throw PlaybackFileException(
      'Não foi possível ler o $label. Verifique a localização e a permissão de acesso.',
    );
  } on FormatException {
    throw PlaybackFileException(
      'A localização do $label é inválida. Localize o arquivo novamente.',
    );
  } on ArgumentError {
    throw PlaybackFileException(
      'A localização do $label é inválida. Localize o arquivo novamente.',
    );
  }
}

Future<void> _validateWav(RandomAccessFile file, int length) async {
  const invalid = PlaybackFileException(
    'A audiodescrição não é um WAV válido ou está incompleta. Gere o áudio novamente.',
  );
  if (length < 44) throw invalid;
  final header = await file.read(12);
  if (!_tag(header, 0, 'RIFF') || !_tag(header, 8, 'WAVE')) throw invalid;
  final riffEnd = _uint32(header, 4) + 8;
  if (riffEnd > length || riffEnd < 44) throw invalid;
  var offset = 12;
  int? format;
  int? blockAlign;
  int? audioBytes;
  while (offset + 8 <= riffEnd) {
    await file.setPosition(offset);
    final chunk = await file.read(8);
    if (chunk.length != 8) throw invalid;
    final size = _uint32(chunk, 4);
    final payload = offset + 8;
    if (payload + size > riffEnd) throw invalid;
    if (_tag(chunk, 0, 'fmt ')) {
      if (size < 16) throw invalid;
      final formatBytes = await file.read(16);
      if (formatBytes.length != 16) throw invalid;
      final data = ByteData.sublistView(formatBytes);
      format = data.getUint16(0, Endian.little);
      blockAlign = data.getUint16(12, Endian.little);
      if (data.getUint16(2, Endian.little) == 0 ||
          data.getUint32(4, Endian.little) == 0 ||
          blockAlign == 0) {
        throw invalid;
      }
    } else if (_tag(chunk, 0, 'data')) {
      audioBytes = size;
    }
    offset = payload + size + (size.isOdd ? 1 : 0);
  }
  if (format == null || audioBytes == null || audioBytes == 0) throw invalid;
  if ((format == 1 || format == 3) && audioBytes % blockAlign! != 0) {
    throw invalid;
  }
}

bool _tag(List<int> bytes, int offset, String tag) {
  if (offset + tag.length > bytes.length) return false;
  for (var i = 0; i < tag.length; i++) {
    if (bytes[offset + i] != tag.codeUnitAt(i)) return false;
  }
  return true;
}

int _uint32(Uint8List bytes, int offset) =>
    ByteData.sublistView(bytes).getUint32(offset, Endian.little);
