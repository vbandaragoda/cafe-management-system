import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user.dart';

/// Persists the JWT + logged-in user across app restarts, and the
/// user's theme preference. Backed by shared_preferences (simple
/// key/value, appropriate for a token string and a small JSON blob —
/// the larger relational cache lives in sqflite, see local_db_service).
class SessionService {
  Future<void> saveSession({required String token, required AppUser user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.authToken, token);
    await prefs.setString(StorageKeys.authUser, jsonEncode(user.toJson()));
    await prefs.setBool(StorageKeys.guestMode, false);
  }

  Future<void> enterGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.authUser);
    await prefs.setBool(StorageKeys.guestMode, true);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.authUser);
    await prefs.setBool(StorageKeys.guestMode, false);
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authToken);
  }

  Future<AppUser?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.authUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> readGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.guestMode) ?? false;
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode);
  }

  Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.themeMode);
  }
}
