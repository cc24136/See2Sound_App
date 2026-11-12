import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see2sound_app/core/storage/storage_settings_service.dart';
import 'package:see2sound_app/features/generate/controllers/generation_controller.dart';
import 'package:see2sound_app/features/generate/generate_page.dart';
import 'package:see2sound_app/features/generate/models/audio_description_metadata.dart';
import 'package:see2sound_app/features/generate/models/generation_status.dart';
import 'package:see2sound_app/features/library/services/library_service.dart';

void main() {
  testWidgets(
    'gradiente flui com percentual parado sem reconstruir o preenchimento',
    (tester) async {
      final controller = _PanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_panel(controller, highContrast: false));
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.value, isNull);
      final fill = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final shader = tester.widget<ShaderMask>(find.byType(ShaderMask));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        tester.widget<ShaderMask>(find.byType(ShaderMask)),
        isNot(same(shader)),
      );
      expect(
        tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        ),
        same(fill),
      );
      expect(fill.value, .65);
      expect(find.text('65% concluído'), findsOneWidget);
      expect(find.textContaining('restante'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .65,
      );

      for (final state in [GenerationUiState.ready, GenerationUiState.error]) {
        controller.uiState = state;
        await tester.pumpWidget(_panel(controller, highContrast: false));
        await tester.pumpAndSettle();
        expect(find.byType(ShaderMask), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
    },
  );

  testWidgets(
    'redução de movimento interrompe o gradiente e o indicador circular',
    (tester) async {
      final controller = _PanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_panel(controller));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(_panel(controller, reduceMotion: true));
      await tester.pumpAndSettle();
      final shader = tester.widget<ShaderMask>(find.byType(ShaderMask));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.widget<ShaderMask>(find.byType(ShaderMask)), same(shader));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .65,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'exibe percentual, etapa e contagem sem anúncio percentual ao vivo',
    (tester) async {
      final controller = _PanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_panel(controller));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .65,
      );
      expect(find.text('65% concluído'), findsOneWidget);
      expect(find.text('Analisando cenas'), findsOneWidget);
      expect(find.text('2 de 8'), findsOneWidget);
      final liveRegions = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.liveRegion == true);
      expect(liveRegions, hasLength(1));
      expect((liveRegions.single.child! as Text).data, 'Analisando cenas');
    },
  );

  testWidgets(
    'backend antigo usa barra indeterminada e respeita movimento reduzido',
    (tester) async {
      final controller = _PanelController()..percent = null;
      addTearDown(controller.dispose);
      await tester.pumpWidget(_panel(controller, reduceMotion: true));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<TickerMode>(
              find
                  .ancestor(
                    of: find.byType(LinearProgressIndicator),
                    matching: find.byType(TickerMode),
                  )
                  .first,
            )
            .enabled,
        isFalse,
      );
      expect(find.textContaining('% concluído'), findsNothing);
    },
  );

  testWidgets('100% informa preparação local antes da reprodução', (
    tester,
  ) async {
    final controller = _PanelController()
      ..uiState = GenerationUiState.downloadingAudio
      ..percent = 100;
    addTearDown(controller.dispose);
    await tester.pumpWidget(_panel(controller));
    expect(find.text('100% concluído'), findsOneWidget);
    expect(
      find.text('Geração concluída. Preparando e salvando os arquivos...'),
      findsOneWidget,
    );
    expect(find.text('Reproduzir'), findsNothing);
  });

  testWidgets('conclusão mantém ações sem expor resumo técnico', (
    tester,
  ) async {
    final controller = _PanelController()..uiState = GenerationUiState.ready;
    addTearDown(controller.dispose);
    var plays = 0;
    var library = 0;
    var another = 0;
    await tester.pumpWidget(
      _panel(
        controller,
        onPlay: () => plays++,
        onOpenLibrary: () => library++,
        onGenerateAnother: () => another++,
      ),
    );
    expect(find.text('Pronto para reprodução.'), findsOneWidget);
    expect(find.text('Audiodescrição concluída'), findsNothing);
    expect(find.textContaining('descrições geradas'), findsNothing);
    expect(find.textContaining('inseridas'), findsNothing);
    expect(find.textContaining('ignoradas'), findsNothing);
    await tester.tap(find.text('Reproduzir'));
    await tester.tap(find.text('Abrir biblioteca'));
    await tester.tap(find.text('Gerar outra'));
    expect([plays, library, another], [1, 1, 1]);
  });
}

Widget _panel(
  _PanelController controller, {
  bool reduceMotion = false,
  bool highContrast = true,
  VoidCallback? onPlay,
  VoidCallback? onOpenLibrary,
  VoidCallback? onGenerateAnother,
}) => MaterialApp(
  home: Scaffold(
    body: FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GenerationStatusPanel(
        controller: controller,
        highContrast: highContrast,
        visualFocus: true,
        simplifiedInterface: true,
        reduceMotion: reduceMotion,
        onPlay: onPlay ?? () {},
        onOpenSettings: () {},
        onOpenLibrary: onOpenLibrary ?? () {},
        onGenerateAnother: onGenerateAnother ?? () {},
      ),
    ),
  ),
);

class _PanelController extends GenerationController {
  _PanelController()
    : super(
        storageSettingsService: StorageSettingsService(),
        libraryService: LibraryService(),
      );
  GenerationUiState uiState = GenerationUiState.processing;
  double? percent = 65;
  @override
  GenerationUiState get state => uiState;
  @override
  bool get isBusy =>
      uiState != GenerationUiState.ready && uiState != GenerationUiState.error;
  @override
  double? get progressPercent => percent;
  @override
  String get statusMessage => switch (uiState) {
    GenerationUiState.ready => 'Pronto para reprodução.',
    GenerationUiState.downloadingAudio =>
      'Geração concluída. Preparando e salvando os arquivos...',
    _ => 'Analisando cenas',
  };
  @override
  int get stageCurrent => 2;
  @override
  int get stageTotal => 8;
  @override
  AudioDescriptionMetadata get metadata => const AudioDescriptionMetadata(
    jobId: 'job',
    status: GenerationStatus.completed,
    totalDescriptions: 32,
    insertedDescriptions: 32,
    skippedDescriptions: 0,
    cues: [],
    audioUrl: '/audio',
  );
}
