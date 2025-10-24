import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralizza la configurazione degli endpoint API.
///
/// Legge le variabili d'ambiente `API_BASE_URL` o `API_URL` se presenti.
/// In mancanza di valori, usa `localhost` in debug e il dominio production in release.
class AppConfig {
  /// Base URL senza suffisso `/api` (es. http://localhost:5001 o https://shopmart-be.up.railway.app)
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      var url = envUrl.trim();
      if (url.endsWith('/')) url = url.substring(0, url.length - 1);
      // If env contains /api we still return it trimmed — caller can use apiUrl if needed
      return url;
    }

    // In produzione (release) usiamo il dominio deployato
    if (kReleaseMode) return 'https://shopmart-be.up.railway.app';

    // Default per lo sviluppo locale
    return 'http://localhost:5001';
  }

  /// URL con suffisso `/api` (es. http://localhost:5001/api)
  static String get apiUrl {
    final b = baseUrl;
    if (b.endsWith('/api')) return b;
    return '$b/api';
  }
}
