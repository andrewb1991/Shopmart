import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/inventory_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carica variabili di ambiente
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded successfully');
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
      ),
      home: ChangeNotifierProvider(
        create: (_) => InventoryProvider(),
        child: const HomeScreen(),
      ),
    );
  }
}
