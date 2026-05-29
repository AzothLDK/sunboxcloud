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

  // 获取新版本号接口
  static Future<Map<String, dynamic>> getNewVersion() {
    return _httpManager.get('/hems/version/newOne');
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

  // 保存或编辑站点接口
  static Future<Map<String, dynamic>> saveOrEditStation(
    Map<String, dynamic> data,
  ) {
    return _httpManager.post('/hems/basic/station/saveOrEdit', data: data);
  }

  // 获取设备列表接口
  static Future<Map<String, dynamic>> getDeviceList(
    String stationId,
    String deviceType,
  ) {
    return _httpManager.get(
      '/hems/basic/device/getList',
      queryParameters: {
        'stationId': stationId,
        'deviceTypes': deviceType,
        'excludeChildren': true,
      },
    );
  }

  // 获取 App 设备列表接口 (新)
  static Future<Map<String, dynamic>> getAppDeviceList(String stationId) {
    return _httpManager.get(
      '/hems/app/device/getList',
      queryParameters: {'stationId': stationId},
    );
  }

  // 删除设备接口
  static Future<Map<String, dynamic>> removeDevice(String id) {
    return _httpManager.delete('/hems/basic/device/remove/$id');
  }

  // 删除站点接口
  static Future<Map<String, dynamic>> removeStation(String id) {
    return _httpManager.delete('/hems/basic/station/remove/$id');
  }

  // 添加设备接口
  static Future<Map<String, dynamic>> addDevice(Map<String, dynamic> data) {
    return _httpManager.post('/hems/basic/device/addDevice', data: data);
  }

  // 更换设备接口
  static Future<Map<String, dynamic>> replaceDevice(Map<String, dynamic> data) {
    return _httpManager.post('/hems/basic/device/replaceDevice', data: data);
  }

  // 验证设备 SN 接口
  static Future<Map<String, dynamic>> checkSN(String cpSn) {
    return _httpManager.post(
      '/hems/basic/device/checkSN',
      data: {'cpSn': cpSn},
    );
  }

  // 验证设备 MAC 接口
  static Future<Map<String, dynamic>> checkMac(String deviceMac) {
    return _httpManager.post(
      '/hems/basic/device/checkMac',
      data: {'deviceMac': deviceMac},
    );
  }

  // 获取首页数据接口
  static Future<Map<String, dynamic>> getHomeData(String stationId) {
    return _httpManager.get(
      '/hems/app/index/data',
      queryParameters: {'stationId': stationId},
    );
  }

  // 获取登录用户信息接口
  static Future<Map<String, dynamic>> getSunboxLoginInfo() {
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

  // 上传图片接口
  static Future<Map<String, dynamic>> uploadImage(
    String filePath, {
    Map<String, dynamic>? data,
  }) {
    return _httpManager.uploadFile(
      '/admin/system/file/upload',
      filePath,
      data: data,
    );
  }

  // 获取工单列表接口
  static Future<Map<String, dynamic>> getWorkOrderList() {
    return _httpManager.get('/hems/hemsWorkOrder/list');
  }

  // 添加工单接口
  static Future<Map<String, dynamic>> addWorkOrder(Map<String, dynamic> data) {
    return _httpManager.post('/hems/hemsWorkOrder/addWorkOrder', data: data);
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

  // 苹果Token登录接口
  static Future<Map<String, dynamic>> loginByAppleToken(
    Map<String, dynamic> data,
  ) {
    return _httpManager.post(
      '/admin/system/mobileApp/loginByAppleIdToken',
      data: data,
    );
  }

  static Future<Map<String, dynamic>> getEnergySources(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/hems/app/device/energySources',
      queryParameters: queryParameters,
    );
  }

  // 获取区域树接口
  static Future<Map<String, dynamic>> getRegionTree(String lang) {
    return _httpManager.get(
      '/hems/basic/region/tree',
      queryParameters: {'lang': lang},
    );
  }

  // 获取能源来源图表数据接口
  static Future<Map<String, dynamic>> getEnergySourcesChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/hems/app/device/energySourcesChart',
      queryParameters: queryParameters,
    );
  }

  // 获取每日能量图表数据接口
  static Future<Map<String, dynamic>> getEnergyDayChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/hems/app/device/energyDayChart',
      queryParameters: queryParameters,
    );
  }

  // 获取每日功率图表数据接口
  static Future<Map<String, dynamic>> getPowerDayChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/hems/app/device/powerDayChart',
      queryParameters: queryParameters,
    );
  }

  // 获取设备图表数据接口 (新)
  static Future<Map<String, dynamic>> getMeterData(String deviceId) {
    return _httpManager.get(
      '/hems/app/device/meterData',
      queryParameters: {'deviceId': deviceId},
    );
  }

  // 获取负荷图表数据接口 (fhChart)
  static Future<Map<String, dynamic>> getFhChartData(
    String deviceId,
    String updateTime,
  ) {
    return _httpManager.get(
      '/hems/app/device/fhChart',
      queryParameters: {'deviceId': deviceId, 'updateTime': updateTime},
    );
  }

  static Future<Map<String, dynamic>> rpcControl(Map<String, dynamic> data) {
    return _httpManager.post('/hems/common/rpc', data: data);
  }
}
