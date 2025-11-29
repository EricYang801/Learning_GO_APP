import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KV {
  static Future<SharedPreferences> get _sp async =>
      SharedPreferences.getInstance();
  static Future<void> setJson(String k, Object v) async =>
      (await _sp).setString(k, jsonEncode(v));
  static Future<List<dynamic>> getList(String k) async {
    final s = (await _sp).getString(k);
    if (s == null || s.isEmpty) return [];
    try {
      return jsonDecode(s) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMap(String k) async {
    final s = (await _sp).getString(k);
    if (s == null || s.isEmpty) return {};
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
