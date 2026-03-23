import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eskadra_app/core/theme/app_theme_provider.dart';

class EskadraApp extends StatelessWidget {
  const EskadraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Eskadra App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}