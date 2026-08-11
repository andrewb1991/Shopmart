import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  // Su web il clientId è letto dal meta tag in web/index.html e serverClientId
  // NON è supportato dal plugin web; su mobile passiamo clientId/serverClientId
  // dal .env così l'idToken è emesso con l'audience attesa dal backend.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb ? null : dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Stream degli utenti autenticati via pulsante GIS sul web.
  final StreamController<UserModel?> _webSignInController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get webSignInStream => _webSignInController.stream;
  bool _webInitialized = false;

  String get baseUrl => AppConfig.baseUrl;

  /// Inizializza il flusso Google su web: ascolta onCurrentUserChanged (che sul
  /// web emette un account con idToken quando l'utente usa il pulsante GIS),
  /// invia l'idToken al backend e propaga l'utente via [webSignInStream].
  /// No-op su mobile/desktop.
  void initWebGoogleSignIn() {
    if (!kIsWeb || _webInitialized) return;
    _webInitialized = true;
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account == null) return;
      try {
        final auth = await account.authentication;
        final idToken = auth.idToken;
        if (idToken == null) {
          _webSignInController.addError('idToken Google non disponibile');
          return;
        }
        final user = await _authenticateWithBackend(idToken);
        _webSignInController.add(user);
      } catch (e) {
        _webSignInController
            .addError('Errore durante l\'accesso con Google: $e');
      }
    });
    // Prova a ripristinare una sessione esistente senza interazione.
    _googleSignIn.signInSilently();
  }

  /// Invia l'idToken Google al backend (che lo verifica) e salva la sessione.
  Future<UserModel?> _authenticateWithBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: _tokenKey, value: data['token']);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return user;
    }
    String message = 'Errore durante l\'autenticazione con Google';
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['error'] != null) message = err['error'].toString();
    } catch (_) {}
    throw message;
  }

  // Registrazione con email e password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);
        final token = data['token'];

        // Salva token e dati utente
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Errore durante la registrazione';
      }
    } catch (e) {
      throw 'Errore durante la registrazione: $e';
    }
  }

  // Login con email e password
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);
        final token = data['token'];

        // Salva token e dati utente
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Errore durante l\'accesso';
      }
    } catch (e) {
      throw 'Errore durante l\'accesso: $e';
    }
  }

  // Login con Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      debugPrint('🔄 AuthService: Avvio Google sign in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      debugPrint('🔍 AuthService: googleUser = $googleUser');

      if (googleUser == null) {
        // L'utente ha annullato
        debugPrint('❌ AuthService: Google sign in annullato dall\'utente');
        return null;
      }

      // Ottieni i token OAuth (utile per inviare idToken al backend)
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint(
            '🔑 AuthService: googleAuth.idToken=${googleAuth.idToken != null} accessToken=${googleAuth.accessToken != null}');
      } catch (e) {
        debugPrint(
            '⚠️ AuthService: impossibile ottenere googleUser.authentication: $e');
      }

      // Invia dati al backend; preferiamo inviare idToken se presente
      final body = {
        if (googleAuth?.idToken != null) 'idToken': googleAuth!.idToken,
        'googleId': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'firstName': googleUser.displayName?.split(' ').first,
        'lastName': googleUser.displayName?.split(' ').skip(1).join(' '),
      };

      debugPrint(
          '📤 AuthService: invio dati al backend: keys=${body.keys.toList()}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);
        final token = data['token'];

        // Salva token e dati utente
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

        debugPrint(
            '✅ AuthService: Google sign in completato, utente salvato ${user.email}');
        return user;
      } else {
        final error = response.body;
        debugPrint(
            '❌ AuthService: backend response status=${response.statusCode} body=$error');
        throw 'Errore durante l\'autenticazione con Google';
      }
    } catch (e) {
      debugPrint('❌ AuthService: Exception in signInWithGoogle: $e');
      throw 'Errore durante l\'accesso con Google: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    debugPrint('🔄 AuthService: signOut inizio');

    try {
      debugPrint('🔐 AuthService: chiamata a GoogleSignIn.signOut()');
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ AuthService: GoogleSignIn.signOut() ha lanciato: $e');
    }

    try {
      // disconnect() revoca il consenso e rimuove l'account collegato — utile su Android
      debugPrint('🔐 AuthService: chiamata a GoogleSignIn.disconnect()');
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('⚠️ AuthService: GoogleSignIn.disconnect() ha lanciato: $e');
    }

    // Rimuovi sempre le credenziali locali (anche se Google sign out/disconnect fallisce)
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
      debugPrint('🧹 AuthService: credenziali locali rimosse');
    } catch (e) {
      debugPrint('❌ AuthService: errore rimuovendo credenziali locali: $e');
    }
  }

  // Ottieni token salvato
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Ottieni dati utente salvati
  Future<UserModel?> getSavedUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        return UserModel.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Verifica token con backend
  Future<UserModel?> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);

        // Aggiorna dati utente salvati
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

        return user;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Reset password (placeholder for future implementation)
  Future<void> resetPassword(String email) async {
    // TODO: Implementare reset password tramite backend
    throw UnimplementedError('Reset password non ancora implementato');
  }

  // Aggiorna profilo
  Future<UserModel?> updateProfile({
    required String firstName,
    required String lastName,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Token non trovato';

      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
      };

      // Aggiungi password solo se l'utente vuole cambiarla
      if (currentPassword != null && newPassword != null) {
        body['currentPassword'] = currentPassword;
        body['newPassword'] = newPassword;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);

        // Aggiorna dati utente salvati
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Errore durante l\'aggiornamento del profilo';
      }
    } catch (e) {
      throw 'Errore durante l\'aggiornamento del profilo: $e';
    }
  }
}
