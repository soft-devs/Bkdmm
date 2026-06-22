import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import '../features/home/views/home_view.dart';

/// Application entry point with Riverpod support.
void main() {
  runApp(
    const ProviderScope(
      child: BkdmmApp(),
    ),
  );
}

/// Root application widget with theme configuration.
class BkdmmApp extends ConsumerWidget {
  const BkdmmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Add theme mode provider when settings are implemented
    final themeMode = ThemeMode.system;

    return MaterialApp(
      title: 'Bkdmm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeView(),
    );
  }
}