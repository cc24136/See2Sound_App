import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/accessibility/interface_narration_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_components.dart';
import '../player/player_page.dart';
import 'models/audio_description_library_item.dart';
import 'services/library_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
    required this.libraryService,
    required this.reduceMotion,
    required this.simplifiedInterface,
    required this.narrationService,
    required this.onNewVideo,
  });

  final bool highContrast;
  final bool visualFocus;
  final LibraryService libraryService;
  final bool reduceMotion;
  final bool simplifiedInterface;
  final InterfaceNarrationService narrationService;
  final VoidCallback onNewVideo;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchController = TextEditingController();
  _LibrarySort _sort = _LibrarySort.newest;

  @override
  void initState() {
    super.initState();
    widget.libraryService.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.libraryService != widget.libraryService) {
      oldWidget.libraryService.removeListener(_refresh);
      widget.libraryService.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.libraryService.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  List<AudioDescriptionLibraryItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.libraryService.items
        .where(
          (item) =>
              query.isEmpty ||
              item.originalFilename.toLowerCase().contains(query),
        )
        .toList();
    filtered.sort(
      (a, b) => switch (_sort) {
        _LibrarySort.newest => b.createdAt.compareTo(a.createdAt),
        _LibrarySort.oldest => a.createdAt.compareTo(b.createdAt),
        _LibrarySort.name => a.originalFilename.toLowerCase().compareTo(
          b.originalFilename.toLowerCase(),
        ),
        _LibrarySort.duration => (b.duration ?? Duration.zero).compareTo(
          a.duration ?? Duration.zero,
        ),
      },
    );
    return filtered;
  }

  Future<void> _play(AudioDescriptionLibraryItem item) async {
    final videoExists = await File(item.originalVideoPath).exists();
    if (!videoExists) {
      _showMessage('O vídeo original não foi encontrado.');
      return;
    }
    final audioExists = await File(item.audioDescriptionPath).exists();
    if (!audioExists) {
      _showMessage('O arquivo de audiodescrição não foi encontrado.');
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          videoPath: item.originalVideoPath,
          audioPath: item.audioDescriptionPath,
          filename: item.originalFilename,
          highContrast: widget.highContrast,
          visualFocus: widget.visualFocus,
          backTooltip: 'Voltar para Suas audiodescrições',
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    _LibraryMenuAction action,
    AudioDescriptionLibraryItem item,
  ) async {
    switch (action) {
      case _LibraryMenuAction.play:
        await _play(item);
      case _LibraryMenuAction.openLocation:
        await _openLocation(item);
      case _LibraryMenuAction.rename:
        await _rename(item);
      case _LibraryMenuAction.exportCopy:
        await _exportCopy(item);
      case _LibraryMenuAction.remove:
        await _removeFromLibrary(item);
      case _LibraryMenuAction.delete:
        await _deleteFile(item);
    }
  }

  Future<void> _openLocation(AudioDescriptionLibraryItem item) async {
    final file = File(item.audioDescriptionPath);
    if (!await file.exists()) {
      _showMessage('O arquivo de audiodescrição não foi encontrado.');
      return;
    }

    try {
      late final ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', ['-R', file.path]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer.exe', ['/select,${file.path}']);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [file.parent.path]);
      } else {
        throw const LibraryException(
          'Abrir localização não está disponível nesta plataforma.',
        );
      }
      if (result.exitCode != 0) {
        throw LibraryException(
          'Não foi possível abrir a localização do arquivo.',
          result.stderr,
        );
      }
    } on LibraryException catch (error) {
      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao abrir localização: $error');
      debugPrint('$stackTrace');
      _showMessage('Não foi possível abrir a localização do arquivo.');
    }
  }

  Future<void> _rename(AudioDescriptionLibraryItem item) async {
    final currentName = _fileName(item.audioDescriptionPath);
    final controller = TextEditingController(
      text: currentName.toLowerCase().endsWith('.wav')
          ? currentName.substring(0, currentName.length - 4)
          : currentName,
    );
    final requestedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renomear audiodescrição'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Novo nome',
            suffixText: '.wav',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Renomear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (requestedName == null || requestedName.trim().isEmpty) return;

    try {
      final updated = await widget.libraryService.renameAudioFile(
        item,
        requestedName,
      );
      _showMessage(
        'Arquivo renomeado para ${_fileName(updated.audioDescriptionPath)}.',
      );
    } on LibraryException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _exportCopy(AudioDescriptionLibraryItem item) async {
    try {
      final destination = await FilePicker.getDirectoryPath(
        dialogTitle: 'Escolha onde copiar a audiodescrição',
      );
      if (destination == null) return;
      final copiedPath = await widget.libraryService.copyAudioFile(
        item,
        destination,
      );
      _showMessage('Cópia salva em $copiedPath');
    } on LibraryException catch (error) {
      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao selecionar destino da cópia: $error');
      debugPrint('$stackTrace');
      _showMessage('Não foi possível copiar a audiodescrição.');
    }
  }

  Future<void> _removeFromLibrary(AudioDescriptionLibraryItem item) async {
    final confirmed = await _confirm(
      title: 'Remover esta audiodescrição da biblioteca?',
      message: 'O arquivo salvo não será excluído.',
      confirmLabel: 'Remover',
    );
    if (!confirmed) return;

    try {
      await widget.libraryService.removeFromLibrary(item.id);
      _showMessage('Audiodescrição removida da biblioteca.');
    } on LibraryException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteFile(AudioDescriptionLibraryItem item) async {
    final confirmed = await _confirm(
      title: 'Excluir esta audiodescrição?',
      message:
          'Essa ação excluirá o arquivo do dispositivo e não poderá ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await widget.libraryService.deleteAudioFileAndRemove(item);
      _showMessage('Arquivo de audiodescrição excluído.');
    } on LibraryException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: Colors.redAccent)
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    unawaited(widget.narrationService.announce(context, message));
  }

  String _fileName(String path) => path.split(RegExp(r'[/\\]')).last;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final accent = AppColors.accentFor(widget.highContrast);
    final items = _visibleItems;

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding(constraints.maxWidth),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LibraryHeader(
                  highContrast: widget.highContrast,
                  visualFocus: widget.visualFocus,
                  onNewVideo: widget.onNewVideo,
                ),
                const SizedBox(height: 28),
                _LibraryToolbar(
                  controller: _searchController,
                  sort: _sort,
                  onSearchChanged: (_) => setState(() {}),
                  onSortChanged: (value) => setState(() => _sort = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  highContrast: widget.highContrast,
                  simplified: widget.simplifiedInterface,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: !widget.libraryService.isInitialized
                      ? _LoadingState(accent: accent, secondary: secondary)
                      : widget.libraryService.items.isEmpty
                      ? _EmptyLibraryState(
                          highContrast: widget.highContrast,
                          visualFocus: widget.visualFocus,
                          errorMessage: widget.libraryService.loadError,
                          onNewVideo: widget.onNewVideo,
                        )
                      : items.isEmpty
                      ? AppEmptyState(
                          icon: Icons.search_off,
                          title: 'Nenhum resultado encontrado',
                          message:
                              'Tente buscar por outro nome ou altere a ordenação.',
                          highContrast: widget.highContrast,
                        )
                      : Column(
                          children: [
                            if (constraints.maxWidth >=
                                AppBreakpoints.compact) ...[
                              _ListHeader(highContrast: widget.highContrast),
                              const SizedBox(height: 12),
                            ],
                            for (
                              int index = 0;
                              index < items.length;
                              index++
                            ) ...[
                              _AudioDescriptionTile(
                                order: 4 + index.toDouble(),
                                item: items[index],
                                highContrast: widget.highContrast,
                                visualFocus: widget.visualFocus,
                                compact:
                                    constraints.maxWidth <
                                    AppBreakpoints.compact,
                                reduceMotion: widget.reduceMotion,
                                onPrimaryAction: () => _play(items[index]),
                                onMenuAction: (action) => unawaited(
                                  _handleMenuAction(action, items[index]),
                                ),
                              ),
                              if (index != items.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'As audiodescrições geradas aparecem aqui para reprodução, organização ou exportação.',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.highContrast,
    required this.visualFocus,
    required this.onNewVideo,
  });

  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onNewVideo;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.compact;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas audiodescrições',
              style: TextStyle(
                color: text,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie seus vídeos e audiodescrições.',
              style: TextStyle(color: secondary, fontSize: 17, height: 1.3),
            ),
          ],
        );
        final button = FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: FilledButton.icon(
            onPressed: onNewVideo,
            icon: const Icon(Icons.add),
            label: const Text('Novo vídeo'),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: AppSpacing.lg),
              button,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            button,
          ],
        );
      },
    );
  }
}

enum _LibrarySort { newest, oldest, name, duration }

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.controller,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final _LibrarySort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_LibrarySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar audiodescrição',
            hintText: 'Digite o nome do vídeo',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        );
        final order = DropdownButtonFormField<_LibrarySort>(
          initialValue: sort,
          decoration: const InputDecoration(
            labelText: 'Ordenar por',
            prefixIcon: Icon(Icons.sort),
          ),
          items: const [
            DropdownMenuItem(
              value: _LibrarySort.newest,
              child: Text('Mais recentes'),
            ),
            DropdownMenuItem(
              value: _LibrarySort.oldest,
              child: Text('Mais antigas'),
            ),
            DropdownMenuItem(value: _LibrarySort.name, child: Text('Nome')),
            DropdownMenuItem(
              value: _LibrarySort.duration,
              child: Text('Duração'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
        );
        if (constraints.maxWidth < AppBreakpoints.compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: AppSpacing.sm),
              order,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: order),
          ],
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.accent, required this.secondary});

  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Carregando audiodescrições salvas',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            CircularProgressIndicator(color: accent),
            const SizedBox(height: 14),
            Text(
              'Carregando biblioteca...',
              style: TextStyle(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({
    required this.highContrast,
    required this.visualFocus,
    required this.errorMessage,
    required this.onNewVideo,
  });

  final bool highContrast;
  final bool visualFocus;
  final String? errorMessage;
  final VoidCallback onNewVideo;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);
    return Semantics(
      liveRegion: true,
      label: errorMessage ?? 'Nenhuma audiodescrição salva',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
        child: Column(
          children: [
            Icon(
              errorMessage == null
                  ? Icons.library_music_outlined
                  : Icons.error_outline,
              color: accent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Nenhuma audiodescrição ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gere sua primeira audiodescrição para encontrá-la aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onNewVideo,
              icon: const Icon(Icons.add),
              label: const Text('Gerar audiodescrição'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: highContrast ? Colors.black : Colors.white,
                side: visualFocus ? BorderSide(color: accent) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.highContrast});

  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondaryFor(highContrast);
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('Arquivo', style: style.copyWith(color: secondary)),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: style.copyWith(color: secondary)),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'Duração',
              textAlign: TextAlign.right,
              style: style.copyWith(color: secondary),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              'Ação',
              textAlign: TextAlign.center,
              style: style.copyWith(color: secondary),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

enum _LibraryMenuAction {
  play,
  openLocation,
  rename,
  exportCopy,
  remove,
  delete,
}

class _AudioDescriptionTile extends StatefulWidget {
  const _AudioDescriptionTile({
    required this.order,
    required this.item,
    required this.highContrast,
    required this.visualFocus,
    required this.compact,
    required this.reduceMotion,
    required this.onPrimaryAction,
    required this.onMenuAction,
  });

  final double order;
  final AudioDescriptionLibraryItem item;
  final bool highContrast;
  final bool visualFocus;
  final bool compact;
  final bool reduceMotion;
  final VoidCallback onPrimaryAction;
  final ValueChanged<_LibraryMenuAction> onMenuAction;

  @override
  State<_AudioDescriptionTile> createState() => _AudioDescriptionTileState();
}

class _AudioDescriptionTileState extends State<_AudioDescriptionTile> {
  bool focused = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);
    final showFocus = widget.visualFocus && focused;

    if (widget.compact) {
      return Semantics(
        container: true,
        label:
            '${widget.item.originalFilename}, audiodescrição pronta, ${_formatDuration(widget.item.duration)}',
        child: AnimatedContainer(
          duration: AppDurations.adaptive(widget.reduceMotion),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundFor(widget.highContrast),
            borderRadius: AppRadius.control,
            border: Border.all(
              color: border,
              width: widget.highContrast ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.movie_outlined, color: accent, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.originalFilename,
                          style: TextStyle(
                            color: text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Audiodescrição gerada • ${_formatDate(widget.item.createdAt)}',
                          style: TextStyle(color: secondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _LibraryMenuButton(
                    item: widget.item,
                    color: secondary,
                    onSelected: widget.onMenuAction,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  _IconText(
                    icon: Icons.check_circle_outline,
                    label: 'Pronto',
                    color: AppColors.successFor(widget.highContrast),
                  ),
                  _IconText(
                    icon: Icons.schedule,
                    label: _formatDuration(widget.item.duration),
                    color: secondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onPrimaryAction,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Reproduzir ${widget.item.originalFilename}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label:
          '${widget.item.originalFilename}, audiodescrição pronta, ${_formatDuration(widget.item.duration)}',
      child: FocusTraversalOrder(
        order: NumericFocusOrder(widget.order),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) => setState(() => focused = value),
          onShowHoverHighlight: (value) => setState(() => hovered = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPrimaryAction();
                return null;
              },
            ),
          },
          child: AnimatedContainer(
            duration: AppDurations.adaptive(widget.reduceMotion),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: hovered
                  ? AppColors.panelHover
                  : AppColors.backgroundFor(widget.highContrast),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showFocus ? accent : border,
                width: showFocus || widget.highContrast ? 3 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: widget.highContrast
                              ? LinearGradient(colors: [accent, accent])
                              : AppColors.mainGradient,
                        ),
                        child: Icon(
                          Icons.movie_outlined,
                          color: widget.highContrast
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.originalFilename,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: text,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Audiodescrição gerada • ${_formatDate(widget.item.createdAt)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: secondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Pronto',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _formatDuration(widget.item.duration),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: widget.onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: widget.highContrast
                          ? Colors.black
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reproduzir'),
                  ),
                ),
                const SizedBox(width: 8),
                _LibraryMenuButton(
                  item: widget.item,
                  color: secondary,
                  onSelected: widget.onMenuAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.icon, this.label, {this.destructive = false});

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: destructive ? Theme.of(context).colorScheme.error : null,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: destructive
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
        ),
      ],
    );
  }
}

class _LibraryMenuButton extends StatelessWidget {
  const _LibraryMenuButton({
    required this.item,
    required this.color,
    required this.onSelected,
  });

  final AudioDescriptionLibraryItem item;
  final Color color;
  final ValueChanged<_LibraryMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_LibraryMenuAction>(
      tooltip: 'Mais opções para ${item.originalFilename}',
      onSelected: onSelected,
      icon: Icon(Icons.more_vert, color: color),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _LibraryMenuAction.play,
          child: _MenuLabel(Icons.play_arrow, 'Reproduzir'),
        ),
        PopupMenuItem(
          value: _LibraryMenuAction.openLocation,
          child: _MenuLabel(Icons.folder_open, 'Abrir localização'),
        ),
        PopupMenuItem(
          value: _LibraryMenuAction.rename,
          child: _MenuLabel(Icons.drive_file_rename_outline, 'Renomear'),
        ),
        PopupMenuItem(
          value: _LibraryMenuAction.exportCopy,
          child: _MenuLabel(Icons.ios_share_outlined, 'Exportar'),
        ),
        PopupMenuItem(
          value: _LibraryMenuAction.remove,
          child: _MenuLabel(
            Icons.remove_circle_outline,
            'Remover da biblioteca',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _LibraryMenuAction.delete,
          child: _MenuLabel(
            Icons.delete_outline,
            'Excluir arquivo',
            destructive: true,
          ),
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '--:--';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final localDate = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final itemDay = DateTime(localDate.year, localDate.month, localDate.day);
  final difference = today.difference(itemDay).inDays;
  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';
  return '${localDate.day.toString().padLeft(2, '0')}/'
      '${localDate.month.toString().padLeft(2, '0')}';
}
