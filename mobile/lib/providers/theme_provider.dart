import 'package:flutter/material.dart';
import '../services/session_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SessionService _session;
  ThemeMode _mode = ThemeMode.system;

  ThemeProvider({SessionService? session}) : _session = session ?? SessionService() {
    _restore();
  }

  ThemeMode get mode => _mode;

  Future<void> _restore() async {
    final saved = await _session.readThemeMode();
    switch (saved) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _session.saveThemeMode(
      mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system'),
    );
  }
}
