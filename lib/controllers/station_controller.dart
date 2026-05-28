import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../model/station_model.dart';
import '../model/device_model.dart';
import '../model/home_data_model.dart';
import '../utils/network/api_service.dart';
import '../utils/toast_utils.dart';

class StationController extends GetxController {
  // 站点列表
  final stations = <StationModel>[].obs;
  // 当前选中的站点 ID
  final selectedStationId = ''.obs;
  // 当前站点的设备列表
  final devices = <DeviceModel>[].obs;
  // App 设备列表 (从新接口 /hems/app/device/getList 获取)
  final appDevices = <DeviceModel>[].obs;
  // 首页数据
  final homeData = Rxn<HomeDataModel>();

  // 能源来源图表数据
  final energyChartData = Rxn<Map<String, dynamic>>();
  // 能源概览数据
  final energySourcesData = Rxn<Map<String, dynamic>>();
  // 每日能量数据
  final energyDayData = Rxn<Map<String, dynamic>>();
  // 每日功率数据
  final powerDayData = Rxn<Map<String, dynamic>>();
  // 设备图表数据 (meterData)
  final meterData = Rxn<Map<String, dynamic>>();
  // 负荷图表数据 (fhChart)
  final fhChartData = Rxn<Map<String, dynamic>>();

  // 加载状态
  final isStationsLoading = false.obs;
  final isDevicesLoading = false.obs;
  final isHomeDataLoading = false.obs;
  final isEnergyChartLoading = false.obs;
  final isEnergySourcesLoading = false.obs;
  final isEnergyDayLoading = false.obs;
  final isPowerDayLoading = false.obs;
  final isMeterDataLoading = false.obs;
  final isFhChartLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载站点列表
    fetchStations();
  }

  // 获取站点列表
  Future<void> fetchStations() async {
    isStationsLoading.value = true;
    try {
      final response = await ApiService.getStationList();
      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] ?? [];
        stations.value = data
            .map((json) => StationModel.fromJson(json))
            .toList();

        // 如果有站点且未选中，默认选中第一个
        if (stations.isNotEmpty && selectedStationId.value.isEmpty) {
          selectStation(stations.first.id ?? '');
        } else {
          fetchDevices(selectedStationId.value);
          fetchHomeData(selectedStationId.value);
        }
      } else {
        ToastUtils.error(response['msg'] ?? 'fetch_stations_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Fetch Stations Exception: $e',
        name: 'StationController',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    } finally {
      isStationsLoading.value = false;
    }
  }

  // 选中站点并加载其设备和首页数据
  void selectStation(String stationId) {
    if (selectedStationId.value == stationId) return;
    selectedStationId.value = stationId;
    fetchDevices(stationId);
    fetchHomeData(stationId);

    // 同时也获取能源相关数据
    // 注意：这里需要 updateTime，而控制器不持有 updateTime 状态，
    // 所以这里的逻辑最好由 UI 层的监听器来触发，或者在 UI 层手动调用相关 fetch 方法。
  }

  // 获取首页数据
  Future<void> fetchHomeData(
    String stationId, {
    bool showLoading = true,
  }) async {
    if (stationId.isEmpty) return;

    if (showLoading) {
      isHomeDataLoading.value = true;
    }
    try {
      final response = await ApiService.getHomeData(stationId);
      if (response['code'] == 200) {
        homeData.value = HomeDataModel.fromJson(response['data'] ?? {});
      } else {
        // 静默失败，不弹出错误
        developer.log(
          'Fetch Home Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Home Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      if (showLoading) {
        isHomeDataLoading.value = false;
      }
    }
  }

  // 获取设备列表
  Future<void> fetchDevices(String stationId, {String deviceType = ''}) async {
    if (stationId.isEmpty) return;

    isDevicesLoading.value = true;
    try {
      final response = await ApiService.getDeviceList(stationId, deviceType);
      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] ?? [];
        devices.value = data.map((json) => DeviceModel.fromJson(json)).toList();
      } else {
        ToastUtils.error(response['msg'] ?? 'fetch_devices_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Fetch Devices Exception: $e',
        name: 'StationController',
        error: e,
      );
      // ToastUtils.error('network_error'.tr);
    } finally {
      isDevicesLoading.value = false;
    }
  }

  // 获取 App 设备列表 (使用新接口)
  Future<void> fetchAppDevices(String stationId) async {
    if (stationId.isEmpty) return;

    isDevicesLoading.value = true;
    try {
      final response = await ApiService.getAppDeviceList(stationId);
      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] ?? [];
        appDevices.value = data
            .map((json) => DeviceModel.fromJson(json))
            .toList();
      } else {
        ToastUtils.error(response['msg'] ?? 'fetch_devices_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Fetch App Devices Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isDevicesLoading.value = false;
    }
  }

  // 检查站点是否有绑定的设备
  Future<bool> hasDevices(String stationId) async {
    if (stationId.isEmpty) return false;
    try {
      final response = await ApiService.getDeviceList(stationId, '');
      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] ?? [];
        return data.isNotEmpty;
      }
    } catch (e) {
      developer.log('Check Devices Exception: $e', name: 'StationController');
    }
    return false;
  }

  // 刷新所有站点和当前选中的站点设备及首页数据
  Future<void> refreshCurrentStation() async {
    await fetchStations();
    if (selectedStationId.value.isNotEmpty) {
      await Future.wait([
        fetchDevices(selectedStationId.value),
        fetchHomeData(selectedStationId.value),
      ]);
    }
  }

  // 获取当前选中的站点对象
  StationModel? get selectedStation {
    if (selectedStationId.value.isEmpty) return null;
    return stations.firstWhereOrNull((s) => s.id == selectedStationId.value);
  }

  // 添加或编辑站点
  Future<bool> saveOrEditStation(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.saveOrEditStation(data);
      if (response['code'] == 200) {
        await fetchStations(); // 重新加载列表以更新数据
        return true;
      } else {
        ToastUtils.error(response['msg'] ?? 'save_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Save Station Exception: $e',
        name: 'StationController',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    }
    return false;
  }

  // 删除设备
  Future<bool> removeDevice(String deviceId) async {
    try {
      final response = await ApiService.removeDevice(deviceId);
      if (response['code'] == 200) {
        // 删除成功后，重新获取站点和设备数据
        await refreshCurrentStation();
        return true;
      } else {
        ToastUtils.error(response['msg'] ?? 'delete_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Remove Device Exception: $e',
        name: 'StationController',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    }
    return false;
  }

  // 删除站点
  Future<bool> removeStation(String stationId) async {
    try {
      final response = await ApiService.removeStation(stationId);
      if (response['code'] == 200) {
        // 如果删除的是当前选中的站点，清空选中状态
        if (selectedStationId.value == stationId) {
          selectedStationId.value = '';
        }
        // 删除成功后，重新获取所有站点数据
        await fetchStations();
        // 如果清空后重新获取有数据，fetchStations 内部逻辑会自动选择第一个
        return true;
      } else {
        ToastUtils.error(response['msg'] ?? 'delete_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Remove Station Exception: $e',
        name: 'StationController',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    }
    return false;
  }

  // 添加设备
  Future<Map<String, dynamic>> addDevice(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.addDevice(data);
      if (response['code'] == 200) {
        await refreshCurrentStation(); // 刷新当前站点的设备列表
      }
      return response;
    } catch (e) {
      developer.log(
        'Add Device Exception: $e',
        name: 'StationController',
        error: e,
      );
    }
    return {'code': 500, 'msg': 'network_error'.tr};
  }

  // 更换采集棒
  Future<Map<String, dynamic>> replaceDevice(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.replaceDevice(data);
      if (response['code'] == 200) {
        await refreshCurrentStation(); // 刷新数据
      }
      return response;
    } catch (e) {
      developer.log(
        'Replace Device Exception: $e',
        name: 'StationController',
        error: e,
      );
    }
    return {'code': 500, 'msg': 'network_error'.tr};
  }

  // 获取能源来源图表数据
  Future<void> fetchEnergyChartData({
    required String stationId,
    required String updateTime,
    int type = 1,
  }) async {
    if (stationId.isEmpty) return;

    isEnergyChartLoading.value = true;
    try {
      final response = await ApiService.getEnergySourcesChart({
        'stationId': stationId,
        'updateTime': updateTime,
        'type': type,
      });
      if (response['code'] == 200) {
        energyChartData.value = response['data'] ?? {};
      } else {
        developer.log(
          'Fetch Energy Chart Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Energy Chart Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isEnergyChartLoading.value = false;
    }
  }

  // 获取能源概览数据
  Future<void> fetchEnergySourcesData({
    required String stationId,
    required String updateTime,
  }) async {
    if (stationId.isEmpty) return;

    isEnergySourcesLoading.value = true;
    try {
      final response = await ApiService.getEnergySources({
        'stationId': stationId,
        'updateTime': updateTime,
      });
      if (response['code'] == 200) {
        energySourcesData.value = response['data'] ?? {};
      } else {
        developer.log(
          'Fetch Energy Sources Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Energy Sources Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isEnergySourcesLoading.value = false;
    }
  }

  // 获取每日能量图表数据
  Future<void> fetchEnergyDayData({
    required String stationId,
    required String updateTime,
  }) async {
    if (stationId.isEmpty) return;

    isEnergyDayLoading.value = true;
    try {
      final response = await ApiService.getEnergyDayChart({
        'stationId': stationId,
        'updateTime': updateTime,
      });
      if (response['code'] == 200) {
        energyDayData.value = response['data'] ?? {};
      } else {
        developer.log(
          'Fetch Energy Day Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Energy Day Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isEnergyDayLoading.value = false;
    }
  }

  // 获取每日功率图表数据
  Future<void> fetchPowerDayData({
    required String stationId,
    required String updateTime,
  }) async {
    if (stationId.isEmpty) return;

    isPowerDayLoading.value = true;
    try {
      final response = await ApiService.getPowerDayChart({
        'stationId': stationId,
        'updateTime': updateTime,
      });
      if (response['code'] == 200) {
        powerDayData.value = response['data'] ?? {};
      } else {
        developer.log(
          'Fetch Power Day Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Power Day Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isPowerDayLoading.value = false;
    }
  }

  // 获取设备图表数据
  Future<void> fetchMeterData(String deviceId) async {
    if (deviceId.isEmpty) return;

    isMeterDataLoading.value = true;
    try {
      final response = await ApiService.getMeterData(deviceId);
      if (response['code'] == 200) {
        meterData.value = response['data'];
      } else {
        developer.log(
          'Fetch Meter Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch Meter Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isMeterDataLoading.value = false;
    }
  }

  // 获取负荷图表数据
  Future<void> fetchFhChartData(String deviceId, String updateTime) async {
    if (deviceId.isEmpty) return;

    isFhChartLoading.value = true;
    try {
      final response = await ApiService.getFhChartData(deviceId, updateTime);
      if (response['code'] == 200) {
        fhChartData.value = response['data'];
      } else {
        developer.log(
          'Fetch FH Chart Data Failed: ${response['msg']}',
          name: 'StationController',
        );
      }
    } catch (e) {
      developer.log(
        'Fetch FH Chart Data Exception: $e',
        name: 'StationController',
        error: e,
      );
    } finally {
      isFhChartLoading.value = false;
    }
  }
}
