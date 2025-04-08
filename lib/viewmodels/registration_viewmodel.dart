import 'package:flutter/foundation.dart';

import '../models/my_user_model.dart';
import '../repositories/auth_repository.dart';

class RegistrationViewModel with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  MyUser? _user;
  String? errorMessage;
  bool _isLoading = false;

  MyUser? get user => _user;
  bool get isLoading => _isLoading;

  void signUpWithEmail(String email, String password, String name) {
    _isLoading = true;
    notifyListeners();

    _authRepository.signUpWithEmail(email, password, name).then((user) {
      _user = user;
      errorMessage = user == null ? 'Password or email invalid' : null;
      _isLoading = false;
      notifyListeners();
    });
  }
}
