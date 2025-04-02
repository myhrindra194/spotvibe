// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

import '../models/my_user_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  MyUser? _user;
  String? errorMessage;
  bool _isLoading = false;

  MyUser? get user => _user;
  bool get isLoading => _isLoading;

  void signInWithEmail(String email, String password) {
    _isLoading = true;
    notifyListeners();

    _authRepository.signInWithEmail(email, password).then((user) {
      _user = user;
      errorMessage = user == null ? 'Password or email invalid' : null;
      _isLoading = false;
      notifyListeners();
    });
  }

  void signInWithGoogle() {
    _isLoading = true;
    notifyListeners();

    _authRepository.signInWithGoogle().then((user) {
      _user = user;
      errorMessage = user == null ? 'Failed to sign in with Google' : null;
      _isLoading = false;
      notifyListeners();
    });
  }

  void signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository
          .signOut(); // Attendre que la déconnexion soit terminée
      _user = null; // Réinitialiser l'utilisateur
      errorMessage = null; // Réinitialiser les messages d'erreur
    } catch (e) {
      errorMessage = 'Erreur lors de la déconnexion';
      print("Erreur lors de la déconnexion : $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
