import 'package:shared_preferences/shared_preferences.dart';

class GlobalConfig {
  static late SharedPreferences _prefs;

  static const String _baseUrlKey = 'baseUrl';
  static const String _secretStrKey = 'secretStr';
  static const String _fontSizeKey = 'fontSize';
  static const String _isLoggedInKey = 'isLoggedIn';

  static const String _defaultBaseUrl = 'https://api.example.com';
  static const String _defaultSecretStr = '';
  static const int _defaultFontSize = 13;
  static const bool _defaultIsLoggedIn = false;

  static const String _aiApiKeyKey = 'aiApiKey';
  static const String _aiUrlKey = 'aiUrl';
  static const String _aiModelKey = 'aiModel';

  static const String _defaultAiApiKey = 'sk-15632193f7784e5eadcf9e7199b301ea';
  static const String _defaultAiUrl =
      'https://api.deepseek.com/chat/completions';
  static const String _defaultAiModel = 'deepseek-coder';
  static const String _updateFailedNotesKey = 'updateFailedNotes';

  static String get aiApiKey =>
      _prefs.getString(_aiApiKeyKey) ?? _defaultAiApiKey;
  static set aiApiKey(String value) => _prefs.setString(_aiApiKeyKey, value);

  static String get aiUrl => _prefs.getString(_aiUrlKey) ?? _defaultAiUrl;
  static set aiUrl(String value) => _prefs.setString(_aiUrlKey, value);

  static String get aiModel => _prefs.getString(_aiModelKey) ?? _defaultAiModel;
  static set aiModel(String value) => _prefs.setString(_aiModelKey, value);

  static Future<void> setAiApiKey(String value) async {
    await _prefs.setString(_aiApiKeyKey, value);
  }

  static Future<void> setAiUrl(String value) async {
    await _prefs.setString(_aiUrlKey, value);
  }

  static Future<void> setAiModel(String value) async {
    await _prefs.setString(_aiModelKey, value);
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  //clear all data
  static Future<void> clear() async {
    await _prefs.remove(_baseUrlKey);
    await _prefs.remove(_secretStrKey);
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove(_isLoggedInKey);
    await _prefs.remove(_aiApiKeyKey);
    await _prefs.remove(_aiUrlKey);
    await _prefs.remove(_aiModelKey);
    await _prefs.remove(_updateFailedNotesKey);
  }

  static String get baseUrl => _prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  static set baseUrl(String value) => _prefs.setString(_baseUrlKey, value);

  static String get secretStr =>
      _prefs.getString(_secretStrKey) ?? _defaultSecretStr;
  static set secretStr(String value) => _prefs.setString(_secretStrKey, value);

  static int get fontSize => _prefs.getInt(_fontSizeKey) ?? _defaultFontSize;
  static set fontSize(int value) => _prefs.setInt(_fontSizeKey, value);

  static bool get isLoggedIn =>
      _prefs.getBool(_isLoggedInKey) ?? _defaultIsLoggedIn;

  static set isLoggedIn(bool value) => _prefs.setBool(_isLoggedInKey, value);

  static Future<void> setBaseUrl(String value) async {
    await _prefs.setString(_baseUrlKey, value);
  }

  static Future<void> setSecretStr(String value) async {
    await _prefs.setString(_secretStrKey, value);
  }

  static Future<void> setFontSize(int value) async {
    await _prefs.setInt(_fontSizeKey, value);
  }
}
