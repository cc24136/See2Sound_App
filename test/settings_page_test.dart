import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('configurações sem seção Servidor preservam as demais seções', (
    tester,
  ) async {
    await tester.pumpWidget(const See2SoundApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    for (final removed in [
      'Servidor',
      'Endereço da API',
      'Salvar endereço',
      'Endereço salvo',
      'Endereço da API salvo.',
    ]) {
      expect(find.text(removed), findsNothing);
    }
    expect(find.textContaining('10.0.2.2'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    for (final title in [
      'Armazenamento',
      'Acessibilidade visual',
      'Texto e interface',
      'Movimento e animações',
      'Áudio',
      'Navegação',
      'Sobre',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    final highContrast = find.widgetWithText(SwitchListTile, 'Alto contraste');
    await tester.ensureVisible(highContrast);
    await tester.tap(highContrast);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(highContrast).value, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('see2sound.accessibility.highContrast'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
