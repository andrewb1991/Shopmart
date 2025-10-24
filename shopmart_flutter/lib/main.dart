import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/inventory_provider.dart';
import 'providers/saved_recipes_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carica variabili di ambiente
  try {
    // Carica .env in sviluppo e .env.production in release builds
    final envFile = kReleaseMode ? '.env.production' : '.env';
    await dotenv.load(fileName: envFile);
    debugPrint('✅ $envFile loaded successfully');
  } catch (e) {
    // Se non trova il file .env, continua comunque
    debugPrint('⚠️ Warning: .env file not found, using default values - $e');
  }

  // Inizializza la localizzazione italiana per le date
  try {
    await initializeDateFormatting('it_IT', null);
    debugPrint('✅ Date formatting initialized');
  } catch (e) {
    debugPrint('⚠️ Warning: Date formatting initialization failed - $e');
  }

  // Inizializza il servizio notifiche
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Warning: Notification service initialization failed - $e');
  }

  // Cattura errori non gestiti
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SavedRecipesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Shopmart - Magazzino Casa',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('it', 'IT'),
              Locale('en', 'US'),
            ],
            locale: const Locale('it', 'IT'),
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.grey[50],
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.grey[900],
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              cardTheme: CardThemeData(
                elevation: 2,
                color: Colors.grey[850],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show AuthScreen if not authenticated, MainNavigationScreen if authenticated
        return authProvider.isAuthenticated
            ? const MainNavigationScreen()
            : const AuthScreen();
      },
    );
  }
}
