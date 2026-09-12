import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  // نمط Singleton لضمان نسخة واحدة في كل التطبيق
  static final AppStorage _instance = AppStorage._internal();
  factory AppStorage() => _instance;
  AppStorage._internal();

  static SharedPreferences? _preferences;

  // مفاتيح التخزين الثابتة لتجنب الأخطاء الإملائية
  static const String _keyToken = 'auth_token';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyThemeMode = 'is_dark_mode';

  /// دالة التهيئة المسبقة (يتم استدعاؤها في main.dart)
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  //  دوال عامة (Generic Helpers) 

  static Future<bool> setString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  static String? getString(String key) {
    return _preferences?.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _preferences?.getBool(key) ?? defaultValue;
  }

  static Future<bool> setInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  //  دوال مخصصة للمصادقة وتطبيق المترو 

  /// حفظ بيانات الجلسة عند نجاح تسجيل الدخول
  static Future<void> saveUserSession({
    required String token,
    String? userId,
    String? userName,
  }) async {
    await _preferences?.setString(_keyToken, token);
    await _preferences?.setBool(_keyIsLoggedIn, true);
    if (userId != null) await _preferences?.setString(_keyUserId, userId);
    if (userName != null) await _preferences?.setString(_keyUserName, userName);
  }

  /// جلب الـ Token الحالي
  static String? getToken() {
    return _preferences?.getString(_keyToken);
  }

  /// معرفة هل المستخدم مسجل دخول حالياً
  static bool isLoggedIn() {
    return _preferences?.getBool(_keyIsLoggedIn) ?? false;
  }

  /// تسجيل الخروج ومسح بيانات الجلسة فقط
  static Future<void> clearSession() async {
    await _preferences?.remove(_keyToken);
    await _preferences?.remove(_keyUserId);
    await _preferences?.remove(_keyUserName);
    await _preferences?.setBool(_keyIsLoggedIn, false);
  }

  /// مسح كل شيء تماماً من ذاكرة الهاتف
  static Future<bool> clearAll() async {
    return await _preferences?.clear() ?? false;
  }

  Future load() async {}

  Future<void> save(Map<String, Object> map) async {}
}