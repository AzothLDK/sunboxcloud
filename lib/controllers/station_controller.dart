import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../model/station_model.dart';
import '../model/device_model.dart';
import '../utils/network/api_service.dart';
import '../utils/toast_utils.dart';

class StationController extends GetxController {
  // 站点列表
  final stations = <StationModel>[].obs;
  // 当前选中的站点 ID
  final selectedStationId = ''.obs;
  // 当前站点的设备列表
  final devices = <DeviceModel>[].obs;

  // 加载状态
  final isStationsLoading = false.obs;
  final isDevicesLoading = false.obs;

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

  // 选中站点并加载其设备
  void selectStation(String stationId) {
    if (selectedStationId.value == stationId) return;
    selectedStationId.value = stationId;
    fetchDevices(stationId);
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

  // 刷新所有站点和当前选中的站点设备
  Future<void> refreshCurrentStation() async {
    await fetchStations();
    if (selectedStationId.value.isNotEmpty) {
      await fetchDevices(selectedStationId.value);
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
        // 本地更新列表，避免全量刷新
        devices.removeWhere((d) => d.id == deviceId);
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

  // 添加设备
  Future<bool> addDevice(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.addDevice(data);
      if (response['code'] == 200) {
        await refreshCurrentStation(); // 刷新当前站点的设备列表
        return true;
      } else {
        ToastUtils.error(response['msg'] ?? 'add_device_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Add Device Exception: $e',
        name: 'StationController',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    }
    return false;
  }
}
