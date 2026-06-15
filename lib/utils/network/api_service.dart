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
    return _httpManager.get('/sunbox/version/newOne');
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
    return _httpManager.get('/sunbox/basic/station/getList');
  }

  // 保存或编辑站点接口
  static Future<Map<String, dynamic>> saveOrEditStation(
    Map<String, dynamic> data,
  ) {
    return _httpManager.post('/sunbox/basic/station/saveOrEdit', data: data);
  }

  // 获取设备列表接口
  static Future<Map<String, dynamic>> getDeviceList(
    String stationId,
    String deviceType,
  ) {
    return _httpManager.get(
      '/sunbox/basic/device/getList',
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
      '/sunbox/app/device/getList',
      queryParameters: {'stationId': stationId},
    );
  }

  // 删除设备接口
  static Future<Map<String, dynamic>> removeDevice(String id) {
    return _httpManager.delete('/sunbox/basic/device/remove/$id');
  }

  // 删除站点接口
  static Future<Map<String, dynamic>> removeStation(String id) {
    return _httpManager.delete('/sunbox/basic/station/remove/$id');
  }

  // 添加设备接口
  static Future<Map<String, dynamic>> addDevice(Map<String, dynamic> data) {
    return _httpManager.post('/sunbox/app/home/device/addDevice', data: data);
  }

  // 更换设备接口
  static Future<Map<String, dynamic>> replaceDevice(Map<String, dynamic> data) {
    return _httpManager.post(
      '/sunbox/app/home/device/replaceDevice',
      data: data,
    );
  }

  // 验证设备 SN 接口
  static Future<Map<String, dynamic>> checkSN(String cpSn) {
    return _httpManager.post(
      '/sunbox/app/home/device/checkSN',
      data: {'cpSn': cpSn},
    );
  }

  // 验证设备 MAC 接口
  static Future<Map<String, dynamic>> checkMac(String deviceMac) {
    return _httpManager.post(
      '/sunbox/app/home/device/checkMac',
      data: {'deviceMac': deviceMac},
    );
  }

  // 获取首页数据接口
  static Future<Map<String, dynamic>> getHomeData(String stationId) {
    return _httpManager.get(
      '/sunbox/app/index/data',
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
    return _httpManager.get('/sunbox/hemsWorkOrder/list');
  }

  // 添加工单接口
  static Future<Map<String, dynamic>> addWorkOrder(Map<String, dynamic> data) {
    return _httpManager.post('/sunbox/hemsWorkOrder/addWorkOrder', data: data);
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
      '/sunbox/app/device/energySources',
      queryParameters: queryParameters,
    );
  }

  // 获取区域树接口
  static Future<Map<String, dynamic>> getRegionTree(String lang) {
    return _httpManager.get(
      '/sunbox/basic/region/tree',
      queryParameters: {'lang': lang},
    );
  }

  // 获取能源来源图表数据接口
  static Future<Map<String, dynamic>> getEnergySourcesChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/sunbox/app/device/energySourcesChart',
      queryParameters: queryParameters,
    );
  }

  // 获取每日能量图表数据接口
  static Future<Map<String, dynamic>> getEnergyDayChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/sunbox/app/device/energyDayChart',
      queryParameters: queryParameters,
    );
  }

  // 获取每日功率图表数据接口
  static Future<Map<String, dynamic>> getPowerDayChart(
    Map<String, dynamic> queryParameters,
  ) {
    return _httpManager.get(
      '/sunbox/app/device/powerDayChart',
      queryParameters: queryParameters,
    );
  }

  // 获取设备图表数据接口 (新)
  static Future<Map<String, dynamic>> getMeterData(String deviceId) {
    return _httpManager.get(
      '/sunbox/app/device/meterData',
      queryParameters: {'deviceId': deviceId},
    );
  }

  // 获取负荷图表数据接口 (fhChart)
  static Future<Map<String, dynamic>> getFhChartData(
    String deviceId,
    String updateTime,
  ) {
    return _httpManager.get(
      '/sunbox/app/device/fhChart',
      queryParameters: {'deviceId': deviceId, 'updateTime': updateTime},
    );
  }

  static Future<Map<String, dynamic>> rpcControl(Map<String, dynamic> data) {
    return _httpManager.get('/sunbox/common/rpc', queryParameters: data);
  }

  // 获取告警个数
  static Future<Map<String, dynamic>> getCountNumber() {
    return _httpManager.get('/sunbox/alarm/alarmDataCount');
  }

  // 标记告警已读
  static Future<Map<String, dynamic>> markAlarmRead(int id) {
    return _httpManager.get('/sunbox/alarm/read', queryParameters: {'id': id});
  }

  // 获取告警列表
  static Future<Map<String, dynamic>> getAlarmNewData({
    required int pageNum,
    required int pageSize,
    int status = 0,
    int? isRead,
  }) {
    final params = <String, dynamic>{
      'pageNum': pageNum,
      'pageSize': pageSize,
      'status': status,
    };
    if (isRead != null) {
      params['isRead'] = isRead;
    }
    return _httpManager.get(
      '/sunbox/alarm/alarmNewData',
      queryParameters: params,
    );
  }

  static Future<Map<String, dynamic>> getEnergyFlow({
    required String stationId,
    required String updateTime,
  }) {
    return _httpManager.get(
      '/sunbox/app/device/flow',
      queryParameters: {'stationId': stationId, 'updateTime': updateTime},
    );
  }

  // 查询充电实时数据
  static Future<Map<String, dynamic>> getChargeRealtime(
    String chargeConnectorId,
  ) {
    return _httpManager.get(
      '/sunbox/app/charge/realtime',
      queryParameters: {'chargeConnectorId': chargeConnectorId},
    );
  }

  // 获取当前用户可用于启动的默认idTag
  static Future<Map<String, dynamic>> getDefaultIdTag(
    String chargeConnectorId,
  ) {
    return _httpManager.get(
      '/sunbox/app/charge/idTag/default',
      queryParameters: {'chargeConnectorId': chargeConnectorId},
    );
  }

  // 按日期查询充电记录
  static Future<Map<String, dynamic>> getChargeRecordsByDate({
    required String chargeConnectorId,
    required String queryDate,
  }) {
    return _httpManager.post(
      '/sunbox/app/charge/records-by-date',
      data: {'chargeConnectorId': chargeConnectorId, 'queryDate': queryDate},
    );
  }

  // 开始充电
  static Future<Map<String, dynamic>> startCharge({
    required String chargeConnectorId,
    required String idTag,
  }) {
    return _httpManager.post(
      '/sunbox/app/charge/start',
      data: {'chargeConnectorId': chargeConnectorId, 'idTag': idTag},
    );
  }

  // 结束充电
  static Future<Map<String, dynamic>> stopCharge({
    required String chargeOrder,
    String? transactionId,
  }) {
    final Map<String, dynamic> data = {'chargeOrder': chargeOrder};
    if (transactionId != null) {
      data['transactionId'] = transactionId;
    }
    return _httpManager.post('/sunbox/app/charge/stop', data: data);
  }

  // 查询最新3条充电记录
  static Future<Map<String, dynamic>> getLatestChargeRecords(
    String chargeConnectorId,
  ) {
    return _httpManager.get(
      '/sunbox/app/charge/latest-records',
      queryParameters: {'chargeConnectorId': chargeConnectorId},
    );
  }

  // 新增或修改充电任务配置
  static Future<Map<String, dynamic>> saveOrUpdateChargeTaskConfig({
    required String chargeOrder,
    required int enableTask,
    String? id,
    double? maxPower,
    required String startTime,
    required int stopMode,
    String? stopTime,
  }) {
    final Map<String, dynamic> data = {
      'chargeOrder': chargeOrder,
      'enableTask': enableTask,
      'startTime': startTime,
      'stopMode': stopMode,
    };
    if (id != null && id.isNotEmpty) {
      data['id'] = id;
    }
    if (maxPower != null) {
      data['maxPower'] = maxPower;
    }
    if (stopTime != null && stopTime.isNotEmpty) {
      data['stopTime'] = stopTime;
    }
    return _httpManager.post(
      '/sunbox/charge/task-config/saveOrUpdate',
      data: data,
    );
  }

  // 根据充电枪号查询定时任务配置
  static Future<Map<String, dynamic>> getChargeTaskConfig({
    required String chargeOrder,
  }) {
    return _httpManager.get(
      '/sunbox/charge/task-config/getByChargeOrder',
      queryParameters: {'chargeOrder': chargeOrder},
    );
  }

  // 充电统计
  static Future<Map<String, dynamic>> getChargeStatistics({
    String? chargeConnectorId,
    required String startDate,
    required String endDate,
    required String type,
  }) {
    final Map<String, dynamic> data = {
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
    };
    if (chargeConnectorId != null) {
      data['chargeConnectorId'] = chargeConnectorId;
    }
    return _httpManager.post('/sunbox/app/charge/statistics', data: data);
  }
}
