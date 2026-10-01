import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('exibe a tela inicial de geração', (tester) async {
    await tester.pumpWidget(const See2SoundApp());
    await tester.pump();

    expect(find.text('Gerar audiodescrição'), findsWidgets);
    expect(find.text('Selecionar vídeo'), findsOneWidget);
  });

  testWidgets('não apresenta overflow em janela compacta com texto ampliado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'see2sound.accessibility.textSize': 'extraLarge',
    });
    tester.view.physicalSize = const Size(620, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Selecionar vídeo'), findsOneWidget);
  });
}
