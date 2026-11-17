import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/screens/dashboard/courier_dashboard.dart';

class CourierThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final courierThemeModeProvider =
    NotifierProvider<CourierThemeModeNotifier, ThemeMode>(
  CourierThemeModeNotifier.new,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Prod build'lerde .env pakete gömülmez; yalnızca geliştirme modunda yüklenir.
  if (!kReleaseMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('🚨 Warning: .env file not found, using fallback defaults: $e');
      dotenv.testLoad(fileInput: 'LOCAL_IP=127.0.0.1');
    }
  } else {
    dotenv.testLoad(fileInput: '');
  }

  const definedApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://hoppa-backend.onrender.com',
  );
  final localIp = kReleaseMode ? '127.0.0.1' : (dotenv.env['LOCAL_IP'] ?? '127.0.0.1');
  final apiBaseUrl = kReleaseMode
      ? definedApiUrl
      : (dotenv.env['API_URL'] ?? 'http://$localIp:3000');
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

class CourierApp extends ConsumerWidget {
  const CourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(courierThemeModeProvider);

    return MaterialApp(
      title: 'Hoppa Kurye',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: HoppaTheme.courierLight,
      darkTheme: HoppaTheme.courierDark,
      themeMode: themeMode,
      home: const CourierDashboardPage(),
    );
  }
}
