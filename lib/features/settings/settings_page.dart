import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
    required this.audioDescriptionMode,
    required this.narrationVolume,
    required this.speechSpeed,
    required this.onHighContrastChanged,
    required this.onVisualFocusChanged,
    required this.onAudioDescriptionModeChanged,
    required this.onNarrationVolumeChanged,
    required this.onSpeechSpeedChanged,
  });

  final bool highContrast;
  final bool visualFocus;
  final bool audioDescriptionMode;
  final double narrationVolume;
  final double speechSpeed;

  final ValueChanged<bool> onHighContrastChanged;
  final ValueChanged<bool> onVisualFocusChanged;
  final ValueChanged<bool> onAudioDescriptionModeChanged;
  final ValueChanged<double> onNarrationVolumeChanged;
  final ValueChanged<double> onSpeechSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(64, 72, 64, 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações',
                style: TextStyle(
                  color: text,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Personalize o comportamento, a narração e os recursos de acessibilidade do See2Sound.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 17,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 30),

              _SettingsSection(
                title: 'Armazenamento',
                description:
                    'Defina onde os arquivos processados e audiodescrições serão salvos.',
                highContrast: highContrast,
                child: _SaveLocationRow(
                  highContrast: highContrast,
                  visualFocus: visualFocus,
                ),
              ),

              const SizedBox(height: 18),

              _SettingsSection(
                title: 'Audiodescrição',
                description:
                    'Controle a narração gerada e os ajustes principais de áudio.',
                highContrast: highContrast,
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      order: 5,
                      title: 'Modo audiodescrição',
                      description:
                          'Ativa a geração de narração descritiva para os vídeos importados.',
                      value: audioDescriptionMode,
                      highContrast: highContrast,
                      onChanged: onAudioDescriptionModeChanged,
                    ),

                    const SizedBox(height: 18),

                    _SliderSettingRow(
                      order: 6,
                      title: 'Volume da narração',
                      description: 'Define o volume da voz gerada.',
                      value: narrationVolume,
                      highContrast: highContrast,
                      onChanged: onNarrationVolumeChanged,
                    ),

                    const SizedBox(height: 18),

                    _SliderSettingRow(
                      order: 7,
                      title: 'Velocidade da fala',
                      description:
                          'Ajusta a velocidade da narração da audiodescrição.',
                      value: speechSpeed,
                      highContrast: highContrast,
                      onChanged: onSpeechSpeedChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _SettingsSection(
                title: 'Acessibilidade',
                description:
                    'Ajustes visuais para facilitar o uso por teclado e melhorar contraste.',
                highContrast: highContrast,
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      order: 8,
                      title: 'Foco visual',
                      description:
                          'Exibe bordas de destaque em botões e painéis selecionados pelo teclado.',
                      value: visualFocus,
                      highContrast: highContrast,
                      onChanged: onVisualFocusChanged,
                    ),

                    const SizedBox(height: 18),

                    _SwitchSettingRow(
                      order: 9,
                      title: 'Alto contraste',
                      description:
                          'Troca a interface para cores mais fortes e sem gradientes.',
                      value: highContrast,
                      highContrast: highContrast,
                      onChanged: onHighContrastChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _SettingsSection(
                title: 'Sobre',
                description: 'Informações gerais da aplicação.',
                highContrast: highContrast,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: accent,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'See2Sound ver 0.1 — aplicação em desenvolvimento para geração de audiodescrição contextualizada.',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.description,
    required this.highContrast,
    required this.child,
  });

  final String title;
  final String description;
  final bool highContrast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final panel = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: highContrast ? 2 : 1,
        ),
        boxShadow: [
          if (!highContrast)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            description,
            style: TextStyle(
              color: secondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}

class _SaveLocationRow extends StatelessWidget {
  const _SaveLocationRow({
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final border = AppColors.borderFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundFor(highContrast),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: highContrast ? 2 : 1,
              ),
            ),
            child: Text(
              'Nenhuma pasta selecionada',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: secondary,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        FocusTraversalOrder(
          order: const NumericFocusOrder(4),
          child: ElevatedButton.icon(
            onPressed: () {
              // Depois: abrir seletor de pasta.
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Procurar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: highContrast ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: visualFocus
                    ? BorderSide(
                        color: accent,
                        width: highContrast ? 2 : 1,
                      )
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchSettingRow extends StatelessWidget {
  const _SwitchSettingRow({
    required this.order,
    required this.title,
    required this.description,
    required this.value,
    required this.highContrast,
    required this.onChanged,
  });

  final double order;
  final String title;
  final String description;
  final bool value;
  final bool highContrast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: _SettingTextBlock(
            title: title,
            description: description,
            highContrast: highContrast,
          ),
        ),

        const SizedBox(width: 18),

        FocusTraversalOrder(
          order: NumericFocusOrder(order),
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: highContrast ? Colors.black : Colors.white,
            activeTrackColor: accent,
            inactiveThumbColor: text,
            inactiveTrackColor: secondary.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class _SliderSettingRow extends StatelessWidget {
  const _SliderSettingRow({
    required this.order,
    required this.title,
    required this.description,
    required this.value,
    required this.highContrast,
    required this.onChanged,
  });

  final double order;
  final String title;
  final String description;
  final double value;
  final bool highContrast;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: _SettingTextBlock(
            title: title,
            description: description,
            highContrast: highContrast,
          ),
        ),

        const SizedBox(width: 24),

        SizedBox(
          width: 280,
          child: Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(order),
                  child: Slider(
                    value: value,
                    onChanged: onChanged,
                    activeColor: accent,
                    inactiveColor: secondary.withValues(alpha: 0.25),
                  ),
                ),
              ),

              SizedBox(
                width: 44,
                child: Text(
                  '${(value * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTextBlock extends StatelessWidget {
  const _SettingTextBlock({
    required this.title,
    required this.description,
    required this.highContrast,
  });

  final String title;
  final String description;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: secondary,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}