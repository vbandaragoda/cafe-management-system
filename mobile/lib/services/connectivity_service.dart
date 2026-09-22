import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over connectivity_plus so the rest of the app depends
/// on a simple bool stream rather than the plugin's result-list API.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _anyOnline(results);
  }

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged.map(_anyOnline);

  bool _anyOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
