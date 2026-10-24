import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/features/player/media_file_validation.dart';
import 'support/wav_fixture.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'see2sound-wav-validation-',
    );
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'resolve caminho absoluto com espaços, acentos, # e % sem alterar o arquivo',
    () async {
      final file = File('${directory.path}/descrição final #100%.wav');
      final bytes = pcmWav(junkChunk: true);
      await file.writeAsBytes(bytes);
      final resolved = await validatePlaybackFile(file.path, audio: true);
      expect(resolved.isAbsolute, isTrue);
      expect(await resolved.readAsBytes(), bytes);
      final fromUri = await validatePlaybackFile(
        file.absolute.uri.toString(),
        audio: true,
      );
      expect(fromUri.path, resolved.path);
    },
  );
  test('arquivo ausente produz mensagem acessível', () async {
    await expectLater(
      validatePlaybackFile('${directory.path}/ausente.wav', audio: true),
      throwsA(
        isA<PlaybackFileException>().having(
          (e) => e.message,
          'mensagem',
          contains('não foi encontrado'),
        ),
      ),
    );
  });
  test('vídeo vazio não chega ao plugin', () async {
    final file = await File('${directory.path}/vazio.mp4').writeAsBytes([]);
    await expectLater(
      validatePlaybackFile(file.path, audio: false),
      throwsA(isA<PlaybackFileException>()),
    );
  });
  for (final corruption in [
    'empty',
    'header',
    'truncated',
    'missingFormat',
    'zeroData',
    'badAlignment',
  ]) {
    test('rejeita WAV $corruption antes do carregamento nativo', () async {
      var bytes = pcmWav();
      switch (corruption) {
        case 'empty':
          bytes = Uint8List(0);
        case 'header':
          bytes[0] = 0;
        case 'truncated':
          bytes = Uint8List.sublistView(bytes, 0, bytes.length - 2);
        case 'missingFormat':
          bytes[12] = 0;
        case 'zeroData':
          ByteData.sublistView(bytes).setUint32(40, 0, Endian.little);
        case 'badAlignment':
          ByteData.sublistView(bytes).setUint16(32, 3, Endian.little);
      }
      final file = await File(
        '${directory.path}/inválido.wav',
      ).writeAsBytes(bytes);
      await expectLater(
        validatePlaybackFile(file.path, audio: true),
        throwsA(isA<PlaybackFileException>()),
      );
    });
  }
}
