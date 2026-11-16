import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'src/screens/dashboard/courier_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('🚨 Warning: .env file not found, using fallback defaults: $e');
    dotenv.testLoad(fileInput: 'LOCAL_IP=127.0.0.1');
  }

  // Use LOCAL_IP or API_URL from environment
  final localIp = dotenv.env['LOCAL_IP'] ?? '127.0.0.1';
  final apiBaseUrl = dotenv.env['API_URL'] ?? 'http://$localIp:3000';
  debugPrint('🔌 Courier App connecting to Backend API: $apiBaseUrl');

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(baseUrl: apiBaseUrl)),
      ],
      child: const CourierApp(),
    ),
  );
}

class CourierApp extends StatelessWidget {
  const CourierApp({super.key});

  static const Color hoppaOrange = Color(0xFFFF6B00);
  static const Color hoppaGreen = Color(0xFF00A651);
  static const Color surfaceSlate = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: hoppaOrange,
      primary: hoppaOrange,
      secondary: hoppaGreen,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'Hoppa Kurye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surfaceSlate,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF0F172A),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: hoppaOrange, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: hoppaOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: hoppaOrange,
          brightness: Brightness.dark,
          primary: hoppaOrange,
          secondary: hoppaGreen,
          surface: const Color(0xFF111827),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const CourierDashboardPage(),
    );
  }
}
