import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/app_shell/app_shell.dart';

class See2SoundApp extends StatelessWidget {
    const See2SoundApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
        title: 'See2Sound',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
        );
    }
}