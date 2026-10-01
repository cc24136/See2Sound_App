import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/storage_settings_service.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../generate/generate_page.dart';
import '../library/library_page.dart';
import '../library/services/library_service.dart';
import '../settings/settings_page.dart';

enum AppPage { generate, library, settings }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final StorageSettingsService storageSettingsService;
  late final LibraryService libraryService;

  AppPage currentPage = AppPage.generate;

  bool highContrast = false;
  bool visualFocus = true;

  double narrationVolume = 0.6;
  double speechSpeed = 0.5;
  bool audioDescriptionMode = true;

  @override
  void initState() {
    super.initState();
    storageSettingsService = StorageSettingsService();
    libraryService = LibraryService();
    unawaited(_initializeServices());
  }

  Future<void> _initializeServices() async {
    try {
      await Future.wait([
        storageSettingsService.initialize(),
        libraryService.initialize(),
      ]);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao inicializar serviços locais: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  void dispose() {
    storageSettingsService.dispose();
    libraryService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (currentPage) {
      case AppPage.generate:
        page = GeneratePage(
          highContrast: highContrast,
          visualFocus: visualFocus,
          storageSettingsService: storageSettingsService,
          libraryService: libraryService,
          onOpenSettings: () {
            setState(() {
              currentPage = AppPage.settings;
            });
          },
        );
        break;

      case AppPage.library:
        page = LibraryPage(
          highContrast: highContrast,
          visualFocus: visualFocus,
          libraryService: libraryService,
          onNewVideo: () {
            setState(() {
              currentPage = AppPage.generate;
            });
          },
        );
        break;

      case AppPage.settings:
        page = SettingsPage(
          highContrast: highContrast,
          visualFocus: visualFocus,
          audioDescriptionMode: audioDescriptionMode,
          narrationVolume: narrationVolume,
          speechSpeed: speechSpeed,
          storageSettingsService: storageSettingsService,
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
