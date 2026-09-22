/// App-wide constants: API endpoints, storage keys, business constants.
///
/// [apiBaseUrl] points at the Caffora Spring Boot backend
/// (see ../../../caffora-backend). Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
/// (10.0.2.2 is how the Android emulator reaches your host machine's
/// localhost; iOS simulator can use http://localhost:8080/api directly;
/// a physical device needs your machine's LAN IP.)
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration orderPollInterval = Duration(seconds: 8);
}

class StorageKeys {
  StorageKeys._();

  static const String authToken = 'caffora_auth_token';
  static const String authUser = 'caffora_auth_user';
  static const String themeMode = 'caffora_theme_mode';
  static const String guestMode = 'caffora_guest_mode';
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/detail';
  static const String admin = '/admin';
  static const String tableScan = '/table/scan';
  static const String profile = '/profile';
}
