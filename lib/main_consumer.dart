import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:core_auth/core_auth.dart';

import 'apps/consumer/services/customer_auth_service.dart';
import 'shared/core/services/language_provider.dart';
import 'shared/core/theme/app_theme.dart';
import 'shared/core/l10n/app_localizations.dart';
import 'apps/consumer/address/delivery_provider.dart';
import 'shared/core/services/navigation_provider.dart';
import 'apps/consumer/business/business_provider.dart';
import 'apps/consumer/favorites/favorite_provider.dart';
import 'apps/consumer/splash/splash_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  FlavorConfig(name: "consumer", variables: {"flavor": "consumer"});

  await Firebase.initializeApp();

  // Disable App Verification for Dev/QA Testing
  if (const String.fromEnvironment('flavor') == 'consumer' ||
      const bool.fromEnvironment('dart.vm.product') == false) {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    } catch (_) {}
  }

  await initializeDateFormatting('tr_TR', null);
  runApp(const riverpod.ProviderScope(child: ConsumerApp()));
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
          create: (_) => FavoriteProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Hoppa Consumer',
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
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
