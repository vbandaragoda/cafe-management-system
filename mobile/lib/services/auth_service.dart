import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult({required this.token, required this.user});
}

/// Wraps /api/auth/* on the Caffora backend.
class AuthService {
  final ApiClient _client;
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    return _resultFromJson(json);
  }

  Future<AuthResult> register({required String name, required String email, required String password}) async {
    final json = await _client.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    return _resultFromJson(json);
  }

  Future<AppUser> me() async {
    final json = await _client.get('/auth/me') as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  AuthResult _resultFromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? json['accessToken'] as String? ?? '';
    final userJson = (json['user'] as Map<String, dynamic>?) ?? json;
    return AuthResult(token: token, user: AppUser.fromJson(userJson));
  }
}
