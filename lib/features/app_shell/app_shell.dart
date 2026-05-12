import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../generate/generate_page.dart';
import '../library/library_page.dart';
import '../settings/settings_page.dart';

enum AppPage {
  generate,
  library,
  settings,
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage currentPage = AppPage.generate;

  bool highContrast = false;
  bool visualFocus = true;

  double narrationVolume = 0.6;
  double speechSpeed = 0.5;
  bool audioDescriptionMode = true;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (currentPage) {
      case AppPage.generate:
        page = GeneratePage(
          highContrast: highContrast,
          visualFocus: visualFocus,
        );
        break;

      case AppPage.library:
        page = LibraryPage(
          highContrast: highContrast,
          visualFocus: visualFocus,
        );
        break;

      case AppPage.settings:
        page = SettingsPage(
          highContrast: highContrast,
          visualFocus: visualFocus,
          audioDescriptionMode: audioDescriptionMode,
          narrationVolume: narrationVolume,
          speechSpeed: speechSpeed,
          onHighContrastChanged: (value) {
            setState(() {
              highContrast = value;
            });
          },
          onVisualFocusChanged: (value) {
            setState(() {
              visualFocus = value;
            });
          },
          onAudioDescriptionModeChanged: (value) {
            setState(() {
              audioDescriptionMode = value;
            });
          },
          onNarrationVolumeChanged: (value) {
            setState(() {
              narrationVolume = value;
            });
          },
          onSpeechSpeedChanged: (value) {
            setState(() {
              speechSpeed = value;
            });
          },
        );
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(highContrast),
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            AppSidebar(
              currentPage: currentPage,
              highContrast: highContrast,
              visualFocus: visualFocus,
              onChangePage: (page) {
                setState(() {
                  currentPage = page;
                });
              },
            ),
            Expanded(
              child: Container(
                color: AppColors.backgroundFor(highContrast),
                child: page,
              ),
            ),
          ],
        ),
      ),
    );
  }
}