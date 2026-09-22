import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

/// Drives the "You are offline — showing cached data" banner seen on
/// the Orders screen in the Figma dark frame, plus gates whether
/// screens attempt a live fetch or fall back to the sqflite cache.
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service;
  bool _isOnline = true;
  StreamSubscription<bool>? _sub;

  ConnectivityProvider({ConnectivityService? service}) : _service = service ?? ConnectivityService() {
    _init();
  }

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    _isOnline = await _service.isOnline();
    notifyListeners();
    _sub = _service.onStatusChange.listen((online) {
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
