import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'app/app.dart';
import 'shared/services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储服务
  await StorageService.init();

  runApp(
    const ProviderScope(
      child: TDTheme(
        data: TDThemeData.defaultData(),
        child: BkdmmApp(),
      ),
    ),
  );
}