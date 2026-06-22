import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/views/home_view.dart';
import '../shared/providers/providers.dart';
import 'app_theme.dart';

/// Application entry
class BkdmmApp extends ConsumerWidget {
  const BkdmmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeModeEnum;
    final accentColor = settings.accentColorValue;

    // Get base themes
    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;

    // Apply custom accent color if set
    if (accentColor != null) {
      lightTheme = _applyAccentColor(lightTheme, accentColor, Brightness.light);
      darkTheme = _applyAccentColor(darkTheme, accentColor, Brightness.dark);
    }

    return MaterialApp(
      title: 'Bkdmm - Data Modeling Tool',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const HomeView(),
    );
  }

  /// Apply custom accent color to theme
  ThemeData _applyAccentColor(
    ThemeData baseTheme,
    Color accentColor,
    Brightness brightness,
  ) {
    // Create a new color scheme based on the accent color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      // Update specific theme components that use primary color
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
