import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_win/fragmented_mp4_duration.dart';

List<int> words(List<int> values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setUint32(i * 4, values[i]);
  }
  return data.buffer.asUint8List();
}

List<int> box(String name, List<int> payload) => [
  ...words([8 + payload.length]),
  ...name.codeUnits,
  ...payload,
];
List<int> movie({int scale = 1000}) => box('moov', [
  ...box('trak', [
    ...box('tkhd', words([0, 0, 0, 1])),
    ...box('mdia', box('mdhd', words([0, 0, 0, scale]))),
  ]),
  ...box('mvex', box('trex', words([0, 1, 1, 40]))),
]);
List<int> fragment(int base, {bool explicit = false}) => box(
  'moof',
  box('traf', [
    ...box('tfhd', words([0, 1])),
    ...box('tfdt', words([0x01000000, 0, base])),
    ...box('trun', words(explicit ? [0x100, 2, 25, 75] : [0, 5])),
  ]),
);
void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('see2sound-mp4-timing-');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  Future<Duration?> duration(List<int> bytes) async {
    final file = await File('${dir.path}/timing.mp4').writeAsBytes(bytes);
    return readFragmentedMp4Duration(file);
  }

  test('deriva duração real de tfdt e defaults trex em fragmentos', () async {
    expect(
      await duration([
        ...movie(),
        ...fragment(0),
        ...box('mdat', List.filled(1024, 0)),
        ...fragment(200),
      ]),
      const Duration(milliseconds: 400),
    );
  });
  test('usa durações individuais trun e tfdt de 64 bits', () async {
    expect(
      await duration([...movie(), ...fragment(500, explicit: true)]),
      const Duration(milliseconds: 600),
    );
  });
  test(
    'metadata truncada ou timescale zero não produz duração inventada',
    () async {
      expect(await duration([0, 1, 2]), isNull);
      expect(await duration([...movie(scale: 0), ...fragment(0)]), isNull);
      expect(
        await duration([...movie(), ...fragment(0)].sublist(0, 50)),
        isNull,
      );
      expect(await duration(movie()), isNull);
    },
  );
  test('amostras declaradas sem bytes suficientes são rejeitadas', () async {
    final bad = box(
      'moof',
      box('traf', [
        ...box('tfhd', words([0, 1])),
        ...box('trun', words([0x100, 100, 40])),
      ]),
    );
    expect(await duration([...movie(), ...bad]), isNull);
  });
}
