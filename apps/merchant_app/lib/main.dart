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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:core_shared/shared/core/services/notification_navigation_helper.dart';
import 'package:core_shared/shared/core/services/language_provider.dart';
import 'package:core_shared/shared/core/l10n/app_localizations.dart';
import 'package:core_shared/shared/core/theme/app_theme.dart';
import 'package:core_shared/shared/core/config/app_config.dart';
import 'apps/merchant/auth/merchant_auth_wrapper.dart';
import 'apps/merchant/merchant_order_list_page.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("🚨 Warning: .env file not found, using fallback defaults: $e");
    dotenv.testLoad(fileInput: 'LOCAL_IP=127.0.0.1');
  }

  FlavorConfig(name: "merchant", variables: {"flavor": "merchant"});

  NotificationNavigationHelper.onMerchantNavigate = (orderId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => MerchantOrderListPage(orderId: orderId),
      ),
    );
  };

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();

      if (!AppConfig.isProduction) {
        FirebaseAuth.instance.useAuthEmulator(AppConfig.localHostIp, 9300);
        FirebaseFirestore.instance.useFirestoreEmulator(
          AppConfig.localHostIp,
          8080,
        );
      }
    } catch (e) {
      debugPrint("🚨 Firebase initialization failed: $e");
    }
  }

  await initializeDateFormatting('tr_TR', null);

  final localIp = dotenv.env['LOCAL_IP'] ?? '127.0.0.1';
  final apiBaseUrl = dotenv.env['API_URL'] ?? 'http://$localIp:3000';
  print("🔌 Connecting to Backend API: $apiBaseUrl");

  runApp(riverpod.ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient(baseUrl: apiBaseUrl)),
    ],
    child: const MerchantApp(),
  ));
}

class MerchantApp extends riverpod.ConsumerStatefulWidget {
  const MerchantApp({super.key});

  @override
  riverpod.ConsumerState<MerchantApp> createState() => _MerchantAppState();
}

class _MerchantAppState extends riverpod.ConsumerState<MerchantApp> {
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
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Hoppa Merchant',
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

            theme: AppTheme.merchantTheme,
            home: const MerchantAuthWrapper(),
          );
        },
      ),
    );
  }
}
