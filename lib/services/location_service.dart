import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _locationEnabledKey = 'location_enabled';
  static const String _lastAddressKey = 'last_address';

  /// Vérifie si la localisation est activée côté app
  static Future<bool> isLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationEnabledKey) ?? false;
  }

  /// Active la localisation, demande la permission et récupère l'adresse
  static Future<String?> enableLocation() async {
    final prefs = await SharedPreferences.getInstance();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    String address = _placemarkToAddress(placemarks.first);
    await prefs.setBool(_locationEnabledKey, true);
    await prefs.setString(_lastAddressKey, address);
    return address;
  }

  /// Désactive la localisation côté app
  static Future<void> disableLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, false);
    await prefs.remove(_lastAddressKey);
  }

  /// Récupère la dernière adresse connue (ou null)
  static Future<String?> getLastAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastAddressKey);
  }

  /// Utilitaire pour formater une adresse à partir d'un Placemark
  static String _placemarkToAddress(Placemark placemark) {
    final List<String> parts = [
      if (placemark.locality != null && placemark.locality!.isNotEmpty) placemark.locality!,
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) placemark.administrativeArea!,
      if (placemark.country != null && placemark.country!.isNotEmpty) placemark.country!,
    ];
    return parts.join(', ');
  }
} 