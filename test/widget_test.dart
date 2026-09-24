import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/app.dart';

void main() {
  testWidgets('exibe a tela inicial de geração', (tester) async {
    await tester.pumpWidget(const See2SoundApp());

    expect(find.text('Bem-vindo ao See2Sound'), findsOneWidget);
    expect(find.text('Importar Arquivo'), findsOneWidget);
  });
}
