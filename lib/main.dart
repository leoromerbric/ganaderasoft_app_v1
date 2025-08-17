import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';
import 'services/offline_manager.dart';

void main() {
  runApp(const GanaderaSoftApp());
}

class GanaderaSoftApp extends StatefulWidget {
  const GanaderaSoftApp({super.key});

  @override
  State<GanaderaSoftApp> createState() => _GanaderaSoftAppState();
}

class _GanaderaSoftAppState extends State<GanaderaSoftApp> {
  @override
  void initState() {
    super.initState();
    // Start monitoring connectivity for auto-sync
    OfflineManager.startMonitoring();
  }

  @override
  void dispose() {
    OfflineManager.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
