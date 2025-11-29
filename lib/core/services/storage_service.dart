import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地儲存服務
class StorageService {
  StorageService._(); // 單例模式

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  SharedPreferences? _prefs;

  /// 初始化（可選，會在首次使用時自動初始化）
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _sp async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 儲存 JSON 資料
  Future<void> setJson(String key, Object value) async {
    final sp = await _sp;
    await sp.setString(key, jsonEncode(value));
  }

  /// 讀取 List 資料
  Future<List<dynamic>> getList(String key) async {
    final sp = await _sp;
    final s = sp.getString(key);
    if (s == null || s.isEmpty) return [];
    try {
      return jsonDecode(s) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// 讀取 Map 資料
  Future<Map<String, dynamic>> getMap(String key) async {
    final sp = await _sp;
    final s = sp.getString(key);
    if (s == null || s.isEmpty) return {};
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// 讀取字串
  Future<String?> getString(String key) async {
    final sp = await _sp;
    return sp.getString(key);
  }

  /// 儲存字串
  Future<void> setString(String key, String value) async {
    final sp = await _sp;
    await sp.setString(key, value);
  }

  /// 讀取整數
  Future<int?> getInt(String key) async {
    final sp = await _sp;
    return sp.getInt(key);
  }

  /// 儲存整數
  Future<void> setInt(String key, int value) async {
    final sp = await _sp;
    await sp.setInt(key, value);
  }

  /// 讀取布林值
  Future<bool?> getBool(String key) async {
    final sp = await _sp;
    return sp.getBool(key);
  }

  /// 儲存布林值
  Future<void> setBool(String key, bool value) async {
    final sp = await _sp;
    await sp.setBool(key, value);
  }

  /// 刪除指定鍵值
  Future<void> remove(String key) async {
    final sp = await _sp;
    await sp.remove(key);
  }

  /// 清除所有資料
  Future<void> clear() async {
    final sp = await _sp;
    await sp.clear();
  }
}

// 為了向後相容，保留原本的 KV 類別
class KV {
  static Future<void> setJson(String k, Object v) =>
      StorageService.instance.setJson(k, v);

  static Future<List<dynamic>> getList(String k) =>
      StorageService.instance.getList(k);

  static Future<Map<String, dynamic>> getMap(String k) =>
      StorageService.instance.getMap(k);
}
