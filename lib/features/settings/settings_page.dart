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

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(64, 72, 64, 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
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
                'Ajuste a experiência visual, a narração da interface e o local de salvamento.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 30),

              _SettingsCard(
                title: 'Armazenamento',
                highContrast: highContrast,
                child: _SaveLocationRow(
                  highContrast: highContrast,
                  visualFocus: visualFocus,
                ),
              ),

              const SizedBox(height: 16),

              _SettingsCard(
                title: 'Audiodescrição da interface',
                highContrast: highContrast,
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      order: 5,
                      title: 'Audiodescrição',
                      description:
                          'Narra botões, telas e ações selecionadas durante a navegação pelo app.',
                      value: audioDescriptionMode,
                      highContrast: highContrast,
                      visualFocus: visualFocus,
                      onChanged: onAudioDescriptionModeChanged,
                    ),

                    if (audioDescriptionMode) ...[
                      const SizedBox(height: 18),
                      _SoftDivider(highContrast: highContrast),
                      const SizedBox(height: 18),

                      _SliderSettingRow(
                        order: 6,
                        title: 'Volume da narração',
                        value: narrationVolume,
                        highContrast: highContrast,
                        onChanged: onNarrationVolumeChanged,
                      ),

                      const SizedBox(height: 14),

                      _SliderSettingRow(
                        order: 7,
                        title: 'Velocidade da fala',
                        value: speechSpeed,
                        highContrast: highContrast,
                        onChanged: onSpeechSpeedChanged,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SettingsCard(
                title: 'Acessibilidade visual',
                highContrast: highContrast,
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      order: 8,
                      title: 'Foco visual',
                      description:
                          'Mostra bordas de destaque nos elementos selecionados por Tab.',
                      value: visualFocus,
                      highContrast: highContrast,
                      visualFocus: visualFocus,
                      onChanged: onVisualFocusChanged,
                    ),

                    const SizedBox(height: 18),

                    _SwitchSettingRow(
                      order: 9,
                      title: 'Alto contraste',
                      description:
                          'Remove gradientes e usa cores fortes para melhorar a leitura.',
                      value: highContrast,
                      highContrast: highContrast,
                      visualFocus: visualFocus,
                      onChanged: onHighContrastChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SettingsCard(
                title: 'Sobre',
                highContrast: highContrast,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentFor(highContrast),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.highContrast,
    required this.child,
  });

  final String title;
  final bool highContrast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final panel = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border,
          width: highContrast ? 2 : 1,
        ),
        boxShadow: [
          if (!highContrast)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!highContrast)
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )
              else
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.accentFor(highContrast),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

              const SizedBox(width: 10),

              Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

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
          child: _GradientButton(
            label: 'Procurar',
            icon: Icons.folder_open,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onPressed: () {
              // Depois: abrir seletor de pasta.
            },
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
    required this.visualFocus,
    required this.onChanged,
  });

  final double order;
  final String title;
  final String description;
  final bool value;
  final bool highContrast;
  final bool visualFocus;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
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
          child: _GradientSwitch(
            value: value,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onChanged: onChanged,
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
    required this.value,
    required this.highContrast,
    required this.onChanged,
  });

  final double order;
  final String title;
  final double value;
  final bool highContrast;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 24),

        SizedBox(
          width: 310,
          child: Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(order),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:
                          highContrast ? accent : AppColors.gradientMiddle,
                      inactiveTrackColor:
                          secondary.withValues(alpha: highContrast ? 0.4 : 0.18),
                      thumbColor:
                          highContrast ? accent : AppColors.gradientStart,
                      overlayColor: accent.withValues(alpha: 0.16),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: value,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: 46,
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

class _GradientSwitch extends StatefulWidget {
  const _GradientSwitch({
    required this.value,
    required this.highContrast,
    required this.visualFocus,
    required this.onChanged,
  });

  final bool value;
  final bool highContrast;
  final bool visualFocus;
  final ValueChanged<bool> onChanged;

  @override
  State<_GradientSwitch> createState() => _GradientSwitchState();
}

class _GradientSwitchState extends State<_GradientSwitch> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);

    return FocusableActionDetector(
      onShowFocusHighlight: (value) {
        setState(() {
          focused = value;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onChanged(!widget.value);
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        checked: widget.value,
        child: GestureDetector(
          onTap: () => widget.onChanged(!widget.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 56,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: widget.highContrast
                  ? (widget.value ? accent : Colors.black)
                  : null,
              gradient: widget.highContrast
                  ? null
                  : widget.value
                      ? AppColors.mainGradient
                      : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.visualFocus && focused
                    ? accent
                    : widget.value
                        ? accent
                        : border,
                width: widget.visualFocus && focused ? 3 : 1,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment:
                  widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.highContrast
                      ? (widget.value ? Colors.black : Colors.white)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.highContrast,
    required this.visualFocus,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: highContrast ? accent : null,
            gradient: highContrast ? null : AppColors.mainGradient,
            borderRadius: BorderRadius.circular(10),
            border: visualFocus
                ? Border.all(
                    color: accent,
                    width: highContrast ? 2 : 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: highContrast ? Colors.black : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: highContrast ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider({
    required this.highContrast,
  });

  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: highContrast ? 2 : 1,
      color: AppColors.borderFor(highContrast).withValues(
        alpha: highContrast ? 1 : 0.6,
      ),
    );
  }
}