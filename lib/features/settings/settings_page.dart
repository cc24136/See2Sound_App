import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/page_container.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/setting_panel.dart';

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
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Configurações',
            subtitle: 'Ajuste acessibilidade, narração e comportamento do app.',
            highContrast: highContrast,
          ),

          const SizedBox(height: 24),

          SettingPanel(
            highContrast: highContrast,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Local de salvamento',
                    style: TextStyle(
                      color: AppColors.textPrimaryFor(highContrast),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(8),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Procurar...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentFor(highContrast),
                      foregroundColor:
                          highContrast ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SettingPanel(
            highContrast: highContrast,
            child: Column(
              children: [
                _SwitchRow(
                  order: 9,
                  label: 'Modo audiodescrição',
                  value: audioDescriptionMode,
                  highContrast: highContrast,
                  onChanged: onAudioDescriptionModeChanged,
                ),
                const SizedBox(height: 12),
                _SliderRow(
                  order: 10,
                  label: 'Volume da narração',
                  value: narrationVolume,
                  highContrast: highContrast,
                  onChanged: onNarrationVolumeChanged,
                ),
                const SizedBox(height: 12),
                _SliderRow(
                  order: 11,
                  label: 'Velocidade da fala',
                  value: speechSpeed,
                  highContrast: highContrast,
                  onChanged: onSpeechSpeedChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SettingPanel(
            highContrast: highContrast,
            child: _SwitchRow(
              order: 12,
              label: 'Foco visual',
              value: visualFocus,
              highContrast: highContrast,
              onChanged: onVisualFocusChanged,
            ),
          ),

          const SizedBox(height: 14),

          SettingPanel(
            highContrast: highContrast,
            child: _SwitchRow(
              order: 13,
              label: 'Alto contraste',
              value: highContrast,
              highContrast: highContrast,
              onChanged: onHighContrastChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.order,
    required this.label,
    required this.value,
    required this.highContrast,
    required this.onChanged,
  });

  final double order;
  final String label;
  final bool value;
  final bool highContrast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimaryFor(highContrast),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FocusTraversalOrder(
          order: NumericFocusOrder(order),
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.order,
    required this.label,
    required this.value,
    required this.highContrast,
    required this.onChanged,
  });

  final double order;
  final String label;
  final double value;
  final bool highContrast;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimaryFor(highContrast),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 260,
          child: FocusTraversalOrder(
            order: NumericFocusOrder(order),
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: accent,
              inactiveColor: AppColors.borderFor(highContrast),
            ),
          ),
        ),
      ],
    );
  }
}