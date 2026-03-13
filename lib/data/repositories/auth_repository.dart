import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _authService.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(email: email, password: password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Stream<dynamic> get authStateChanges => _authService.authStateChanges;

  bool get isLoggedIn => _authService.currentUser != null;
}