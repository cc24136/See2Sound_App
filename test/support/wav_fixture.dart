import 'dart:typed_data';

// Small valid PCM fixture for file/timeout tests only. Native playback tests
// use the actual backend WAV and original video instead.
Uint8List pcmWav({bool junkChunk = false}) {
  final extra = junkChunk ? 10 : 0;
  final data = ByteData(52 + extra);
  void tag(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, data.lengthInBytes - 8, Endian.little);
  tag(8, 'WAVE');
  var offset = 12;
  if (junkChunk) {
    tag(offset, 'JUNK');
    data.setUint32(offset + 4, 1, Endian.little);
    offset += 10;
  }
  tag(offset, 'fmt ');
  data.setUint32(offset + 4, 16, Endian.little);
  data.setUint16(offset + 8, 1, Endian.little);
  data.setUint16(offset + 10, 1, Endian.little);
  data.setUint32(offset + 12, 8000, Endian.little);
  data.setUint32(offset + 16, 16000, Endian.little);
  data.setUint16(offset + 20, 2, Endian.little);
  data.setUint16(offset + 22, 16, Endian.little);
  offset += 24;
  tag(offset, 'data');
  data.setUint32(offset + 4, 8, Endian.little);
  return data.buffer.asUint8List();
}
