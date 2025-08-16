import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const GanaderaSoftApp());
}

class GanaderaSoftApp extends StatelessWidget {
  const GanaderaSoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GanaderaSoft',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
