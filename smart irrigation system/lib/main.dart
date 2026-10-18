import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase was already initialized or options differ, print notice
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const SmartIrrigationApp());
}

class SmartIrrigationApp extends StatefulWidget {
  const SmartIrrigationApp({super.key});

  @override
  State<SmartIrrigationApp> createState() => _SmartIrrigationAppState();
}

class _SmartIrrigationAppState extends State<SmartIrrigationApp> {
  // Theme state: defaults to dark mode for crisp modern aesthetic
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Primary green brand color tailored for smart agriculture
    const seedColor = Color(0xFF2E7D32);

    return MaterialApp(
      title: 'Smart Irrigation',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Light Theme (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),

      // Dark Theme (Material 3)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1320),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF0B1320),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),

      home: DashboardScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
