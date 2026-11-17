import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:core_shared/shared/core/services/navigation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:core_auth/core_auth.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:core_network/core_network.dart';
import 'package:core_shared/shared/core/services/notification_navigation_helper.dart';

import 'apps/consumer/services/customer_auth_service.dart';
import 'package:core_shared/shared/core/services/language_provider.dart';
import 'package:core_shared/shared/core/theme/app_theme.dart';
import 'package:core_shared/shared/core/l10n/app_localizations.dart';
import 'apps/consumer/address/delivery_provider.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'apps/consumer/business/business_provider.dart';
import 'apps/consumer/favorites/favorite_provider.dart';
import 'apps/consumer/splash/splash_page.dart';
import 'apps/consumer/orders/order_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prod build'lerde .env pakete gömülmez; yalnızca geliştirme modunda yüklenir.
  if (!kReleaseMode) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env not loaded, using dev defaults: $e");
      dotenv.testLoad(fileInput: 'LOCAL_IP=127.0.0.1');
    }
  } else {
    dotenv.testLoad(fileInput: '');
  }

  const definedSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://buikknlswbpregrsyjzh.supabase.co',
  );
  const definedSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  final supabaseUrl = kReleaseMode
      ? definedSupabaseUrl
      : (dotenv.env['SUPABASE_URL'] ?? definedSupabaseUrl);
  final supabaseAnonKey = kReleaseMode
      ? definedSupabaseAnonKey
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? definedSupabaseAnonKey);

  // Supabase yalnızca anahtar tanımlıysa başlatılır
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Supabase initialization failed: $e");
    }
  }

  FlavorConfig(name: "consumer", variables: {"flavor": "consumer"});

  NotificationNavigationHelper.onConsumerNavigate = (orderId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: orderId),
      ),
    );
  };

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();

      // App Verification bypass strictly restricted to local debug mode only
      if (kDebugMode) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
      }
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }

  await initializeDateFormatting('tr_TR', null);

  const definedApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://hoppa-backend.onrender.com',
  );
  final localIp = kReleaseMode ? '127.0.0.1' : (dotenv.env['LOCAL_IP'] ?? '127.0.0.1');
  final apiBaseUrl = kReleaseMode
      ? definedApiUrl
      : (dotenv.env['API_URL'] ?? 'http://$localIp:3000');
  debugPrint("Connecting to Backend API: $apiBaseUrl");

  runApp(riverpod.ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient(baseUrl: apiBaseUrl)),
    ],
    child: const ConsumerApp(),
  ));
}

class ConsumerApp extends riverpod.ConsumerStatefulWidget {
  const ConsumerApp({super.key});

  @override
  riverpod.ConsumerState<ConsumerApp> createState() => _ConsumerAppState();
}

class _ConsumerAppState extends riverpod.ConsumerState<ConsumerApp> {
  @override
  void initState() {
    super.initState();
    _wakeUpServer();
  }

  void _wakeUpServer() {
    ref
        .read(apiClientProvider)
        .get('/health', requiresAuth: false)
        .then((_) {
          print("Server is up and running.");
        })
        .catchError((error) {
          print("Error waking up server: $error");
        });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CustomerAuthService>(create: (_) => CustomerAuthService()),
        ChangeNotifierProvider<DeliveryProvider>(
          create: (_) => DeliveryProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<BusinessProvider>(
          create: (_) => BusinessProvider(),
        ),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => FavoriteProvider(ref),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Hoppa Consumer',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,

            locale: languageProvider.currentLocale,
            supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: AppTheme.consumerTheme,
            darkTheme: AppTheme.consumerDarkTheme,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
