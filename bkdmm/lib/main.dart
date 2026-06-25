import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'shared/services/services.dart';
import 'utils/logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务 (开发环境)
  await LoggingService.init(
    config: LoggingConfig.development(),
  );

  // 初始化存储服务
  await StorageService.init();

  runApp(
    ProviderScope(
      observers: [
        // 可选: 添加 Riverpod 状态日志观察者
        // RiverpodLogObserver(
        //   logProviderAdded: true,
        //   logProviderUpdated: true,
        // ),
      ],
      child: BkdmmApp(),
    ),
  );
}