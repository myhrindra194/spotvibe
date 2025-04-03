import 'package:flutter/foundation.dart';

import '../models/my_user_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository;
  MyUser? _user;
  String? errorMessage;
  bool _isLoading = false;
  bool _isLoggingOut = false;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  MyUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithEmail(email, password);
      _user = user;
      errorMessage = user == null ? 'Invalid email or password' : null;
    } catch (e) {
      errorMessage = 'Sign-in failed: ${e.toString()}';
      if (kDebugMode) print('Sign-in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      _user = user;
      errorMessage = user == null ? 'Google sign-in failed' : null;
    } catch (e) {
      errorMessage = 'Google sign-in failed: ${e.toString()}';
      if (kDebugMode) print('Google sign-in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    if (_isLoggingOut) return false;

    _isLoggingOut = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _user = null;
      return true;
    } catch (e) {
      errorMessage = 'Logout failed: ${e.toString()}';
      if (kDebugMode) print('Logout error: $e');
      return false;
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }
}
