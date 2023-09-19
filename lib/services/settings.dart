import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  final SharedPreferences prefs;

  Settings(this.prefs);

  int? getInt(String key) => prefs.getInt(key);
  bool? getBool(String key) => prefs.getBool(key);
  double? getDouble(String key) => prefs.getDouble(key);
  String? getString(String key) => prefs.getString(key);
  List<String>? getStringList(String key) => prefs.getStringList(key);

  Future<bool> setInt(String key, int value) async {
    Future<bool> success = prefs.setInt(key, value);
    notifyListeners();
    return success;
  }

  Future<bool> setBool(String key, bool value) async {
    Future<bool> success = prefs.setBool(key, value);
    notifyListeners();
    return success;
  }

  Future<bool> setDouble(String key, double value) async {
    Future<bool> success = prefs.setDouble(key, value);
    notifyListeners();
    return success;
  }

  Future<bool> setString(String key, String value) async {
    Future<bool> success = prefs.setString(key, value);
    notifyListeners();
    return success;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    Future<bool> success = prefs.setStringList(key, value);
    notifyListeners();
    return success;
  }

  Future<bool> remove(String key) async {
    Future<bool> success = prefs.remove(key);
    notifyListeners();
    return success;
  }
}
