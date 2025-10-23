import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // IMPORTANTE: Sostituisci con il tuo Web Client ID da Google Cloud Console
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5001';

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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utente ha annullato
        return null;
      }

      // Invia dati al backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'googleId': googleUser.id,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'firstName': googleUser.displayName?.split(' ').first,
          'lastName': googleUser.displayName?.split(' ').skip(1).join(' '),
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
        throw 'Errore durante l\'autenticazione con Google';
      }
    } catch (e) {
      throw 'Errore durante l\'accesso con Google: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
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
