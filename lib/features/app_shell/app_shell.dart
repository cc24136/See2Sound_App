import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/accessibility/interface_narration_service.dart';
import '../../core/config/api_settings_service.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/storage/storage_settings_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/theme/app_theme.dart';
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
  late final AppSettingsController appSettings;
  late final InterfaceNarrationService narrationService;
  late final ApiSettingsService apiSettingsService;

  AppPage currentPage = AppPage.generate;

  @override
  void initState() {
    super.initState();
    storageSettingsService = StorageSettingsService();
    libraryService = LibraryService();
    appSettings = AppSettingsController()..addListener(_refresh);
    narrationService = InterfaceNarrationService(appSettings);
    apiSettingsService = ApiSettingsService();
    unawaited(_initializeServices());
  }

  Future<void> _initializeServices() async {
    try {
      await Future.wait([
        storageSettingsService.initialize(),
        libraryService.initialize(),
        appSettings.initialize(),
        apiSettingsService.initialize(),
      ]);
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao inicializar serviços locais: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  void dispose() {
    unawaited(narrationService.stop());
    appSettings
      ..removeListener(_refresh)
      ..dispose();
    storageSettingsService.dispose();
    libraryService.dispose();
    apiSettingsService.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = appSettings.highContrast;
    final visualFocus = appSettings.visualFocus;
    final pages = <Widget>[
      GeneratePage(
        highContrast: highContrast,
        visualFocus: visualFocus,
        storageSettingsService: storageSettingsService,
        libraryService: libraryService,
        reduceMotion: appSettings.reduceMotion,
        simplifiedInterface: appSettings.simplifiedInterface,
        narrationService: narrationService,
        apiSettingsService: apiSettingsService,
        onOpenSettings: () {
          setState(() {
            currentPage = AppPage.settings;
          });
        },
        onOpenLibrary: () {
          setState(() => currentPage = AppPage.library);
        },
      ),
      LibraryPage(
        highContrast: highContrast,
        visualFocus: visualFocus,
        libraryService: libraryService,
        reduceMotion: appSettings.reduceMotion,
        simplifiedInterface: appSettings.simplifiedInterface,
        narrationService: narrationService,
        onNewVideo: () {
          setState(() {
            currentPage = AppPage.generate;
          });
        },
      ),
      SettingsPage(
        settings: appSettings,
        storageSettingsService: storageSettingsService,
        apiSettingsService: apiSettingsService,
        narrationService: narrationService,
      ),
    ];

    final mediaQuery = MediaQuery.of(context);
    final effectiveScale =
        mediaQuery.textScaler.scale(1) * appSettings.textSize.scale;
    return Theme(
      data: AppTheme.dark(highContrast: highContrast),
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(effectiveScale),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactSidebar =
                constraints.maxWidth < AppBreakpoints.sidebarCompact;
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
                      compact: compactSidebar,
                      reduceMotion: appSettings.reduceMotion,
                      simplifiedInterface: appSettings.simplifiedInterface,
                      onChangePage: (selectedPage) {
                        setState(() => currentPage = selectedPage);
                      },
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppColors.backgroundFor(highContrast),
                        child: IndexedStack(
                          index: currentPage.index,
                          children: pages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
