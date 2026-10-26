import 'dart:io';
import 'dart:typed_data';

// Reads timing metadata only; mdat video/audio samples are never buffered.
// Fragmented MP4s may legitimately leave mvhd/mdhd durations at zero.
Future<Duration?> readFragmentedMp4Duration(File file) async {
  RandomAccessFile? input;
  try {
    input = await file.open();
    final length = await input.length();
    final scales = <int, int>{};
    final defaults = <int, int>{};
    final ends = <int, int>{};
    var count = 0;
    await for (final box in _boxes(input, 0, length)) {
      if (++count > 100000) return null;
      if (box.type == 'moov') {
        await for (final child in _boxes(input, box.start, box.end)) {
          if (child.type == 'trak') {
            int? id;
            int? scale;
            await for (final track in _boxes(input, child.start, child.end)) {
              if (track.type == 'tkhd') {
                final data = await _payload(input, track);
                id = _u32(data, data[0] == 1 ? 20 : 12);
              } else if (track.type == 'mdia') {
                await for (final media
                    in _boxes(input, track.start, track.end)) {
                  if (media.type == 'mdhd') {
                    final data = await _payload(input, media);
                    scale = _u32(data, data[0] == 1 ? 20 : 12);
                  }
                }
              }
            }
            if (id != null && scale != null && scale > 0) scales[id] = scale;
          } else if (child.type == 'mvex') {
            await for (final entry in _boxes(input, child.start, child.end)) {
              if (entry.type == 'trex') {
                final data = await _payload(input, entry);
                defaults[_u32(data, 4)] = _u32(data, 12);
              }
            }
          }
        }
      } else if (box.type == 'moof') {
        await for (final traf in _boxes(input, box.start, box.end)) {
          if (traf.type != 'traf') continue;
          int? id;
          int? base;
          int? defaultDuration;
          final runs = <_Box>[];
          await for (final entry in _boxes(input, traf.start, traf.end)) {
            if (entry.type == 'tfhd') {
              final data = await _payload(input, entry);
              final flags = _u32(data, 0) & 0xffffff;
              id = _u32(data, 4);
              var offset = 8;
              if (flags & 1 != 0) offset += 8;
              if (flags & 2 != 0) offset += 4;
              if (flags & 8 != 0) defaultDuration = _u32(data, offset);
            } else if (entry.type == 'tfdt') {
              final data = await _payload(input, entry);
              base = data[0] == 1
                  ? ByteData.sublistView(data).getUint64(4)
                  : _u32(data, 4);
            } else if (entry.type == 'trun') {
              runs.add(entry);
            }
          }
          if (id == null || !scales.containsKey(id)) continue;
          var end = base ?? ends[id] ?? 0;
          for (final run in runs) {
            final data = await _payload(input, run);
            final flags = _u32(data, 0) & 0xffffff;
            final samples = _u32(data, 4);
            if (samples > 1000000) return null;
            var offset = 8;
            if (flags & 1 != 0) offset += 4;
            if (flags & 4 != 0) offset += 4;
            var stride = 0;
            for (final flag in [0x100, 0x200, 0x400, 0x800]) {
              if (flags & flag != 0) stride += 4;
            }
            if (offset + samples * stride > data.length) return null;
            if (flags & 0x100 == 0) {
              final duration = defaultDuration ?? defaults[id];
              if (duration == null || duration == 0) return null;
              end += samples * duration;
            } else {
              for (var sample = 0; sample < samples; sample++) {
                end += _u32(data, offset);
                offset += stride;
              }
            }
          }
          if (end > (ends[id] ?? 0)) ends[id] = end;
        }
      }
    }
    var microseconds = 0;
    ends.forEach((id, end) {
      final value = (end * Duration.microsecondsPerSecond) ~/ scales[id]!;
      if (value > microseconds) microseconds = value;
    });
    return microseconds > 0 ? Duration(microseconds: microseconds) : null;
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  } on RangeError {
    return null;
  } finally {
    await input?.close();
  }
}

class _Box {
  _Box(this.type, this.start, this.end);
  final String type;
  final int start;
  final int end;
}

Stream<_Box> _boxes(RandomAccessFile input, int start, int end) async* {
  var offset = start;
  while (offset < end) {
    if (end - offset < 8) throw const FormatException('Truncated MP4 box');
    await input.setPosition(offset);
    final header = await input.read(8);
    if (header.length != 8) throw const FormatException('Truncated MP4 header');
    var size = _u32(header, 0);
    var headerSize = 8;
    if (size == 1) {
      final extended = await input.read(8);
      size = ByteData.sublistView(extended).getUint64(0);
      headerSize = 16;
    } else if (size == 0) {
      size = end - offset;
    }
    if (size < headerSize || size > end - offset) {
      throw const FormatException('Invalid MP4 box size');
    }
    yield _Box(String.fromCharCodes(header.sublist(4, 8)), offset + headerSize,
        offset + size);
    offset += size;
  }
}

Future<Uint8List> _payload(RandomAccessFile input, _Box box) async {
  final size = box.end - box.start;
  if (size > 4 * 1024 * 1024) {
    throw const FormatException('Oversized MP4 metadata');
  }
  await input.setPosition(box.start);
  final data = await input.read(size);
  if (data.length != size) {
    throw const FormatException('Truncated MP4 metadata');
  }
  return data;
}

int _u32(Uint8List data, int offset) =>
    ByteData.sublistView(data).getUint32(offset);
