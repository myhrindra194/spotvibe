import 'package:firebase_auth/firebase_auth.dart';

import '../models/my_user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<MyUser?> signUpWithEmail(
      String email, String password, String name) async {
    User? user = await _authService.signUpWithEmailAndPassword(email, password);
    if (user != null) {
      return MyUser(id: user.uid, email: email, name: name);
    }
    return null;
  }

  Future<MyUser?> signInWithEmail(String email, String password) async {
    User? user = await _authService.signInWithEmailAndPassword(email, password);
    if (user != null) {
      return MyUser(id: user.uid, email: email, name: user.displayName ?? '');
    }
    return null;
  }

  Future<MyUser?> signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      return MyUser(
          id: user.uid, email: user.email ?? '', name: user.displayName ?? '');
    }
    return null;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
