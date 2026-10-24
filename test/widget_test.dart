import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see2sound_app/shared/widgets/upload_panel.dart';
import 'package:flutter/semantics.dart';
import 'dart:ui' show Tristate;
import 'package:see2sound_app/features/generate/generate_page.dart';

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
  testWidgets('navegação preserva o estado da tela de geração', (tester) async {
    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(GeneratePage));
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerar audiodescrição'));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GeneratePage)), same(state));
  });

  testWidgets('switch de alto contraste expõe ação de ativação ao leitor', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    final toggle = find.byType(SwitchListTile).first;
    await tester.ensureVisible(toggle);
    final node = tester.getSemantics(toggle);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      node.getSemanticsData().flagsCollection.isToggled != Tristate.none,
      isTrue,
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    semantics.dispose();
  });

  testWidgets('telas em celular estreito com texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'see2sound.accessibility.textSize': 'extraLarge',
    });
    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();
    for (final name in [
      'Configurações',
      'Suas audiodescrições',
      'Gerar audiodescrição',
    ]) {
      await tester.tap(find.byTooltip(name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('mantém navegação em janela baixa e fonte do sistema a 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final settings = find.byTooltip('Configurações');
    await tester.ensureVisible(settings);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('seletor oferece uma ação semântica e ativação por teclado', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadPanel(
            onTap: () => activations++,
            highContrast: false,
            visualFocus: true,
          ),
        ),
      ),
    );
    final panel = find.byType(UploadPanel);
    final node = tester.getSemantics(panel);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 2);
    semantics.dispose();
  });
}
