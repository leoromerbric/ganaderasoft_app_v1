import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const GanaderaSoftApp());
}

class GanaderaSoftApp extends StatelessWidget {
  const GanaderaSoftApp({super.key});

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
