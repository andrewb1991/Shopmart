import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _webSignInSub;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;

  AuthProvider() {
    _loadSavedUser();
    // Attiva il flusso Google web (pulsante GIS) e reagisce al login riuscito.
    _authService.initWebGoogleSignIn();
    _webSignInSub = _authService.webSignInStream.listen(
      (user) {
        if (user != null) {
          _user = user;
          _error = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _webSignInSub?.cancel();
    super.dispose();
  }

  // Carica utente salvato al boot
  Future<void> _loadSavedUser() async {
    try {
      debugPrint('🔄 AuthProvider: Caricamento utente salvato...');
      _user = await _authService.getSavedUser();
      debugPrint(
          '✅ AuthProvider: Utente caricato: ${_user?.email ?? "nessuno"}');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Errore nel caricamento utente: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Registrazione con email
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    debugPrint('🔄 AuthProvider: Inizio registrazione per $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📞 AuthProvider: Chiamata a AuthService.registerWithEmail');
      _user = await _authService.registerWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      debugPrint(
          '✅ AuthProvider: Registrazione completata. User: ${_user?.email}');
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e, stackTrace) {
      debugPrint('❌ AuthProvider: Errore registrazione: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login con email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login con Google
  Future<bool> signInWithGoogle() async {
    debugPrint('🔄 AuthProvider: start signInWithGoogle');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resultUser = await _authService.signInWithGoogle();
      _user = resultUser;
      debugPrint('✅ AuthProvider: signInWithGoogle resultUser=${_user?.email}');

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e, stackTrace) {
      debugPrint('❌ AuthProvider: signInWithGoogle error: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> signOut() async {
    debugPrint('🔄 AuthProvider: start signOut');
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      debugPrint('✅ AuthProvider: signOut completed, user cleared');
    } catch (e, stackTrace) {
      debugPrint('❌ AuthProvider: signOut error: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Aggiorna profilo
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? currentPassword,
    String? newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Ottieni token per le API
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  // Pulisci errore
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
