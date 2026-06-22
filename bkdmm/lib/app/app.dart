import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/views/home_view.dart';
import 'app_theme.dart';

/// 应用入口
class BkdmmApp extends ConsumerWidget {
  const BkdmmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Bkdmm - 数据建模工具',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeView(),
    );
  }
}