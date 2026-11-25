import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveAuthToken(String token) async {
    await _prefs?.setString(AppConstants.keyAuthToken, token);
  }

  static String? getAuthToken() {
    return _prefs?.getString(AppConstants.keyAuthToken);
  }

  static Future<void> saveUserRole(String role) async {
    await _prefs?.setString(AppConstants.keyUserRole, role);
  }

  static String getUserRole() {
    return _prefs?.getString(AppConstants.keyUserRole) ?? 'courier';
  }

  static Future<void> saveBusinessSlug(String slug) async {
    await _prefs?.setString(AppConstants.keyBusinessSlug, slug);
  }

  static String getBusinessSlug() {
    return _prefs?.getString(AppConstants.keyBusinessSlug) ?? 'reparto-cdmx';
  }

  static Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.keyThemeMode, mode);
  }

  static String getThemeMode() {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'light';
  }

  static Future<void> saveCourierOnline(bool isOnline) async {
    await _prefs?.setBool(AppConstants.keyIsOnline, isOnline);
  }

  static bool getCourierOnline() {
    return _prefs?.getBool(AppConstants.keyIsOnline) ?? true;
  }

  static Future<void> saveCourierId(String id) async {
    await _prefs?.setString(AppConstants.keyCourierId, id);
  }

  static String? getCourierId() {
    return _prefs?.getString(AppConstants.keyCourierId);
  }

  static Future<void> saveClientIdentifier(String identifier) async {
    await _prefs?.setString('client_identifier', identifier);
  }

  static String? getClientIdentifier() {
    return _prefs?.getString('client_identifier');
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
