import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

enum AuthStatus { unknown, guest, authenticated }

/// Owns the 3-role access model the assignment asks for: an
/// unauthenticated [AuthStatus.guest] browsing the public menu, an
/// authenticated CUSTOMER ("Registered User"), and an authenticated
/// ADMIN — [isAdmin] is what every admin-only screen/action checks.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SessionService _session;

  AuthProvider({AuthService? authService, SessionService? session})
      : _authService = authService ?? AuthService(),
        _session = session ?? SessionService() {
    _restore();
  }

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isGuest => status == AuthStatus.guest;

  Future<void> _restore() async {
    final token = await _session.readToken();
    final storedUser = await _session.readUser();
    if (token != null && token.isNotEmpty && storedUser != null) {
      user = storedUser;
      status = AuthStatus.authenticated;
    } else if (await _session.readGuestMode()) {
      status = AuthStatus.guest;
    } else {
      status = AuthStatus.guest;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email: email, password: password);
      await _session.saveSession(token: result.token, user: result.user);
      user = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Could not reach the Caffora server. Check your connection and try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _authService.register(name: name, email: email, password: password);
      await _session.saveSession(token: result.token, user: result.user);
      user = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.fieldErrors?.isNotEmpty == true ? e.fieldErrors!.join('\n') : e.message;
      return false;
    } catch (_) {
      error = 'Could not reach the Caffora server. Check your connection and try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    await _session.enterGuestMode();
    status = AuthStatus.guest;
    user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _session.clearSession();
    user = null;
    status = AuthStatus.guest;
    notifyListeners();
  }
}
