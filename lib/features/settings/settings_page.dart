import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/accessibility/interface_narration_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/storage/storage_settings_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/section_title.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.storageSettingsService,
  });

  final AppSettingsController settings;
  final StorageSettingsService storageSettingsService;

  Future<void> _selectStorageDirectory(BuildContext context) async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Escolha onde salvar as audiodescrições',
      );
      if (selectedPath == null) return;
      await storageSettingsService.setDirectoryPath(selectedPath);
      if (!context.mounted) return;
      _showMessage(context, 'Pasta de armazenamento atualizada.');
      await InterfaceNarrationService(
        settings,
      ).announce(context, 'Pasta de armazenamento atualizada.');
    } on StorageSettingsException catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao selecionar pasta: $error');
      debugPrint('$stackTrace');
      if (context.mounted) _showMessage(context, error.message);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao abrir seletor de pasta: $error');
      debugPrint('$stackTrace');
      if (context.mounted) {
        _showMessage(
          context,
          'Não foi possível selecionar a pasta. Verifique a permissão e tente novamente.',
        );
      }
    }
  }

  Future<void> _openStorageDirectory(BuildContext context) async {
    final path = storageSettingsService.directoryPath;
    if (path == null) return;
    try {
      if (!await Directory(path).exists()) {
        throw const StorageSettingsException(
          'A pasta selecionada não está mais disponível.',
        );
      }
      late final ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer.exe', [path]);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [path]);
      } else {
        throw const StorageSettingsException(
          'Abrir pasta não está disponível nesta plataforma.',
        );
      }
      if (result.exitCode != 0) {
        throw const StorageSettingsException(
          'Não foi possível abrir a pasta selecionada.',
        );
      }
    } on StorageSettingsException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao abrir pasta: $error');
      debugPrint('$stackTrace');
      if (context.mounted) {
        _showMessage(context, 'Não foi possível abrir a pasta selecionada.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = settings.highContrast;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding(constraints.maxWidth),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: 'Configurações',
                    subtitle:
                        'Personalize leitura, navegação, movimento, áudio e armazenamento.',
                    highContrast: highContrast,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsSection(
                    title: 'Armazenamento',
                    icon: Icons.folder_outlined,
                    settings: settings,
                    child: ListenableBuilder(
                      listenable: storageSettingsService,
                      builder: (context, _) => _StorageSetting(
                        path: storageSettingsService.directoryPath,
                        onChoose: () => _selectStorageDirectory(context),
                        onOpen: storageSettingsService.hasDirectory
                            ? () => _openStorageDirectory(context)
                            : null,
                      ),
                    ),
                  ),
                  _SettingsSection(
                    title: 'Acessibilidade visual',
                    icon: Icons.visibility_outlined,
                    settings: settings,
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: 'Alto contraste',
                          description:
                              'Usa fundo preto, bordas claras e cores de estado mais intensas.',
                          value: settings.highContrast,
                          onChanged: settings.setHighContrast,
                        ),
                        const _SettingDivider(),
                        _SwitchRow(
                          title: 'Foco visual',
                          description:
                              'Destaca somente o controle que está com foco de teclado.',
                          value: settings.visualFocus,
                          onChanged: settings.setVisualFocus,
                        ),
                        const _SettingDivider(),
                        _SwitchRow(
                          title: 'Interface simplificada',
                          description:
                              'Reduz sombras, gradientes e efeitos decorativos sem esconder funções.',
                          value: settings.simplifiedInterface,
                          onChanged: settings.setSimplifiedInterface,
                        ),
                      ],
                    ),
                  ),
                  _SettingsSection(
                    title: 'Texto e interface',
                    icon: Icons.text_fields,
                    settings: settings,
                    child: _ChoiceSetting<AppTextSize>(
                      title: 'Tamanho do texto',
                      description: 'Ajusta o texto em todo o aplicativo.',
                      value: settings.textSize,
                      values: AppTextSize.values,
                      label: (value) => value.label,
                      onChanged: settings.setTextSize,
                    ),
                  ),
                  _SettingsSection(
                    title: 'Movimento e animações',
                    icon: Icons.motion_photos_off_outlined,
                    settings: settings,
                    child: _SwitchRow(
                      title: 'Reduzir animações',
                      description:
                          'Remove transições e movimentos que não são essenciais.',
                      value: settings.reduceMotion,
                      onChanged: settings.setReduceMotion,
                    ),
                  ),
                  _SettingsSection(
                    title: 'Áudio',
                    icon: Icons.volume_up_outlined,
                    settings: settings,
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: 'Audiodescrição da interface',
                          description:
                              'Anuncia mudanças importantes, erros e conclusões. Não narra movimentos do mouse.',
                          value: settings.interfaceNarration,
                          onChanged: settings.setInterfaceNarration,
                        ),
                        if (settings.interfaceNarration) ...[
                          const _SettingDivider(),
                          _SliderSetting(
                            title: 'Volume da narração',
                            semanticValue:
                                '${(settings.narrationVolume * 100).round()} por cento',
                            value: settings.narrationVolume,
                            min: 0,
                            max: 1,
                            divisions: 10,
                            valueLabel:
                                '${(settings.narrationVolume * 100).round()}%',
                            onChanged: settings.setNarrationVolume,
                          ),
                          const _SettingDivider(),
                          _ChoiceSetting<double>(
                            title: 'Velocidade da fala',
                            description:
                                'Define a velocidade dos anúncios adicionais.',
                            value: settings.speechSpeed,
                            values: const [0.75, 1, 1.25, 1.5],
                            label: (value) => '${value}x',
                            onChanged: settings.setSpeechSpeed,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SettingsSection(
                    title: 'Navegação',
                    icon: Icons.keyboard_alt_outlined,
                    settings: settings,
                    child: const _ShortcutList(),
                  ),
                  _SettingsSection(
                    title: 'Sobre',
                    icon: Icons.info_outline,
                    settings: settings,
                    child: const Text(
                      'See2Sound versão 1.0 — geração, reprodução e organização de audiodescrições com foco em acessibilidade.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.settings,
    required this.child,
  });

  final String title;
  final IconData icon;
  final AppSettingsController settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highContrast = settings.highContrast;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        highContrast: highContrast,
        simplified: settings.simplifiedInterface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: AppColors.accentFor(highContrast),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textPrimaryFor(highContrast),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _StorageSetting extends StatelessWidget {
  const _StorageSetting({
    required this.path,
    required this.onChoose,
    required this.onOpen,
  });

  final String? path;
  final VoidCallback onChoose;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final hasPath = path != null && path!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Local das audiodescrições', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          readOnly: true,
          label: hasPath
              ? 'Pasta selecionada: $path'
              : 'Nenhuma pasta selecionada',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: AppRadius.control,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: SelectableText(
              path ?? 'Nenhuma pasta selecionada',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: onChoose,
              icon: const Icon(Icons.folder_open),
              label: Text(hasPath ? 'Alterar' : 'Escolher pasta'),
            ),
            if (hasPath)
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir pasta'),
              ),
          ],
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      hint: description,
      child: ExcludeSemantics(
        child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: AppTypography.label),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(description, style: AppTypography.body),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChoiceSetting<T> extends StatelessWidget {
  const _ChoiceSetting({
    required this.title,
    required this.description,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final String description;
  final T value;
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xxs),
        Text(description, style: AppTypography.body),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: values
              .map(
                (option) => ChoiceChip(
                  label: Text(label(option)),
                  selected: option == value,
                  onSelected: (_) => onChanged(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.semanticValue,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String title;
  final String semanticValue;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.label)),
            Text(valueLabel, style: AppTypography.label),
          ],
        ),
        Semantics(
          label: title,
          value: semanticValue,
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ShortcutList extends StatelessWidget {
  const _ShortcutList();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      ('Tab', 'Próximo elemento'),
      ('Shift + Tab', 'Elemento anterior'),
      ('Enter', 'Ativar controle'),
      ('Espaço', 'Ativar ou reproduzir/pausar no player'),
      ('← / →', 'Retroceder ou avançar no player'),
      ('Esc', 'Fechar diálogo ou menu'),
    ];
    return Column(
      children: [
        for (final shortcut in shortcuts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(shortcut.$1, style: AppTypography.label),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(shortcut.$2, style: AppTypography.body)),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(color: Theme.of(context).colorScheme.outline),
    );
  }
}
