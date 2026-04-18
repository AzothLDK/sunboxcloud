import 'package:dio/dio.dart';
import 'package:sunboxcloud/utils/network/http_manager.dart';

class ApiService {
  static final HttpManager _httpManager = HttpManager();

  // 获取验证码图片和UUID
  static Future<Map<String, dynamic>> getCaptchaImage() {
    return _httpManager.get('/admin/system/captchaImage');
  }

  // 登录接口
  static Future<Map<String, dynamic>> login(String data) {
    return _httpManager.login('/admin/system/loginNoCaptcha', data: data);
  }

  // 发送邮箱验证码接口
  static Future<Map<String, dynamic>> sendEmailCode(Map<String, dynamic> data) {
    return _httpManager.post(
      '/admin/system/mobileApp/sendEmailCode',
      data: data,
    );
  }

  // 验证邮箱验证码接口
  static Future<Map<String, dynamic>> verifyCode(String data) {
    return _httpManager.post('/admin/system/mobileApp/VerifyCode', data: data);
  }

  // 注册接口
  static Future<Map<String, dynamic>> register(String data) {
    return _httpManager.post('/admin/system/mobileApp/register', data: data);
  }

  // 重置密码接口
  static Future<Map<String, dynamic>> resetPassword(String data) {
    return _httpManager.post(
      '/admin/system/mobileApp/resetPassword',
      data: data,
    );
  }

  // 修改邮箱接口
  static Future<Map<String, dynamic>> editEmail(Map<String, dynamic> data) {
    return _httpManager.post('/admin/system/mobileUser/editMaiL', data: data);
  }

  // 修改用户信息接口
  static Future<Map<String, dynamic>> editUser(FormData formData) {
    return _httpManager.post(
      '/admin/system/mobileUser/editUser',
      data: formData,
    );
  }

  // 获取站点列表接口
  static Future<Map<String, dynamic>> getStationList() {
    return _httpManager.get('/hems/basic/station/getList');
  }

  // 获取登录用户信息接口
  static Future<Map<String, dynamic>> getLoginInfo() {
    return _httpManager.get('/admin/system/getInfo');
  }

  // 获取路由接口
  static Future<Map<String, dynamic>> getRouters(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/admin/system/getRouters',
      queryParameters: queryParameters,
    );
  }

  // 谷歌Token登录接口
  static Future<Map<String, dynamic>> loginByGoogleToken(
    Map<String, dynamic> data,
  ) {
    return _httpManager.post(
      '/admin/system/mobileApp/loginByGoogleToken',
      data: data,
    );
  }
}
