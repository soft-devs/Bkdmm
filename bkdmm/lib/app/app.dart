import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../core/i18n/i18n.dart';
import '../l10n/app_localizations.dart';
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
    final localeState = ref.watch(appLocaleProvider);

    // Get base themes
    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;

    // Apply custom accent color if set
    if (accentColor != null) {
      lightTheme = _applyAccentColor(lightTheme, accentColor, Brightness.light);
      darkTheme = _applyAccentColor(darkTheme, accentColor, Brightness.dark);
    }

    // Build TDesign theme data with custom accent color
    final tdThemeData = _buildTDThemeData(accentColor);

    // Create TDesign resource delegate for internationalization
    final tdDelegate = AppTDResourceDelegate(context);

    return TDTheme(
      data: tdThemeData,
      child: MaterialApp(
        title: 'Bkdmm',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,

        // Internationalization configuration
        locale: localeState.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,

        home: Builder(
          builder: (context) {
            // Set TDesign text delegate for internationalization
            TDTheme.setResourceBuilder(
              (context) => tdDelegate..updateContext(context),
              needAlwaysBuild: true,
            );
            return const HomeView();
          },
        ),
      ),
    );
  }

  /// Build TDesign theme data with custom brand color
  TDThemeData _buildTDThemeData(Color? accentColor) {
    if (accentColor == null) {
      return TDThemeData.defaultData();
    }

    // Create custom theme JSON with the accent color
    final hexColor = '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final themeJson = '''
    {
      "customTheme": {
        "color": {
          "brandNormalColor": "$hexColor"
        }
      }
    }
    ''';

    try {
      return TDThemeData.fromJson('customTheme', themeJson) ?? TDThemeData.defaultData();
    } catch (e) {
      // If JSON parsing fails, return default theme
      return TDThemeData.defaultData();
    }
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
