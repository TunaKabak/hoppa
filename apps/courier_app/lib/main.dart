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
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("🚨 Warning: .env file not found, using fallback defaults: $e");
    dotenv.testLoad(fileInput: 'LOCAL_IP=127.0.0.1');
  }

  // Use LOCAL_IP or API_URL from environment
  final localIp = dotenv.env['LOCAL_IP'] ?? '127.0.0.1';
  final apiBaseUrl = dotenv.env['API_URL'] ?? 'http://$localIp:3000';
  debugPrint("🔌 Courier App connecting to Backend API: $apiBaseUrl");

  runApp(ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient(baseUrl: apiBaseUrl)),
    ],
    child: const CourierApp(),
  ));
}

class CourierApp extends StatelessWidget {
  const CourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoppa Kurye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A651), // Vibrant green matching Hoppa branding
          primary: const Color(0xFF00A651),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const CourierDashboardPage(),
    );
  }
}
