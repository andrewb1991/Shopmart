import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // IMPORTANTE: Sostituisci con il tuo Web Client ID da Google Cloud Console
    // Provide both clientId and serverClientId when available. Some web
    // implementations read the clientId meta tag, others prefer the
    // explicit clientId property. Supplying both is defensive.
    clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  String get baseUrl => AppConfig.baseUrl;

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
