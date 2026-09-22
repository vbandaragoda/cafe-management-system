import 'package:geolocator/geolocator.dart';

/// Device-sensor feature #1 (geolocation), used on the Profile screen
/// for a "distance to the Caffora counter" estimate. Handles the
/// permission dance explicitly rather than assuming it's granted.
class LocationService {
  /// The Caffora flagship counter, used as a fixed reference point for
  /// the on-device distance calculation (no server round-trip needed).
  static const double storeLat = 51.5074;
  static const double storeLng = -0.1278;

  Future<LocationResult> getDistanceToStore() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure('Location services are turned off on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure('Location permission was denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure('Location permission is permanently denied. Enable it in device settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final meters = Geolocator.distanceBetween(position.latitude, position.longitude, storeLat, storeLng);
      return LocationResult.success(meters / 1000.0);
    } catch (e) {
      return LocationResult.failure('Could not read your current location.');
    }
  }
}

class LocationResult {
  final bool ok;
  final double? distanceKm;
  final String? error;

  LocationResult._(this.ok, this.distanceKm, this.error);

  factory LocationResult.success(double distanceKm) => LocationResult._(true, distanceKm, null);
  factory LocationResult.failure(String error) => LocationResult._(false, null, error);
}
