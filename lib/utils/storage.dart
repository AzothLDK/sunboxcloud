import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as convert;

class GlobalStorage {
  GlobalStorage._internal();
  factory GlobalStorage() => _instance;
  static final GlobalStorage _instance = GlobalStorage._internal();
  static late final SharedPreferences _sp;
  // 添加一个标志来跟踪是否已初始化
  static bool _isInitialized = false;

  static Future<GlobalStorage> getInstance() async {
    // 只有在未初始化的情况下才进行初始化
    if (!_isInitialized) {
      _sp = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
    return _instance;
  }

  static String? getLoginInfo() {
    var modelJson = _sp.getString("userInfo");
    return modelJson;
  }

  static Future<void> saveLoginInfo(Map<dynamic, dynamic> userInfo) async {
    String saveTemp = convert.jsonEncode(userInfo);
    _sp.setString("userInfo", saveTemp);
  }

  static Future<void> saveUserPassWord(Map<String, dynamic> userInfo) async {
    String saveTemp = convert.jsonEncode(userInfo);
    _sp.setString("password", saveTemp);
  }

  static String? getPassword() {
    var modelJson = _sp.getString("password");
    return modelJson;
  }

  static String? getToken() {
    var modelJson = _sp.getString("token");
    return modelJson;
  }

  static Future<void> saveToken(String token) async {
    _sp.setString("token", token);
  }

  static Future<void> clearUserInfo() async {
    // 不使用_sp.clear()，而是逐个删除不需要的键
    await _sp.remove('userInfo');
    await _sp.remove('password');
    await _sp.remove('token');
    await _sp.remove('single');
    await _sp.remove('companyList');
    // 保留language键，不删除
  }

  static Future<void> clearUserInfoWithoutPassword() async {
    // 不使用_sp.clear()，而是逐个删除不需要的键
    await _sp.remove('userInfo');
    // await _sp.remove('password');
    await _sp.remove('token');
    await _sp.remove('single');
    await _sp.remove('companyList');
    // 保留language键，不删除
  }

  static Future<void> deleteKeyValue(String key) async {
    _sp.remove(key);
  }

  // 保存appId
  static Future<void> saveAppId(String appId) async {
    _sp.setString("appId", appId);
  }

  // 获取appId
  static String? getAppId() {
    return _sp.getString("appId");
  }

  // 保存用户是否为管理员
  static Future<void> saveIsAdmin(bool isAdmin) async {
    _sp.setBool("isAdmin", isAdmin);
  }

  // 获取用户是否为管理员
  static bool getIsAdmin() {
    return _sp.getBool("isAdmin") ?? false;
  }
}
