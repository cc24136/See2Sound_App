import 'package:flutter/material.dart';
import '../../shared/widgets/page_container.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/upload_panel.dart';

class GeneratePage extends StatelessWidget {
  const GeneratePage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      centerVertically: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionTitle(
            title: 'Bem-vindo ao See2Sound',
            subtitle:
                'Importe um novo arquivo para gerar uma nova audiodescrição',
            highContrast: highContrast,
            textAlign: TextAlign.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: 30),
          UploadPanel(
            highContrast: highContrast,
            visualFocus: visualFocus,
            onTap: () {
              // Depois entra o seletor de arquivo.
            },
          ),
        ],
      ),
    );
  }
}